"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.batchSaveFoods = exports.getFood = exports.deleteFood = exports.saveFood = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
/**
 * Cloud Function to save a food item to Firestore
 * This will trigger the syncFoodToAlgolia function automatically
 * Used by Database Manager to save/update foods
 */
exports.saveFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ success: false, error: 'Method not allowed' });
        return;
    }
    try {
        const foodData = req.body;
        if (!foodData || !foodData.objectID) {
            res.status(400).json({
                success: false,
                error: 'Food data with objectID is required'
            });
            return;
        }
        const db = admin.firestore();
        const foodId = foodData.objectID;
        // Prepare the food document for Firestore
        // Remove objectID from the data (it's used as the document ID)
        const { objectID } = foodData, foodDataWithoutId = __rest(foodData, ["objectID"]);
        // Add metadata
        const firestoreData = Object.assign(Object.assign({}, foodDataWithoutId), { updatedAt: admin.firestore.FieldValue.serverTimestamp(), updatedBy: 'database_manager' });
        // If this is a new food, add createdAt
        const existingDoc = await db.collection('foods').doc(foodId).get();
        if (!existingDoc.exists) {
            firestoreData.createdAt = admin.firestore.FieldValue.serverTimestamp();
            firestoreData.source = foodData.source || 'database_manager';
        }
        // Save to Firestore - this will trigger syncFoodToAlgolia automatically
        await db.collection('foods').doc(foodId).set(firestoreData, { merge: true });
        console.log(`✅ Saved food ${foodId} to Firestore (will sync to Algolia via trigger)`);
        res.status(200).json({
            success: true,
            message: 'Food saved successfully',
            foodId: foodId
        });
    }
    catch (error) {
        console.error('❌ Error saving food:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to save food'
        });
    }
});
/**
 * Cloud Function to delete a food item from Firestore
 * This will trigger the syncFoodToAlgolia function to remove from Algolia
 */
exports.deleteFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId } = req.body;
        if (!foodId) {
            res.status(400).json({ success: false, error: 'Food ID is required' });
            return;
        }
        const db = admin.firestore();
        await db.collection('foods').doc(foodId).delete();
        console.log(`✅ Deleted food ${foodId} from Firestore (will remove from Algolia via trigger)`);
        res.status(200).json({
            success: true,
            message: 'Food deleted successfully'
        });
    }
    catch (error) {
        console.error('❌ Error deleting food:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete food'
        });
    }
});
/**
 * Cloud Function to get a food item directly from Firestore
 * Returns the latest data without waiting for Algolia sync
 */
exports.getFood = functions.https.onRequest(async (req, res) => {
    var _a;
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const foodId = req.query.foodId || ((_a = req.body) === null || _a === void 0 ? void 0 : _a.foodId);
        if (!foodId) {
            res.status(400).json({ success: false, error: 'Food ID is required' });
            return;
        }
        const db = admin.firestore();
        const foodDoc = await db.collection('foods').doc(foodId).get();
        if (!foodDoc.exists) {
            res.status(404).json({ success: false, error: 'Food not found' });
            return;
        }
        const data = foodDoc.data();
        // Return food with objectID included
        res.status(200).json({
            success: true,
            food: Object.assign({ objectID: foodDoc.id }, data)
        });
    }
    catch (error) {
        console.error('❌ Error getting food:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get food'
        });
    }
});
/**
 * Cloud Function to batch save multiple foods to Firestore
 * Used by Database Manager for bulk operations
 */
exports.batchSaveFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foods } = req.body;
        if (!foods || !Array.isArray(foods) || foods.length === 0) {
            res.status(400).json({
                success: false,
                error: 'Array of foods is required'
            });
            return;
        }
        const db = admin.firestore();
        const batch = db.batch();
        const timestamp = admin.firestore.FieldValue.serverTimestamp();
        for (const food of foods) {
            if (!food.objectID) {
                continue; // Skip foods without objectID
            }
            const foodRef = db.collection('foods').doc(food.objectID);
            const { objectID } = food, foodDataWithoutId = __rest(food, ["objectID"]);
            batch.set(foodRef, Object.assign(Object.assign({}, foodDataWithoutId), { updatedAt: timestamp, updatedBy: 'database_manager' }), { merge: true });
        }
        await batch.commit();
        console.log(`✅ Batch saved ${foods.length} foods to Firestore`);
        res.status(200).json({
            success: true,
            message: `Successfully saved ${foods.length} foods`,
            count: foods.length
        });
    }
    catch (error) {
        console.error('❌ Error batch saving foods:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to batch save foods'
        });
    }
});
//# sourceMappingURL=save-food.js.map