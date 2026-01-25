const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.env.ALGOLIA_ADMIN_API_KEY;

async function searchGenericOliveOil() {
  const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

  try {
    // Search for olive oil
    const result = await client.searchSingleIndex({
      indexName: 'uk_foods_cleaned',
      searchParams: {
        query: 'olive oil',
        filters: '',
        hitsPerPage: 100,
      },
    });

    console.log('Total hits for olive oil:', result.hits.length);

    const genericItems = result.hits.filter(hit => {
      const brand = (hit.brand || hit.brandName || '').toLowerCase();
      return brand.includes('generic');
    });

    console.log('\nFound', genericItems.length, 'generic olive oil products:\n');

    genericItems.forEach((item, idx) => {
      console.log((idx + 1) + '. ' + (item.name || item.foodName));
      console.log('   Brand:', item.brand || item.brandName);
      console.log('   ID:', item.objectID);
      console.log('   Calories:', item.calories);
      console.log('');
    });

  } catch (error) {
    console.error('Error searching:', error);
  }
}

searchGenericOliveOil();
