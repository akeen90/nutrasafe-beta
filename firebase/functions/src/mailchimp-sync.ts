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

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

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
const subscribeToMailchimp = async (email: string, userId: string): Promise<void> => {
  const config = getMailchimpConfig();
  const url = `https://${config.serverPrefix}.api.mailchimp.com/3.0/lists/${config.audienceId}/members`;

  try {
    const response = await axios.post(
      url,
      {
        email_address: email,
        status: 'subscribed', // Single opt-in (user already consented in app)
        merge_fields: {
          UID: userId, // Store user ID for reference
        },
        tags: ['NutraSafe App']
      },
      {
        auth: {
          username: 'anystring', // Mailchimp uses 'anystring' as username
          password: config.apiKey
        },
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log(`✅ Subscribed ${email} to Mailchimp:`, response.data.id);
  } catch (error: any) {
    if (error.response?.data?.title === 'Member Exists') {
      // User already subscribed - update their status
      await updateMailchimpSubscription(email, 'subscribed');
    } else {
      console.error(`❌ Failed to subscribe ${email}:`, error.response?.data || error.message);
      throw error;
    }
  }
};

/**
 * Update existing Mailchimp subscription status
 */
const updateMailchimpSubscription = async (email: string, status: 'subscribed' | 'unsubscribed'): Promise<void> => {
  const config = getMailchimpConfig();

  // Generate subscriber hash (MD5 of lowercase email)
  const crypto = require('crypto');
  const subscriberHash = crypto.createHash('md5').update(email.toLowerCase()).digest('hex');

  const url = `https://${config.serverPrefix}.api.mailchimp.com/3.0/lists/${config.audienceId}/members/${subscriberHash}`;

  try {
    const response = await axios.patch(
      url,
      {
        status: status
      },
      {
        auth: {
          username: 'anystring',
          password: config.apiKey
        },
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log(`✅ Updated ${email} to status "${status}":`, response.data.id);
  } catch (error: any) {
    console.error(`❌ Failed to update ${email}:`, error.response?.data || error.message);
    throw error;
  }
};

/**
 * Unsubscribe a user from Mailchimp
 */
const unsubscribeFromMailchimp = async (email: string): Promise<void> => {
  await updateMailchimpSubscription(email, 'unsubscribed');
};

/**
 * Firestore Trigger: Sync email consent changes to Mailchimp
 *
 * Triggers when user document is created or updated
 */
export const syncEmailConsentToMailchimp = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;

    // Get current data
    const newData = change.after.exists ? change.after.data() : null;
    const oldData = change.before.exists ? change.before.data() : null;

    // Check if email consent fields exist and have changed
    const newConsent = newData?.emailMarketingConsent;
    const oldConsent = oldData?.emailMarketingConsent;
    const isWithdrawn = newData?.emailMarketingConsentWithdrawn || false;
    const email = newData?.email;

    // Skip if no email address
    if (!email || email === '') {
      console.log(`⏭️  Skipping sync for ${userId}: no email address`);
      return null;
    }

    // Skip if consent hasn't changed
    if (newConsent === oldConsent && isWithdrawn === oldData?.emailMarketingConsentWithdrawn) {
      console.log(`⏭️  Skipping sync for ${userId}: no consent change`);
      return null;
    }

    try {
      if (newConsent === true && !isWithdrawn) {
        // User opted in - subscribe to Mailchimp
        console.log(`📧 User ${userId} opted IN - subscribing ${email} to Mailchimp`);
        await subscribeToMailchimp(email, userId);
      } else if (newConsent === false || isWithdrawn) {
        // User opted out - unsubscribe from Mailchimp
        console.log(`🚫 User ${userId} opted OUT - unsubscribing ${email} from Mailchimp`);
        await unsubscribeFromMailchimp(email);
      }

      return null;
    } catch (error: any) {
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
export const syncAllEmailConsentsToMailchimp = functions.https.onCall(async (data, context) => {
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
      } catch (error) {
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
  } catch (error: any) {
    console.error('❌ Bulk sync failed:', error);
    throw new functions.https.HttpsError('internal', `Sync failed: ${error.message}`);
  }
});
