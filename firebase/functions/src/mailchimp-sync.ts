/**
 * Mailchimp Email Sync for Essential Updates
 *
 * Automatically syncs all new users to Mailchimp for essential app updates.
 * Every user who signs up is added to the Mailchimp audience.
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
 * Firestore Trigger: Auto-sync new users to Mailchimp for essential updates
 *
 * Triggers when a new user document is created - adds them to Mailchimp automatically
 */
export const syncEmailConsentToMailchimp = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const userData = snapshot.data();
    const email = userData?.email;
    const displayName = userData?.displayName || userData?.name || '';

    // Skip if no email address
    if (!email || email === '') {
      console.log(`⏭️  Skipping sync for ${userId}: no email address`);
      return null;
    }

    try {
      console.log(`📧 New user ${userId} - adding ${email} to Mailchimp for essential updates`);
      await subscribeToMailchimpWithName(email, userId, displayName);
      return null;
    } catch (error: any) {
      console.error(`❌ Mailchimp sync failed for ${userId}:`, error);
      // Don't throw - we don't want to fail user creation if Mailchimp is down
      return null;
    }
  });

/**
 * Subscribe a user to Mailchimp with name fields
 */
const subscribeToMailchimpWithName = async (email: string, userId: string, displayName: string): Promise<void> => {
  const config = getMailchimpConfig();
  const url = `https://${config.serverPrefix}.api.mailchimp.com/3.0/lists/${config.audienceId}/members`;

  const nameParts = displayName.split(' ');
  const firstName = nameParts[0] || '';
  const lastName = nameParts.slice(1).join(' ') || '';

  try {
    const response = await axios.post(
      url,
      {
        email_address: email,
        status: 'subscribed',
        merge_fields: {
          FNAME: firstName,
          LNAME: lastName,
          UID: userId,
        },
        tags: ['NutraSafe App', 'Essential Updates']
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

    console.log(`✅ Added ${email} to Mailchimp:`, response.data.id);
  } catch (error: any) {
    if (error.response?.data?.title === 'Member Exists') {
      console.log(`ℹ️  ${email} already exists in Mailchimp`);
    } else {
      console.error(`❌ Failed to add ${email}:`, error.response?.data || error.message);
      throw error;
    }
  }
};

/**
 * Manual function to sync all users to Mailchimp for essential updates
 *
 * Usage: firebase functions:call syncAllEmailConsentsToMailchimp
 */
export const syncAllEmailConsentsToMailchimp = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated to sync emails');
  }

  let syncedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  try {
    // Get all users with email addresses
    const usersSnapshot = await db.collection('users').get();

    console.log(`📊 Found ${usersSnapshot.size} total users`);

    // Sync each user
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const email = userData.email;
      const displayName = userData.displayName || userData.name || '';

      if (!email || email === '') {
        console.log(`⏭️  Skipping ${doc.id}: no email`);
        skippedCount++;
        continue;
      }

      try {
        await subscribeToMailchimpWithName(email, doc.id, displayName);
        syncedCount++;
      } catch (error) {
        console.error(`❌ Failed to sync ${email}:`, error);
        errorCount++;
      }
    }

    console.log(`✅ Sync complete: ${syncedCount} synced, ${skippedCount} skipped, ${errorCount} errors`);

    return {
      success: true,
      syncedCount,
      skippedCount,
      errorCount,
      totalUsers: usersSnapshot.size
    };
  } catch (error: any) {
    console.error('❌ Bulk sync failed:', error);
    throw new functions.https.HttpsError('internal', `Sync failed: ${error.message}`);
  }
});
