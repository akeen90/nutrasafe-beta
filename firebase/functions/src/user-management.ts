import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Helper function to check if a user is an admin
 * Admins have write access to food collections and can manage users
 */
async function isAdmin(uid: string): Promise<boolean> {
  const db = admin.firestore();
  const adminDoc = await db.collection('admins').doc(uid).get();
  return adminDoc.exists;
}

// Owner emails - always have admin access (project owners)
const OWNER_EMAILS = [
  'aaronmkeen@gmail.com',
  'aaron@nutrasafe.co.uk'
];

// Legacy owner UID for backwards compatibility
const OWNER_UID = 'dM0rqAAVhjRcfFhAYtkJ6AFOd9j2';

/**
 * Helper function to verify admin access for sensitive operations
 * Throws an error if user is not authenticated or not an admin
 */
async function requireAdmin(context: functions.https.CallableContext): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to access this function'
    );
  }

  // Debug logging
  console.log('=== requireAdmin check ===');
  console.log('User UID:', context.auth.uid);
  console.log('User email from token:', context.auth.token.email);
  console.log('OWNER_UID:', OWNER_UID);
  console.log('OWNER_EMAILS:', OWNER_EMAILS);

  // Check if owner by UID (legacy)
  if (context.auth.uid === OWNER_UID) {
    console.log('Access granted: UID matches OWNER_UID');
    return;
  }

  // Check if owner by email
  const userEmail = context.auth.token.email?.toLowerCase();
  console.log('Checking email:', userEmail);
  if (userEmail && OWNER_EMAILS.some(email => email.toLowerCase() === userEmail)) {
    console.log('Access granted: Email matches OWNER_EMAILS');
    return;
  }

  // Check if admin in Firestore
  console.log('Checking Firestore /admins collection for UID:', context.auth.uid);
  const userIsAdmin = await isAdmin(context.auth.uid);
  console.log('Is admin in Firestore:', userIsAdmin);

  if (!userIsAdmin) {
    console.log('Access DENIED: Not owner, not admin');
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required. User must be in /admins collection.'
    );
  }

  console.log('Access granted: User is admin in Firestore');
}

// Get all users with pagination (ADMIN ONLY)
export const getUsers = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  try {
    console.log(`Admin ${context.auth?.uid} getting users list...`);

    const db = admin.firestore();
    const limit = data.limit || 50;
    const offset = data.offset || 0;

    // Get users from Firestore
    const usersSnapshot = await db.collection('users')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    // Also get total count
    const totalSnapshot = await db.collection('users').get();
    const totalUsers = totalSnapshot.size;

    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Convert Firestore timestamps to ISO strings
      createdAt: doc.data().createdAt ? doc.data().createdAt.toDate().toISOString() : null,
      lastLogin: doc.data().lastLogin ? doc.data().lastLogin.toDate().toISOString() : null,
      lastActivity: doc.data().lastActivity ? doc.data().lastActivity.toDate().toISOString() : null
    }));

    console.log(`Found ${users.length} users (${totalUsers} total)`);

    return {
      success: true,
      users,
      totalUsers,
      hasMore: offset + users.length < totalUsers
    };

  } catch (error) {
    console.error('Error getting users:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get users');
  }
});

// Add new user (ADMIN ONLY)
export const addUser = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  try {
    const {
      email,
      displayName,
      phoneNumber,
      role = 'user',
      allergens = [],
      preferences = {}
    } = data;

    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'Email is required');
    }

    console.log(`Admin ${context.auth?.uid} adding new user: ${email}`);

    const db = admin.firestore();
    const userRef = db.collection('users').doc();

    const userData = {
      email,
      displayName: displayName || '',
      phoneNumber: phoneNumber || '',
      role,
      allergens,
      preferences,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
      lastActivity: null,
      // App usage stats
      totalScans: 0,
      totalSearches: 0,
      foodsLogged: 0,
      reactionsLogged: 0
    };

    await userRef.set(userData);

    return {
      success: true,
      message: 'User added successfully',
      userId: userRef.id,
      user: {
        id: userRef.id,
        ...userData,
        createdAt: new Date().toISOString()
      }
    };

  } catch (error) {
    console.error('Error adding user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to add user');
  }
});

// Update user (ADMIN ONLY)
export const updateUser = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  try {
    const { userId, ...updateData } = data;

    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
    }

    console.log(`Admin ${context.auth?.uid} updating user: ${userId}`);

    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);

    // Remove fields that shouldn't be updated directly
    const { createdAt, ...safeUpdateData } = updateData;

    await userRef.update({
      ...safeUpdateData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: 'User updated successfully',
      userId
    };

  } catch (error) {
    console.error('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update user');
  }
});

// Delete users (batch operation) (ADMIN ONLY)
export const deleteUsers = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  try {
    const { userIds } = data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'User IDs array is required');
    }

    console.log(`Admin ${context.auth?.uid} deleting users: ${userIds.join(', ')}`);

    const db = admin.firestore();
    const batch = db.batch();

    for (const userId of userIds) {
      const userRef = db.collection('users').doc(userId);
      batch.delete(userRef);
    }

    await batch.commit();

    return {
      success: true,
      message: `Successfully deleted ${userIds.length} user(s)`,
      deletedIds: userIds
    };

  } catch (error) {
    console.error('Error deleting users:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete users');
  }
});

// Get user analytics (ADMIN ONLY)
export const getUserAnalytics = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  try {
    console.log(`Admin ${context.auth?.uid} getting user analytics...`);

    const db = admin.firestore();
    
    // Get all users for analysis
    const usersSnapshot = await db.collection('users').get();
    const users = usersSnapshot.docs.map(doc => doc.data());

    // Calculate analytics
    const totalUsers = users.length;
    const activeUsers = users.filter(user => user.isActive).length;
    
    // Date calculations
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    // Users by activity
    const newUsersToday = users.filter(user => {
      const createdAt = user.createdAt ? user.createdAt.toDate() : null;
      return createdAt && createdAt > oneDayAgo;
    }).length;

    const newUsersThisWeek = users.filter(user => {
      const createdAt = user.createdAt ? user.createdAt.toDate() : null;
      return createdAt && createdAt > oneWeekAgo;
    }).length;

    const recentlyActiveUsers = users.filter(user => {
      const lastActivity = user.lastActivity ? user.lastActivity.toDate() : null;
      return lastActivity && lastActivity > oneWeekAgo;
    }).length;

    // App usage stats
    const totalScans = users.reduce((sum, user) => sum + (user.totalScans || 0), 0);
    const totalSearches = users.reduce((sum, user) => sum + (user.totalSearches || 0), 0);
    const totalFoodsLogged = users.reduce((sum, user) => sum + (user.foodsLogged || 0), 0);
    const totalReactionsLogged = users.reduce((sum, user) => sum + (user.reactionsLogged || 0), 0);

    // Most common allergens
    const allergenCounts: { [key: string]: number } = {};
    users.forEach(user => {
      if (user.allergens && Array.isArray(user.allergens)) {
        user.allergens.forEach((allergen: string) => {
          allergenCounts[allergen] = (allergenCounts[allergen] || 0) + 1;
        });
      }
    });

    const topAllergens = Object.entries(allergenCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([allergen, count]) => ({ allergen, count }));

    // User growth data (30 days)
    const userGrowthData = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      
      const usersOnDate = users.filter(user => {
        const createdAt = user.createdAt ? user.createdAt.toDate() : null;
        return createdAt && createdAt.toDateString() === date.toDateString();
      }).length;
      
      userGrowthData.push({
        date: dateStr,
        newUsers: usersOnDate
      });
    }

    const analytics = {
      // User statistics
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsersThisWeek,
      recentlyActiveUsers,

      // App usage
      totalScans,
      totalSearches,
      totalFoodsLogged,
      totalReactionsLogged,

      // Insights
      topAllergens,
      userGrowthData,

      // Averages
      avgScansPerUser: totalUsers > 0 ? (totalScans / totalUsers).toFixed(1) : 0,
      avgSearchesPerUser: totalUsers > 0 ? (totalSearches / totalUsers).toFixed(1) : 0,

      generatedAt: new Date().toISOString()
    };

    console.log(`User analytics generated - Total: ${totalUsers}, Active: ${activeUsers}`);

    return {
      success: true,
      analytics
    };

  } catch (error) {
    console.error('Error getting user analytics:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get user analytics');
  }
});

// Get all authenticated user emails (ADMIN ONLY)
// Pulls directly from Firebase Authentication, not Firestore
export const getAuthenticatedEmails = functions.https.onCall(async (data, context) => {
  console.log('=== getAuthenticatedEmails START ===');

  // Step 1: Check auth exists
  if (!context.auth) {
    console.log('No auth context');
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  console.log('Auth exists, UID:', context.auth.uid);

  // Step 2: Check if owner (skip Firestore admin check for simplicity)
  const OWNER_UID = 'dM0rqAAVhjRcfFhAYtkJ6AFOd9j2';
  const OWNER_EMAILS = ['aaronmkeen@gmail.com', 'aaron@nutrasafe.co.uk'];
  const userEmail = context.auth.token.email?.toLowerCase();

  const isOwner = context.auth.uid === OWNER_UID ||
                  (userEmail && OWNER_EMAILS.some(e => e.toLowerCase() === userEmail));

  if (!isOwner) {
    console.log('Not owner - UID:', context.auth.uid, 'Email:', userEmail);
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  console.log('Owner check passed');

  // Step 3: Get users from Firebase Auth
  try {
    console.log('Calling admin.auth().listUsers...');
    const listUsersResult = await admin.auth().listUsers(1000);
    console.log('listUsers returned', listUsersResult.users.length, 'users');

    const emails = listUsersResult.users
      .filter(u => u.email)
      .map(u => ({
        uid: u.uid,
        email: u.email!,
        displayName: u.displayName || null,
        createdAt: u.metadata.creationTime || null,
        lastSignIn: u.metadata.lastSignInTime || null,
        emailVerified: u.emailVerified,
        disabled: u.disabled
      }));

    console.log('Returning', emails.length, 'emails');
    return {
      success: true,
      emails,
      totalCount: emails.length,
      generatedAt: new Date().toISOString()
    };

  } catch (authError: any) {
    console.error('admin.auth().listUsers failed:', authError.message);
    console.error('Error code:', authError.code);

    // Return empty list instead of crashing
    return {
      success: true,
      emails: [],
      totalCount: 0,
      error: `Auth Admin SDK error: ${authError.message}. Add Firebase Authentication Admin role to service account.`,
      generatedAt: new Date().toISOString()
    };
  }
});

// Bulk add emails to Mailchimp (ADMIN ONLY)
export const bulkAddToMailchimp = functions.https.onCall(async (data, context) => {
  // Verify admin access
  await requireAdmin(context);

  const { emails } = data;

  if (!emails || !Array.isArray(emails) || emails.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Emails array is required');
  }

  console.log(`Admin ${context.auth?.uid} bulk adding ${emails.length} emails to Mailchimp...`);

  // Get Mailchimp config
  const config = functions.config().mailchimp;
  if (!config || !config.api_key || !config.audience_id) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Mailchimp not configured. Run: firebase functions:config:set mailchimp.api_key="YOUR_KEY" mailchimp.audience_id="YOUR_ID" mailchimp.server_prefix="us1"'
    );
  }

  const axios = require('axios');
  const serverPrefix = config.server_prefix || 'us1';
  const url = `https://${serverPrefix}.api.mailchimp.com/3.0/lists/${config.audience_id}`;

  let addedCount = 0;
  let updatedCount = 0;
  let errorCount = 0;
  const errors: { email: string; error: string }[] = [];

  // Mailchimp batch operation - add members
  // Use batch endpoint for efficiency
  const members = emails.map((item: { email: string; displayName?: string; uid?: string }) => ({
    email_address: item.email,
    status: 'subscribed',
    merge_fields: {
      FNAME: item.displayName?.split(' ')[0] || '',
      LNAME: item.displayName?.split(' ').slice(1).join(' ') || '',
      UID: item.uid || ''
    },
    tags: ['NutraSafe App', 'Bulk Import']
  }));

  try {
    // Use Mailchimp batch subscribe/update endpoint
    const response = await axios.post(
      `${url}`,
      {
        members,
        update_existing: true
      },
      {
        auth: {
          username: 'anystring',
          password: config.api_key
        },
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    addedCount = response.data.new_members?.length || 0;
    updatedCount = response.data.updated_members?.length || 0;

    if (response.data.errors) {
      for (const err of response.data.errors) {
        errorCount++;
        errors.push({
          email: err.email_address,
          error: err.error
        });
      }
    }

    console.log(`Mailchimp bulk add: ${addedCount} added, ${updatedCount} updated, ${errorCount} errors`);

  } catch (error: any) {
    console.error('Mailchimp bulk add error:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', `Mailchimp error: ${error.response?.data?.detail || error.message}`);
  }

  return {
    success: true,
    addedCount,
    updatedCount,
    errorCount,
    errors: errors.slice(0, 10), // Return first 10 errors
    totalProcessed: emails.length
  };
});