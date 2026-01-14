#!/usr/bin/env node

/**
 * Upload Food Databases to Firebase
 *
 * This script uploads three CSV databases to Firebase Firestore:
 *   - New Main: uk_foods_complete.csv → newMain collection
 *   - New Fast Food: fast_food_database.csv → newFastFood collection
 *   - New Generic: generic_items_database.csv → newGeneric collection
 *
 * Usage:
 *   cd firebase/scripts
 *   node upload-databases.js [--collection=newMain|newFastFood|newGeneric|all]
 *
 * Prerequisites:
 *   - Be logged in via: firebase login
 *   - Set GOOGLE_APPLICATION_CREDENTIALS or use firebase CLI auth
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');

// Initialize Firebase Admin with service account
const serviceAccount = require('../service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nutrasafe-705c7'
});

const db = admin.firestore();

// Database configurations
const databases = {
  newMain: {
    csvPath: path.join(__dirname, '../../uk_foods_complete.csv'),
    collection: 'newMain',
    description: 'UK Foods Complete Database'
  },
  newFastFood: {
    csvPath: path.join(__dirname, '../../fast_food_database.csv'),
    collection: 'newFastFood',
    description: 'Fast Food Database'
  },
  newGeneric: {
    csvPath: path.join(__dirname, '../../generic_items_database.csv'),
    collection: 'newGeneric',
    description: 'Generic Items Database'
  }
};

/**
 * Parse a CSV file and return array of objects
 */
function parseCSV(filePath) {
  console.log(`📖 Reading CSV: ${filePath}`);
  const fileContent = fs.readFileSync(filePath, 'utf-8');

  const records = parse(fileContent, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
    relax_quotes: true,
    relax_column_count: true
  });

  console.log(`   Found ${records.length} records`);
  return records;
}

/**
 * Transform CSV record to Firestore document
 */
function transformRecord(record, index) {
  // Generate a unique ID based on name and brand, or use barcode if available
  let objectID;
  if (record.barcode && record.barcode.trim() !== '') {
    objectID = `barcode_${record.barcode.trim()}`;
  } else {
    // Create ID from name and brand
    const name = (record.name || '').toLowerCase().replace(/[^a-z0-9]/g, '_').substring(0, 50);
    const brand = (record.brand || 'generic').toLowerCase().replace(/[^a-z0-9]/g, '_').substring(0, 20);
    objectID = `${brand}_${name}_${index}`;
  }

  // Parse numeric fields
  const parseNum = (val) => {
    if (val === undefined || val === null || val === '') return null;
    const num = parseFloat(val);
    return isNaN(num) ? null : num;
  };

  // Parse boolean fields
  const parseBool = (val) => {
    if (val === undefined || val === null || val === '') return false;
    return val === 'true' || val === 'True' || val === '1' || val === true;
  };

  // Build the document
  const doc = {
    // Basic info
    name: record.name || '',
    brand: record.brand || '',
    barcode: record.barcode || '',

    // Categories
    category: record.category || '',
    subcategory: record.subcategory || '',

    // Nutrition (per serving or per 100g)
    calories: parseNum(record.calories),
    protein: parseNum(record.protein),
    carbs: parseNum(record.carbs),
    fat: parseNum(record.fat),
    saturatedFat: parseNum(record.saturated_fat),
    fiber: parseNum(record.fiber),
    sugar: parseNum(record.sugar),
    sodium: parseNum(record.sodium),

    // Serving info
    servingSize: parseNum(record.serving_size_g),
    servingDescription: record.serving_description || '',

    // Ingredients & allergens
    ingredients: record.ingredients || '',
    allergens: record.allergens || '',

    // Flags
    isPerUnit: parseBool(record.is_per_unit),
    isVerified: parseBool(record.is_verified),

    // Metadata
    source: 'csv_import',
    importedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  // Remove null values to save space
  Object.keys(doc).forEach(key => {
    if (doc[key] === null || doc[key] === undefined) {
      delete doc[key];
    }
  });

  return { objectID, doc };
}

/**
 * Upload records to Firestore in batches
 */
async function uploadToFirestore(records, collectionName, description) {
  console.log(`\n🚀 Uploading ${records.length} records to '${collectionName}'...`);
  console.log(`   ${description}\n`);

  const BATCH_SIZE = 500; // Firestore batch limit
  let uploaded = 0;
  let errors = 0;

  // Process in batches
  for (let i = 0; i < records.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const batchRecords = records.slice(i, i + BATCH_SIZE);

    for (let j = 0; j < batchRecords.length; j++) {
      try {
        const { objectID, doc } = transformRecord(batchRecords[j], i + j);
        const docRef = db.collection(collectionName).doc(objectID);
        batch.set(docRef, doc, { merge: true });
      } catch (err) {
        errors++;
        console.error(`   ❌ Error transforming record ${i + j}: ${err.message}`);
      }
    }

    try {
      await batch.commit();
      uploaded += batchRecords.length;

      // Progress indicator
      const progress = Math.round((uploaded / records.length) * 100);
      process.stdout.write(`\r   Progress: ${progress}% (${uploaded}/${records.length})`);
    } catch (err) {
      errors += batchRecords.length;
      console.error(`\n   ❌ Batch commit failed: ${err.message}`);
    }
  }

  console.log(`\n\n   ✅ Uploaded: ${uploaded}`);
  if (errors > 0) {
    console.log(`   ❌ Errors: ${errors}`);
  }

  return { uploaded, errors };
}

/**
 * Main function
 */
async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  let collectionsToUpload = ['newMain', 'newFastFood', 'newGeneric']; // Default: all

  for (const arg of args) {
    if (arg.startsWith('--collection=')) {
      const value = arg.split('=')[1];
      if (value === 'all') {
        collectionsToUpload = ['newMain', 'newFastFood', 'newGeneric'];
      } else if (databases[value]) {
        collectionsToUpload = [value];
      } else {
        console.error(`❌ Unknown collection: ${value}`);
        console.log('   Valid options: newMain, newFastFood, newGeneric, all');
        process.exit(1);
      }
    }
  }

  console.log('═══════════════════════════════════════════════════════════════');
  console.log('           NUTRASAFE DATABASE UPLOAD TO FIREBASE');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log(`\nCollections to upload: ${collectionsToUpload.join(', ')}\n`);

  const results = {};

  for (const collectionKey of collectionsToUpload) {
    const config = databases[collectionKey];

    console.log('───────────────────────────────────────────────────────────────');
    console.log(`📦 Processing: ${config.description}`);
    console.log('───────────────────────────────────────────────────────────────');

    // Check if CSV file exists
    if (!fs.existsSync(config.csvPath)) {
      console.error(`❌ CSV file not found: ${config.csvPath}`);
      results[collectionKey] = { uploaded: 0, errors: 1, message: 'File not found' };
      continue;
    }

    try {
      // Parse CSV
      const records = parseCSV(config.csvPath);

      // Upload to Firestore
      const result = await uploadToFirestore(records, config.collection, config.description);
      results[collectionKey] = result;

    } catch (err) {
      console.error(`❌ Failed to process ${collectionKey}: ${err.message}`);
      results[collectionKey] = { uploaded: 0, errors: 1, message: err.message };
    }
  }

  // Final summary
  console.log('\n═══════════════════════════════════════════════════════════════');
  console.log('                         SUMMARY');
  console.log('═══════════════════════════════════════════════════════════════');

  let totalUploaded = 0;
  let totalErrors = 0;

  for (const [key, result] of Object.entries(results)) {
    const config = databases[key];
    console.log(`\n📦 ${config.description} (${config.collection})`);
    console.log(`   ✅ Uploaded: ${result.uploaded}`);
    if (result.errors > 0) {
      console.log(`   ❌ Errors: ${result.errors}`);
    }
    if (result.message) {
      console.log(`   ⚠️  Note: ${result.message}`);
    }
    totalUploaded += result.uploaded;
    totalErrors += result.errors;
  }

  console.log('\n───────────────────────────────────────────────────────────────');
  console.log(`TOTAL: ${totalUploaded} items uploaded, ${totalErrors} errors`);
  console.log('═══════════════════════════════════════════════════════════════\n');

  process.exit(totalErrors > 0 ? 1 : 0);
}

// Run
main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
