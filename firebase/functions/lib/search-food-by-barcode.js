"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodByBarcode = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const additive_analyzer_enhanced_1 = require("./additive-analyzer-enhanced");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Helper function to check if ingredients are in English
function isEnglishIngredients(ingredientsText) {
    if (!ingredientsText || ingredientsText.trim().length === 0) {
        return false;
    }
    // Check for non-Latin scripts (Arabic, Chinese, Japanese, Korean, Cyrillic, Greek, Thai, etc.)
    const nonLatinPattern = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF\u0400-\u04FF\u0370-\u03FF\u0E00-\u0E7F]/;
    if (nonLatinPattern.test(ingredientsText)) {
        console.log('⚠️ Non-Latin script detected in ingredients (Arabic, Chinese, Japanese, Korean, Cyrillic, Greek, Thai, etc.)');
        return false;
    }
    // Check for common European non-English characters (French, German, Spanish, Italian accents)
    const nonEnglishPattern = /[áàâäãåąčćęèéêëėįìíîïłńòóôöõøùúûüųūÿýżźñçčšž]/i;
    if (nonEnglishPattern.test(ingredientsText)) {
        console.log('⚠️ Non-English European characters detected in ingredients');
        return false;
    }
    // Check for common non-English words
    const nonEnglishWords = [
        // French
        'ingrédients', 'eau', 'huile', 'sucre', 'sel', 'lait', 'beurre',
        // German
        'zutaten', 'wasser', 'zucker', 'salz', 'milch', 'butter',
        // Spanish
        'ingredientes', 'agua', 'azúcar', 'leche', 'mantequilla',
        // Italian
        'ingredienti', 'acqua', 'zucchero', 'latte', 'burro'
    ];
    const lowerText = ingredientsText.toLowerCase();
    const hasNonEnglishWords = nonEnglishWords.some(word => {
        // Check for word boundaries to avoid false positives
        const regex = new RegExp(`\\b${word}\\b`, 'i');
        return regex.test(lowerText);
    });
    if (hasNonEnglishWords) {
        console.log('⚠️ Non-English words detected in ingredients');
        return false;
    }
    // Check for common English food words (positive indicator)
    const englishWords = ['water', 'sugar', 'salt', 'flour', 'oil', 'butter', 'milk', 'wheat', 'ingredients'];
    const hasEnglishWords = englishWords.some(word => {
        const regex = new RegExp(`\\b${word}\\b`, 'i');
        return regex.test(lowerText);
    });
    return hasEnglishWords;
}
// Helper function to check if a product is UK/English
function isUKEnglishProduct(product) {
    // Check countries
    const countries = product.countries_tags || product.countries || [];
    const countriesString = Array.isArray(countries) ? countries.join(',').toLowerCase() : String(countries).toLowerCase();
    const isUKProduct = countriesString.includes('united-kingdom') ||
        countriesString.includes('uk') ||
        countriesString.includes('great-britain') ||
        countriesString.includes('england') ||
        countriesString.includes('scotland') ||
        countriesString.includes('wales') ||
        countriesString.includes('northern-ireland');
    // Check languages
    const languages = product.languages_tags || product.languages || [];
    const languagesString = Array.isArray(languages) ? languages.join(',').toLowerCase() : String(languages).toLowerCase();
    const hasEnglishLanguage = languagesString.includes('en') || languagesString.includes('english');
    // Check ingredients language
    const ingredientsText = product.ingredients_text_en || product.ingredients_text || '';
    const hasEnglishIngredients = isEnglishIngredients(ingredientsText);
    console.log(`🔍 Product check - UK: ${isUKProduct}, English lang: ${hasEnglishLanguage}, English ingredients: ${hasEnglishIngredients}`);
    // Accept if: (UK product OR has English language) AND has English ingredients
    // This ensures we get UK products or any product with proper English ingredient labels
    return (isUKProduct || hasEnglishLanguage) && hasEnglishIngredients;
}
// Helper function to fetch from OpenFoodFacts with UK filtering
async function fetchFromOpenFoodFacts(barcode) {
    try {
        console.log(`🌍 Fetching barcode ${barcode} from OpenFoodFacts...`);
        const response = await axios_1.default.get(`https://world.openfoodfacts.org/api/v2/product/${barcode}`, {
            timeout: 5000,
            headers: {
                'User-Agent': 'NutraSafe/1.0 (https://nutrasafe.co.uk)'
            }
        });
        if (response.data.status === 1 && response.data.product) {
            const product = response.data.product;
            // Filter for UK English products
            if (!isUKEnglishProduct(product)) {
                console.log(`❌ Product ${product.product_name || barcode} is not a UK English product - skipping`);
                return null;
            }
            console.log(`✅ Found UK English product: ${product.product_name || 'Unknown'}`);
            return product;
        }
        console.log(`⚠️ Product not found on OpenFoodFacts`);
        return null;
    }
    catch (error) {
        console.error('❌ OpenFoodFacts API error:', error);
        return null;
    }
}
// Helper function to safely get a numeric value from nutriments with multiple fallback keys
function getNutrientValue(nutriments, ...keys) {
    for (const key of keys) {
        const value = nutriments[key];
        if (value !== undefined && value !== null && value !== '') {
            const num = typeof value === 'number' ? value : parseFloat(value);
            if (!isNaN(num))
                return num;
        }
    }
    return 0;
}
// Helper function to transform OpenFoodFacts data to our format
function transformOpenFoodFactsProduct(offProduct, barcode) {
    const nutriments = offProduct.nutriments || {};
    // Get ingredients text (prefer English version)
    const ingredientsText = offProduct.ingredients_text_en || offProduct.ingredients_text || '';
    // Extract nutrition with multiple fallback keys (OpenFoodFacts can be inconsistent)
    const calories = getNutrientValue(nutriments, 'energy-kcal_100g', 'energy-kcal_value', 'energy-kcal') || (getNutrientValue(nutriments, 'energy_100g', 'energy_value', 'energy') / 4.184);
    const protein = getNutrientValue(nutriments, 'proteins_100g', 'proteins_value', 'proteins', 'protein_100g', 'protein');
    const carbohydrates = getNutrientValue(nutriments, 'carbohydrates_100g', 'carbohydrates_value', 'carbohydrates');
    const fat = getNutrientValue(nutriments, 'fat_100g', 'fat_value', 'fat');
    const fiber = getNutrientValue(nutriments, 'fiber_100g', 'fiber_value', 'fiber', 'fibre_100g', 'fibre');
    const sugar = getNutrientValue(nutriments, 'sugars_100g', 'sugars_value', 'sugars', 'sugar_100g', 'sugar');
    // Sodium: prefer sodium_100g, but convert from salt if not available (salt * 400)
    let sodium = getNutrientValue(nutriments, 'sodium_100g', 'sodium_value', 'sodium');
    if (sodium === 0) {
        const salt = getNutrientValue(nutriments, 'salt_100g', 'salt_value', 'salt');
        sodium = salt * 400; // salt to sodium conversion (mg)
    }
    sodium = sodium * 1000; // Convert g to mg
    // Log what we found for debugging
    console.log(`📊 OpenFoodFacts nutrition for ${offProduct.product_name}:`);
    console.log(`   Calories: ${calories} kcal (raw: ${nutriments['energy-kcal_100g']}, ${nutriments['energy_100g']})`);
    console.log(`   Protein: ${protein}g, Carbs: ${carbohydrates}g, Fat: ${fat}g`);
    console.log(`   Fiber: ${fiber}g, Sugar: ${sugar}g, Sodium: ${sodium}mg`);
    console.log(`   Raw nutriments keys: ${Object.keys(nutriments).slice(0, 15).join(', ')}...`);
    return {
        food_id: `off-${barcode}`,
        food_name: offProduct.product_name || offProduct.product_name_en || 'Unknown Product',
        brand_name: offProduct.brands || null,
        barcode: barcode,
        calories: Math.round(calories * 10) / 10,
        protein: Math.round(protein * 10) / 10,
        carbohydrates: Math.round(carbohydrates * 10) / 10,
        fat: Math.round(fat * 10) / 10,
        fiber: Math.round(fiber * 10) / 10,
        sugar: Math.round(sugar * 10) / 10,
        sodium: Math.round(sodium),
        serving_description: 'per 100g',
        ingredients: ingredientsText,
        additives: [],
        additivesDatabaseVersion: additive_analyzer_enhanced_1.DATABASE_VERSION,
        processing_score: 0,
        processing_grade: 'A',
        processing_label: 'Not analyzed',
        micronutrient_profile: null,
        source_collection: 'openfoodfacts',
        verified_by: null,
        verified_at: null
    };
}
exports.searchFoodByBarcode = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        (0, additive_analyzer_enhanced_1.loadAdditiveDatabase)();
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
                    foundFood = Object.assign({ id: doc.id, collection: collection }, data);
                    foundCollection = collection;
                    console.log(`Found food in ${collection}: ${data.foodName || data.name}`);
                    break;
                }
            }
            catch (error) {
                console.log(`Error searching ${collection}:`, error);
            }
        }
        if (!foundFood) {
            console.log(`No food found in Firebase collections with barcode: ${barcode}`);
            // Try OpenFoodFacts as fallback
            const offProduct = await fetchFromOpenFoodFacts(barcode);
            if (offProduct) {
                // Transform and analyze the OpenFoodFacts product
                const transformedFood = transformOpenFoodFactsProduct(offProduct, barcode);
                // Analyze ingredients for additives if available
                if (transformedFood.ingredients && transformedFood.ingredients.length > 0) {
                    try {
                        const analysisResult = (0, additive_analyzer_enhanced_1.analyzeIngredientsForAdditives)(transformedFood.ingredients);
                        const processingScore = (0, additive_analyzer_enhanced_1.calculateProcessingScore)(analysisResult.detectedAdditives, transformedFood.ingredients);
                        const grade = (0, additive_analyzer_enhanced_1.determineGrade)(processingScore.totalScore, analysisResult.hasRedFlags);
                        transformedFood.additives = analysisResult.detectedAdditives.map(additive => (Object.assign(Object.assign({}, additive), { id: additive.code, consumerInfo: additive.consumer_guide })));
                        transformedFood.processing_score = processingScore.totalScore;
                        transformedFood.processing_grade = grade.grade;
                        transformedFood.processing_label = grade.label;
                    }
                    catch (error) {
                        console.log(`Additive analysis failed for OpenFoodFacts product:`, error);
                    }
                }
                console.log(`✅ Returning UK English product from OpenFoodFacts: ${transformedFood.food_name}`);
                // Return the OpenFoodFacts product
                res.json({
                    success: true,
                    food: transformedFood
                });
                return;
            }
            // Neither Firebase nor OpenFoodFacts (UK English) has this product
            console.log(`❌ No UK English product found anywhere for barcode: ${barcode}`);
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
                    message: 'No UK English product found with this barcode',
                    action: 'user_contribution_needed',
                    placeholder_id: placeholderId,
                    barcode: barcode
                });
            }
            catch (error) {
                console.error('Error creating placeholder food:', error);
                res.json({
                    success: false,
                    error: 'Product not found',
                    message: 'No UK English product found with this barcode'
                });
            }
            return;
        }
        // Transform the food data to match iOS app expectations
        // Support both nested nutritionData object AND flat structure (from CSV imports)
        const nutrition = foundFood.nutritionData || foundFood;
        const foodName = foundFood.foodName || foundFood.name || 'Unknown Product';
        const brandName = foundFood.brandName || foundFood.brand || null;
        // Analyze ingredients for additives and processing score
        let additiveAnalysis = null;
        let processingInfo = null;
        const ingredientsData = foundFood.extractedIngredients || foundFood.ingredients || null;
        const ingredientsString = Array.isArray(ingredientsData) ? ingredientsData.join(', ') : ingredientsData;
        if (ingredientsString && typeof ingredientsString === 'string') {
            try {
                const analysisResult = (0, additive_analyzer_enhanced_1.analyzeIngredientsForAdditives)(ingredientsString);
                const processingScore = (0, additive_analyzer_enhanced_1.calculateProcessingScore)(analysisResult.detectedAdditives, ingredientsString);
                const grade = (0, additive_analyzer_enhanced_1.determineGrade)(processingScore.totalScore, analysisResult.hasRedFlags);
                additiveAnalysis = analysisResult.detectedAdditives.map(additive => (Object.assign(Object.assign({}, additive), { id: additive.code, consumerInfo: additive.consumer_guide })));
                processingInfo = {
                    score: processingScore.totalScore,
                    grade: grade.grade,
                    label: grade.label,
                    breakdown: processingScore.breakdown
                };
            }
            catch (error) {
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
            additivesDatabaseVersion: additive_analyzer_enhanced_1.DATABASE_VERSION, // Database version used for analysis
            processing_score: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.score) || 0,
            processing_grade: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.grade) || 'A',
            processing_label: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.label) || 'Minimal processing',
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
    }
    catch (error) {
        console.error('Error searching food by barcode:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error while searching for barcode'
        });
    }
});
//# sourceMappingURL=search-food-by-barcode.js.map