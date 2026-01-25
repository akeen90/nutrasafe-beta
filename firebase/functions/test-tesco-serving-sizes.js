/**
 * Check what serving size data Tesco products have in Algolia
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function checkTescoServingSizes() {
  try {
    const response = await axios.post(
      `${BASE_URL}/tesco_products/query`,
      {
        query: 'chocolate',
        hitsPerPage: 20,
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

    console.log('🍫 Checking Tesco Serving Size Data\n');
    console.log('='.repeat(80));

    if (products.length === 0) {
      console.log('❌ No products found');
      return;
    }

    products.slice(0, 15).forEach((p, i) => {
      console.log(`\n${i + 1}. ${p.name}`);
      console.log(`   servingDescription: ${p.servingDescription || 'N/A'}`);
      console.log(`   servingSizeG: ${p.servingSizeG || 'N/A'}`);
      console.log(`   packageSize: ${p.packageSize || 'N/A'}`);
      console.log(`   netWeight: ${p.netWeight || 'N/A'}`);
      console.log(`   size: ${p.size || 'N/A'}`);

      // Show all fields with "serving" or "size" in the name
      const sizeFields = Object.keys(p).filter(k =>
        k.toLowerCase().includes('serv') || k.toLowerCase().includes('size') || k.toLowerCase().includes('weight')
      );
      if (sizeFields.length > 0) {
        console.log(`   All size-related fields: ${sizeFields.join(', ')}`);
        sizeFields.forEach(f => {
          if (p[f] && !['servingDescription', 'servingSizeG', 'packageSize', 'netWeight', 'size'].includes(f)) {
            console.log(`      ${f}: ${p[f]}`);
          }
        });
      }
    });

    console.log('\n' + '='.repeat(80));
    console.log('\n📊 Summary:\n');

    const withServingSize = products.filter(p => p.servingSizeG && p.servingSizeG > 0).length;
    const withPackageSize = products.filter(p => p.packageSize || p.netWeight || p.size).length;

    console.log(`Products with servingSizeG: ${withServingSize}/${products.length}`);
    console.log(`Products with package size data: ${withPackageSize}/${products.length}`);

    // Check if servingSizeG matches package size
    let matchesPackageCount = 0;
    products.forEach(p => {
      if (p.servingSizeG && (p.packageSize || p.netWeight || p.size)) {
        const packageSizeStr = p.packageSize || p.netWeight || p.size || '';
        const packageNum = parseFloat(packageSizeStr.replace(/[^0-9.]/g, ''));

        if (Math.abs(p.servingSizeG - packageNum) < 1) {
          matchesPackageCount++;
        }
      }
    });

    console.log(`\n⚠️  servingSizeG appears to be package size: ${matchesPackageCount}/${products.length}`);

    if (matchesPackageCount > products.length / 2) {
      console.log('\n❌ PROBLEM: servingSizeG is being set to package size instead of serving size!');
      console.log('   Tesco products need proper serving size calculation.');
    }

  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkTescoServingSizes();
