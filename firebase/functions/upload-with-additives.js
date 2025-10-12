#!/usr/bin/env node

/**
 * Upload foods with additive analysis
 * Analyzes ingredients for additives BEFORE uploading
 */

const fs = require('fs');
const csv = require('csv-parser');
const https = require('https');

const CSV_PATH = '/Users/aaronkeen/Desktop/Spellchecked foods .csv';
const REPLACE_URL = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net/replaceAllFoods';
const ADDITIVE_URL = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced';

function parseNumber(value) {
  if (!value || value === '' || value === 'null' || value === 'undefined') {
    return null;
  }
  const num = parseFloat(value);
  return isNaN(num) ? null : num;
}

// Analyze additives for ingredients string
async function analyzeAdditives(ingredients) {
  return new Promise((resolve, reject) => {
    if (!ingredients || ingredients.trim().length === 0) {
      resolve([]);
      return;
    }

    const postData = JSON.stringify({ ingredients: ingredients });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(ADDITIVE_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const result = JSON.parse(data);
            resolve(result.additives || []);
          } catch (error) {
            console.error('Failed to parse additive response:', error);
            resolve([]);
          }
        } else {
          console.error(`Additive analysis failed: HTTP ${res.statusCode}`);
          resolve([]);
        }
      });
    });

    req.on('error', (error) => {
      console.error('Additive request error:', error);
      resolve([]);
    });

    req.setTimeout(10000, () => {
      req.destroy();
      console.error('Additive analysis timeout');
      resolve([]);
    });

    req.write(postData);
    req.end();
  });
}

async function csvToFoodDocument(row) {
  const ingredients = row.clean_ingredients || '';

  // Analyze additives from ingredients
  const additives = await analyzeAdditives(ingredients);

  return {
    foodName: row.clean_food_name || '',
    brandName: row.clean_brand_name || '',
    ingredients: ingredients,
    extractedIngredients: ingredients,
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
    additives: additives,
    servingSize: row.orig_serving_size || '100g',
    source: 'spellchecked_import',
    verifiedBy: 'data_import',
    importedAt: new Date().toISOString()
  };
}

async function uploadBatch(foods, batchNum, totalBatches) {
  return new Promise((resolve, reject) => {
    console.log(`📤 Uploading batch ${batchNum}/${totalBatches} (${foods.length} foods)...`);

    const postData = JSON.stringify({ foods, deleteFirst: batchNum === 1 });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(REPLACE_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(data);
          console.log(`✅ Batch ${batchNum}/${totalBatches} complete (deleted: ${result.deleted}, uploaded: ${result.uploaded})`);
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
  console.log('🚀 UPLOADING FOODS WITH ADDITIVE ANALYSIS');
  console.log('===========================================\n');

  const rows = [];

  // Read CSV
  console.log('📖 Reading CSV...');
  await new Promise((resolve, reject) => {
    fs.createReadStream(CSV_PATH)
      .pipe(csv())
      .on('data', (row) => {
        rows.push(row);
      })
      .on('end', resolve)
      .on('error', reject);
  });

  console.log(`📊 Read ${rows.length} foods from CSV\n`);

  // Process in smaller batches to avoid overwhelming the additive API
  const BATCH_SIZE = 100;
  const totalBatches = Math.ceil(rows.length / BATCH_SIZE);

  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batchRows = rows.slice(i, i + BATCH_SIZE);
    const batchNum = Math.floor(i / BATCH_SIZE) + 1;

    console.log(`\n🔬 Analyzing additives for batch ${batchNum}/${totalBatches}...`);

    // Analyze additives for this batch (with progress)
    const foods = [];
    for (let j = 0; j < batchRows.length; j++) {
      const food = await csvToFoodDocument(batchRows[j]);
      foods.push(food);

      if ((j + 1) % 10 === 0 || j === batchRows.length - 1) {
        process.stdout.write(`\r   Analyzed ${j + 1}/${batchRows.length} foods in batch ${batchNum}...`);
      }
    }
    console.log('');

    // Upload this batch
    await uploadBatch(foods, batchNum, totalBatches);
  }

  console.log(`\n✅ Upload complete! Processed ${rows.length} foods with additive analysis.\n`);
  process.exit(0);
}

main().catch((error) => {
  console.error('\n❌ Error:', error);
  process.exit(1);
});
