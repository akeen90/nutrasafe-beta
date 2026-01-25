/**
 * Quick test to see if uk_foods_cleaned has actual barcodes
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function searchIndex(indexName, query, hitsPerPage = 50) {
  try {
    const response = await axios.post(
      `${BASE_URL}/${indexName}/query`,
      {
        query: query,
        hitsPerPage: hitsPerPage,
        attributesToRetrieve: ['name', 'brandName', 'barcode', 'objectID']
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
    console.error(`Error:`, error.message);
    return [];
  }
}

async function testUKFoodsBarcodes() {
  console.log('🔍 Checking uk_foods_cleaned for barcodes...\n');

  const products = await searchIndex('uk_foods_cleaned', '', 50);

  let withBarcode = 0;
  let withoutBarcode = 0;
  const examples = [];

  for (const product of products) {
    if (product.barcode && product.barcode.trim().length > 0) {
      withBarcode++;
      if (examples.length < 10) {
        examples.push({
          name: product.name,
          brand: product.brandName,
          barcode: product.barcode
        });
      }
    } else {
      withoutBarcode++;
    }
  }

  console.log(`📊 Results from ${products.length} products:\n`);
  console.log(`✅ With barcode: ${withBarcode} (${((withBarcode / products.length) * 100).toFixed(1)}%)`);
  console.log(`❌ Without barcode: ${withoutBarcode} (${((withoutBarcode / products.length) * 100).toFixed(1)}%)`);

  if (examples.length > 0) {
    console.log(`\n📋 Examples with barcodes:\n`);
    examples.forEach((e, i) => {
      console.log(`${i + 1}. ${e.name} (${e.brand || 'N/A'})`);
      console.log(`   Barcode: ${e.barcode}\n`);
    });
  }

  console.log(`\n💡 Conclusion: uk_foods_cleaned ${withBarcode > 0 ? 'DOES' : 'DOES NOT'} have barcodes`);
}

testUKFoodsBarcodes().catch(console.error);
