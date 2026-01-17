"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fixExistingFoodsVerification = exports.resetAllFoodsToInitial = exports.resetAdminManualFoods = exports.moveFoodBetweenCollections = exports.deleteFoodFromAlgolia = exports.deleteVerifiedFoods = exports.updateServingSizes = exports.addVerifiedFood = exports.updateVerifiedFood = void 0;
const functions = require("firebase-functions");
const functionsV2 = require("firebase-functions/v2");
const params_1 = require("firebase-functions/params");
const admin = require("firebase-admin");
const algoliasearch_1 = require("algoliasearch");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const algoliaAdminKey = (0, params_1.defineSecret)('ALGOLIA_ADMIN_API_KEY');
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
};
// Update verified food
exports.updateVerifiedFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, foodName, brandName, barcode, extractedIngredients, nutritionData, verifiedBy, verificationMethod } = req.body;
        if (!foodId) {
            res.status(400).json({ error: 'Food ID is required' });
            return;
        }
        console.log(`Updating food: ${foodId}`);
        // Prepare update data
        const updateData = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        // Add regular food fields if provided
        if (foodName !== undefined)
            updateData.foodName = foodName;
        if (brandName !== undefined)
            updateData.brandName = brandName;
        if (barcode !== undefined)
            updateData.barcode = barcode;
        if (extractedIngredients !== undefined) {
            updateData.extractedIngredients = extractedIngredients;
            updateData.ingredients = extractedIngredients; // Backup compatibility
        }
        if (nutritionData !== undefined)
            updateData.nutritionData = nutritionData;
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
        // Update the food document
        await admin.firestore()
            .collection('verifiedFoods')
            .doc(foodId)
            .update(updateData);
        res.json({
            success: true,
            message: 'Food updated successfully'
        });
    }
    catch (error) {
        console.error('Error updating food:', error);
        res.status(500).json({ error: 'Failed to update food' });
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
exports.deleteFoodFromAlgolia = functionsV2.https.onRequest({
    secrets: [algoliaAdminKey],
    cors: true,
}, async (req, res) => {
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
//# sourceMappingURL=food-management.js.map