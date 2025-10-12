#!/usr/bin/env node

/**
 * Efficient Database Replacement
 * Uploads the ENTIRE CSV in ONE request to minimize costs
 */

const fs = require('fs');
const csv = require('csv-parser');
const https = require('https');

const CSV_PATH = '/Users/aaronkeen/Desktop/Spellchecked foods .csv';
const FIREBASE_FUNCTION_URL = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net/replaceAllFoods';

function parseNumber(value) {
  if (!value || value === '' || value === 'null' || value === 'undefined') {
    return null;
  }
  const num = parseFloat(value);
  return isNaN(num) ? null : num;
}

function csvToFoodDocument(row) {
  return {
    foodName: row.clean_food_name || '',
    brandName: row.clean_brand_name || '',
    ingredients: row.clean_ingredients || '',
    barcode: row.orig_barcode || '',
    category: row.orig_category || '',
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
    servingSize: row.orig_serving_size || '100g',
    source: 'spellchecked_import'
  };
}

async function uploadAll(foods) {
  return new Promise((resolve, reject) => {
    console.log(`📤 Uploading ${foods.length} foods in ONE request...`);

    const postData = JSON.stringify({ foods, deleteFirst: true });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(FIREBASE_FUNCTION_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(data);
          console.log(`✅ Success!`);
          console.log(`   Deleted: ${result.deleted} old foods`);
          console.log(`   Uploaded: ${result.uploaded} new foods`);
          resolve();
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function main() {
  console.log('\n===========================================');
  console.log('🚀 EFFICIENT DATABASE REPLACEMENT');
  console.log('===========================================\n');

  const foods = [];

  // Read CSV
  console.log('📖 Reading CSV...');
  await new Promise((resolve, reject) => {
    fs.createReadStream(CSV_PATH)
      .pipe(csv())
      .on('data', (row) => {
        foods.push(csvToFoodDocument(row));
      })
      .on('end', resolve)
      .on('error', reject);
  });

  console.log(`📊 Read ${foods.length} foods from CSV\n`);

  // Upload ALL foods in ONE request
  await uploadAll(foods);

  console.log(`\n✅ Database replacement complete!\n`);
  process.exit(0);
}

main().catch((error) => {
  console.error('\n❌ Error:', error);
  process.exit(1);
});
