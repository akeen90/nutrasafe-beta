#!/usr/bin/env node

/**
 * Replace Foods Database Script
 *
 * This script completely replaces the Firebase foods collection with spellchecked data.
 *
 * DANGER: This will DELETE all existing foods and upload new ones!
 *
 * Usage: node replace-foods-database.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');

// Initialize Firebase Admin (will use default application credentials)
admin.initializeApp({
  projectId: 'nutrasafe-705c7'
});

const db = admin.firestore();
const BATCH_SIZE = 500; // Firestore batch limit
const CSV_PATH = '/Users/aaronkeen/Desktop/Spellchecked foods .csv';

let totalDeleted = 0;
let totalUploaded = 0;
let uploadBatch = [];
let batchCount = 0;

// Helper function to safely parse numbers
function parseNumber(value) {
  if (!value || value === '' || value === 'null' || value === 'undefined') {
    return null;
  }
  const num = parseFloat(value);
  return isNaN(num) ? null : num;
}

// Helper function to convert CSV row to Firebase food document
function csvToFoodDocument(row) {
  const foodData = {
    // Clean spellchecked data (primary fields)
    foodName: row.clean_food_name || '',
    foodNameLower: (row.clean_food_name || '').toLowerCase(), // For case-insensitive search
    brandName: row.clean_brand_name || '',
    brandNameLower: (row.clean_brand_name || '').toLowerCase(), // For case-insensitive search
    ingredients: row.clean_ingredients || '',

    // Preserve original data fields
    barcode: row.orig_barcode || '',
    category: row.orig_category || '',

    // Nutrition data (per 100g)
    nutrition: {
      calories: { kcal: parseNumber(row.orig_energy_kcal) || 0 },
      fat: { per100g: parseNumber(row.orig_fat) || 0 },
      saturates: { per100g: parseNumber(row.orig_saturates) || 0 },
      carbohydrates: { per100g: parseNumber(row.orig_carbohydrates) || 0 },
      sugars: { per100g: parseNumber(row.orig_sugars) || 0 },
      protein: { per100g: parseNumber(row.orig_protein) || 0 },
      salt: { per100g: parseNumber(row.orig_salt) || 0 },
      fiber: { per100g: parseNumber(row.orig_fibre) || 0 }
    },

    // Serving information
    servingSize: row.orig_serving_size || '100g',
    servingQuantity: parseNumber(row.orig_serving_quantity),

    // Additional metadata
    packaging: row.orig_packaging || '',
    stores: row.orig_stores || '',
    countries: row.orig_countries || '',
    nutritionGrade: row.orig_nutrition_grade || '',
    novaGroup: parseNumber(row.orig_nova_group),

    // Images
    imageFrontUrl: row.orig_image_front_url || '',
    imageNutritionUrl: row.orig_image_nutrition_url || '',
    imageIngredientsUrl: row.orig_image_ingredients_url || '',

    // Source tracking
    source: row.orig_source || 'spellchecked_import',
    completeness: parseNumber(row.orig_completeness),
    originalId: row.orig_id || '',

    // Import timestamp
    importedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  // Clean up empty strings and null values in nested objects
  if (foodData.nutrition.calories.kcal === 0) delete foodData.nutrition.calories;
  if (foodData.nutrition.fat.per100g === 0) delete foodData.nutrition.fat;
  if (foodData.nutrition.saturates.per100g === 0) delete foodData.nutrition.saturates;
  if (foodData.nutrition.carbohydrates.per100g === 0) delete foodData.nutrition.carbohydrates;
  if (foodData.nutrition.sugars.per100g === 0) delete foodData.nutrition.sugars;
  if (foodData.nutrition.protein.per100g === 0) delete foodData.nutrition.protein;
  if (foodData.nutrition.salt.per100g === 0) delete foodData.nutrition.salt;
  if (foodData.nutrition.fiber.per100g === 0) delete foodData.nutrition.fiber;

  return foodData;
}

// Step 1: Delete all existing foods
async function deleteAllFoods() {
  console.log('\n🗑️  STEP 1: Deleting all existing foods from Firebase...\n');

  const batchSize = 500;
  let deletedCount = 0;

  while (true) {
    const snapshot = await db.collection('verifiedFoods').limit(batchSize).get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deletedCount++;
    });

    await batch.commit();
    console.log(`   Deleted ${deletedCount} foods...`);

    if (snapshot.size < batchSize) {
      break;
    }
  }

  totalDeleted = deletedCount;
  console.log(`\n✅ Deleted ${totalDeleted} existing foods\n`);
}

// Step 2: Upload new spellchecked foods
async function uploadSpellcheckedFoods() {
  console.log('📤 STEP 2: Uploading spellchecked foods from CSV...\n');

  return new Promise((resolve, reject) => {
    const results = [];

    fs.createReadStream(CSV_PATH)
      .pipe(csv())
      .on('data', (row) => {
        results.push(row);
      })
      .on('end', async () => {
        console.log(`   Read ${results.length} foods from CSV\n`);

        // Process in batches
        for (let i = 0; i < results.length; i += BATCH_SIZE) {
          const batch = db.batch();
          const chunk = results.slice(i, i + BATCH_SIZE);

          chunk.forEach((row) => {
            const foodData = csvToFoodDocument(row);
            const docRef = db.collection('verifiedFoods').doc();
            batch.set(docRef, foodData);
            totalUploaded++;
          });

          await batch.commit();
          console.log(`   Uploaded ${totalUploaded} / ${results.length} foods...`);
        }

        console.log(`\n✅ Uploaded ${totalUploaded} spellchecked foods\n`);
        resolve();
      })
      .on('error', (error) => {
        console.error('Error reading CSV:', error);
        reject(error);
      });
  });
}

// Main execution
async function main() {
  console.log('\n===========================================');
  console.log('🚨 FIREBASE FOODS DATABASE REPLACEMENT 🚨');
  console.log('===========================================\n');
  console.log('⚠️  WARNING: This will DELETE all existing foods!');
  console.log('⚠️  WARNING: This action cannot be undone!\n');
  console.log(`📁 Source: ${CSV_PATH}\n`);

  try {
    // Check if CSV file exists
    if (!fs.existsSync(CSV_PATH)) {
      throw new Error(`CSV file not found at: ${CSV_PATH}`);
    }

    const startTime = Date.now();

    // Step 1: Delete existing foods
    await deleteAllFoods();

    // Step 2: Upload new spellchecked foods
    await uploadSpellcheckedFoods();

    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    console.log('===========================================');
    console.log('✅ DATABASE REPLACEMENT COMPLETE!');
    console.log('===========================================\n');
    console.log(`   Deleted:  ${totalDeleted} old foods`);
    console.log(`   Uploaded: ${totalUploaded} new foods`);
    console.log(`   Duration: ${duration} seconds\n`);

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Run the script
main();
