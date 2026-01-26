/**
 * Check what serving size Tesco provides for ketchup/sauces
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function checkTescoKetchupServing() {
  try {
    const response = await axios.post(
      `${BASE_URL}/tesco_products/query`,
      {
        query: 'heinz ketchup',
        hitsPerPage: 10,
        attributesToRetrieve: ['*']
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

    console.log('🍅 Checking Tesco Ketchup/Sauce Serving Sizes\n');
    console.log('='.repeat(80));

    products.forEach((p, i) => {
      console.log(`\n${i + 1}. ${p.name}`);
      console.log(`   servingSizeG: ${p.servingSizeG || 'N/A'}`);
      console.log(`   servingSize: ${p.servingSize || 'N/A'}`);
      console.log(`   servingDescription: ${p.servingDescription || 'N/A'}`);
      console.log(`   calories (per 100g): ${p.calories}`);

      if (p.servingSizeG) {
        const servingCals = p.calories * (p.servingSizeG / 100);
        console.log(`   → Serving calories: ${servingCals.toFixed(0)} kcal`);
        if (servingCals > 700) {
          console.log(`   ⚠️  WARNING: Serving > 700 cals (likely package size, not serving!)`);
        }
      }
    });

    console.log('\n' + '='.repeat(80));

  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkTescoKetchupServing();
