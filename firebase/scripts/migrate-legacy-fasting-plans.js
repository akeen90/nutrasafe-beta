#!/usr/bin/env node

/**
 * Legacy Fasting Plans Migration Script
 *
 * This script fixes fasting plans that have null user_id values (created before
 * the user_id field was required). These legacy documents create a security risk
 * as any authenticated user could access them.
 *
 * Options:
 *   1. Delete orphaned plans (default - RECOMMENDED)
 *   2. Assign to specific user (use --assign-to=<uid>)
 *   3. Dry run (use --dry-run to preview changes)
 *
 * Usage:
 *   # Preview what will be deleted (recommended first step)
 *   node migrate-legacy-fasting-plans.js --dry-run
 *
 *   # Delete all orphaned fasting plans
 *   node migrate-legacy-fasting-plans.js --delete
 *
 *   # Assign all to a specific user (get UID from Firebase Console)
 *   node migrate-legacy-fasting-plans.js --assign-to=abc123def456
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, '../service-account-key.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateLegacyFastingPlans(options = {}) {
  console.log('\n🔍 Scanning for legacy fasting plans with null user_id...\n');

  // Find all fasting plans where user_id is null or doesn't exist
  const legacyPlansQuery = await db.collection('fasting_plans')
    .where('user_id', '==', null)
    .get();

  const legacyPlans = legacyPlansQuery.docs;

  if (legacyPlans.length === 0) {
    console.log('✅ No legacy fasting plans found. Database is clean!\n');
    return;
  }

  console.log(`📊 Found ${legacyPlans.length} legacy fasting plan(s) with null user_id:\n`);

  // Display details
  legacyPlans.forEach((doc, index) => {
    const data = doc.data();
    console.log(`${index + 1}. Plan ID: ${doc.id}`);
    console.log(`   Created: ${data.created_at?.toDate?.() || 'Unknown'}`);
    console.log(`   Type: ${data.fasting_type || 'Unknown'}`);
    console.log(`   Duration: ${data.duration_hours || 'Unknown'} hours`);
    console.log('');
  });

  // Dry run - just preview
  if (options.dryRun) {
    console.log('🔍 DRY RUN MODE - No changes will be made\n');
    console.log('To proceed with migration:');
    console.log('  • Delete orphaned plans: node migrate-legacy-fasting-plans.js --delete');
    console.log('  • Assign to user: node migrate-legacy-fasting-plans.js --assign-to=<uid>\n');
    return;
  }

  // Delete orphaned plans
  if (options.delete) {
    console.log('🗑️  Deleting orphaned fasting plans...\n');

    const batch = db.batch();
    legacyPlans.forEach(doc => {
      batch.delete(doc.ref);
    });

    try {
      await batch.commit();
      console.log(`✅ Successfully deleted ${legacyPlans.length} legacy fasting plan(s)\n`);
      console.log('🔐 Security improved: No more cross-user accessible fasting plans\n');
    } catch (error) {
      console.error('❌ Failed to delete plans:', error.message);
      process.exit(1);
    }

    return;
  }

  // Assign to specific user
  if (options.assignTo) {
    console.log(`👤 Assigning all legacy plans to user: ${options.assignTo}\n`);

    // Verify user exists
    try {
      const userRecord = await admin.auth().getUser(options.assignTo);
      console.log(`✅ User verified: ${userRecord.email || 'Unknown'}\n`);
    } catch (error) {
      console.error(`❌ User not found: ${options.assignTo}`);
      console.error('   Please check the UID is correct');
      process.exit(1);
    }

    const batch = db.batch();
    legacyPlans.forEach(doc => {
      batch.update(doc.ref, {
        user_id: options.assignTo,
        migrated_at: admin.firestore.FieldValue.serverTimestamp(),
        migration_note: 'Legacy plan assigned to user via migration script'
      });
    });

    try {
      await batch.commit();
      console.log(`✅ Successfully assigned ${legacyPlans.length} legacy plan(s) to user ${options.assignTo}\n`);
    } catch (error) {
      console.error('❌ Failed to update plans:', error.message);
      process.exit(1);
    }

    return;
  }

  // No action specified
  console.log('⚠️  No action specified. Use one of:\n');
  console.log('  --dry-run          Preview changes without modifying data');
  console.log('  --delete           Delete orphaned plans (RECOMMENDED)');
  console.log('  --assign-to=<uid>  Assign all plans to specific user\n');
}

// Parse command line arguments
const args = process.argv.slice(2);
const options = {};

args.forEach(arg => {
  if (arg === '--dry-run') {
    options.dryRun = true;
  } else if (arg === '--delete') {
    options.delete = true;
  } else if (arg.startsWith('--assign-to=')) {
    options.assignTo = arg.split('=')[1];
  }
});

migrateLegacyFastingPlans(options)
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
