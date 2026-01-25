const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.env.ALGOLIA_ADMIN_API_KEY;

async function searchGenericOliveOil() {
  const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

  try {
    // Search for olive oil with brand containing "generic" (case insensitive)
    const result = await client.searchSingleIndex({
      indexName: 'uk_foods_cleaned',
      searchParams: {
        query: 'olive oil',
        filters: '',
        hitsPerPage: 100,
      },
    });

    console.log(`Total hits for "olive oil": ${result.hits.length}`);
    console.log('\n=== Generic Olive Oil Products ===\n');

    const genericItems = result.hits.filter(hit => {
      const brand = (hit.brand || hit.brandName || '').toLowerCase();
      return brand.includes('generic');
    });

    console.log(`Found ${genericItems.length} generic olive oil products:\n`);

    genericItems.forEach((item, idx) => {
      console.log(`${idx + 1}. ${item.name || item.foodName}`);
      console.log(`   Brand: ${item.brand || item.brandName}`);
      console.log(`   ID: ${item.objectID}`);
      console.log(`   Calories: ${item.calories}`);
      console.log(`   Barcode: ${item.barcode || 'N/A'}`);
      console.log('');
    });

    // Also check for exact "Generic" brand filter
    console.log('\n=== Searching with brand filter ===\n');

    const brandFilterResult = await client.searchSingleIndex({
      indexName: 'uk_foods_cleaned',
      searchParams: {
        query: '',
        filters: 'brand:Generic OR brandName:Generic',
        hitsPerPage: 100,
      },
    });

    console.log(`Found ${brandFilterResult.hits.length} items with brand="Generic"`);
    brandFilterResult.hits.forEach((item, idx) => {
      console.log(`${idx + 1}. ${item.name || item.foodName} (${item.brand || item.brandName})`);
    });

  } catch (error) {
    console.error('Error searching:', error);
  }
}

searchGenericOliveOil();
