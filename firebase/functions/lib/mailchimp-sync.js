"use strict";
/**
 * Mailchimp Email Marketing Sync
 *
 * Syncs user email consent to Mailchimp audience when consent is updated in Firestore.
 * GDPR-compliant: only adds users who have explicitly opted in, and removes them when they opt out.
 *
 * Setup Instructions:
 * 1. Get your Mailchimp API key from: Account → Extras → API Keys
 * 2. Get your Audience ID from: Audience → Settings → Audience name and defaults
 * 3. Set Firebase config:
 *    firebase functions:config:set mailchimp.api_key="YOUR_API_KEY"
 *    firebase functions:config:set mailchimp.audience_id="YOUR_AUDIENCE_ID"
 *    firebase functions:config:set mailchimp.server_prefix="us1"  // e.g., us1, us2, etc.
 * 4. Deploy functions: firebase deploy --only functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncAllEmailConsentsToMailchimp = exports.syncEmailConsentToMailchimp = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const db = admin.firestore();
// Get Mailchimp config from Firebase environment
const getMailchimpConfig = () => {
    const config = functions.config().mailchimp;
    if (!config) {
        throw new Error('Mailchimp config not set. Run: firebase functions:config:set mailchimp.api_key="YOUR_KEY" mailchimp.audience_id="YOUR_ID" mailchimp.server_prefix="us1"');
    }
    return {
        apiKey: config.api_key,
        audienceId: config.audience_id,
        serverPrefix: config.server_prefix || 'us1'
    };
};
/**
 * Subscribe a user to Mailchimp
 */
const subscribeToMailchimp = async (email, userId) => {
    var _a, _b, _c;
    const config = getMailchimpConfig();
    const url = `https://${config.serverPrefix}.api.mailchimp.com/3.0/lists/${config.audienceId}/members`;
    try {
        const response = await axios_1.default.post(url, {
            email_address: email,
            status: 'subscribed', // Single opt-in (user already consented in app)
            merge_fields: {
                UID: userId, // Store user ID for reference
            },
            tags: ['NutraSafe App']
        }, {
            auth: {
                username: 'anystring', // Mailchimp uses 'anystring' as username
                password: config.apiKey
            },
            headers: {
                'Content-Type': 'application/json'
            }
        });
        console.log(`✅ Subscribed ${email} to Mailchimp:`, response.data.id);
    }
    catch (error) {
        if (((_b = (_a = error.response) === null || _a === void 0 ? void 0 : _a.data) === null || _b === void 0 ? void 0 : _b.title) === 'Member Exists') {
            // User already subscribed - update their status
            await updateMailchimpSubscription(email, 'subscribed');
        }
        else {
            console.error(`❌ Failed to subscribe ${email}:`, ((_c = error.response) === null || _c === void 0 ? void 0 : _c.data) || error.message);
            throw error;
        }
    }
};
/**
 * Update existing Mailchimp subscription status
 */
const updateMailchimpSubscription = async (email, status) => {
    var _a;
    const config = getMailchimpConfig();
    // Generate subscriber hash (MD5 of lowercase email)
    const crypto = require('crypto');
    const subscriberHash = crypto.createHash('md5').update(email.toLowerCase()).digest('hex');
    const url = `https://${config.serverPrefix}.api.mailchimp.com/3.0/lists/${config.audienceId}/members/${subscriberHash}`;
    try {
        const response = await axios_1.default.patch(url, {
            status: status
        }, {
            auth: {
                username: 'anystring',
                password: config.apiKey
            },
            headers: {
                'Content-Type': 'application/json'
            }
        });
        console.log(`✅ Updated ${email} to status "${status}":`, response.data.id);
    }
    catch (error) {
        console.error(`❌ Failed to update ${email}:`, ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
        throw error;
    }
};
/**
 * Unsubscribe a user from Mailchimp
 */
const unsubscribeFromMailchimp = async (email) => {
    await updateMailchimpSubscription(email, 'unsubscribed');
};
/**
 * Firestore Trigger: Sync email consent changes to Mailchimp
 *
 * Triggers when user document is created or updated
 */
exports.syncEmailConsentToMailchimp = functions.firestore
    .document('users/{userId}')
    .onWrite(async (change, context) => {
    const userId = context.params.userId;
    // Get current data
    const newData = change.after.exists ? change.after.data() : null;
    const oldData = change.before.exists ? change.before.data() : null;
    // Check if email consent fields exist and have changed
    const newConsent = newData === null || newData === void 0 ? void 0 : newData.emailMarketingConsent;
    const oldConsent = oldData === null || oldData === void 0 ? void 0 : oldData.emailMarketingConsent;
    const isWithdrawn = (newData === null || newData === void 0 ? void 0 : newData.emailMarketingConsentWithdrawn) || false;
    const email = newData === null || newData === void 0 ? void 0 : newData.email;
    // Skip if no email address
    if (!email || email === '') {
        console.log(`⏭️  Skipping sync for ${userId}: no email address`);
        return null;
    }
    // Skip if consent hasn't changed
    if (newConsent === oldConsent && isWithdrawn === (oldData === null || oldData === void 0 ? void 0 : oldData.emailMarketingConsentWithdrawn)) {
        console.log(`⏭️  Skipping sync for ${userId}: no consent change`);
        return null;
    }
    try {
        if (newConsent === true && !isWithdrawn) {
            // User opted in - subscribe to Mailchimp
            console.log(`📧 User ${userId} opted IN - subscribing ${email} to Mailchimp`);
            await subscribeToMailchimp(email, userId);
        }
        else if (newConsent === false || isWithdrawn) {
            // User opted out - unsubscribe from Mailchimp
            console.log(`🚫 User ${userId} opted OUT - unsubscribing ${email} from Mailchimp`);
            await unsubscribeFromMailchimp(email);
        }
        return null;
    }
    catch (error) {
        console.error(`❌ Mailchimp sync failed for ${userId}:`, error);
        // Don't throw - we don't want to fail the user's action if Mailchimp is down
        return null;
    }
});
/**
 * Manual function to sync all opted-in users to Mailchimp
 *
 * Usage: firebase functions:call syncAllEmailConsentsToMailchimp
 */
exports.syncAllEmailConsentsToMailchimp = functions.https.onCall(async (data, context) => {
    // Require authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated to sync emails');
    }
    // TODO: Add admin check here if needed
    // const userDoc = await db.collection('users').doc(context.auth.uid).get();
    // if (!userDoc.data()?.isAdmin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Must be admin');
    // }
    let syncedCount = 0;
    let errorCount = 0;
    try {
        // Get all users who have opted in
        const usersSnapshot = await db.collection('users')
            .where('emailMarketingConsent', '==', true)
            .where('emailMarketingConsentWithdrawn', '==', false)
            .get();
        console.log(`📊 Found ${usersSnapshot.size} users with email consent`);
        // Sync each user
        for (const doc of usersSnapshot.docs) {
            const userData = doc.data();
            const email = userData.email;
            if (!email || email === '') {
                console.log(`⏭️  Skipping ${doc.id}: no email`);
                continue;
            }
            try {
                await subscribeToMailchimp(email, doc.id);
                syncedCount++;
            }
            catch (error) {
                console.error(`❌ Failed to sync ${email}:`, error);
                errorCount++;
            }
        }
        console.log(`✅ Sync complete: ${syncedCount} synced, ${errorCount} errors`);
        return {
            success: true,
            syncedCount,
            errorCount,
            totalUsers: usersSnapshot.size
        };
    }
    catch (error) {
        console.error('❌ Bulk sync failed:', error);
        throw new functions.https.HttpsError('internal', `Sync failed: ${error.message}`);
    }
});
//# sourceMappingURL=mailchimp-sync.js.map