#!/usr/bin/env node

const admin = require('firebase-admin');
const { bulkImportFoodsToAlgolia } = require('./lib/algolia-sync');

// Initialize Firebase Admin
admin.initializeApp();

console.log('🔄 Starting bulk import to update all foods with new ranking fields...\n');
console.log('This will add:');
console.log('  - isGeneric field (1 for generic brands, 0 for others)');
console.log('  - nameLength field (for ranking shorter names higher)\n');

// Call the function directly
bulkImportFoodsToAlgolia({ data: {} }, { auth: { uid: 'admin' } })
  .then(result => {
    console.log('\n✅ Bulk import completed successfully!\n');
    console.log('Results:');
    console.log(JSON.stringify(result, null, 2));
    console.log('\n📝 Now test searching for "apple" - generic apples should appear first!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error during bulk import:', error);
    process.exit(1);
  });
