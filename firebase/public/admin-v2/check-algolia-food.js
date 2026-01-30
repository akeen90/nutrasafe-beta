const algoliasearch = require('algoliasearch');

const client = algoliasearch('CEXWF473VC', '577cc4ee3fed660318917bbb54abfb2e');

const indices = [
  'uk_foods_cleaned',
  'tescoProducts',
  'fast_foods_database',
  'generic_database',
  'foods',
  'verified_foods'
];

async function findFood(foodId) {
  console.log(`Searching for food ID: ${foodId}\n`);
  
  for (const indexName of indices) {
    try {
      const index = client.initIndex(indexName);
      const result = await index.search('', {
        filters: `objectID:${foodId}`,
        attributesToRetrieve: ['objectID', 'title', 'name', 'foodName', 'suggestedServingUnit', 'unitOverrideLocked', 'servingDescription']
      });
      
      if (result.hits.length > 0) {
        console.log(`✅ FOUND in index: ${indexName}`);
        console.log(JSON.stringify(result.hits[0], null, 2));
        return;
      }
    } catch (error) {
      console.log(`❌ Error searching ${indexName}:`, error.message);
    }
  }
  
  console.log('❌ Food not found in any index');
}

findFood('254900750').then(() => process.exit(0));
