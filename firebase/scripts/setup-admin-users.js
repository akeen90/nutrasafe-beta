#!/usr/bin/env node

/**
 * Admin User Setup Script
 *
 * This script creates admin user documents in Firestore to enable write access
 * to food collections. Only users in the /admins collection can modify food data.
 *
 * Usage:
 *   node setup-admin-users.js <firebase-uid-1> [firebase-uid-2] [...]
 *
 * Example:
 *   node setup-admin-users.js abc123def456 xyz789uvw012
 *
 * To get your Firebase UID:
 *   1. Sign in to your app
 *   2. Go to Firebase Console > Authentication > Users
 *   3. Copy the UID of the user you want to make an admin
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, '../service-account-key.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupAdminUsers(userIds) {
  if (userIds.length === 0) {
    console.error('❌ Error: No user IDs provided');
    console.log('\nUsage: node setup-admin-users.js <firebase-uid-1> [firebase-uid-2] ...');
    console.log('\nTo find your Firebase UID:');
    console.log('  1. Sign in to your app');
    console.log('  2. Go to Firebase Console > Authentication > Users');
    console.log('  3. Copy the UID of the user you want to make an admin');
    process.exit(1);
  }

  console.log(`\n🔧 Setting up ${userIds.length} admin user(s)...\n`);

  const batch = db.batch();
  const results = [];

  for (const userId of userIds) {
    try {
      // Verify user exists in Firebase Auth
      const userRecord = await admin.auth().getUser(userId);

      const adminRef = db.collection('admins').doc(userId);
      batch.set(adminRef, {
        uid: userId,
        email: userRecord.email || 'Unknown',
        displayName: userRecord.displayName || 'Unknown',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        permissions: {
          canEditFoods: true,
          canVerifyFoods: true,
          canDeleteFoods: true,
          canManageUsers: false  // Set to true for super admins
        }
      });

      results.push({
        success: true,
        userId,
        email: userRecord.email
      });

      console.log(`✅ Queued admin setup for: ${userRecord.email} (${userId})`);
    } catch (error) {
      results.push({
        success: false,
        userId,
        error: error.message
      });

      console.error(`❌ Failed to setup admin for ${userId}: ${error.message}`);
    }
  }

  // Commit all changes
  try {
    await batch.commit();
    console.log('\n✅ All admin users successfully created in Firestore\n');
  } catch (error) {
    console.error('\n❌ Failed to commit batch:', error.message);
    process.exit(1);
  }

  // Summary
  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log('═══════════════════════════════════════');
  console.log('SUMMARY:');
  console.log(`  ✅ Successful: ${successful}`);
  console.log(`  ❌ Failed: ${failed}`);
  console.log('═══════════════════════════════════════\n');

  // List successful admins
  if (successful > 0) {
    console.log('✅ Admin users with food database write access:');
    results.filter(r => r.success).forEach(r => {
      console.log(`   - ${r.email || 'Unknown'} (${r.userId})`);
    });
    console.log('');
  }

  // List failed admins
  if (failed > 0) {
    console.log('❌ Failed admin setups:');
    results.filter(r => !r.success).forEach(r => {
      console.log(`   - ${r.userId}: ${r.error}`);
    });
    console.log('');
  }

  console.log('🔐 Security Notes:');
  console.log('   - Admin users can now write to all food collections');
  console.log('   - Regular users can only read food data (search functionality)');
  console.log('   - User-specific data (diary, reactions, etc.) remains protected');
  console.log('   - Deploy Firestore rules: firebase deploy --only firestore:rules\n');

  process.exit(0);
}

// Get user IDs from command line arguments
const userIds = process.argv.slice(2);

setupAdminUsers(userIds).catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
