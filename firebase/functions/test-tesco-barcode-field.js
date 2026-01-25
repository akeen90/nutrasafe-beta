/**
 * Check what fields Tesco products actually have in Algolia
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function checkTescoFields() {
  try {
    const response = await axios.post(
      `${BASE_URL}/tesco_products/query`,
      {
        query: '',
        hitsPerPage: 10,
        attributesToRetrieve: ['*'] // Get ALL fields
      },
      {
        headers: {
          'X-Algolia-Application-Id': ALGOLIA_APP_ID,
          'X-Algolia-API-Key': ALGOLIA_SEARCH_KEY,
          'Content-Type': 'application/json'
        }
      }
    );

    const products = response.data.hits || [];

    console.log('🔍 Checking Tesco product fields in Algolia\n');
    console.log('='.repeat(80));

    if (products.length === 0) {
      console.log('❌ No Tesco products found');
      return;
    }

    products.slice(0, 5).forEach((p, i) => {
      console.log(`\n${i + 1}. ${p.name}`);
      console.log(`   objectID: ${p.objectID}`);
      console.log(`   barcode field: ${p.barcode ? '✅ "' + p.barcode + '"' : '❌ undefined/null'}`);
      console.log(`   gtin field: ${p.gtin ? '✅ "' + p.gtin + '"' : '❌ undefined/null'}`);
      console.log(`   All fields: ${Object.keys(p).join(', ')}`);
    });

    console.log('\n' + '='.repeat(80));

    // Summary
    const withBarcode = products.filter(p => p.barcode).length;
    const withGtin = products.filter(p => p.gtin).length;

    console.log(`\n📊 Summary (${products.length} products checked):`);
    console.log(`   Products with 'barcode' field: ${withBarcode} (${((withBarcode/products.length)*100).toFixed(0)}%)`);
    console.log(`   Products with 'gtin' field: ${withGtin} (${((withGtin/products.length)*100).toFixed(0)}%)`);

    if (withBarcode === 0 && withGtin > 0) {
      console.log('\n❌ PROBLEM: Tesco uses "gtin" field, but Swift model only has "barcode"!');
      console.log('   The barcode field is not populated in Algolia.');
      console.log('   Swift code needs to decode "gtin" field or Algolia needs barcode populated.');
    } else if (withBarcode > 0) {
      console.log('\n✅ Tesco products have "barcode" field populated');
    }

  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkTescoFields();
