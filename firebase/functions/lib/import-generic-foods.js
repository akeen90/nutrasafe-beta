"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNutrientSuggestions = exports.importGenericFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Remove unused interface
exports.importGenericFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        console.log('Starting generic foods import...');
        // Import from SQLite database
        const sqlite3 = require('sqlite3').verbose();
        const { open } = require('sqlite');
        const db = await open({
            filename: './lib/generic_foods.db',
            driver: sqlite3.Database
        });
        // Get all generic foods
        const foods = await db.all(`
      SELECT 
        name, category, serving_name, serving_weight_g, serving_description,
        energy, protein, carbs, fat, fiber, sugar,
        vitamin_a, vitamin_d, vitamin_e, vitamin_k, vitamin_c,
        thiamine, riboflavin, niacin, pantothenic_acid, vitamin_b6,
        biotin, folate, vitamin_b12,
        calcium, iron, magnesium, phosphorus, potassium, zinc,
        copper, manganese, selenium, chromium, molybdenum, iodine,
        omega_3, choline, ingredients, created_at
      FROM generic_foods
    `);
        await db.close();
        // Batch write to Firestore
        const batch = admin.firestore().batch();
        let imported = 0;
        for (const food of foods) {
            // Create nutrition data object
            const nutritionData = {
                calories: food.energy || 0,
                protein: food.protein || 0,
                carbs: food.carbs || 0,
                fat: food.fat || 0,
                fiber: food.fiber || 0,
                sugar: food.sugar || 0,
                // Micronutrients (only include if not null)
                ...(food.vitamin_a && { vitaminA: food.vitamin_a }),
                ...(food.vitamin_d && { vitaminD: food.vitamin_d }),
                ...(food.vitamin_e && { vitaminE: food.vitamin_e }),
                ...(food.vitamin_k && { vitaminK: food.vitamin_k }),
                ...(food.vitamin_c && { vitaminC: food.vitamin_c }),
                ...(food.thiamine && { thiamine: food.thiamine }),
                ...(food.riboflavin && { riboflavin: food.riboflavin }),
                ...(food.niacin && { niacin: food.niacin }),
                ...(food.pantothenic_acid && { pantothenicAcid: food.pantothenic_acid }),
                ...(food.vitamin_b6 && { vitaminB6: food.vitamin_b6 }),
                ...(food.biotin && { biotin: food.biotin }),
                ...(food.folate && { folate: food.folate }),
                ...(food.vitamin_b12 && { vitaminB12: food.vitamin_b12 }),
                ...(food.calcium && { calcium: food.calcium }),
                ...(food.iron && { iron: food.iron }),
                ...(food.magnesium && { magnesium: food.magnesium }),
                ...(food.phosphorus && { phosphorus: food.phosphorus }),
                ...(food.potassium && { potassium: food.potassium }),
                ...(food.zinc && { zinc: food.zinc }),
                ...(food.copper && { copper: food.copper }),
                ...(food.manganese && { manganese: food.manganese }),
                ...(food.selenium && { selenium: food.selenium }),
                ...(food.chromium && { chromium: food.chromium }),
                ...(food.molybdenum && { molybdenum: food.molybdenum }),
                ...(food.iodine && { iodine: food.iodine }),
                ...(food.omega_3 && { omega3: food.omega_3 }),
                ...(food.choline && { choline: food.choline })
            };
            // Create Firestore document
            const docData = {
                foodName: food.name,
                brandName: null,
                barcode: '',
                category: food.category,
                servingSize: food.serving_description,
                servingWeightG: food.serving_weight_g,
                nutritionData: nutritionData,
                ingredients: food.ingredients ? JSON.parse(food.ingredients) : [food.name.toLowerCase()],
                extractedIngredients: food.ingredients ? JSON.parse(food.ingredients) : [food.name.toLowerCase()],
                isGeneric: true,
                isVerified: true,
                verificationStatus: 'approved',
                dataSource: 'generic_database',
                confidence: 'high',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                // Micronutrient profile for the new system
                micronutrientProfile: {
                    hasData: true,
                    dataSource: 'reference_database',
                    confidenceScore: 'high',
                    ...nutritionData
                }
            };
            // Use a consistent document ID
            const docId = `generic_${food.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${food.serving_name || 'standard'}`;
            const docRef = admin.firestore().collection('verifiedFoods').doc(docId);
            batch.set(docRef, docData);
            imported++;
            // Commit batch every 500 documents (Firestore limit)
            if (imported % 500 === 0) {
                await batch.commit();
                console.log(`Imported ${imported} foods so far...`);
            }
        }
        // Commit remaining documents
        if (imported % 500 !== 0) {
            await batch.commit();
        }
        console.log(`Successfully imported ${imported} generic foods to Firestore`);
        res.json({
            success: true,
            imported: imported,
            message: `Imported ${imported} generic foods with comprehensive micronutrient data`
        });
    }
    catch (error) {
        console.error('Error importing generic foods:', error);
        res.status(500).json({
            error: 'Failed to import generic foods',
            details: error.message
        });
    }
});
// Helper function to get food suggestions based on missing nutrients
exports.getNutrientSuggestions = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { missingNutrients } = req.body;
        if (!missingNutrients || !Array.isArray(missingNutrients)) {
            res.status(400).json({ error: 'Missing or invalid missingNutrients array' });
            return;
        }
        console.log(`Getting food suggestions for missing nutrients: ${missingNutrients.join(', ')}`);
        const suggestions = [];
        // Query generic foods that are high in the missing nutrients
        for (const nutrient of missingNutrients) {
            let queryField = '';
            let threshold = 0;
            // Map nutrient names to Firestore fields and set thresholds
            switch (nutrient.toLowerCase()) {
                case 'vitamin_c':
                case 'vitaminc':
                    queryField = 'micronutrientProfile.vitaminC';
                    threshold = 20; // mg
                    break;
                case 'calcium':
                    queryField = 'micronutrientProfile.calcium';
                    threshold = 100; // mg
                    break;
                case 'iron':
                    queryField = 'micronutrientProfile.iron';
                    threshold = 2; // mg
                    break;
                case 'vitamin_a':
                case 'vitamina':
                    queryField = 'micronutrientProfile.vitaminA';
                    threshold = 100; // µg
                    break;
                case 'vitamin_d':
                case 'vitamind':
                    queryField = 'micronutrientProfile.vitaminD';
                    threshold = 1; // µg
                    break;
                case 'folate':
                    queryField = 'micronutrientProfile.folate';
                    threshold = 50; // µg
                    break;
                case 'potassium':
                    queryField = 'micronutrientProfile.potassium';
                    threshold = 300; // mg
                    break;
                case 'magnesium':
                    queryField = 'micronutrientProfile.magnesium';
                    threshold = 50; // mg
                    break;
                default:
                    continue;
            }
            // Query Firestore for foods high in this nutrient
            const snapshot = await admin.firestore()
                .collection('verifiedFoods')
                .where('isGeneric', '==', true)
                .where(queryField, '>=', threshold)
                .orderBy(queryField, 'desc')
                .limit(5)
                .get();
            const foods = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    name: data.foodName,
                    category: data.category,
                    servingSize: data.servingSize,
                    nutrientAmount: data.micronutrientProfile[nutrient] || 0,
                    nutrientName: nutrient
                };
            });
            if (foods.length > 0) {
                suggestions.push({
                    nutrient: nutrient,
                    foods: foods
                });
            }
        }
        res.json({
            suggestions: suggestions,
            message: `Found suggestions for ${suggestions.length} nutrients`
        });
    }
    catch (error) {
        console.error('Error getting nutrient suggestions:', error);
        res.status(500).json({
            error: 'Failed to get nutrient suggestions',
            details: error.message
        });
    }
});
//# sourceMappingURL=import-generic-foods.js.map