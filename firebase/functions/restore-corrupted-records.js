#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');
const fs = require('fs');
const path = require('path');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node restore-corrupted-records.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

// Corrupted records in uk_foods_cleaned (objectID format: barcode_XXXXXXXX)
const UK_FOODS_CORRUPTED = [
  { objectID: 'barcode_4025500243555', name: 'Banana & Custard Flavour' },
  { objectID: 'barcode_9340156092001', name: 'Banana & Mango Custard' },
  { objectID: 'barcode_5059512736636', name: 'Banana Bites' },
  { objectID: 'barcode_0811620022231', name: 'Banana Core Power' },
  { objectID: 'barcode_9329521002760', name: 'Banana Daifuku' },
  { objectID: 'barcode_96169537', name: 'Banana Devon Custard' },
  { objectID: 'barcode_0771047593007', name: 'Banana Frosty' },
  { objectID: 'barcode_9339687285457', name: 'Banana Fruit Custard' },
  { objectID: 'barcode_5055958701184', name: 'Banana Graze Protein Oat Bites' },
  { objectID: 'barcode_5060709282768', name: 'Banana Ketchup' },
  { objectID: 'barcode_00150139', name: 'Banana Ketchup' },
  { objectID: 'barcode_29376674', name: 'Banana Maple Peanut Butter' },
  { objectID: 'barcode_5060189400010', name: 'Banana Nut Free Flapjack' },
  { objectID: 'barcode_0035751513042', name: 'Banana Nut Muffin' },
  { objectID: 'barcode_0667888592753', name: 'Banana Peelz' },
  { objectID: 'barcode_0011213031590', name: 'Banana Pepper Rings' },
  { objectID: 'barcode_0001121303159', name: 'Banana Pepper Rings, Mild' },
  { objectID: 'barcode_8720165350155', name: 'Banana Plenny Shake' },
  { objectID: 'barcode_5024121347412', name: 'Banana Puffcorn' },
  { objectID: 'barcode_5060107332737', name: 'Banana Raisin Oaty Fingers' },
  { objectID: 'barcode_4088600566535', name: 'Banana Rusk Fingers' },
  { objectID: 'barcode_9418870001354', name: 'Banana Salted Caramel Cake' },
  { objectID: 'barcode_8847105461013', name: 'Banana Slice Cake' },
  { objectID: 'barcode_5000221608998', name: 'Banana Slices' },
  { objectID: 'barcode_5060040254417', name: 'Banana Wafers' },
  { objectID: 'barcode_5024121339127', name: 'Banana Weaning Wands' },
  { objectID: 'barcode_5060455516223', name: 'Banana Whey Protein' },
  { objectID: 'barcode_5000128861083', name: 'Bananas' },
  { objectID: 'barcode_0058779142988', name: 'Bananas Foster Core Ice Cream' },
  { objectID: 'barcode_5036589255154', name: 'Blueberry & Banana' },
  { objectID: 'barcode_5036589256151', name: 'Blueberry & Banana Whole Milk Yogurt' },
];

// CSV column indices (0-indexed)
// name,brand,barcode,category,subcategory,calories,protein,carbs,fat,saturated_fat,fiber,sugar,sodium,serving_size_g,serving_description,ingredients,allergens,is_verified
const CSV_COLS = {
  name: 0,
  brand: 1,
  barcode: 2,
  category: 3,
  subcategory: 4,
  calories: 5,
  protein: 6,
  carbs: 7,
  fat: 8,
  saturated_fat: 9,
  fiber: 10,
  sugar: 11,
  sodium: 12,
  serving_size_g: 13,
  serving_description: 14,
  ingredients: 15,
  allergens: 16,
  is_verified: 17,
};

function parseCSVLine(line) {
  const values = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      values.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  values.push(current.trim());
  return values;
}

async function loadCSVData() {
  console.log('📂 Loading CSV data...');
  const csvPath = path.join(__dirname, '../../uk_foods_cleaned.csv');
  const content = fs.readFileSync(csvPath, 'utf-8');
  const lines = content.split('\n');

  const barcodeToData = new Map();

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const values = parseCSVLine(line);
    const barcode = values[CSV_COLS.barcode];

    if (barcode) {
      barcodeToData.set(barcode, {
        name: values[CSV_COLS.name] || '',
        brand: values[CSV_COLS.brand] || '',
        barcode,
        category: values[CSV_COLS.category] || '',
        subcategory: values[CSV_COLS.subcategory] || '',
        calories: parseFloat(values[CSV_COLS.calories]) || 0,
        protein: parseFloat(values[CSV_COLS.protein]) || 0,
        carbs: parseFloat(values[CSV_COLS.carbs]) || 0,
        fat: parseFloat(values[CSV_COLS.fat]) || 0,
        saturatedFat: parseFloat(values[CSV_COLS.saturated_fat]) || 0,
        fiber: parseFloat(values[CSV_COLS.fiber]) || 0,
        fibre: parseFloat(values[CSV_COLS.fiber]) || 0,
        sugar: parseFloat(values[CSV_COLS.sugar]) || 0,
        sodium: parseFloat(values[CSV_COLS.sodium]) || 0,
        servingSizeG: parseFloat(values[CSV_COLS.serving_size_g]) || 100,
      });
    }
  }

  console.log(`   Loaded ${barcodeToData.size} records from CSV`);
  return barcodeToData;
}

async function restoreUKFoods(csvData) {
  console.log('\n📊 Restoring uk_foods_cleaned records...');

  const updates = [];
  const notFound = [];

  for (const item of UK_FOODS_CORRUPTED) {
    const barcode = item.objectID.replace('barcode_', '');
    const csvRecord = csvData.get(barcode);

    if (csvRecord) {
      updates.push({
        objectID: item.objectID,
        calories: csvRecord.calories,
        protein: csvRecord.protein,
        carbs: csvRecord.carbs,
        fat: csvRecord.fat,
        saturatedFat: csvRecord.saturatedFat,
        fiber: csvRecord.fiber,
        fibre: csvRecord.fibre,
        sugar: csvRecord.sugar,
        sodium: csvRecord.sodium,
        isVerified: false, // Remove the isVerified flag we incorrectly set
      });
      console.log(`   ✓ Found: "${item.name}" -> ${csvRecord.calories} cal`);
    } else {
      notFound.push(item);
      console.log(`   ✗ Not found in CSV: "${item.name}" (barcode: ${barcode})`);
    }
  }

  if (updates.length > 0) {
    await client.partialUpdateObjects({
      indexName: 'uk_foods_cleaned',
      objects: updates,
      createIfNotExists: false,
    });
    console.log(`\n   ✅ Restored ${updates.length} records in uk_foods_cleaned`);
  }

  return { restored: updates.length, notFound };
}

async function restoreFoodsIndex() {
  console.log('\n📊 Restoring foods index records...');

  // For the foods index, we need to find these records from another source
  // Let's check if any have barcodes we can match
  const foodsCorrupted = [
    'o2H2lZZD2FF98qazUusn', '8D3us67J3i2WfHSmHMer', 'm4EKBgr92J0Vd9a4Y2Ge',
    'Fq2XutJ6dxznp3pahppz', 'QM05I8c70L834SreOFs8', 'sfd43VzCu0NP6ylw96Ng',
    'vlZv6YN0Un4jq9T2NXxB', 'PZPwnUQQwAU0NF6Cx2qK', '657IzoZ6aVR9FNufIrrc',
    'rCDFmsUXrZVXNyVCL1oj', 'IqDWBz4p1sLjwglqpZmq', 'xyRnLyItHwkcLRlPsxlX',
    '9AWky0NEw2KNFYjPJMQD', 'aZctmWVe2n4tyT05xbcn', 'YGnnc04XoggV477q4CNJ',
    'PJogjKscFjuNXvHcamjZ', 'OEvNopINnvIzmEGmLmsZ', 'A1447C15-36DC-4C28-994F-33C24EC9A192',
    '0BRnEJumGxmEcYNXBJDD', 'TbpAsdl17bwhMZB0edsT', 'oE7DCNvdToC5y2GsuhBR',
    '5yoWJtd4nAYeQapsr6A1', 'kuv3cFg1bnp6orXfsnlt', 'xOR1ItvecZR15c1Hk7AK',
    '0BB3BF76-E86C-4A7B-B02A-5D5B2203CC66', '46D1E0ED-2B44-4479-92AD-DED2439B3676',
    '0QxLqUTlgPoDes7mH2Qy', 'o05hCx0CmoEuWNEwrEdL', 'D5OGaGeOOrJy0iaFGODy',
    '25MyA2AZKLEFYnC3h2Gp', 'QynRpte6vT04l9pBZTXg', 'QIukDRKeBBW7MbXwvCbI',
    'i2M7MG0auwpxngqKCPH5', 'yI8RFbcxYILPY55em5uB', 'q31UvgoY12jIKkCoWjfI',
    'bmV6NnfpIIF0DrVuwQte',
  ];

  // Fetch current records to get their barcodes
  const records = await Promise.all(
    foodsCorrupted.map(async (objectID) => {
      try {
        const result = await client.getObject({
          indexName: 'foods',
          objectID,
          attributesToRetrieve: ['name', 'barcode', 'brandName', 'brand'],
        });
        return { objectID, ...result };
      } catch (e) {
        return null;
      }
    })
  );

  const validRecords = records.filter(Boolean);
  console.log(`   Found ${validRecords.length} records in foods index`);

  // These records don't have barcodes in the CSV format
  // We need to either:
  // 1. Delete these records and let them be re-indexed
  // 2. Mark them for manual review
  // 3. Try to match by name in uk_foods_cleaned

  console.log('\n   ⚠️  Foods index records need manual review or deletion');
  console.log('   These records were imported from various sources and their original values are lost.');
  console.log('   Options:');
  console.log('   1. Delete corrupted records (users will have to search again)');
  console.log('   2. Mark as unverified and let users report issues');

  return { restored: 0, needsManualReview: foodsCorrupted.length };
}

async function main() {
  console.log('🔧 Restoring corrupted banana records...\n');

  const csvData = await loadCSVData();
  const ukResult = await restoreUKFoods(csvData);
  const foodsResult = await restoreFoodsIndex();

  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`uk_foods_cleaned: ${ukResult.restored} restored`);
  if (ukResult.notFound.length > 0) {
    console.log(`  - ${ukResult.notFound.length} not found in CSV`);
  }
  console.log(`foods: ${foodsResult.needsManualReview} need manual review`);
  console.log('\n🎉 Done!');
}

main().catch(console.error);
