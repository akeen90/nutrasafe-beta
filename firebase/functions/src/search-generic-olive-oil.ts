import * as functions from 'firebase-functions';
import { algoliasearch } from 'algoliasearch';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY;

export const searchGenericOliveOil = functions
  .runWith({ timeoutSeconds: 60 })
  .https.onRequest(async (req, res) => {
    try {
      const client = algoliasearch(ALGOLIA_APP_ID!, ALGOLIA_ADMIN_KEY!);

      // Search for all olive oil products
      const result = await client.searchSingleIndex({
        indexName: 'uk_foods_cleaned',
        searchParams: {
          query: 'olive oil',
          filters: '',
          hitsPerPage: 200,
        },
      });

      console.log(`Total hits for "olive oil": ${result.hits.length}`);

      // Filter for generic brand
      const genericItems = result.hits.filter((hit: any) => {
        const brand = (hit.brand || hit.brandName || '').toLowerCase();
        return brand.includes('generic');
      });

      console.log(`Found ${genericItems.length} generic olive oil products`);

      res.json({
        success: true,
        totalOliveOilResults: result.hits.length,
        genericCount: genericItems.length,
        genericItems: genericItems.map((item: any) => ({
          id: item.objectID,
          name: item.name || item.foodName,
          brand: item.brand || item.brandName,
          calories: item.calories,
          barcode: item.barcode,
        })),
      });
    } catch (error) {
      console.error('Error searching:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
