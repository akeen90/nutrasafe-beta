import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { analyzeIngredientsForAdditives, calculateProcessingScore, determineGrade, loadAdditiveDatabase } from './additive-analyzer-enhanced';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const searchFoodByBarcode = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    loadAdditiveDatabase();

    const barcode = req.body.barcode || req.query.barcode;
    
    if (!barcode) {
      res.status(400).json({ 
        success: false,
        error: 'Barcode parameter is required' 
      });
      return;
    }

    console.log(`Searching for barcode: "${barcode}"`);

    // Search all food collections for the barcode
    const collections = ['verifiedFoods', 'foods', 'manualFoods'];
    let foundFood = null;
    let foundCollection = null;

    for (const collection of collections) {
      try {
        console.log(`Searching ${collection} for barcode: ${barcode}`);
        
        const snapshot = await admin.firestore()
          .collection(collection)
          .where('barcode', '==', barcode)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          const doc = snapshot.docs[0];
          const data = doc.data();
          
          foundFood = {
            id: doc.id,
            collection: collection,
            ...data
          } as any;
          foundCollection = collection;
          console.log(`Found food in ${collection}: ${data.foodName || data.name}`);
          break;
        }
      } catch (error) {
        console.log(`Error searching ${collection}:`, error);
      }
    }

    if (!foundFood) {
      console.log(`No food found with barcode: ${barcode}`);

      // Create placeholder entry for unknown barcode
      const placeholderId = `barcode-${barcode}-${Date.now()}`;
      const placeholderFood = {
        id: placeholderId,
        barcode: barcode,
        name: `Unknown Product (${barcode})`,
        brand: null,
        status: 'pending_user_input',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        contributedBy: 'barcode_scan',
        needsUserData: true,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        ingredients: [],
        verified: false
      };

      try {
        // Add to pendingFoods collection for admin review
        await admin.firestore()
          .collection('pendingFoods')
          .doc(placeholderId)
          .set(placeholderFood);

        console.log(`Created placeholder entry for barcode: ${barcode}`);

        // Return response indicating food needs user input
        res.json({
          success: false,
          error: 'Product not found',
          message: 'No food found with this barcode in our database',
          action: 'user_contribution_needed',
          placeholder_id: placeholderId,
          barcode: barcode
        });
      } catch (error) {
        console.error('Error creating placeholder food:', error);
        res.json({
          success: false,
          error: 'Product not found',
          message: 'No food found with this barcode in our database'
        });
      }
      return;
    }

    // Transform the food data to match iOS app expectations
    const nutrition = foundFood.nutritionData || {};
    const foodName = foundFood.foodName || foundFood.name || 'Unknown Product';
    const brandName = foundFood.brandName || foundFood.brand || null;

    // Analyze ingredients for additives and processing score
    let additiveAnalysis = null;
    let processingInfo = null;
    const ingredientsData = foundFood.extractedIngredients || foundFood.ingredients || null;
    const ingredientsString = Array.isArray(ingredientsData) ? ingredientsData.join(', ') : ingredientsData;

    if (ingredientsString && typeof ingredientsString === 'string') {
      try {
        const analysisResult = analyzeIngredientsForAdditives(ingredientsString);
        const processingScore = calculateProcessingScore(analysisResult.detectedAdditives, ingredientsString);
        const grade = determineGrade(processingScore.totalScore, analysisResult.hasRedFlags);

        additiveAnalysis = analysisResult.detectedAdditives.map(additive => ({
          ...additive,
          id: additive.code,
          consumerInfo: additive.consumer_guide
        }));

        processingInfo = {
          score: processingScore.totalScore,
          grade: grade.grade,
          label: grade.label,
          breakdown: processingScore.breakdown
        };
      } catch (error) {
        console.log(`Additive analysis failed for ${foodName}:`, error);
      }
    }

    // Format nutrition data
    const calorieValue = nutrition.calories || nutrition.energy || 0;
    const proteinValue = nutrition.protein || 0;
    const carbsValue = nutrition.carbs || nutrition.carbohydrates || 0;
    const fatValue = nutrition.fat || 0;
    const fiberValue = nutrition.fiber || nutrition.fibre || 0;
    const sugarValue = nutrition.sugar || nutrition.sugars || 0;
    const sodiumValue = nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0);

    // Return data in the format expected by iOS app
    const responseFood = {
      food_id: foundFood.id,
      food_name: foodName,
      brand_name: brandName,
      barcode: foundFood.barcode || barcode,
      calories: typeof calorieValue === 'object' ? calorieValue.kcal || calorieValue.per100g || 0 : calorieValue,
      protein: typeof proteinValue === 'object' ? proteinValue.per100g || 0 : proteinValue,
      carbohydrates: typeof carbsValue === 'object' ? carbsValue.per100g || 0 : carbsValue,
      fat: typeof fatValue === 'object' ? fatValue.per100g || 0 : fatValue,
      fiber: typeof fiberValue === 'object' ? fiberValue.per100g || 0 : fiberValue,
      sugar: typeof sugarValue === 'object' ? sugarValue.per100g || 0 : sugarValue,
      sodium: typeof sodiumValue === 'object' ? sodiumValue.per100g || 0 : sodiumValue,
      serving_description: foundFood.servingSize || 'per 100g',
      
      // Include ingredients as a string (what the iOS app expects)
      ingredients: ingredientsString || '',
      
      // Include additive analysis
      additives: additiveAnalysis || [],
      processing_score: processingInfo?.score || 0,
      processing_grade: processingInfo?.grade || 'A',
      processing_label: processingInfo?.label || 'Minimal processing',
      
      // Include micronutrient profile
      micronutrient_profile: foundFood.micronutrientProfile || null,
      
      // Include source information
      source_collection: foundCollection,
      verified_by: foundFood.verifiedBy || null,
      verified_at: foundFood.verifiedAt || null
    };

    console.log(`Successfully found and formatted food: ${foodName} (${brandName || 'No brand'}) with ${ingredientsString ? 'ingredients' : 'no ingredients'}`);

    res.json({
      success: true,
      food: responseFood
    });

  } catch (error) {
    console.error('Error searching food by barcode:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error while searching for barcode' 
    });
  }
});