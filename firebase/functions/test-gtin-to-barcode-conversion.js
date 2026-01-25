/**
 * Test if we can convert Tesco GTIN-14 to EAN-13 by removing first digit
 *
 * GTIN-14 format: 0 + EAN-13
 * Where first digit is often a packaging indicator (0 = base unit)
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function searchIndex(indexName, query, hitsPerPage = 20) {
  try {
    const response = await axios.post(
      `${BASE_URL}/${indexName}/query`,
      {
        query: query,
        hitsPerPage: hitsPerPage,
        attributesToRetrieve: ['name', 'brandName', 'gtin', 'barcode', 'objectID']
      },
      {
        headers: {
          'X-Algolia-Application-Id': ALGOLIA_APP_ID,
          'X-Algolia-API-Key': ALGOLIA_SEARCH_KEY,
          'Content-Type': 'application/json'
        }
      }
    );
    return response.data.hits || [];
  } catch (error) {
    console.error(`Error searching ${indexName}:`, error.message);
    return [];
  }
}

async function searchByBarcode(indexName, barcode) {
  const results = await searchIndex(indexName, barcode, 5);
  return results.find(hit => hit.barcode === barcode);
}

function convertGTIN14ToEAN13(gtin14) {
  // GTIN-14 is often: packaging_indicator + EAN-13
  // Remove first digit if it's a 14-digit GTIN
  if (gtin14 && gtin14.length === 14) {
    return gtin14.substring(1); // Remove first character
  }
  return gtin14;
}

async function testGTINConversion() {
  console.log('🔍 Testing GTIN-14 to EAN-13 Conversion\n');
  console.log('=' .repeat(80));
  console.log('\nTheory: Tesco GTIN-14 = 0 + EAN-13 (remove first digit to get barcode)\n');

  // Get Tesco products
  console.log('📦 Fetching 30 Tesco products...\n');
  const tescoProducts = await searchIndex('tesco_products', '', 30);

  if (tescoProducts.length === 0) {
    console.log('❌ No Tesco products found!');
    return;
  }

  let matchCount = 0;
  let noGtinCount = 0;
  let wrongLengthCount = 0;
  const matches = [];
  const noMatches = [];

  for (const product of tescoProducts) {
    const gtin = product.gtin || product.barcode;

    if (!gtin) {
      noGtinCount++;
      continue;
    }

    // Check GTIN length
    if (gtin.length !== 14) {
      wrongLengthCount++;
      console.log(`⚠️  GTIN not 14 digits: ${product.name} (GTIN: ${gtin}, length: ${gtin.length})`);
      continue;
    }

    // Convert GTIN-14 to EAN-13
    const ean13 = convertGTIN14ToEAN13(gtin);

    console.log(`\n🔄 Converting: ${product.name}`);
    console.log(`   GTIN-14: ${gtin}`);
    console.log(`   EAN-13:  ${ean13} (removed first digit)`);

    // Search uk_foods_cleaned with converted barcode
    const ukMatch = await searchByBarcode('uk_foods_cleaned', ean13);

    if (ukMatch) {
      matchCount++;
      console.log(`   ✅ MATCH! ${ukMatch.name}`);
      console.log(`      UK Barcode: ${ukMatch.barcode}`);
      matches.push({
        tescoName: product.name,
        tescoBrand: product.brandName,
        gtin14: gtin,
        ean13: ean13,
        ukName: ukMatch.name,
        ukBarcode: ukMatch.barcode
      });
    } else {
      console.log(`   ❌ No match`);
      noMatches.push({
        tescoName: product.name,
        tescoBrand: product.brandName,
        gtin14: gtin,
        ean13: ean13
      });
    }
  }

  // Summary
  console.log('\n' + '='.repeat(80));
  console.log('\n📊 SUMMARY\n');
  console.log(`Total Tesco products tested: ${tescoProducts.length}`);
  console.log(`Products without GTIN: ${noGtinCount}`);
  console.log(`Products with wrong GTIN length: ${wrongLengthCount}`);
  console.log(`Valid GTIN-14 products: ${tescoProducts.length - noGtinCount - wrongLengthCount}`);
  console.log(`✅ Matches after conversion: ${matchCount}`);
  console.log(`❌ No matches: ${noMatches.length}`);

  const validProducts = tescoProducts.length - noGtinCount - wrongLengthCount;
  if (validProducts > 0) {
    console.log(`\n🎯 Match rate: ${((matchCount / validProducts) * 100).toFixed(1)}%`);
  }

  if (matches.length > 0) {
    console.log('\n\n✅ SUCCESSFUL CONVERSIONS:\n');
    matches.forEach((m, i) => {
      console.log(`${i + 1}. Tesco: ${m.tescoName} (${m.tescoBrand || 'N/A'})`);
      console.log(`   UK Foods: ${m.ukName}`);
      console.log(`   GTIN-14: ${m.gtin14} → EAN-13: ${m.ean13}`);
      console.log(`   Matched Barcode: ${m.ukBarcode}\n`);
    });
  }

  if (noMatches.length > 0 && noMatches.length <= 5) {
    console.log('\n❌ FAILED CONVERSIONS (examples):\n');
    noMatches.slice(0, 5).forEach((m, i) => {
      console.log(`${i + 1}. ${m.tescoName} (${m.tescoBrand || 'N/A'})`);
      console.log(`   GTIN-14: ${m.gtin14} → EAN-13: ${m.ean13}\n`);
    });
  }

  console.log('='.repeat(80));
  console.log('\n💡 CONCLUSION:\n');
  if (matchCount > 0) {
    const matchRate = (matchCount / validProducts) * 100;
    console.log(`✅ Conversion WORKS! ${matchRate.toFixed(1)}% of GTINs converted to matching barcodes`);
    console.log('   We can search Tesco by converting GTIN-14 → EAN-13 (remove first digit)');
    console.log('   This means barcode search SHOULD include tesco_products with conversion!\n');
  } else {
    console.log('❌ Conversion does NOT work. GTIN-14 and EAN-13 are not compatible.\n');
  }
}

testGTINConversion().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
