#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');
const fs = require('fs');
const path = require('path');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node restore-foods-index.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

const FOODS_CORRUPTED = [
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

async function loadCSVByBarcode() {
  console.log('📂 Loading CSV data...');
  const csvPath = path.join(__dirname, '../../uk_foods_cleaned.csv');
  const content = fs.readFileSync(csvPath, 'utf-8');
  const lines = content.split('\n');

  const barcodeToData = new Map();
  const nameToData = new Map();

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const values = parseCSVLine(line);
    const name = values[0] || '';
    const barcode = values[2];

    const data = {
      name,
      brand: values[1] || '',
      barcode,
      calories: parseFloat(values[5]) || 0,
      protein: parseFloat(values[6]) || 0,
      carbs: parseFloat(values[7]) || 0,
      fat: parseFloat(values[8]) || 0,
      saturatedFat: parseFloat(values[9]) || 0,
      fiber: parseFloat(values[10]) || 0,
      fibre: parseFloat(values[10]) || 0,
      sugar: parseFloat(values[11]) || 0,
      sodium: parseFloat(values[12]) || 0,
    };

    if (barcode) {
      barcodeToData.set(barcode, data);
    }
    // Also index by lowercase name for fuzzy matching
    const normalizedName = name.toLowerCase().trim();
    if (!nameToData.has(normalizedName)) {
      nameToData.set(normalizedName, data);
    }
  }

  return { barcodeToData, nameToData };
}

async function main() {
  console.log('🔧 Attempting to restore foods index records...\n');

  const { barcodeToData, nameToData } = await loadCSVByBarcode();
  console.log(`   Loaded ${barcodeToData.size} records by barcode`);
  console.log(`   Loaded ${nameToData.size} records by name\n`);

  // Fetch all corrupted records to check their barcodes
  const records = [];
  for (const objectID of FOODS_CORRUPTED) {
    try {
      const result = await client.getObject({
        indexName: 'foods',
        objectID,
      });
      records.push({ objectID, ...result });
    } catch (e) {
      console.log(`   ✗ Could not fetch ${objectID}`);
    }
  }

  console.log(`📊 Checking ${records.length} corrupted records...\n`);

  const updates = [];
  const toDelete = [];

  for (const record of records) {
    const name = record.name || '';
    const barcode = record.barcode || '';

    // Try to match by barcode first
    let csvData = null;
    if (barcode && barcodeToData.has(barcode)) {
      csvData = barcodeToData.get(barcode);
    }

    // Try to match by exact name
    if (!csvData) {
      const normalizedName = name.toLowerCase().trim();
      if (nameToData.has(normalizedName)) {
        csvData = nameToData.get(normalizedName);
      }
    }

    if (csvData) {
      updates.push({
        objectID: record.objectID,
        calories: csvData.calories,
        protein: csvData.protein,
        carbs: csvData.carbs,
        fat: csvData.fat,
        saturatedFat: csvData.saturatedFat,
        fiber: csvData.fiber,
        fibre: csvData.fibre,
        sugar: csvData.sugar,
        sodium: csvData.sodium,
        isVerified: false,
      });
      console.log(`   ✓ Match found: "${name}" -> ${csvData.calories} cal (from ${csvData.name})`);
    } else {
      toDelete.push(record.objectID);
      console.log(`   ✗ No match: "${name}" - will delete`);
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Can restore: ${updates.length}`);
  console.log(`   Need deletion: ${toDelete.length}`);

  if (updates.length > 0) {
    console.log('\n📤 Updating matched records...');
    await client.partialUpdateObjects({
      indexName: 'foods',
      objects: updates,
      createIfNotExists: false,
    });
    console.log(`   ✅ Updated ${updates.length} records`);
  }

  if (toDelete.length > 0) {
    console.log('\n🗑️  Deleting unmatched records...');
    await client.deleteObjects({
      indexName: 'foods',
      objectIDs: toDelete,
    });
    console.log(`   ✅ Deleted ${toDelete.length} records`);
  }

  console.log('\n🎉 Done!');
}

main().catch(console.error);
