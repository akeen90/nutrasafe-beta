import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Efficient version of addVerifiedFoodManually that maps ALL fields and uses efficient duplicate detection
export const addVerifiedFoodComplete = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const requestData = req.body;
    const {
      foodName,
      brandName,
      barcode,
      extractedIngredients,
      category,
      nutritionData,
      servingSize,
      servingQuantity,
      packaging,
      stores,
      countries,
      nutritionGrade,
      novaGroup,
      imageFrontUrl,
      imageNutritionUrl,
      imageIngredientsUrl,
      source,
      completeness,
      isUKProduct,
      verifiedBy
    } = requestData;

    if (!foodName) {
      res.status(400).json({ error: 'Missing required field: foodName' });
      return;
    }

    console.log(`Adding complete verified food: ${foodName} (${brandName || 'No brand'})`);

    // EFFICIENT duplicate checking with targeted queries - PREVENTS £90 BILLS!
    let isDuplicate = false;
    const duplicateReasons: string[] = [];

    // 1. Check for barcode duplicates FIRST (if barcode exists) - Max 5 reads
    if (barcode && barcode.trim() !== '') {
      console.log(`Checking for barcode duplicate: ${barcode}`);
      const barcodeQuery = await admin.firestore()
        .collection('verifiedFoods')
        .where('barcode', '==', barcode.trim())
        .limit(5)
        .get();
      
      if (!barcodeQuery.empty) {
        isDuplicate = true;
        duplicateReasons.push(`barcode ${barcode}`);
        console.log(`Found barcode duplicate: ${barcodeQuery.docs[0].data().foodName}`);
      }
    }

    // 2. Check for exact food name + brand duplicates - Max 10 reads
    if (!isDuplicate && foodName && foodName.trim() !== '') {
      console.log(`Checking for name+brand duplicate: ${foodName} by ${brandName || 'no brand'}`);
      
      // Normalize for consistent matching
      const normalizedFoodName = foodName.toLowerCase()
        .replace(/[^\w\s]/g, '')
        .replace(/\s+/g, ' ')
        .trim();
      
      // Query by exact foodName match
      const nameQuery = await admin.firestore()
        .collection('verifiedFoods')
        .where('foodName', '>=', foodName)
        .where('foodName', '<=', foodName + '\uf8ff')
        .limit(10)
        .get();
      
      // Check each result for exact match
      for (const doc of nameQuery.docs) {
        const existingFood = doc.data();
        const existingNormalizedName = (existingFood.foodName || '')
          .toLowerCase()
          .replace(/[^\w\s]/g, '')
          .replace(/\s+/g, ' ')
          .trim();
        
        // Must have exact name match
        if (existingNormalizedName !== normalizedFoodName) {
          continue;
        }
        
        // Check brand matching
        const newBrand = (brandName || '').toLowerCase().trim();
        const existingBrand = (existingFood.brandName || '').toLowerCase().trim();
        
        // Both have brands - must match exactly
        if (newBrand && existingBrand) {
          if (newBrand === existingBrand) {
            isDuplicate = true;
            duplicateReasons.push(`name "${foodName}" + brand "${brandName}"`);
            break;
          }
        }
        // One has brand, other doesn't - different products
        else if (newBrand !== existingBrand) {
          continue;
        }
        // Both have no brand and same name - duplicate
        else {
          isDuplicate = true;
          duplicateReasons.push(`name "${foodName}" (both no brand)`);
          break;
        }
      }
    }

    // Handle duplicate detection result
    if (isDuplicate) {
      console.log(`Duplicate found: ${duplicateReasons.join(', ')}`);
      res.status(400).json({
        error: 'This food already exists in the verified database',
        duplicateReasons: duplicateReasons,
        suggestion: 'Use the edit function to update the existing food instead'
      });
      return;
    }

    // Create COMPLETE verified food record with ALL fields mapped
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const verifiedFoodData = {
      // Basic identification
      foodName: foodName || '',
      brandName: brandName || null,
      barcode: barcode || null,
      category: category || null,
      
      // Ingredients (critical for allergen detection)
      extractedIngredients: extractedIngredients || null,
      ingredients: extractedIngredients || null, // Backup for compatibility
      
      // Complete nutrition data
      nutritionData: nutritionData || {},
      
      // Additional nutrition info for scoring
      nutritionGrade: nutritionGrade || null,
      novaGroup: novaGroup || null,
      
      // Serving information
      servingSize: servingSize || null,
      servingQuantity: servingQuantity || null,
      
      // Product details
      packaging: packaging || null,
      stores: stores || null,
      countries: countries || null,
      
      // Image URLs for display
      imageFrontUrl: imageFrontUrl || null,
      imageNutritionUrl: imageNutritionUrl || null,
      imageIngredientsUrl: imageIngredientsUrl || null,
      
      // Data quality and source
      source: source || 'efficient_import_2025',
      completeness: completeness || 0,
      isUKProduct: isUKProduct !== undefined ? isUKProduct : true,
      
      // Verification metadata
      verified: true,
      verifiedAt: timestamp,
      verifiedBy: verifiedBy || 'efficient_import_system',
      adminNotes: 'Added via efficient import system with complete field mapping',
      originalSubmissionId: null,
      
      // Creation timestamp
      dateAdded: new Date().toISOString(),
      createdAt: timestamp
    };

    // Add to verified foods collection
    const docRef = await admin.firestore()
      .collection('verifiedFoods')
      .add(verifiedFoodData);

    console.log(`Successfully added complete verified food with ID: ${docRef.id}`);
    console.log(`Fields mapped: ${Object.keys(verifiedFoodData).length} total`);

    res.status(200).json({
      success: true,
      foodId: docRef.id,
      message: 'Complete food record added successfully to verified database',
      fieldsCount: Object.keys(verifiedFoodData).length,
      hasIngredients: !!extractedIngredients,
      hasNutrition: !!(nutritionData && Object.keys(nutritionData).length > 0),
      hasImages: !!(imageFrontUrl || imageNutritionUrl || imageIngredientsUrl)
    });

  } catch (error) {
    console.error('Error adding complete verified food:', error);
    res.status(500).json({
      error: 'Failed to add verified food',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Export the function
export default addVerifiedFoodComplete;