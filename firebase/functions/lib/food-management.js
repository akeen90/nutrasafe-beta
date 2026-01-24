"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.browseAllIndices = exports.deleteFoodComprehensive = exports.adminSaveFood = exports.searchTescoAndUpdate = exports.fixExistingFoodsVerification = exports.resetAllFoodsToInitial = exports.resetAdminManualFoods = exports.moveFoodsBetweenIndices = exports.moveFoodBetweenCollections = exports.deleteFoodFromAlgolia = exports.deleteVerifiedFoods = exports.updateServingSizes = exports.addVerifiedFood = exports.updateVerifiedFood = void 0;
const functions = require("firebase-functions");
const params_1 = require("firebase-functions/params");
const admin = require("firebase-admin");
const algoliasearch_1 = require("algoliasearch");
const axios_1 = require("axios");
const cors = require('cors')({ origin: true });
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const algoliaAdminKey = (0, params_1.defineSecret)('ALGOLIA_ADMIN_API_KEY');
// Tesco8 API Configuration
const TESCO8_API_KEY = '7e61162448msh2832ba8d19f26cep1e55c3jsn5242e6c6d761';
const TESCO8_HOST = 'tesco8.p.rapidapi.com';
// Map Algolia index names to Firestore collection names (where applicable)
const INDEX_TO_COLLECTION = {
    'uk_foods_cleaned': null, // Algolia-only, no direct Firestore sync
    'fast_foods_database': null, // Algolia-only
    'generic_database': null, // Algolia-only
    'foods': 'foods', // Has Firestore backing
    'verified_foods': 'verifiedFoods',
    'manual_foods': 'manualFoods',
    'user_added': 'userAdded',
    'ai_enhanced': 'aiEnhanced',
    'ai_manually_added': 'aiManuallyAdded',
    'tesco_products': 'tescoProducts', // Fixed: was 'tesco_products', should be 'tescoProducts'
};
// Algolia-only indices (no Firestore backing)
const ALGOLIA_ONLY_INDICES = ['uk_foods_cleaned', 'fast_foods_database', 'generic_database'];
// Update verified food
exports.updateVerifiedFood = functions.runWith({ secrets: [algoliaAdminKey] }).https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, foodName, brandName, barcode, extractedIngredients, nutritionData, verifiedBy, verificationMethod, collection, servingSize, servingSizeG, servingUnit, isPerUnit, source } = req.body;
        if (!foodId) {
            res.status(400).json({ error: 'Food ID is required' });
            return;
        }
        // Determine which collection to update (default to verifiedFoods)
        const targetCollection = collection || 'verifiedFoods';
        console.log(`Updating food: ${foodId} in collection: ${targetCollection}`);
        // Prepare update data
        const updateData = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        // Add regular food fields if provided
        if (foodName !== undefined) {
            updateData.foodName = foodName;
            updateData.name = foodName; // Keep both for compatibility
        }
        if (brandName !== undefined) {
            updateData.brandName = brandName;
            updateData.brand = brandName; // Keep both for compatibility
        }
        if (barcode !== undefined)
            updateData.barcode = barcode;
        if (extractedIngredients !== undefined) {
            updateData.extractedIngredients = extractedIngredients;
            updateData.ingredients = extractedIngredients; // Backup compatibility
        }
        if (nutritionData !== undefined)
            updateData.nutritionData = nutritionData;
        if (servingSize !== undefined) {
            updateData.servingSize = servingSize;
            updateData.servingDescription = servingSize; // Keep both for compatibility
        }
        if (servingSizeG !== undefined)
            updateData.servingSizeG = servingSizeG;
        if (servingUnit !== undefined)
            updateData.servingUnit = servingUnit;
        if (isPerUnit !== undefined)
            updateData.isPerUnit = isPerUnit;
        if (source !== undefined)
            updateData.source = source;
        // Add verification status if provided
        if (verifiedBy !== undefined) {
            updateData.verifiedBy = verifiedBy;
            updateData.verifiedAt = admin.firestore.FieldValue.serverTimestamp();
            if (verificationMethod) {
                updateData.verificationMethod = verificationMethod;
            }
            else {
                // Set default verification method based on verifiedBy
                switch (verifiedBy) {
                    case 'human':
                        updateData.verificationMethod = 'manual';
                        break;
                    case 'ai':
                        updateData.verificationMethod = 'automatic';
                        break;
                    default:
                        updateData.verificationMethod = null;
                }
            }
        }
        console.log('Update data:', updateData);
        // Check if this is an Algolia-only index
        if (ALGOLIA_ONLY_INDICES.includes(targetCollection)) {
            // For Algolia-only indices, update directly in Algolia
            const algoliaKey = algoliaAdminKey.value()?.trim();
            if (!algoliaKey) {
                res.status(500).json({ error: 'Algolia API key not configured' });
                return;
            }
            const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaKey);
            // Prepare Algolia update object with flattened nutrition data
            const algoliaUpdate = {
                objectID: foodId,
                updatedAt: new Date().toISOString()
            };
            // Add basic fields
            if (updateData.foodName || updateData.name) {
                algoliaUpdate.name = updateData.foodName || updateData.name;
                algoliaUpdate.foodName = updateData.foodName || updateData.name;
            }
            if (updateData.brandName || updateData.brand) {
                algoliaUpdate.brand = updateData.brandName || updateData.brand;
                algoliaUpdate.brandName = updateData.brandName || updateData.brand;
            }
            if (updateData.barcode !== undefined)
                algoliaUpdate.barcode = updateData.barcode;
            if (updateData.ingredients || updateData.extractedIngredients) {
                algoliaUpdate.ingredients = updateData.ingredients || updateData.extractedIngredients;
            }
            if (updateData.servingSize || updateData.servingDescription) {
                algoliaUpdate.servingDescription = updateData.servingSize || updateData.servingDescription;
            }
            if (updateData.servingSizeG !== undefined)
                algoliaUpdate.servingSizeG = updateData.servingSizeG;
            if (updateData.servingUnit !== undefined)
                algoliaUpdate.servingUnit = updateData.servingUnit;
            // Flatten nutrition data for Algolia (handle both carbs and carbohydrates)
            if (updateData.nutritionData) {
                const nd = updateData.nutritionData;
                if (nd.calories !== undefined && nd.calories !== null)
                    algoliaUpdate.calories = nd.calories;
                if (nd.protein !== undefined && nd.protein !== null)
                    algoliaUpdate.protein = nd.protein;
                // Handle both carbs and carbohydrates field names
                const carbsValue = nd.carbs !== undefined ? nd.carbs : nd.carbohydrates;
                if (carbsValue !== undefined && carbsValue !== null)
                    algoliaUpdate.carbs = carbsValue;
                if (nd.fat !== undefined && nd.fat !== null)
                    algoliaUpdate.fat = nd.fat;
                if (nd.fiber !== undefined && nd.fiber !== null)
                    algoliaUpdate.fiber = nd.fiber;
                if (nd.sugar !== undefined && nd.sugar !== null)
                    algoliaUpdate.sugar = nd.sugar;
                if (nd.salt !== undefined && nd.salt !== null)
                    algoliaUpdate.salt = nd.salt;
                if (nd.sodium !== undefined && nd.sodium !== null)
                    algoliaUpdate.sodium = nd.sodium;
                if (nd.saturatedFat !== undefined && nd.saturatedFat !== null)
                    algoliaUpdate.saturatedFat = nd.saturatedFat;
            }
            // Remove undefined values
            Object.keys(algoliaUpdate).forEach(key => {
                if (algoliaUpdate[key] === undefined)
                    delete algoliaUpdate[key];
            });
            await client.partialUpdateObject({
                indexName: targetCollection,
                objectID: foodId,
                attributesToUpdate: algoliaUpdate
            });
            res.json({
                success: true,
                message: 'Food updated in Algolia successfully'
            });
        }
        else {
            // For Firestore-backed collections, update both Firestore and Algolia
            await admin.firestore()
                .collection(targetCollection)
                .doc(foodId)
                .set(updateData, { merge: true });
            // Send response immediately after Firestore update (don't wait for Algolia)
            res.json({
                success: true,
                message: 'Food updated successfully'
            });
            // Sync to Algolia in background (fire-and-forget for faster response)
            // This is safe because Firestore is the source of truth
            const algoliaKey = algoliaAdminKey.value()?.trim();
            if (algoliaKey) {
                const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaKey);
                // Map Firestore collection to Algolia index
                const collectionToIndex = {
                    'verifiedFoods': 'verified_foods',
                    'foods': 'foods',
                    'manualFoods': 'manual_foods',
                    'userAdded': 'user_added',
                    'aiEnhanced': 'ai_enhanced',
                    'aiManuallyAdded': 'ai_manually_added',
                    'tesco_products': 'tescoProducts'
                };
                const algoliaIndex = collectionToIndex[targetCollection] || targetCollection;
                // Prepare Algolia update object (flatten nutrition data)
                const algoliaUpdate = {
                    objectID: foodId,
                    name: updateData.foodName || updateData.name,
                    foodName: updateData.foodName || updateData.name,
                    brand: updateData.brandName || updateData.brand,
                    brandName: updateData.brandName || updateData.brand,
                    barcode: updateData.barcode,
                    ingredients: updateData.ingredients || updateData.extractedIngredients,
                    servingDescription: updateData.servingSize || updateData.servingDescription,
                    servingSizeG: updateData.servingSizeG,
                    servingUnit: updateData.servingUnit,
                    isPerUnit: updateData.isPerUnit,
                    source: updateData.source,
                    updatedAt: new Date().toISOString()
                };
                // Flatten nutrition data for Algolia (handle both carbs and carbohydrates)
                if (updateData.nutritionData) {
                    const nd = updateData.nutritionData;
                    if (nd.calories !== undefined && nd.calories !== null)
                        algoliaUpdate.calories = nd.calories;
                    if (nd.protein !== undefined && nd.protein !== null)
                        algoliaUpdate.protein = nd.protein;
                    // Handle both carbs and carbohydrates field names
                    const carbsValue = nd.carbs !== undefined ? nd.carbs : nd.carbohydrates;
                    if (carbsValue !== undefined && carbsValue !== null)
                        algoliaUpdate.carbs = carbsValue;
                    if (nd.fat !== undefined && nd.fat !== null)
                        algoliaUpdate.fat = nd.fat;
                    if (nd.fiber !== undefined && nd.fiber !== null)
                        algoliaUpdate.fiber = nd.fiber;
                    if (nd.sugar !== undefined && nd.sugar !== null)
                        algoliaUpdate.sugar = nd.sugar;
                    if (nd.salt !== undefined && nd.salt !== null)
                        algoliaUpdate.salt = nd.salt;
                    if (nd.sodium !== undefined && nd.sodium !== null)
                        algoliaUpdate.sodium = nd.sodium;
                    if (nd.saturatedFat !== undefined && nd.saturatedFat !== null)
                        algoliaUpdate.saturatedFat = nd.saturatedFat;
                }
                // Remove undefined values
                Object.keys(algoliaUpdate).forEach(key => {
                    if (algoliaUpdate[key] === undefined)
                        delete algoliaUpdate[key];
                });
                // Fire-and-forget Algolia update (don't await)
                client.partialUpdateObject({
                    indexName: algoliaIndex,
                    objectID: foodId,
                    attributesToUpdate: algoliaUpdate,
                    createIfNotExists: true
                })
                    .then(() => console.log(`✅ Algolia sync complete: ${algoliaIndex}/${foodId}`))
                    .catch((err) => console.error(`⚠️ Algolia sync failed for ${foodId}:`, err));
            }
        }
    }
    catch (error) {
        console.error('Error updating food:', error);
        res.status(500).json({ error: 'Failed to update food', details: String(error) });
    }
});
// Add new food directly to human verified collection
exports.addVerifiedFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodName, brandName, barcode, extractedIngredients, nutritionData, servingSize } = req.body;
        if (!foodName) {
            res.status(400).json({ error: 'Food name is required' });
            return;
        }
        console.log(`Adding new food: ${foodName}`);
        // Prepare food data
        const foodData = {
            foodName: foodName || '',
            brandName: brandName || '',
            barcode: barcode || '',
            extractedIngredients: extractedIngredients || '',
            ingredients: extractedIngredients || '', // Backup compatibility
            nutritionData: nutritionData || {},
            servingSize: servingSize || '100g serving',
            // Set as company verified (added through admin dashboard)
            verifiedBy: 'company',
            verificationMethod: 'manual',
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            // Timestamps
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        // Add to verifiedFoods collection
        const docRef = await admin.firestore()
            .collection('verifiedFoods')
            .add(foodData);
        res.json({
            success: true,
            message: 'Food added successfully',
            foodId: docRef.id,
            food: {
                id: docRef.id,
                ...foodData,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
                verifiedAt: new Date().toISOString()
            }
        });
    }
    catch (error) {
        console.error('Error adding food:', error);
        res.status(500).json({ error: 'Failed to add food' });
    }
});
// Update foods with realistic serving sizes
exports.updateServingSizes = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const db = admin.firestore();
        const batch = db.batch();
        let updateCount = 0;
        // Define realistic serving sizes for common foods
        const servingSizeUpdates = [
            // Candy/Sweets
            { searchTerms: ['nerds'], servingDescription: '1 small box (14g)', servingSizeGrams: 14 },
            { searchTerms: ['biscoff', 'cookie'], servingDescription: '1 biscuit (8g)', servingSizeGrams: 8 },
            { searchTerms: ['oreo'], servingDescription: '1 cookie (11g)', servingSizeGrams: 11 },
            { searchTerms: ['kit kat', 'kitkat'], servingDescription: '1 finger (5g)', servingSizeGrams: 5 },
            { searchTerms: ['twix'], servingDescription: '1 finger (29g)', servingSizeGrams: 29 },
            { searchTerms: ['mars bar'], servingDescription: '1 bar (51g)', servingSizeGrams: 51 },
            { searchTerms: ['snickers'], servingDescription: '1 bar (50g)', servingSizeGrams: 50 },
            { searchTerms: ['bounty'], servingDescription: '1 bar (28g)', servingSizeGrams: 28 },
            // Drinks
            { searchTerms: ['coca cola', 'coke'], servingDescription: '1 can (330ml)', servingSizeGrams: 330 },
            { searchTerms: ['pepsi'], servingDescription: '1 can (330ml)', servingSizeGrams: 330 },
            // Snacks  
            { searchTerms: ['pringles'], servingDescription: '1 serving (30g)', servingSizeGrams: 30 },
            { searchTerms: ['walkers', 'crisps'], servingDescription: '1 bag (25g)', servingSizeGrams: 25 }
        ];
        for (const update of servingSizeUpdates) {
            // Search all collections for matching foods
            const collections = ['fatsecret_foods', 'manual_foods', 'admin_manual'];
            for (const collectionName of collections) {
                const collectionRef = db.collection(collectionName);
                for (const searchTerm of update.searchTerms) {
                    const querySnapshot = await collectionRef
                        .where('name', '>=', searchTerm)
                        .where('name', '<=', searchTerm + '\uf8ff')
                        .get();
                    querySnapshot.forEach(doc => {
                        const food = doc.data();
                        // Only update if it currently has generic "100g serving"
                        if ((food.servingDescription || '').includes('100g serving') ||
                            (food.servingSize || '').includes('100g serving')) {
                            batch.update(doc.ref, {
                                servingDescription: update.servingDescription,
                                servingSize: update.servingDescription,
                                updatedAt: admin.firestore.FieldValue.serverTimestamp()
                            });
                            updateCount++;
                        }
                    });
                }
            }
        }
        // Commit batch updates
        if (updateCount > 0) {
            await batch.commit();
            console.log(`Updated ${updateCount} foods with realistic serving sizes`);
        }
        res.json({
            success: true,
            message: `Updated ${updateCount} foods with realistic serving sizes`,
            updatedCount: updateCount
        });
    }
    catch (error) {
        console.error('Error updating serving sizes:', error);
        res.status(500).json({ error: 'Failed to update serving sizes' });
    }
});
// Delete verified foods
exports.deleteVerifiedFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodIds } = req.body;
        if (!foodIds || !Array.isArray(foodIds) || foodIds.length === 0) {
            res.status(400).json({ error: 'Food IDs array is required' });
            return;
        }
        console.log(`Deleting foods: ${foodIds.join(', ')}`);
        // Delete all foods in batch
        const batch = admin.firestore().batch();
        for (const foodId of foodIds) {
            const docRef = admin.firestore().collection('verifiedFoods').doc(foodId);
            batch.delete(docRef);
        }
        await batch.commit();
        res.json({
            success: true,
            message: `Successfully deleted ${foodIds.length} food(s)`,
            deletedIds: foodIds
        });
    }
    catch (error) {
        console.error('Error deleting foods:', error);
        res.status(500).json({ error: 'Failed to delete foods' });
    }
});
// Delete food from any Algolia index (and Firestore if applicable)
exports.deleteFoodFromAlgolia = functions.runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 60,
}).https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, indexName } = req.body;
        if (!foodId) {
            res.status(400).json({ success: false, error: 'Food ID (objectID) is required' });
            return;
        }
        if (!indexName) {
            res.status(400).json({ success: false, error: 'Index name is required' });
            return;
        }
        console.log(`🗑️ Deleting food ${foodId} from Algolia index: ${indexName}`);
        // Initialize Algolia client
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
        // Delete from Algolia
        await client.deleteObject({
            indexName: indexName,
            objectID: foodId,
        });
        console.log(`✅ Deleted ${foodId} from Algolia index: ${indexName}`);
        // Also try to delete from Firestore if there's a corresponding collection
        const firestoreCollection = INDEX_TO_COLLECTION[indexName];
        if (firestoreCollection) {
            try {
                await admin.firestore().collection(firestoreCollection).doc(foodId).delete();
                console.log(`✅ Also deleted ${foodId} from Firestore collection: ${firestoreCollection}`);
            }
            catch (firestoreError) {
                // Log but don't fail - Algolia deletion is the priority
                console.log(`ℹ️ No matching Firestore document found in ${firestoreCollection} (this is OK)`);
            }
        }
        res.json({
            success: true,
            message: `Successfully deleted food from ${indexName}`,
            deletedId: foodId,
            indexName: indexName,
            firestoreDeleted: firestoreCollection ? true : false
        });
    }
    catch (error) {
        console.error('❌ Error deleting food from Algolia:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete food',
            details: error.message
        });
    }
});
// Move food between collections (for future use when collections are separated)
exports.moveFoodBetweenCollections = functions.https.onRequest(async (req, res) => {
    // Enhanced CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.set('Access-Control-Max-Age', '3600');
    // Handle preflight OPTIONS request
    if (req.method === 'OPTIONS') {
        console.log('Handling CORS preflight request');
        res.status(200).send();
        return;
    }
    console.log(`Request method: ${req.method}, headers:`, req.headers);
    try {
        const { foodId, fromCollection, toCollection } = req.body;
        if (!foodId || !fromCollection || !toCollection) {
            res.status(400).json({ error: 'foodId, fromCollection, and toCollection are required' });
            return;
        }
        console.log(`Moving food ${foodId} from ${fromCollection} to ${toCollection}`);
        // For now, since we're using verifiedFoods for everything, just update verification status
        const updateData = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        // Add verification metadata based on target collection
        switch (toCollection) {
            case 'humanVerifiedFoods':
                updateData.verifiedBy = 'human';
                updateData.verificationMethod = 'manual';
                updateData.verifiedAt = admin.firestore.FieldValue.serverTimestamp();
                break;
            case 'aiVerifiedFoods':
                updateData.verifiedBy = 'ai';
                updateData.verificationMethod = 'automatic';
                updateData.verifiedAt = admin.firestore.FieldValue.serverTimestamp();
                break;
            case 'unverifiedFoods':
                updateData.verifiedBy = null;
                updateData.verificationMethod = null;
                updateData.verifiedAt = null;
                break;
        }
        // Update the food document with verification status
        await admin.firestore()
            .collection('verifiedFoods') // Currently all foods are here
            .doc(foodId)
            .update(updateData);
        res.json({
            success: true,
            message: `Food moved from ${fromCollection} to ${toCollection}`,
            foodId,
            fromCollection,
            toCollection
        });
    }
    catch (error) {
        console.error('Error moving food between collections:', error);
        res.status(500).json({ error: 'Failed to move food' });
    }
});
// Move foods between Algolia indices (comprehensive)
exports.moveFoodsBetweenIndices = functions.runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 540,
    memory: '1GB'
}).https.onRequest(async (req, res) => {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    try {
        const { foodIds, fromIndex, toIndex } = req.body;
        if (!foodIds || !Array.isArray(foodIds) || foodIds.length === 0) {
            res.status(400).json({ error: 'foodIds array is required' });
            return;
        }
        if (!fromIndex || !toIndex) {
            res.status(400).json({ error: 'fromIndex and toIndex are required' });
            return;
        }
        if (fromIndex === toIndex) {
            res.status(400).json({ error: 'fromIndex and toIndex must be different' });
            return;
        }
        console.log(`🔄 Moving ${foodIds.length} foods from ${fromIndex} to ${toIndex}`);
        // Initialize Algolia client
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
        let successCount = 0;
        let failedCount = 0;
        const errors = [];
        const movedFoods = [];
        // Process each food
        for (const foodId of foodIds) {
            try {
                console.log(`Moving ${foodId}...`);
                // 1. Get the food data from source index
                const sourceObject = await client.getObject({
                    indexName: fromIndex,
                    objectID: foodId
                });
                if (!sourceObject) {
                    throw new Error('Food not found in source index');
                }
                // 2. Add to destination index with automatic verification for verified_foods
                const updates = {
                    ...sourceObject,
                    objectID: foodId,
                    // Update metadata to reflect the move
                    movedFrom: fromIndex,
                    movedAt: new Date().toISOString(),
                };
                // Automatically verify foods when moving to verified_foods index
                if (toIndex === 'verified_foods') {
                    updates.isVerified = true;
                    updates.verifiedAt = new Date().toISOString();
                    updates.verifiedBy = 'admin_manual';
                    console.log(`✅ Auto-verifying ${foodId} for verified_foods index`);
                }
                await client.saveObject({
                    indexName: toIndex,
                    body: updates
                });
                // 3. Delete from source index
                await client.deleteObject({
                    indexName: fromIndex,
                    objectID: foodId
                });
                // 4. Update Firestore if applicable
                const sourceCollection = INDEX_TO_COLLECTION[fromIndex];
                const destCollection = INDEX_TO_COLLECTION[toIndex];
                if (sourceCollection && destCollection && sourceCollection !== destCollection) {
                    // Both have Firestore backing - move the document
                    const sourceDoc = await admin.firestore().collection(sourceCollection).doc(foodId).get();
                    if (sourceDoc.exists) {
                        const data = sourceDoc.data();
                        await admin.firestore().collection(destCollection).doc(foodId).set({
                            ...data,
                            movedFrom: fromIndex,
                            movedAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                        await admin.firestore().collection(sourceCollection).doc(foodId).delete();
                        console.log(`✅ Also moved Firestore document from ${sourceCollection} to ${destCollection}`);
                    }
                }
                else if (sourceCollection) {
                    // Source has Firestore backing but destination doesn't - just delete from Firestore
                    await admin.firestore().collection(sourceCollection).doc(foodId).delete();
                    console.log(`✅ Removed from Firestore collection ${sourceCollection}`);
                }
                else if (destCollection) {
                    // Destination has Firestore backing but source doesn't - create document
                    await admin.firestore().collection(destCollection).doc(foodId).set({
                        ...sourceObject,
                        movedFrom: fromIndex,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`✅ Created Firestore document in ${destCollection}`);
                }
                successCount++;
                movedFoods.push(foodId);
                console.log(`✅ Successfully moved ${foodId}`);
            }
            catch (error) {
                failedCount++;
                const errorMsg = `${foodId}: ${error.message}`;
                errors.push(errorMsg);
                console.error(`❌ Failed to move ${foodId}:`, error);
            }
        }
        console.log(`🎉 Move complete: ${successCount} succeeded, ${failedCount} failed`);
        res.json({
            success: true,
            moved: successCount,
            failed: failedCount,
            errors: errors.length > 0 ? errors : undefined,
            movedFoods,
            fromIndex,
            toIndex,
        });
    }
    catch (error) {
        console.error('❌ Error moving foods:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to move foods',
            details: error.message
        });
    }
});
// Reset admin_manual foods to unverified (clean slate)
exports.resetAdminManualFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        console.log('Resetting admin_manual foods to unverified for clean slate...');
        const db = admin.firestore();
        // Process foods in batches to avoid memory issues
        const BATCH_SIZE = 500;
        let totalProcessed = 0;
        // Get initial count
        const countSnapshot = await db.collection('verifiedFoods')
            .where('verifiedBy', '==', 'admin_manual')
            .count()
            .get();
        const totalFoods = countSnapshot.data().count;
        console.log(`Found ${totalFoods} admin_manual foods to reset`);
        // Process in batches with proper pagination
        while (totalProcessed < totalFoods) {
            const batch = db.batch();
            // Get next batch of admin_manual foods (this will automatically get different ones as we process)
            const adminManualFoodsSnapshot = await db.collection('verifiedFoods')
                .where('verifiedBy', '==', 'admin_manual')
                .limit(BATCH_SIZE)
                .get();
            if (adminManualFoodsSnapshot.empty) {
                console.log('No more admin_manual foods found - clean slate complete');
                break; // No more foods to process
            }
            // Reset this batch
            adminManualFoodsSnapshot.docs.forEach(doc => {
                batch.update(doc.ref, {
                    verifiedBy: null,
                    verificationMethod: null,
                    verifiedAt: null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });
            // Commit this batch
            await batch.commit();
            totalProcessed += adminManualFoodsSnapshot.size;
            console.log(`Processed batch: ${adminManualFoodsSnapshot.size} foods (${totalProcessed}/${totalFoods} total)`);
            // Short delay to avoid overwhelming Firestore
            await new Promise(resolve => setTimeout(resolve, 100));
            // Safety check to prevent infinite loops
            if (totalProcessed >= totalFoods) {
                console.log('Reached expected total, stopping');
                break;
            }
        }
        console.log(`Successfully reset ${totalProcessed} admin_manual foods to unverified`);
        res.json({
            success: true,
            message: `Successfully reset ${totalProcessed} admin_manual foods to unverified status`,
            updatedCount: totalProcessed
        });
    }
    catch (error) {
        console.error('Error resetting admin_manual foods:', error);
        res.status(500).json({ error: 'Failed to reset admin_manual foods to unverified' });
    }
});
// Reset all foods to initial/unverified status
exports.resetAllFoodsToInitial = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        console.log('Resetting all foods to initial/unverified status...');
        const db = admin.firestore();
        const batch = db.batch();
        // Get all foods in the database
        const allFoodsSnapshot = await db.collection('verifiedFoods').get();
        console.log(`Found ${allFoodsSnapshot.size} foods to reset`);
        // Reset all foods to unverified status
        allFoodsSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, {
                verifiedBy: null,
                verificationMethod: null,
                verifiedAt: null,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        // Commit all updates
        await batch.commit();
        console.log(`Successfully reset ${allFoodsSnapshot.size} foods to initial status`);
        res.json({
            success: true,
            message: `Successfully reset ${allFoodsSnapshot.size} foods to initial/unverified status`,
            updatedCount: allFoodsSnapshot.size
        });
    }
    catch (error) {
        console.error('Error resetting foods to initial status:', error);
        res.status(500).json({ error: 'Failed to reset foods to initial status' });
    }
});
// Fix existing foods to have proper verification status (one-time utility function)
exports.fixExistingFoodsVerification = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        console.log('Fixing existing foods verification status...');
        const db = admin.firestore();
        const batch = db.batch();
        // Get all foods that don't have a verifiedBy field
        const foodsSnapshot = await db.collection('verifiedFoods')
            .where('verifiedBy', '==', null)
            .get();
        if (foodsSnapshot.empty) {
            // Try getting foods without the field at all
            const allFoodsSnapshot = await db.collection('verifiedFoods').get();
            let foodsWithoutVerification = 0;
            allFoodsSnapshot.docs.forEach(doc => {
                const data = doc.data();
                if (!data.hasOwnProperty('verifiedBy') || data.verifiedBy === undefined) {
                    // Set as unverified (initial foods)
                    batch.update(doc.ref, {
                        verifiedBy: null,
                        verificationMethod: null,
                        verifiedAt: null,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    foodsWithoutVerification++;
                }
            });
            if (foodsWithoutVerification > 0) {
                await batch.commit();
                console.log(`Fixed ${foodsWithoutVerification} foods without verification status`);
                res.json({
                    success: true,
                    message: `Successfully updated ${foodsWithoutVerification} foods to initial (unverified) status`,
                    updatedCount: foodsWithoutVerification
                });
            }
            else {
                res.json({
                    success: true,
                    message: 'All foods already have verification status',
                    updatedCount: 0
                });
            }
        }
        else {
            // Update foods that explicitly have verifiedBy: null
            foodsSnapshot.docs.forEach(doc => {
                batch.update(doc.ref, {
                    verificationMethod: null,
                    verifiedAt: null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });
            await batch.commit();
            res.json({
                success: true,
                message: `Successfully updated ${foodsSnapshot.size} foods verification status`,
                updatedCount: foodsSnapshot.size
            });
        }
    }
    catch (error) {
        console.error('Error fixing foods verification:', error);
        res.status(500).json({ error: 'Failed to fix foods verification status' });
    }
});
// Search Tesco by GTIN/barcode first, then fallback to name/brand, and update food
exports.searchTescoAndUpdate = functions.runWith({ secrets: [algoliaAdminKey], timeoutSeconds: 60 }).https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, barcode, foodName, brandName, collection, reportId } = req.body;
        if (!foodId && !barcode && !foodName) {
            res.status(400).json({ success: false, error: 'Food ID, barcode, or food name is required' });
            return;
        }
        console.log(`🔍 Searching Tesco for: barcode=${barcode}, name=${foodName}, brand=${brandName}`);
        let tescoProduct = null;
        // Step 1: Try searching by barcode/GTIN first
        if (barcode) {
            console.log(`🔍 Searching by barcode: ${barcode}`);
            try {
                // Search Tesco by keyword (barcode)
                const searchResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-search-by-keyword`, {
                    params: { query: barcode, page: '0' },
                    headers: {
                        'x-rapidapi-host': TESCO8_HOST,
                        'x-rapidapi-key': TESCO8_API_KEY
                    },
                    timeout: 15000
                });
                if (searchResponse.data?.success && searchResponse.data?.products?.length > 0) {
                    // Find product with matching barcode
                    const matchingProduct = searchResponse.data.products.find((p) => p.gtin === barcode || p.ean === barcode);
                    if (matchingProduct) {
                        // Get full product details
                        const detailsResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-details`, {
                            params: { productId: matchingProduct.id },
                            headers: {
                                'x-rapidapi-host': TESCO8_HOST,
                                'x-rapidapi-key': TESCO8_API_KEY
                            },
                            timeout: 15000
                        });
                        if (detailsResponse.data?.success && detailsResponse.data?.product) {
                            tescoProduct = detailsResponse.data.product;
                            console.log(`✅ Found product by barcode: ${tescoProduct.title}`);
                        }
                    }
                }
            }
            catch (barcodeError) {
                console.log(`⚠️ Barcode search failed: ${barcodeError}`);
            }
        }
        // Step 2: Fallback to name/brand search
        if (!tescoProduct && foodName) {
            const searchQuery = brandName ? `${brandName} ${foodName}` : foodName;
            console.log(`🔍 Searching by name: ${searchQuery}`);
            try {
                const searchResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-search-by-keyword`, {
                    params: { query: searchQuery, page: '0' },
                    headers: {
                        'x-rapidapi-host': TESCO8_HOST,
                        'x-rapidapi-key': TESCO8_API_KEY
                    },
                    timeout: 15000
                });
                if (searchResponse.data?.success && searchResponse.data?.products?.length > 0) {
                    // Get the first (best match) product
                    const firstProduct = searchResponse.data.products[0];
                    // Get full product details
                    const detailsResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-details`, {
                        params: { productId: firstProduct.id },
                        headers: {
                            'x-rapidapi-host': TESCO8_HOST,
                            'x-rapidapi-key': TESCO8_API_KEY
                        },
                        timeout: 15000
                    });
                    if (detailsResponse.data?.success && detailsResponse.data?.product) {
                        tescoProduct = detailsResponse.data.product;
                        console.log(`✅ Found product by name: ${tescoProduct.title}`);
                    }
                }
            }
            catch (nameError) {
                console.log(`⚠️ Name search failed: ${nameError}`);
            }
        }
        if (!tescoProduct) {
            res.json({ success: false, error: 'No matching product found in Tesco' });
            return;
        }
        // Extract nutrition data from Tesco product
        const nutrition = tescoProduct.nutrition || {};
        const nutritionData = {
            calories: nutrition.energyKcal || nutrition.energy_kcal || 0,
            protein: nutrition.protein || 0,
            carbs: nutrition.carbohydrate || nutrition.carbs || 0,
            carbohydrates: nutrition.carbohydrate || nutrition.carbs || 0,
            fat: nutrition.fat || 0,
            fiber: nutrition.fibre || nutrition.fiber || 0,
            fibre: nutrition.fibre || nutrition.fiber || 0,
            sugar: nutrition.sugars || nutrition.sugar || 0,
            sugars: nutrition.sugars || nutrition.sugar || 0,
            sodium: nutrition.sodium || 0,
            salt: nutrition.salt || 0,
            saturatedFat: nutrition.saturates || nutrition.saturatedFat || 0
        };
        // Prepare update data
        const updateData = {
            foodName: tescoProduct.title || foodName,
            name: tescoProduct.title || foodName,
            brandName: tescoProduct.brand || brandName || 'Tesco',
            brand: tescoProduct.brand || brandName || 'Tesco',
            barcode: tescoProduct.gtin || barcode,
            gtin: tescoProduct.gtin || barcode,
            nutritionData,
            ingredients: tescoProduct.ingredients?.join(', ') || '',
            extractedIngredients: tescoProduct.ingredients?.join(', ') || '',
            servingDescription: tescoProduct.servingSize || 'per 100g',
            servingSize: tescoProduct.servingSize || 'per 100g',
            source: 'tesco_api',
            tescoProductId: tescoProduct.id,
            imageUrl: tescoProduct.imageUrl,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedFromTesco: true,
            tescoUpdatedAt: new Date().toISOString()
        };
        // Update in Firestore
        const targetCollection = collection || 'verifiedFoods';
        const docId = foodId || `tesco_${tescoProduct.id}`;
        await admin.firestore()
            .collection(targetCollection)
            .doc(docId)
            .set(updateData, { merge: true });
        console.log(`✅ Updated food in Firestore: ${targetCollection}/${docId}`);
        // Also update in Algolia
        try {
            const algoliaKey = algoliaAdminKey.value();
            if (algoliaKey) {
                const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaKey);
                const collectionToIndex = {
                    'verifiedFoods': 'verified_foods',
                    'foods': 'foods',
                    'manualFoods': 'manual_foods',
                    'userAdded': 'user_added',
                    'tesco_products': 'tescoProducts'
                };
                const algoliaIndex = collectionToIndex[targetCollection] || targetCollection;
                const algoliaUpdate = {
                    objectID: docId,
                    name: updateData.foodName,
                    foodName: updateData.foodName,
                    brand: updateData.brandName,
                    brandName: updateData.brandName,
                    barcode: updateData.barcode,
                    gtin: updateData.gtin,
                    calories: nutritionData.calories,
                    protein: nutritionData.protein,
                    carbs: nutritionData.carbs,
                    fat: nutritionData.fat,
                    fiber: nutritionData.fiber,
                    sugar: nutritionData.sugar,
                    sodium: nutritionData.sodium,
                    saturatedFat: nutritionData.saturatedFat,
                    ingredients: updateData.ingredients,
                    servingDescription: updateData.servingDescription,
                    source: 'tesco_api',
                    imageUrl: updateData.imageUrl,
                    updatedAt: new Date().toISOString()
                };
                await client.partialUpdateObject({
                    indexName: algoliaIndex,
                    objectID: docId,
                    attributesToUpdate: algoliaUpdate,
                    createIfNotExists: true
                });
                console.log(`✅ Updated food in Algolia: ${algoliaIndex}/${docId}`);
            }
        }
        catch (algoliaError) {
            console.error('⚠️ Algolia sync failed:', algoliaError);
        }
        // Optionally mark the report as resolved
        if (reportId) {
            try {
                await admin.firestore()
                    .collection('userReports')
                    .doc(reportId)
                    .update({
                    status: 'resolved',
                    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
                    resolvedBy: 'tesco_api_update',
                    notes: `Updated with Tesco data: ${tescoProduct.title}`
                });
                console.log(`✅ Marked report ${reportId} as resolved`);
            }
            catch (reportError) {
                console.error('⚠️ Failed to update report status:', reportError);
            }
        }
        res.json({
            success: true,
            message: `Updated food with Tesco data: ${tescoProduct.title}`,
            product: {
                id: docId,
                name: updateData.foodName,
                brand: updateData.brandName,
                barcode: updateData.barcode
            }
        });
    }
    catch (error) {
        console.error('Error searching Tesco:', error);
        res.status(500).json({ success: false, error: 'Failed to search Tesco', details: String(error) });
    }
});
/**
 * Admin Save Food - General purpose food update function for admin tools
 * Handles both Firestore-backed and Algolia-only indices
 */
exports.adminSaveFood = functions
    .runWith({ secrets: [algoliaAdminKey], timeoutSeconds: 60 })
    .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ success: false, error: 'Method not allowed' });
        return;
    }
    try {
        const { foodId, indexName, updates } = req.body;
        if (!foodId) {
            res.status(400).json({ success: false, error: 'foodId is required' });
            return;
        }
        if (!indexName) {
            res.status(400).json({ success: false, error: 'indexName is required' });
            return;
        }
        console.log(`📝 Admin saving food: ${foodId} in index: ${indexName}`);
        // Build the update object with flattened nutrition
        const updateObj = {
            updatedAt: new Date().toISOString(),
        };
        if (updates) {
            // Basic fields
            if (updates.foodName !== undefined) {
                updateObj.name = updates.foodName;
                updateObj.foodName = updates.foodName;
            }
            if (updates.brandName !== undefined) {
                updateObj.brand = updates.brandName;
                updateObj.brandName = updates.brandName;
            }
            if (updates.barcode !== undefined) {
                updateObj.barcode = updates.barcode;
            }
            if (updates.category !== undefined) {
                updateObj.category = updates.category;
            }
            if (updates.servingSize !== undefined) {
                updateObj.servingDescription = updates.servingSize;
                updateObj.servingSize = updates.servingSize;
            }
            if (updates.servingSizeG !== undefined) {
                updateObj.servingSizeG = updates.servingSizeG;
            }
            if (updates.servingUnit !== undefined) {
                updateObj.servingUnit = updates.servingUnit;
            }
            if (updates.ingredients !== undefined) {
                updateObj.ingredients = updates.ingredients;
                updateObj.extractedIngredients = updates.ingredients;
            }
            // Flatten nutrition data
            if (updates.nutrition) {
                const n = updates.nutrition;
                if (n.calories !== undefined && n.calories !== null)
                    updateObj.calories = n.calories;
                if (n.protein !== undefined && n.protein !== null)
                    updateObj.protein = n.protein;
                if (n.carbs !== undefined && n.carbs !== null) {
                    updateObj.carbs = n.carbs;
                    updateObj.carbohydrates = n.carbs;
                }
                if (n.fat !== undefined && n.fat !== null)
                    updateObj.fat = n.fat;
                if (n.fiber !== undefined && n.fiber !== null) {
                    updateObj.fiber = n.fiber;
                    updateObj.fibre = n.fiber;
                }
                if (n.sugar !== undefined && n.sugar !== null) {
                    updateObj.sugar = n.sugar;
                    updateObj.sugars = n.sugar;
                }
                if (n.salt !== undefined && n.salt !== null)
                    updateObj.salt = n.salt;
                if (n.sodium !== undefined && n.sodium !== null)
                    updateObj.sodium = n.sodium;
                if (n.saturatedFat !== undefined && n.saturatedFat !== null) {
                    updateObj.saturatedFat = n.saturatedFat;
                    updateObj.saturates = n.saturatedFat;
                }
            }
        }
        console.log('Update object:', JSON.stringify(updateObj, null, 2));
        // Get Algolia admin key
        const algoliaKey = algoliaAdminKey.value()?.trim();
        if (!algoliaKey) {
            res.status(500).json({ success: false, error: 'Algolia API key not configured' });
            return;
        }
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaKey);
        // Check if this is an Algolia-only index or has Firestore backing
        const firestoreCollection = INDEX_TO_COLLECTION[indexName];
        if (firestoreCollection) {
            // Has Firestore backing - update Firestore (will auto-sync to Algolia via triggers)
            console.log(`📂 Updating Firestore: ${firestoreCollection}/${foodId}`);
            const firestoreUpdate = {
                ...updateObj,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            await admin.firestore()
                .collection(firestoreCollection)
                .doc(foodId)
                .update(firestoreUpdate);
            console.log(`✅ Firestore updated: ${firestoreCollection}/${foodId}`);
        }
        else {
            // Algolia-only index - update directly in Algolia
            console.log(`🔍 Updating Algolia directly: ${indexName}/${foodId}`);
            await client.partialUpdateObject({
                indexName: indexName,
                objectID: foodId,
                attributesToUpdate: updateObj,
                createIfNotExists: false,
            });
            console.log(`✅ Algolia updated: ${indexName}/${foodId}`);
        }
        res.json({
            success: true,
            message: `Food ${foodId} updated successfully`,
            index: indexName,
            firestoreBacked: !!firestoreCollection,
        });
    }
    catch (error) {
        console.error('Error saving food:', error);
        res.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
// All Algolia indices
const ALL_ALGOLIA_INDICES = [
    'verified_foods',
    'foods',
    'manual_foods',
    'user_added',
    'ai_enhanced',
    'ai_manually_added',
    'tesco_products',
    'uk_foods_cleaned',
    'fast_foods_database',
    'generic_database',
];
/**
 * Comprehensive Delete - Removes a food from ALL indices where it exists
 * This solves the issue of foods "coming back" when they exist in multiple indices
 */
exports.deleteFoodComprehensive = functions.runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 60,
    memory: '256MB',
}).https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, indexName, barcode, deleteFromAllIndices = true } = req.body;
        if (!foodId && !barcode) {
            res.status(400).json({ success: false, error: 'Food ID or barcode is required' });
            return;
        }
        console.log(`🗑️ Comprehensive delete: foodId=${foodId}, barcode=${barcode}, indexName=${indexName}`);
        // Initialize Algolia client
        const algoliaKey = algoliaAdminKey.value();
        if (!algoliaKey) {
            res.status(500).json({ success: false, error: 'Algolia API key not configured' });
            return;
        }
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaKey);
        const deletedFrom = [];
        const errors = [];
        // Step 1: Delete from the primary index if provided
        if (foodId && indexName) {
            try {
                await client.deleteObject({ indexName, objectID: foodId });
                console.log(`✅ Deleted ${foodId} from primary index: ${indexName}`);
                // Also delete from Firestore if applicable
                const firestoreCollection = INDEX_TO_COLLECTION[indexName];
                if (firestoreCollection) {
                    try {
                        await admin.firestore().collection(firestoreCollection).doc(foodId).delete();
                        deletedFrom.push({ index: indexName, objectID: foodId, firestore: firestoreCollection });
                        console.log(`✅ Deleted from Firestore: ${firestoreCollection}/${foodId}`);
                    }
                    catch (fsError) {
                        deletedFrom.push({ index: indexName, objectID: foodId });
                        console.log(`ℹ️ No Firestore doc found in ${firestoreCollection}`);
                    }
                }
                else {
                    deletedFrom.push({ index: indexName, objectID: foodId });
                }
            }
            catch (err) {
                errors.push(`Failed to delete from ${indexName}: ${err.message}`);
            }
        }
        // Step 2: If we have a barcode, search and delete from ALL other indices
        if (barcode && deleteFromAllIndices) {
            console.log(`🔍 Searching for barcode ${barcode} across all indices...`);
            for (const idx of ALL_ALGOLIA_INDICES) {
                // Skip the primary index we already deleted from
                if (idx === indexName)
                    continue;
                try {
                    // Search for foods with this barcode using searchSingleIndex
                    const searchResult = await client.searchSingleIndex({
                        indexName: idx,
                        searchParams: {
                            query: barcode,
                            attributesToRetrieve: ['objectID', 'barcode', 'gtin'],
                            hitsPerPage: 50,
                        },
                    });
                    // Filter to only matching barcodes
                    const matchingFoods = (searchResult.hits || []).filter((hit) => {
                        return hit.barcode === barcode || hit.gtin === barcode;
                    });
                    for (const hit of matchingFoods) {
                        const objId = hit.objectID;
                        try {
                            await client.deleteObject({ indexName: idx, objectID: objId });
                            console.log(`✅ Deleted ${objId} from ${idx}`);
                            // Also delete from Firestore
                            const fsCol = INDEX_TO_COLLECTION[idx];
                            if (fsCol) {
                                try {
                                    await admin.firestore().collection(fsCol).doc(objId).delete();
                                    deletedFrom.push({ index: idx, objectID: objId, firestore: fsCol });
                                    console.log(`✅ Deleted from Firestore: ${fsCol}/${objId}`);
                                }
                                catch {
                                    deletedFrom.push({ index: idx, objectID: objId });
                                }
                            }
                            else {
                                deletedFrom.push({ index: idx, objectID: objId });
                            }
                        }
                        catch (delErr) {
                            errors.push(`Failed to delete ${objId} from ${idx}: ${delErr.message}`);
                        }
                    }
                }
                catch (searchErr) {
                    console.log(`ℹ️ Could not search ${idx}: ${searchErr.message}`);
                }
            }
        }
        // Step 3: Also search by objectID in all indices (same food might have same ID)
        if (foodId && deleteFromAllIndices) {
            for (const idx of ALL_ALGOLIA_INDICES) {
                if (idx === indexName)
                    continue;
                try {
                    // Try to get the object directly by ID
                    const obj = await client.getObject({ indexName: idx, objectID: foodId });
                    if (obj) {
                        await client.deleteObject({ indexName: idx, objectID: foodId });
                        console.log(`✅ Deleted ${foodId} from ${idx} (same objectID)`);
                        const fsCol = INDEX_TO_COLLECTION[idx];
                        if (fsCol) {
                            try {
                                await admin.firestore().collection(fsCol).doc(foodId).delete();
                                deletedFrom.push({ index: idx, objectID: foodId, firestore: fsCol });
                            }
                            catch {
                                deletedFrom.push({ index: idx, objectID: foodId });
                            }
                        }
                        else {
                            deletedFrom.push({ index: idx, objectID: foodId });
                        }
                    }
                }
                catch {
                    // Object doesn't exist in this index, continue
                }
            }
        }
        console.log(`🏁 Comprehensive delete complete. Deleted from ${deletedFrom.length} locations.`);
        res.json({
            success: true,
            message: `Deleted food from ${deletedFrom.length} location(s)`,
            deletedFrom,
            errors: errors.length > 0 ? errors : undefined,
        });
    }
    catch (error) {
        console.error('❌ Comprehensive delete error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete food comprehensively',
            details: error.message,
        });
    }
});
// Browse all records from specified indices
exports.browseAllIndices = functions.runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 540,
    memory: '2GB'
}).https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            const { indices } = req.body;
            if (!indices || !Array.isArray(indices) || indices.length === 0) {
                res.status(400).json({ success: false, error: 'Indices array is required' });
                return;
            }
            console.log(`📦 Browsing all records from ${indices.length} indices...`);
            const allProducts = [];
            // Initialize Algolia client (same way as scanDatabaseIssues)
            const adminKey = algoliaAdminKey.value();
            const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
            // Browse each index using SDK's browse method (same as scanDatabaseIssues)
            for (const indexName of indices) {
                console.log(`📦 Browsing ${indexName}...`);
                try {
                    let browseCount = 0;
                    let cursor = undefined;
                    let batchNumber = 0;
                    // Browse all objects using cursor-based pagination (no 1000 limit)
                    do {
                        batchNumber++;
                        // Build browse parameters
                        const browseParams = {
                            hitsPerPage: 1000,
                        };
                        // Add cursor for subsequent requests
                        if (cursor) {
                            browseParams.cursor = cursor;
                        }
                        // Use SDK's browse method (exactly like scanDatabaseIssues)
                        const result = await client.browse({
                            indexName,
                            browseParams,
                        });
                        const hits = result.hits || [];
                        hits.forEach((hit) => {
                            allProducts.push({
                                ...hit,
                                sourceIndex: indexName,
                            });
                        });
                        browseCount += hits.length;
                        cursor = result.cursor;
                        // Log progress every 10k records
                        if (browseCount % 10000 === 0) {
                            console.log(`  → Browsed ${browseCount.toLocaleString()} records from ${indexName}...`);
                        }
                        // Safety check to prevent infinite loops
                        if (batchNumber > 200) {
                            console.log('⚠️ Reached batch limit (200), stopping browse');
                            break;
                        }
                    } while (cursor);
                    console.log(`✅ ${indexName}: ${browseCount.toLocaleString()} total products`);
                }
                catch (indexError) {
                    console.error(`❌ Error browsing ${indexName}:`, indexError.message);
                    // Continue with other indices even if one fails
                }
            }
            console.log(`📊 Total products browsed: ${allProducts.length.toLocaleString()}`);
            res.json({
                success: true,
                totalProducts: allProducts.length,
                products: allProducts,
            });
        }
        catch (error) {
            console.error('❌ Browse all indices error:', error);
            res.status(500).json({
                success: false,
                error: 'Failed to browse indices',
                details: error.message,
            });
        }
    });
});
//# sourceMappingURL=food-management.js.map