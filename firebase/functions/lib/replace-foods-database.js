"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.replaceAllFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
/**
 * Cloud Function to replace all foods in the database
 * POST body should contain: { foods: [...], deleteFirst: true }
 */
exports.replaceAllFoods = functions
    .runWith({
    timeoutSeconds: 540,
    memory: '2GB'
})
    .https.onRequest(async (req, res) => {
    // CORS
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    try {
        const { foods, deleteFirst } = req.body;
        if (!Array.isArray(foods)) {
            res.status(400).json({ error: 'foods must be an array' });
            return;
        }
        const db = admin.firestore();
        let deletedCount = 0;
        let uploadedCount = 0;
        // Step 1: Delete ALL existing foods if this is the first batch
        if (deleteFirst === true) {
            console.log('Deleting ALL existing foods...');
            const batchSize = 500;
            let continueDeleting = true;
            // Keep deleting until collection is empty
            while (continueDeleting) {
                const snapshot = await db.collection('verifiedFoods').limit(batchSize).get();
                if (snapshot.empty) {
                    continueDeleting = false;
                    break;
                }
                const batch = db.batch();
                snapshot.docs.forEach((doc) => {
                    batch.delete(doc.ref);
                    deletedCount++;
                });
                await batch.commit();
                console.log(`Deleted ${deletedCount} foods so far...`);
                // If we got fewer than batchSize, we're done
                if (snapshot.size < batchSize) {
                    // But double-check by querying again
                    const checkSnapshot = await db.collection('verifiedFoods').limit(1).get();
                    if (checkSnapshot.empty) {
                        continueDeleting = false;
                    }
                }
            }
            console.log(`✅ Total deleted: ${deletedCount} foods - collection is now empty`);
        }
        // Step 2: Upload new foods in batches
        console.log(`Uploading ${foods.length} foods...`);
        const batchSize = 500;
        for (let i = 0; i < foods.length; i += batchSize) {
            const batch = db.batch();
            const chunk = foods.slice(i, i + batchSize);
            chunk.forEach((food) => {
                const docRef = db.collection('verifiedFoods').doc();
                batch.set(docRef, Object.assign(Object.assign({}, food), { importedAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
                uploadedCount++;
            });
            await batch.commit();
            console.log(`Uploaded ${uploadedCount} / ${foods.length} foods...`);
        }
        res.status(200).json({
            success: true,
            deleted: deletedCount,
            uploaded: uploadedCount
        });
    }
    catch (error) {
        console.error('Error replacing foods:', error);
        res.status(500).json({
            error: 'Failed to replace foods',
            message: error.message
        });
    }
});
//# sourceMappingURL=replace-foods-database.js.map