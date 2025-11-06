import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const auditMissingIngredients = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    console.log('Starting ingredients audit...');

    const collections = ['verifiedFoods', 'foods', 'manualFoods'];
    const results: any = {
      collections: {},
      totals: {
        totalProducts: 0,
        missingIngredients: 0,
        emptyIngredients: 0,
        emptyArrayIngredients: 0,
        hasIngredients: 0
      },
      sampleMissingProducts: []
    };

    for (const collectionName of collections) {
      console.log(`\nAuditing collection: ${collectionName}`);

      const snapshot = await admin.firestore()
        .collection(collectionName)
        .get();

      const stats = {
        total: snapshot.size,
        missing: 0,
        empty: 0,
        emptyArray: 0,
        hasIngredients: 0,
        samples: [] as any[]
      };

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const foodName = data.foodName || data.name || 'Unknown';
        const brandName = data.brandName || data.brand || 'Unknown';
        const barcode = data.barcode || 'No barcode';

        // Check extractedIngredients or ingredients field
        const ingredients = data.extractedIngredients || data.ingredients;

        // Categorize ingredient status
        if (ingredients === null || ingredients === undefined) {
          stats.missing++;
          if (stats.samples.length < 20) {
            stats.samples.push({
              id: doc.id,
              name: foodName,
              brand: brandName,
              barcode: barcode,
              reason: 'null/undefined'
            });
          }
        } else if (ingredients === '') {
          stats.empty++;
          if (stats.samples.length < 20) {
            stats.samples.push({
              id: doc.id,
              name: foodName,
              brand: brandName,
              barcode: barcode,
              reason: 'empty string'
            });
          }
        } else if (Array.isArray(ingredients) && ingredients.length === 0) {
          stats.emptyArray++;
          if (stats.samples.length < 20) {
            stats.samples.push({
              id: doc.id,
              name: foodName,
              brand: brandName,
              barcode: barcode,
              reason: 'empty array'
            });
          }
        } else {
          stats.hasIngredients++;
        }
      }

      results.collections[collectionName] = stats;
      results.totals.totalProducts += stats.total;
      results.totals.missingIngredients += stats.missing;
      results.totals.emptyIngredients += stats.empty;
      results.totals.emptyArrayIngredients += stats.emptyArray;
      results.totals.hasIngredients += stats.hasIngredients;

      // Add samples to global samples list
      results.sampleMissingProducts.push(...stats.samples.slice(0, 10));

      console.log(`${collectionName} stats:`, {
        total: stats.total,
        missing: stats.missing,
        empty: stats.empty,
        emptyArray: stats.emptyArray,
        hasIngredients: stats.hasIngredients
      });
    }

    // Calculate percentages
    const totalProblematic = results.totals.missingIngredients +
                            results.totals.emptyIngredients +
                            results.totals.emptyArrayIngredients;

    const problemPercentage = results.totals.totalProducts > 0
      ? ((totalProblematic / results.totals.totalProducts) * 100).toFixed(2)
      : '0';

    results.summary = {
      totalProducts: results.totals.totalProducts,
      totalProblematic: totalProblematic,
      problematicPercentage: `${problemPercentage}%`,
      breakdown: {
        nullUndefined: results.totals.missingIngredients,
        emptyString: results.totals.emptyIngredients,
        emptyArray: results.totals.emptyArrayIngredients
      },
      healthyProducts: results.totals.hasIngredients
    };

    console.log('\n=== AUDIT SUMMARY ===');
    console.log(`Total products: ${results.totals.totalProducts}`);
    console.log(`Products with missing ingredients: ${totalProblematic} (${problemPercentage}%)`);
    console.log(`  - null/undefined: ${results.totals.missingIngredients}`);
    console.log(`  - empty string: ${results.totals.emptyIngredients}`);
    console.log(`  - empty array: ${results.totals.emptyArrayIngredients}`);
    console.log(`Products with ingredients: ${results.totals.hasIngredients}`);

    res.json({
      success: true,
      audit: results
    });

  } catch (error) {
    console.error('Error during ingredients audit:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to audit ingredients',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});
