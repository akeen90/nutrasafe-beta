// Script to upload food databases to Algolia
// Run with: node upload-to-algolia.js

const { algoliasearch } = require('algoliasearch');
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = 'e54f75aae315af794ece385f3dc9c94b';

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

// Database configurations
const databases = [
  {
    file: '../../uk_foods_cleaned.csv',
    indexName: 'uk_foods_cleaned',
    description: 'UK Foods Cleaned - main database'
  },
  {
    file: '../../fast_food_database.csv',
    indexName: 'fast_foods_database',
    description: 'Fast Food restaurants'
  },
  {
    file: '../../generic_items_database.csv',
    indexName: 'generic_database',
    description: 'Generic food items'
  }
];

async function uploadDatabase(config) {
  console.log(`\n📦 Uploading ${config.description}...`);
  console.log(`   File: ${config.file}`);
  console.log(`   Index: ${config.indexName}`);

  const filePath = path.join(__dirname, config.file);

  if (!fs.existsSync(filePath)) {
    console.error(`   ❌ File not found: ${filePath}`);
    return;
  }

  // Read and parse CSV - don't cast to preserve barcodes as strings
  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const records = parse(fileContent, {
    columns: true,
    skip_empty_lines: true,
    cast: false,  // Don't auto-cast to preserve barcodes as strings
    relax_quotes: true,
    relax_column_count: true
  });

  console.log(`   Found ${records.length} records`);

  // Transform records to Algolia format
  const objects = records.map((record, index) => {
    // Generate objectID if not present
    const objectID = record.objectID || record.id || record.food_id ||
                     (record.barcode ? `barcode_${record.barcode}` : `${config.indexName}_${index}`);

    // Parse numeric fields
    const parseNum = (val) => {
      if (val === undefined || val === null || val === '') return 0;
      const num = parseFloat(val);
      return isNaN(num) ? 0 : num;
    };

    const transformed = {
      objectID,
      name: record.name || record.food_name || '',
      // App expects 'brandName' not 'brand'
      brandName: record.brand || null,
      calories: parseNum(record.calories),
      protein: parseNum(record.protein),
      carbs: parseNum(record.carbs) || parseNum(record.carbohydrates),
      fat: parseNum(record.fat),
      fiber: parseNum(record.fiber) || parseNum(record.fibre),
      sugar: parseNum(record.sugar) || parseNum(record.sugars),
      sodium: parseNum(record.sodium),
      saturatedFat: parseNum(record.saturatedFat) || parseNum(record.saturated_fat),
      ingredients: record.ingredients || null,
      barcode: record.barcode || null,
      // App expects 'servingSize' not 'servingDescription'
      servingSize: record.servingDescription || record.serving_description || 'per 100g',
      // App expects 'servingSizeG' for numeric serving size
      servingSizeG: parseNum(record.serving_size_g) || parseNum(record.servingSizeG) || null,
      isVerified: record.isVerified === 'true' || record.isVerified === true ||
                  record.is_verified === 'true' || record.is_verified === true || false,
      category: record.category || null,
      subcategory: record.subcategory || null,
    };

    // Add portions if present
    if (record.portions) {
      try {
        transformed.portions = typeof record.portions === 'string'
          ? JSON.parse(record.portions)
          : record.portions;
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return transformed;
  });

  // Filter out records without names
  const validObjects = objects.filter(obj => obj.name && obj.name.trim() !== '');
  console.log(`   Valid records: ${validObjects.length}`);

  if (validObjects.length === 0) {
    console.log('   ⚠️ No valid records to upload');
    return;
  }

  try {
    // Clear the index first (create new if doesn't exist)
    console.log(`   Clearing/creating index...`);
    try {
      await client.clearObjects({ indexName: config.indexName });
    } catch (e) {
      // Index might not exist yet, that's ok
      console.log(`   Creating new index ${config.indexName}...`);
    }

    // Upload in batches
    const batchSize = 1000;
    let uploaded = 0;

    for (let i = 0; i < validObjects.length; i += batchSize) {
      const batch = validObjects.slice(i, i + batchSize);
      await client.saveObjects({
        indexName: config.indexName,
        objects: batch
      });
      uploaded += batch.length;
      process.stdout.write(`\r   Uploaded ${uploaded}/${validObjects.length} records...`);
    }
    console.log('');

    // Configure index settings for better search
    await client.setSettings({
      indexName: config.indexName,
      indexSettings: {
        searchableAttributes: ['name', 'brand', 'ingredients', 'barcode'],
        attributesForFaceting: ['brand', 'isVerified', 'category'],
        customRanking: ['desc(isVerified)', 'asc(name)']
      }
    });

    console.log(`   ✅ Successfully uploaded ${validObjects.length} records to ${config.indexName}`);
  } catch (error) {
    console.error(`   ❌ Error uploading to ${config.indexName}:`, error.message);
  }
}

async function main() {
  console.log('🚀 Starting database upload to Algolia...\n');

  for (const db of databases) {
    await uploadDatabase(db);
  }

  console.log('\n✅ All uploads complete!');

  // List indices to verify
  console.log('\n📋 Current Algolia indices:');
  const response = await client.listIndices();
  for (const index of response.items) {
    console.log(`   - ${index.name}: ${index.entries} records`);
  }
}

main().catch(console.error);
