import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Efficient version of addVerifiedFoodManually with fixed duplicate detection
export const addVerifiedFoodManuallyEfficient = functions.https.onRequest(async (req, res) => {
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
    const { foodName, brandName, barcode, ingredients, extractedIngredients, nutritionData, verifiedBy } = req.body;

    if (!foodName) {
      res.status(400).json({ error: 'Missing required field: foodName' });
      return;
    }

    console.log(`Adding verified food manually: ${foodName} (${brandName || 'No brand'})`);

    // Efficient duplicate checking with targeted queries - SAVES MONEY!
    let isDuplicate = false;
    const duplicateReasons = [];

    // 1. Check for barcode duplicates FIRST (if barcode exists)
    if (barcode) {
      console.log(`Checking for barcode duplicate: ${barcode}`);
      const barcodeQuery = await admin.firestore()
        .collection('verifiedFoods')
        .where('barcode', '==', barcode)
        .limit(5)
        .get();
      
      if (!barcodeQuery.empty) {
        isDuplicate = true;
        duplicateReasons.push(`barcode ${barcode}`);
        console.log(`Found barcode duplicate: ${barcodeQuery.docs[0].data().foodName}`);
      }
    }

    // 2. Check for exact food name + brand duplicates (only if not already duplicate)
    if (!isDuplicate) {
      console.log(`Checking for name+brand duplicate: ${foodName} by ${brandName || 'no brand'}`);
      
      // Normalize for consistent matching
      const normalizedFoodName = foodName.toLowerCase().replace(/[^\w\s]/g, '').replace(/\s+/g, ' ').trim();
      
      // Query by exact foodName match (case-insensitive via normalization)
      const nameQuery = await admin.firestore()
        .collection('verifiedFoods')
        .where('foodName', '>=', foodName)
        .where('foodName', '<=', foodName + '\uf8ff')
        .limit(10)
        .get();
      
      // Check each result for exact match
      for (const doc of nameQuery.docs) {
        const existingFood = doc.data();
        const existingNormalizedName = (existingFood.foodName || '').toLowerCase().replace(/[^\w\s]/g, '').replace(/\s+/g, ' ').trim();
        
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

    // Create verified food record
    const verifiedFoodData = {
      foodName,
      brandName: brandName || null,
      ingredients: ingredients || null,
      extractedIngredients: extractedIngredients || ingredients || null,
      nutritionData: nutritionData || {},
      barcode: barcode || null,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      verifiedBy: verifiedBy || 'admin_manual',
      adminNotes: 'Added manually via admin dashboard (efficient version)',
      originalSubmissionId: null // No original submission for manual additions
    };

    // Add to verified foods collection
    const docRef = await admin.firestore()
      .collection('verifiedFoods')
      .add(verifiedFoodData);

    console.log(`Successfully added verified food manually with ID: ${docRef.id}`);

    res.status(200).json({
      success: true,
      foodId: docRef.id,
      message: 'Food added successfully to verified database (efficient version)'
    });

  } catch (error) {
    console.error('Error adding verified food manually:', error);
    res.status(500).json({
      error: 'Failed to add verified food',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});