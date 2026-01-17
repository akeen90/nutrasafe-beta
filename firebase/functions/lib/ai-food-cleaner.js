"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCleansedFoodStatus = exports.emergencyCleanCleansedFoods = exports.updateCleansedFood = exports.deleteCleansedFood = exports.exportCleansedFoods = exports.getCleansedFoods = exports.analyzeAndCleanFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const uk_product_database_1 = require("./uk-product-database");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.analyzeAndCleanFoods = functions.runWith({
    timeoutSeconds: 540, // 9 minutes for large batches
    memory: '2GB' // More memory for processing large batches
}).https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foods, batchId } = req.body;
        if (!foods || !Array.isArray(foods)) {
            res.status(400).json({ error: 'Foods array is required' });
            return;
        }
        console.log(`🤖 AI Analysis started for batch ${batchId}: ${foods.length} foods`);
        const openaiApiKey = functions.config().openai?.api_key;
        if (!openaiApiKey) {
            res.status(500).json({ error: 'OpenAI API key not configured' });
            return;
        }
        const results = [];
        let totalCost = 0;
        // Process foods in optimized chunks based on batch size
        const chunkSize = foods.length <= 10 ? 5 : Math.min(10, Math.ceil(foods.length / 8)); // Larger chunks for big batches
        const delayBetweenChunks = foods.length <= 10 ? 2000 : 500; // Shorter delay for large batches
        console.log(`📊 Processing ${foods.length} foods in chunks of ${chunkSize} with ${delayBetweenChunks}ms delays`);
        for (let i = 0; i < foods.length; i += chunkSize) {
            const chunk = foods.slice(i, i + chunkSize);
            const chunkNumber = Math.floor(i / chunkSize) + 1;
            const totalChunks = Math.ceil(foods.length / chunkSize);
            console.log(`🔄 Processing chunk ${chunkNumber}/${totalChunks} (${chunk.length} foods)`);
            try {
                const aiResult = await analyzeChunkWithAI(chunk, openaiApiKey);
                results.push(...aiResult.results);
                totalCost += aiResult.cost;
                console.log(`✅ Chunk ${chunkNumber}/${totalChunks} complete, Cost: $${aiResult.cost.toFixed(4)}`);
                // Add shorter delay between chunks for large batches
                if (i + chunkSize < foods.length) {
                    console.log(`⏳ Waiting ${delayBetweenChunks}ms...`);
                    await new Promise(resolve => setTimeout(resolve, delayBetweenChunks));
                }
            }
            catch (chunkError) {
                console.error(`❌ Chunk ${Math.floor(i / chunkSize) + 1} failed:`, chunkError);
                // Add error results for this chunk (but don't include cleanedData so they won't be saved)
                chunk.forEach((food) => {
                    results.push({
                        originalId: food.id || food.name,
                        issues: ['AI analysis failed'],
                        severity: 'medium',
                        suggestions: {},
                        cleanedData: null // Don't save failed analyses
                    });
                });
                // Wait longer after an error to avoid hitting rate limits again
                if (i + chunkSize < foods.length) {
                    console.log('⏳ Waiting 5 seconds after error to avoid rate limits...');
                    await new Promise(resolve => setTimeout(resolve, 5000));
                }
            }
        }
        // Save results to cleansed database - FIXED: Save all foods with cleanedData, ignore issues array
        const cleanedFoods = results.filter(r => r.cleanedData);
        console.log(`✅ FIXED FILTER: ${cleanedFoods.length} out of ${results.length} foods have cleanedData and will be saved`);
        if (cleanedFoods.length > 0) {
            // TEMPORARILY DISABLED: Check for existing foods to allow reprocessing with new serving size logic
            // const existingFoodsQuery = await admin.firestore().collection('cleansedFoods')
            //   .where('originalId', 'in', cleanedFoods.map(f => f.originalId))
            //   .get();
            // 
            // const existingIds = new Set(existingFoodsQuery.docs.map(doc => doc.data().originalId));
            // const newFoods = cleanedFoods.filter(food => !existingIds.has(food.originalId));
            // FORCE REPROCESSING: Process all foods to update with new serving size logic
            const existingIds = new Set(); // Empty set means no existing foods
            const newFoods = cleanedFoods; // Process all foods
            console.log(`🔍 Found ${existingIds.size} existing foods, adding ${newFoods.length} new foods`);
            if (newFoods.length > 0) {
                const batch = admin.firestore().batch();
                newFoods.forEach(result => {
                    const docRef = admin.firestore().collection('cleansedFoods').doc();
                    // Find the original food data from the input
                    const originalFood = foods.find(f => f.id === result.originalId || f._id === result.originalId);
                    // Filter out undefined values to avoid Firestore errors
                    const cleanData = (obj) => {
                        if (obj === null || obj === undefined)
                            return null;
                        if (Array.isArray(obj))
                            return obj.map(cleanData);
                        if (typeof obj === 'object') {
                            const cleaned = {};
                            Object.keys(obj).forEach(key => {
                                const value = cleanData(obj[key]);
                                if (value !== undefined) {
                                    cleaned[key] = value;
                                }
                            });
                            return cleaned;
                        }
                        return obj;
                    };
                    batch.set(docRef, {
                        // Store both original and cleaned data for before/after comparison
                        originalData: cleanData(originalFood) || {},
                        cleanedData: cleanData(result.cleanedData) || {},
                        // AI Analysis metadata
                        aiAnalysis: {
                            issues: result.issues || [],
                            severity: result.severity || 'low',
                            suggestions: cleanData(result.suggestions) || {},
                            duplicateOf: result.duplicateOf || [],
                            processedAt: admin.firestore.FieldValue.serverTimestamp(),
                            batchId: batchId,
                            changesDetected: !!result.suggestions && Object.keys(result.suggestions).length > 0,
                            // NEW: Deletion recommendation tracking - use direct cleanedData
                            recommendedForDeletion: result.cleanedData?.recommendedForDeletion || false,
                            deletionReason: result.cleanedData?.deletionReason || null
                        },
                        // Reference data
                        originalId: result.originalId,
                        status: 'pending_review', // Can be: pending_review, approved, rejected
                        // Make it easily searchable
                        name: result.cleanedData?.name || originalFood?.name || 'Unknown',
                        brand: result.cleanedData?.brand || originalFood?.brand || null,
                        barcode: result.cleanedData?.barcode || originalFood?.barcode || null
                    });
                });
                await batch.commit();
                console.log(`💾 Saved ${newFoods.length} NEW foods to cleansedFoods collection (skipped ${existingIds.size} duplicates)`);
            }
            else {
                console.log(`⚠️ No new foods to save - all ${cleanedFoods.length} foods already exist in cleansedFoods collection`);
            }
        }
        // Log summary
        const failedCount = results.filter(r => r.issues.includes('AI analysis failed')).length;
        const successCount = results.filter(r => !r.issues.includes('AI analysis failed')).length;
        console.log(`📊 Analysis Summary: ${successCount} successful, ${failedCount} failed (not saved)`);
        // Log batch completion
        await admin.firestore().collection('aiProcessingLogs').add({
            batchId,
            foodsProcessed: foods.length,
            issuesFound: results.reduce((sum, r) => sum + r.issues.length, 0),
            estimatedCost: totalCost,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'completed'
        });
        res.json({
            success: true,
            batchId,
            processed: foods.length,
            results: results.map(r => ({
                id: r.originalId,
                issues: r.issues,
                severity: r.severity,
                cleanedData: r.cleanedData // Include the enhanced food data
            })),
            summary: {
                totalIssues: results.reduce((sum, r) => sum + r.issues.length, 0),
                highSeverity: results.filter(r => r.severity === 'high').length,
                mediumSeverity: results.filter(r => r.severity === 'medium').length,
                lowSeverity: results.filter(r => r.severity === 'low').length,
                estimatedCost: totalCost
            }
        });
    }
    catch (error) {
        console.error('Gemini AI food cleaning error:', error);
        res.status(500).json({ error: 'Gemini AI analysis failed', details: String(error) });
    }
});
async function analyzeChunkWithAI(foods, apiKey, retryCount = 0) {
    const maxRetries = 3;
    const baseDelay = 1000; // 1 second
    const prompt = `You are ChatGPT helping with UK food product information. I need you to act exactly like you do in a normal chat conversation - provide real, accurate product data that you know from your training.

For each food product, please look up the REAL UK product information just like you would if someone asked you directly in a chat. Use your knowledge of actual UK products sold in supermarkets.

FIRST - BARCODE PROCESSING (CRITICAL):
1. **VALIDATE existing barcode**: If fake ("000000000000", "123456789", all zeros, all same digits), remove it
2. **SEARCH for real barcode**: If no valid barcode exists, actively search for the real one using:
   - Product name + brand combination
   - Source material (Tesco pages, product packaging, nutrition labels)
   - Your knowledge of UK/EAN barcode patterns for major retailers
   - Cross-reference with known product databases

BARCODE EXAMPLES:
- Input: "000000000000" → Find real barcode → Output: "5012345678901" (if found) OR "" (if not found)
- Input: "123456789" → Find real barcode → Output: "5000169119796" (if found) OR "" (if not found)  
- Input: "" (empty) → Search for barcode → Output: "5012345678901" (if found) OR "" (if not found)
- Input: "5012345678901" → Validate → Output: "5012345678901" (keep real barcodes)

THEN APPLY THESE CHANGES - USE REAL PRODUCT DATA:

1. **RESEARCH ACTUAL PRODUCT DATA** - MANDATORY: Look up the REAL product in your training data:
   
   COCA-COLA CLASSIC EXAMPLE (MANDATORY REFERENCE):
   - Serving Size: 330ml (standard UK can) OR 500ml (bottle) - NEVER 100g for liquids!
   - Full Ingredients: "Carbonated Water, Sugar, Natural Flavourings including Caffeine, Phosphoric Acid, Caramel Colour (E150d)"
   - Nutrition per 100ml: Calories 42kcal, Sugar 10.6g, Carbs 10.6g, Fat 0g, Protein 0g, Salt 0.01g, Sodium 4mg
   - Nutrition per 330ml can: Calories 139kcal, Sugar 35g, Carbs 35g, Fat 0g, Protein 0g, Salt 0.03g
   - Barcode (330ml): 5449000000996 OR similar valid Coca-Cola EAN
   
   MARS BAR EXAMPLE (MANDATORY REFERENCE):
   - Serving Size: 51g (standard UK bar) - NEVER 100g!
   - Full Ingredients: "Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey (from Milk), Palm Fat, Milk Fat, Barley Malt Extract, Salt, Emulsifier (Soya Lecithin), Vanilla Extract"
   - Nutrition per 100g: Calories 449kcal, Sugar 59.5g, Fat 17.4g, Protein 4.2g, Salt 0.24g
   - Nutrition per 51g bar: Calories 229kcal, Sugar 30g, Fat 8.9g, Protein 2.1g, Salt 0.12g
   
   HEINZ BAKED BEANS EXAMPLE (MANDATORY REFERENCE):
   - Serving Size: 415g (standard can) OR 200g (half can serving)
   - Full Ingredients: "Beans (51%), Tomatoes, Water, Sugar, Spirit Vinegar, Modified Corn Flour, Salt, Spice Extracts, Herb Extract"
   - Complete nutrition per 100g AND per serving
   
   METHOD: For each product, ACTIVELY RESEARCH:
   - Look up the actual UK product specifications in your training data
   - Find the real serving size (330ml can, 51g bar, 415g can, etc.)
   - Get the complete ingredient list from UK packaging
   - Get all nutrition values including sugar, fiber, sodium, salt
   - NEVER use generic or estimated values - use actual product data

2. **Complete Nutrition Research** - MANDATORY: Look up ALL nutrition values:
   - Energy (kcal per 100g AND per actual serving)
   - Protein, Carbohydrates, Sugars, Fat, Saturated Fat (all with real values)
   - Fiber, Sodium, Salt (real values, not estimates)
   - Get data from Tesco.com, manufacturer websites, or your product knowledge

3. **Complete Ingredients Research** - MANDATORY: Look up the FULL ingredient list:
   - Get the complete UK ingredient list from your training data
   - Include ALL preservatives, colors, emulsifiers, etc.
   - Use proper E-numbers and chemical names
   - Include percentages where known

4. **Standardise UK brand names** - All major supermarkets: Tesco, Sainsbury's, ASDA, Morrisons, Aldi, Lidl, Marks & Spencer, Waitrose, Co-op, Iceland, B&M, etc.
5. **Extract allergens** - comprehensive allergen information 
6. **Delete non-English foods** - Mark for deletion if food names contain non-English text, foreign characters, or are not in English. Only keep foods with English names and descriptions suitable for UK market.

INPUT FOODS:
${JSON.stringify(foods.map(f => ({
        id: f.id,
        name: f.name || f.foodName,
        brand: f.brand || f.brandName,
        barcode: f.barcode,
        ingredients: f.ingredients,
        nutrition: {
            calories: f.calories?.kcal || f.calories || f.nutritionData?.calories,
            protein: f.protein?.per100g || f.protein || f.nutritionData?.protein,
            carbs: f.carbs?.per100g || f.carbs || f.nutritionData?.carbs,
            fat: f.fat?.per100g || f.fat || f.nutritionData?.fat,
            fiber: f.fiber?.per100g || f.fiber || f.nutritionData?.fiber,
            sugar: f.sugar?.per100g || f.sugar || f.nutritionData?.sugar,
            sodium: f.sodium?.per100g || f.sodium || f.nutritionData?.sodium,
            saturatedFat: f.saturatedFat?.per100g || f.saturatedFat || f.nutritionData?.saturatedFat,
            salt: f.salt?.per100g || f.salt || f.nutritionData?.salt
        }
    })), null, 2)}

CRITICAL: PROCESS EACH FOOD SEPARATELY - Keep Tesco Apple Juice as Apple Juice, Coca Cola as Coca Cola, Mars Bar as Mars Bar, etc. DO NOT make them all the same!

RETURN CLEANED JSON ARRAY (ONE ENTRY FOR EACH INPUT FOOD):
{
  "originalId": "EXACT_ORIGINAL_ID_FROM_INPUT",
  "issues": ["what_was_wrong"],
  "severity": "low|medium|high|critical",
  "cleanedData": {
    "foodName": "CLEANED_food_name_without_serving",
    "brandName": "CLEANED_uk_brand_format",
    "servingSize": {
      "amount": 330,
      "unit": "ml", 
      "description": "per 330ml can"
    },
    "barcode": "5449000000996", // ← REAL Coca-Cola barcode (was fake or empty)
    "ingredients": "Carbonated Water, Sugar, Natural Flavourings including Caffeine, Phosphoric Acid, Caramel Colour (E150d)",
    "fullIngredientsList": "Carbonated Water, Sugar, Natural Flavourings including Caffeine, Phosphoric Acid, Caramel Colour (E150d)",
    "allergens": {
      "contains": [],
      "mayContain": [],
      "statement": "No known allergens"
    },
    "nutritionPer100g": {
      "calories": 42,
      "protein": 0,
      "carbs": 10.6,
      "fat": 0,
      "fiber": 0,
      "sugar": 10.6,
      "sodium": 4,
      "saturatedFat": 0,
      "salt": 0.01
    },
    "nutritionPerServing": {
      "calories": 139,
      "protein": 0,
      "carbs": 35,
      "fat": 0,
      "fiber": 0,
      "sugar": 35,
      "sodium": 13,
      "saturatedFat": 0,
      "salt": 0.03
    },
    "micronutrients": {
      "vitaminC": 15.2,
      "calcium": 120,
      "iron": 8.5,
      "vitaminD": 1.2,
      "vitaminB12": 0.8,
      "folate": 45
    },
    "shouldDelete": true_if_non_english_or_invalid,
    "deleteReason": "Non-English name or invalid data"
  }
}

CRITICAL INGREDIENT PRESERVATION RULE - HIGHEST PRIORITY:
The ingredient fields are the MOST IMPORTANT. You MUST preserve complete ingredient information.

MANDATORY: Use "fullIngredientsList" field to copy the EXACT ORIGINAL ingredient text from the input data.
- For the M&S Apple & Cinnamon Crunch input, copy ALL 585 characters exactly as provided
- DO NOT change punctuation, capitalization, or any characters
- DO NOT summarize, abbreviate, or omit any ingredients
- COPY AND PASTE the complete original ingredient string

Example: If input has "Oat Flakes (59%), Sugar, Vegetable Oil..." then fullIngredientsList should have the EXACT same text including all percentages, brackets, and technical names.

RULES FOR INGREDIENTS FIELD:
1. If the original ingredients look complete and detailed (with percentages, allergens, technical names), COPY THEM EXACTLY
2. For M&S products, copy the EXACT UK ingredient list with ALL details
3. Include ALL percentages (59%, 3%, etc.) 
4. Include ALL sub-ingredients in brackets
5. Include ALL allergen information (contains Gluten, Soya, etc.)
6. Include ALL technical names (Lecithins, Tocopherol-Rich Extract, etc.)
7. NEVER abbreviate or summarize - preserve the FULL LIST
8. NEVER stop at the first few ingredients
9. The ingredients field should be 300+ characters for complex products like cereals
10. COPY AND PASTE the complete original ingredient list if it's already accurate

UK SUPERMARKET DATA SOURCING RULES:
- **Major UK Retailers**: Cross-reference data with Tesco.com, Sainsbury's.co.uk, ASDA.com, Morrisons.com, Aldi.co.uk, Lidl.co.uk, Marksandspencer.com, Waitrose.com, Coop.co.uk, Iceland.co.uk
- **Brand Names**: Exact UK retail formatting - "Tesco Finest" not "tesco finest", "Sainsbury's Taste the Difference" not "sainsburys taste", "M&S" not "marks and spencer"
- **Nutrition Data**: Use official UK retailer nutrition panels - both per 100g AND per serving with exact serving sizes
- **Serving Sizes**: Extract from product names/descriptions with amount and unit separated (e.g. 51, "grams")  
- **Allergens**: Complete UK allergen statements as shown on retail packaging
- **Ingredients**: PRESERVE COMPLETE original lists - UK supermarket ingredient lists are comprehensive and accurate
- **Micronutrients**: Include vitamins/minerals where available from UK retail data (Vitamin C, D, B12, Calcium, Iron, Folate)
- **Barcodes**: Validate against UK EAN-13/8 format or remove if invalid
- ALWAYS include ALL fields in cleanedData

CRITICAL DATA ACCURACY:
- Prioritize UK supermarket website data over generic databases
- Use manufacturer websites for technical ingredient details when available
- Verify nutrition values match UK Food Standards Agency guidelines
- Ensure serving sizes reflect actual UK product packaging`;
    try {
        console.log('🔄 Making axios request to OpenAI API...');
        const response = await axios_1.default.post('https://api.openai.com/v1/chat/completions', {
            model: 'gpt-4o',
            messages: [{
                    role: 'system',
                    content: 'You are a precise food database analyst. You must preserve complete ingredient lists exactly as provided. Return only valid JSON arrays.'
                }, {
                    role: 'user',
                    content: `${prompt}

CRITICAL: When processing ingredients, you MUST preserve the complete original ingredient list with ALL details, percentages, allergen information, and technical names. Do not summarize or shorten ingredients.

FINAL VALIDATION CHECKLIST - BEFORE SENDING RESPONSE:
1. ✅ Did I research the actual product specifications for this specific food?
2. ✅ Is the serving size realistic for UK product packaging (330ml can, 51g bar, 415g can)?
3. ✅ Do I have ALL nutrition values filled in (no empty strings or missing sugar/fiber/sodium)?
4. ✅ Are the ingredients complete with preservatives, colors, E-numbers?
5. ✅ Are per-serving calculations based on the actual serving size, not 100g?

DELETION RULES: 
- DELETE foods with non-English names, foreign characters, or text that is not in English
- DELETE foods labeled "test", "example", "demo", or clearly invalid entries
- KEEP only foods with proper English names suitable for UK market
- When food name contains foreign language or non-English text, set shouldDelete: true

MANDATORY: Return actual product data, not estimates. Use your training knowledge of UK food products.

IMPORTANT: Return the data as a JSON object with a "foods" array containing the processed food objects. Example: {"foods": [...]}`
                }],
            temperature: 0.1,
            max_tokens: 8000,
            response_format: { type: "json_object" }
        }, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`
            }
        });
        console.log('✅ OpenAI API response received:', response.status);
        const data = response.data;
        // OpenAI pricing: gpt-4o is roughly $5 per 1M input tokens, $15 per 1M output tokens
        const inputTokens = data.usage?.prompt_tokens || (prompt.length / 4); // Rough estimate if no usage data
        const outputTokens = data.usage?.completion_tokens || 200; // Conservative estimate
        const cost = (inputTokens * 5 / 1000000) + (outputTokens * 15 / 1000000);
        let aiResults;
        try {
            const openaiContent = data.choices?.[0]?.message?.content;
            if (!openaiContent) {
                throw new Error('No content returned from OpenAI');
            }
            console.log('🤖 RAW AI RESPONSE:', openaiContent);
            const parsedResponse = JSON.parse(openaiContent);
            aiResults = parsedResponse.foods || parsedResponse;
            console.log('📋 PARSED AI RESULTS:', JSON.stringify(aiResults, null, 2));
        }
        catch (parseError) {
            console.error('Failed to parse OpenAI response:', data.choices?.[0]?.message?.content);
            throw new Error('OpenAI returned invalid JSON');
        }
        const results = aiResults.map((aiResult, index) => {
            try {
                // CRITICAL: Match AI result to correct original food by ID, not array index
                const originalFood = foods.find(f => f.id === aiResult.originalId) || foods[index];
                const aiCleaned = aiResult.cleanedData || {};
                console.log(`🔍 Mapping result ${index}: AI ID "${aiResult.originalId}" → Original food: "${originalFood?.name}" (${originalFood?.id})`);
                // 🇬🇧 UK PRODUCT DATABASE LOOKUP - Get real UK product data
                const foodName = aiCleaned.foodName || originalFood?.name || originalFood?.foodName || 'Unknown Food';
                const brandName = aiCleaned.brandName || originalFood?.brand || originalFood?.brandName || '';
                const ukProduct = (0, uk_product_database_1.findUKProduct)(foodName, brandName);
                if (ukProduct) {
                    console.log(`🇬🇧 UK PRODUCT FOUND: ${foodName} → Real data from UK database`);
                }
                else {
                    console.log(`⚠️  UK PRODUCT NOT FOUND: ${foodName} - using AI/original data`);
                }
                return {
                    originalId: aiResult.originalId,
                    issues: [], // FIXED: Clear issues for successful results since we have cleanedData
                    severity: aiResult.severity || 'low',
                    suggestions: {}, // Keep empty for compatibility but AI now makes actual changes
                    duplicateOf: aiResult.duplicateOf || [],
                    cleanedData: {
                        ...originalFood,
                        // CORE FIELDS - Use UK database if available, otherwise AI/original data
                        name: ukProduct ? ukProduct.names[0] : (aiCleaned.foodName || originalFood?.name || originalFood?.foodName || 'Unknown Food'),
                        foodName: ukProduct ? ukProduct.names[0] : (aiCleaned.foodName || originalFood?.name || originalFood?.foodName || 'Unknown Food'),
                        brand: ukProduct ? ukProduct.brands[0] : (aiCleaned.brandName || originalFood?.brand || originalFood?.brandName || ''),
                        brandName: ukProduct ? ukProduct.brands[0] : (aiCleaned.brandName || originalFood?.brand || originalFood?.brandName || ''),
                        barcode: ukProduct ? ukProduct.barcode : (aiCleaned.barcode !== undefined ? aiCleaned.barcode : (originalFood?.barcode || '')),
                        // INGREDIENTS - Use UK database if available, otherwise preserve original
                        ingredients: (() => {
                            if (ukProduct) {
                                console.log(`🇬🇧 USING UK INGREDIENTS: ${ukProduct.ingredients.length} characters from database`);
                                return ukProduct.ingredients;
                            }
                            const originalIngredients = originalFood?.ingredients || '';
                            const aiIngredients = aiCleaned.ingredients || '';
                            const fullIngredients = aiCleaned.fullIngredientsList || '';
                            console.log(`🔧 INGREDIENT PRESERVATION: Original ${originalIngredients.length} chars, AI ${aiIngredients.length} chars, Full ${fullIngredients.length} chars`);
                            // Always use full ingredients if available, otherwise preserve original
                            if (fullIngredients.length > 50) {
                                console.log(`✅ USING FULL INGREDIENTS: ${fullIngredients.length} characters`);
                                return fullIngredients;
                            }
                            else if (originalIngredients.length > 50) {
                                console.log(`✅ PRESERVING ORIGINAL: ${originalIngredients.length} characters maintained`);
                                return originalIngredients;
                            }
                            else {
                                console.log(`⚠️  Using AI or fallback: ${aiIngredients.length || 0} chars`);
                                return aiIngredients || originalFood?.extractedIngredients || '';
                            }
                        })(),
                        fullIngredientsList: aiCleaned.fullIngredientsList || originalFood?.ingredients || '',
                        extractedIngredients: aiCleaned.ingredients || originalFood?.extractedIngredients || originalFood?.ingredients || [],
                        // Enhanced ingredient preservation metadata
                        ingredientsAutoRestored: (() => {
                            const original = originalFood?.ingredients?.length || 0;
                            const ai = aiCleaned.ingredients?.length || 0;
                            return original > 50 && ai < original * 0.8; // Restored if AI truncated significantly
                        })(),
                        aiIngredientsLength: aiCleaned.ingredients?.length || 0,
                        originalIngredientsLength: originalFood?.ingredients?.length || 0,
                        // SERVING SIZE - Use UK database if available
                        servingSize: (() => {
                            if (ukProduct) {
                                console.log(`🇬🇧 USING UK SERVING SIZE: ${ukProduct.servingSize.amount}${ukProduct.servingSize.unit} from database`);
                                return `${ukProduct.servingSize.amount}${ukProduct.servingSize.unit}`;
                            }
                            if (aiCleaned.servingSize && typeof aiCleaned.servingSize === 'object') {
                                const serving = aiCleaned.servingSize;
                                if (serving.amount && serving.unit) {
                                    return `${serving.amount} ${serving.unit}`;
                                }
                                return serving.description || '100g';
                            }
                            return aiCleaned.servingSize || '100g';
                        })(),
                        servingSizes: (() => {
                            const servingSizes = [];
                            // Add AI serving size if available
                            if (aiCleaned.servingSize && typeof aiCleaned.servingSize === 'object') {
                                const serving = aiCleaned.servingSize;
                                if (serving.amount && serving.unit) {
                                    servingSizes.push({
                                        label: serving.description || `Per ${serving.amount}${serving.unit}`,
                                        amount: Number(serving.amount) || 100,
                                        unit: serving.unit || 'g',
                                        isOriginal: true
                                    });
                                }
                            }
                            // Always add standard 100g serving
                            servingSizes.push({ label: 'Per 100g', amount: 100, unit: 'g', isStandard: true });
                            return servingSizes;
                        })(),
                        // NUTRITION DATA - Use UK database if available, otherwise preserve original
                        nutritionData: (() => {
                            let per100g;
                            if (ukProduct) {
                                console.log(`🇬🇧 USING UK NUTRITION: Complete nutrition data from database`);
                                per100g = { ...ukProduct.nutritionPer100g };
                            }
                            else {
                                // Start with original nutrition data (PRESERVE, don't default to 0)
                                const originalNutrition = originalFood?.nutritionData || {};
                                // Create per-100g base data, prioritizing original values
                                per100g = {
                                    calories: Number(aiCleaned.nutritionPer100g?.calories || aiCleaned.nutritionData?.calories || originalNutrition.calories) || null,
                                    protein: Number(aiCleaned.nutritionPer100g?.protein || aiCleaned.nutritionData?.protein || originalNutrition.protein) || null,
                                    carbs: Number(aiCleaned.nutritionPer100g?.carbs || aiCleaned.nutritionData?.carbs || originalNutrition.carbs) || null,
                                    fat: Number(aiCleaned.nutritionPer100g?.fat || aiCleaned.nutritionData?.fat || originalNutrition.fat) || null,
                                    fiber: Number(aiCleaned.nutritionPer100g?.fiber || aiCleaned.nutritionData?.fiber || originalNutrition.fiber) || null,
                                    sugar: Number(aiCleaned.nutritionPer100g?.sugar || aiCleaned.nutritionData?.sugar || originalNutrition.sugar) || null,
                                    sodium: Number(aiCleaned.nutritionPer100g?.sodium || aiCleaned.nutritionData?.sodium || originalNutrition.sodium) || null,
                                    saturatedFat: Number(aiCleaned.nutritionPer100g?.saturatedFat || aiCleaned.nutritionData?.saturatedFat || originalNutrition.saturatedFat) || null,
                                    salt: Number(aiCleaned.nutritionPer100g?.salt || aiCleaned.nutritionData?.salt || originalNutrition.salt) || null
                                };
                            }
                            // Get serving size from the computed section above
                            const servingSize = aiCleaned.servingSize;
                            // Simple serving size parsing for per-serving calculations
                            function parseServingSize(serving) {
                                if (!serving || serving === '100g' || serving === '100g serving')
                                    return 100;
                                const match = serving.match(/(\d+)\s*(g|ml)/i);
                                if (match) {
                                    return parseInt(match[1]);
                                }
                                return null;
                            }
                            // Calculate per-serving data
                            if (ukProduct) {
                                // Use UK database pre-calculated per-serving nutrition
                                console.log(`🇬🇧 USING UK PER-SERVING: Calculated from ${ukProduct.servingSize.amount}${ukProduct.servingSize.unit}`);
                                per100g.perServing = (0, uk_product_database_1.calculateNutritionPerServing)(ukProduct);
                                per100g.servingSize = `${ukProduct.servingSize.amount}${ukProduct.servingSize.unit}`;
                            }
                            else if (servingSize && servingSize !== '100g' && servingSize !== '100g serving') {
                                // Calculate per-serving from per-100g data
                                const servingSizeGrams = parseServingSize(servingSize);
                                if (servingSizeGrams && servingSizeGrams > 0) {
                                    const ratio = servingSizeGrams / 100;
                                    per100g.perServing = {
                                        calories: per100g.calories ? Math.round(per100g.calories * ratio) : null,
                                        protein: per100g.protein ? Math.round(per100g.protein * ratio * 10) / 10 : null,
                                        carbs: per100g.carbs ? Math.round(per100g.carbs * ratio * 10) / 10 : null,
                                        fat: per100g.fat ? Math.round(per100g.fat * ratio * 10) / 10 : null,
                                        fiber: per100g.fiber ? Math.round(per100g.fiber * ratio * 10) / 10 : null,
                                        sugar: per100g.sugar ? Math.round(per100g.sugar * ratio * 10) / 10 : null,
                                        sodium: per100g.sodium ? Math.round(per100g.sodium * ratio * 10) / 10 : null,
                                        saturatedFat: per100g.saturatedFat ? Math.round(per100g.saturatedFat * ratio * 10) / 10 : null,
                                        salt: per100g.salt ? Math.round(per100g.salt * ratio * 10) / 10 : null
                                    };
                                    per100g.servingSize = servingSize;
                                }
                            }
                            // Override with AI per-serving data if specifically provided
                            if (aiCleaned.nutritionPerServing) {
                                per100g.perServing = {
                                    calories: Number(aiCleaned.nutritionPerServing.calories) || null,
                                    protein: Number(aiCleaned.nutritionPerServing.protein) || null,
                                    carbs: Number(aiCleaned.nutritionPerServing.carbs) || null,
                                    fat: Number(aiCleaned.nutritionPerServing.fat) || null,
                                    fiber: Number(aiCleaned.nutritionPerServing.fiber) || null,
                                    sugar: Number(aiCleaned.nutritionPerServing.sugar) || null,
                                    sodium: Number(aiCleaned.nutritionPerServing.sodium) || null,
                                    saturatedFat: Number(aiCleaned.nutritionPerServing.saturatedFat) || null,
                                    salt: Number(aiCleaned.nutritionPerServing.salt) || null
                                };
                                per100g.servingSize = aiCleaned.servingSize || servingSize;
                            }
                            return per100g;
                        })(),
                        // ALLERGENS - Use UK database if available
                        allergens: ukProduct ? ukProduct.allergens : (aiCleaned.allergens || []),
                        // MICRONUTRIENTS - Include if available
                        micronutrients: aiCleaned.micronutrients || null,
                        // PROCESSING SCORE
                        processingScore: aiCleaned.processingScore || 0,
                        processingGrade: aiCleaned.processingGrade || 'A',
                        processingLabel: aiCleaned.processingLabel || 'Minimal processing',
                        // UK RETAILER DATA
                        ukRetailerData: aiCleaned.ukRetailerData || null,
                        // AI ANALYSIS METADATA
                        aiAnalysisMetadata: {
                            provider: 'OpenAI GPT-4o',
                            processedAt: new Date().toISOString(),
                            estimatedCost: 0.002 // Will be updated with actual cost
                        },
                        // DELETION RECOMMENDATION - Use AI direct decision
                        recommendedForDeletion: aiCleaned.shouldDelete || false,
                        deletionReason: aiCleaned.deleteReason || null
                    }
                };
            }
            catch (mapError) {
                console.error(`❌ Error mapping result ${index}:`, mapError);
                console.error(`❌ AI result:`, JSON.stringify(aiResult, null, 2));
                // FIXED: Don't fail the mapping, just log the error and continue with available data
                console.log(`⚠️  Continuing with partial mapping despite error`);
                return {
                    originalId: aiResult.originalId || `error-${index}`,
                    issues: [], // Don't mark as failed - let it save with available data
                    severity: 'low',
                    suggestions: {},
                    duplicateOf: [],
                    cleanedData: {
                        ...foods.find(f => f.id === aiResult.originalId) || foods[index],
                        name: aiResult.cleanedData?.foodName || foods[index]?.name || 'Unknown Food',
                        foodName: aiResult.cleanedData?.foodName || foods[index]?.name || 'Unknown Food'
                    }
                };
            }
        });
        return { results, cost };
    }
    catch (error) {
        console.error('❌ Axios error details:', error.message);
        console.error('❌ Error response:', error.response?.data);
        console.error('❌ Error status:', error.response?.status);
        // Handle axios-specific errors
        if (error.response) {
            // HTTP error response
            const status = error.response.status;
            const errorData = error.response.data;
            // Handle rate limiting with retry
            if ((status === 429 || status === 503) && retryCount < maxRetries) {
                const delay = baseDelay * Math.pow(2, retryCount);
                console.log(`Rate limited, retrying in ${delay}ms (attempt ${retryCount + 1}/${maxRetries})`);
                await new Promise(resolve => setTimeout(resolve, delay));
                return analyzeChunkWithAI(foods, apiKey, retryCount + 1);
            }
            throw new Error(`OpenAI API error: ${status} - ${JSON.stringify(errorData)}`);
        }
        else if (error.request) {
            // Network error
            console.error('❌ Network error - no response received');
            throw new Error('Network error - could not reach OpenAI API');
        }
        else {
            // Other error
            console.error('❌ Request setup error:', error.message);
            throw error;
        }
    }
}
// Function to get cleansed foods with filters
exports.getCleansedFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { filter = 'all', limit = 1000, sortBy = 'recent', // recent, name, brand, severity, calories
        search = '', brand = '', hasBarcode = '', hasIngredients = '', severity = '', dateRange = '' // today, week, month, all
         } = req.query;
        console.log(`🔍 getCleansedFoods: Starting search with filter: ${filter}, limit: ${limit}`);
        // ONLY search cleansedFoods collection - DO NOT touch main database!
        const collections = ['cleansedFoods'];
        const allFoods = [];
        for (const collectionName of collections) {
            try {
                console.log(`🔍 Searching collection: ${collectionName}`);
                let query = admin.firestore().collection(collectionName);
                // Only get foods that have AI analysis data (indicates they've been cleansed)
                // Note: For now, get all foods and filter client-side until we fix the query
                // query = query.where('aiAnalysis', '!=', null);
                // Apply filters based on AI analysis
                // TODO: Re-enable after fixing aiAnalysis query
                // switch (filter) {
                //   case 'duplicates':
                //     query = query.where('aiAnalysis.duplicateOf', '!=', []);
                //     break;
                //   case 'spelling':
                //     query = query.where('aiAnalysis.issues', 'array-contains-any', ['spelling', 'capitalization']);
                //     break;
                //   case 'high_severity':
                //     query = query.where('aiAnalysis.severity', '==', 'high');
                //     break;
                //   case 'medium_severity':
                //     query = query.where('aiAnalysis.severity', '==', 'medium');
                //     break;
                //   case 'needs_review':
                //     query = query.where('aiAnalysis.issues', '!=', []);
                //     break;
                // }
                const snapshot = await query.limit(Math.ceil(parseInt(limit) / collections.length)).get();
                console.log(`🔍 getCleansedFoods: Found ${snapshot.docs.length} cleansed foods in ${collectionName} collection`);
                snapshot.docs.forEach(doc => {
                    const docData = doc.data();
                    console.log(`📄 Processing doc: ${doc.id}, name: ${docData?.name || docData?.foodName || 'NO_NAME'} from ${collectionName}`);
                    // Include foods that either have aiAnalysis OR are in collections that need management
                    const isManageable = docData.aiAnalysis || collectionName === 'verifiedFoods' || collectionName === 'foods';
                    console.log(`🔍 Food manageable: ${isManageable}, has aiAnalysis: ${!!docData.aiAnalysis}`);
                    if (isManageable) {
                        // Remove any 'id' field from docData to prevent it overriding the real doc.id
                        const { id: _, ...cleanData } = docData;
                        allFoods.push({
                            id: doc.id, // Use the real Firestore document ID
                            firestoreId: doc.id, // Keep track of the real ID
                            collection: collectionName, // Track which collection this came from
                            hasAiAnalysis: !!docData.aiAnalysis, // Track if it has AI analysis
                            // Add mock aiAnalysis for non-AI foods to maintain interface compatibility
                            aiAnalysis: docData.aiAnalysis || {
                                issues: [],
                                severity: 'low',
                                suggestions: {},
                                duplicateOf: []
                            },
                            ...cleanData
                        });
                    }
                    else {
                        console.log(`❌ Food not manageable: ${doc.id} from ${collectionName}`);
                    }
                });
            }
            catch (error) {
                console.error(`Error accessing collection ${collectionName}:`, error);
            }
        }
        console.log(`🔍 getCleansedFoods: Found total ${allFoods.length} cleansed foods across all collections`);
        // Apply filters
        let filteredFoods = [...allFoods];
        // Search filter
        if (search && typeof search === 'string') {
            const searchTerm = search.toLowerCase();
            filteredFoods = filteredFoods.filter(food => (food.name || food.foodName || '').toLowerCase().includes(searchTerm) ||
                (food.brand || food.brandName || '').toLowerCase().includes(searchTerm) ||
                (food.ingredients || '').toLowerCase().includes(searchTerm) ||
                (food.cleanedData?.foodName || '').toLowerCase().includes(searchTerm) ||
                (food.cleanedData?.brandName || '').toLowerCase().includes(searchTerm));
        }
        // Brand filter
        if (brand && typeof brand === 'string' && brand !== 'all') {
            filteredFoods = filteredFoods.filter(food => {
                const foodBrand = (food.brand || food.brandName || food.cleanedData?.brandName || '').toLowerCase();
                return foodBrand.includes(brand.toLowerCase());
            });
        }
        // Barcode filter
        if (hasBarcode && typeof hasBarcode === 'string') {
            if (hasBarcode === 'true') {
                filteredFoods = filteredFoods.filter(food => {
                    const barcode = food.barcode || food.cleanedData?.barcode;
                    return barcode && barcode.length > 0 && barcode !== '000000000000' && barcode !== '123456789012';
                });
            }
            else if (hasBarcode === 'false') {
                filteredFoods = filteredFoods.filter(food => {
                    const barcode = food.barcode || food.cleanedData?.barcode;
                    return !barcode || barcode.length === 0 || barcode === '000000000000' || barcode === '123456789012';
                });
            }
        }
        // Ingredients filter
        if (hasIngredients && typeof hasIngredients === 'string') {
            if (hasIngredients === 'true') {
                filteredFoods = filteredFoods.filter(food => {
                    const ingredients = food.ingredients || food.cleanedData?.ingredients;
                    return ingredients && ingredients.trim().length > 0;
                });
            }
            else if (hasIngredients === 'false') {
                filteredFoods = filteredFoods.filter(food => {
                    const ingredients = food.ingredients || food.cleanedData?.ingredients;
                    return !ingredients || ingredients.trim().length === 0;
                });
            }
        }
        // Severity filter
        if (severity && typeof severity === 'string' && severity !== 'all') {
            filteredFoods = filteredFoods.filter(food => {
                const foodSeverity = food.aiAnalysis?.severity || 'low';
                return foodSeverity === severity;
            });
        }
        // Date range filter
        if (dateRange && typeof dateRange === 'string' && dateRange !== 'all') {
            const now = new Date();
            const ranges = {
                'today': new Date(now.getFullYear(), now.getMonth(), now.getDate()),
                'week': new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
                'month': new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
            };
            const rangeStart = ranges[dateRange];
            if (rangeStart) {
                filteredFoods = filteredFoods.filter(food => {
                    const processedAt = food.processedAt || food.aiAnalysis?.processedAt || food.lastModified;
                    if (!processedAt)
                        return false;
                    const foodDate = processedAt.toDate ? processedAt.toDate() : new Date(processedAt);
                    return foodDate >= rangeStart;
                });
            }
        }
        // Advanced sorting
        filteredFoods.sort((a, b) => {
            switch (sortBy) {
                case 'recent':
                    // Most recent first
                    const aDate = a.processedAt || a.aiAnalysis?.processedAt || a.lastModified;
                    const bDate = b.processedAt || b.aiAnalysis?.processedAt || b.lastModified;
                    if (!aDate && !bDate)
                        return 0;
                    if (!aDate)
                        return 1;
                    if (!bDate)
                        return -1;
                    const aTime = aDate.toDate ? aDate.toDate().getTime() : new Date(aDate).getTime();
                    const bTime = bDate.toDate ? bDate.toDate().getTime() : new Date(bDate).getTime();
                    return bTime - aTime;
                case 'name':
                    return (a.name || a.foodName || '').localeCompare(b.name || b.foodName || '');
                case 'brand':
                    const aBrand = a.brand || a.brandName || a.cleanedData?.brandName || '';
                    const bBrand = b.brand || b.brandName || b.cleanedData?.brandName || '';
                    return aBrand.localeCompare(bBrand);
                case 'severity':
                    const severityOrder = { 'critical': 4, 'high': 3, 'medium': 2, 'low': 1 };
                    const aSev = severityOrder[a.aiAnalysis?.severity] || 1;
                    const bSev = severityOrder[b.aiAnalysis?.severity] || 1;
                    return bSev - aSev;
                case 'calories':
                    const aCals = a.nutritionData?.calories || a.cleanedData?.nutritionData?.calories || 0;
                    const bCals = b.nutritionData?.calories || b.cleanedData?.nutritionData?.calories || 0;
                    return bCals - aCals;
                default:
                    return (a.name || a.foodName || '').localeCompare(b.name || b.foodName || '');
            }
        });
        console.log(`📊 getCleansedFoods: Filtered to ${filteredFoods.length} foods (from ${allFoods.length}), sorted by: ${sortBy}`);
        // Log what we're actually returning
        filteredFoods.slice(0, 5).forEach((food, index) => {
            console.log(`📋 Filtered Food ${index + 1}: ${food.name || food.foodName || 'NO_NAME'} (ID: ${food.id}, Collection: ${food.collection})`);
        });
        res.json({
            foods: filteredFoods,
            count: filteredFoods.length,
            total: allFoods.length,
            filter,
            sortBy,
            search,
            brand,
            hasBarcode,
            hasIngredients,
            severity,
            dateRange
        });
    }
    catch (error) {
        console.error('Error getting cleansed foods:', error);
        res.status(500).json({ error: 'Failed to get cleansed foods' });
    }
});
// Export foods with comprehensive data
exports.exportCleansedFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { format = 'csv', // csv, json
        includeAll = 'true', selectedIds = '' } = req.query;
        console.log(`📤 exportCleansedFoods: Starting export in ${format} format`);
        let foods = [];
        if (includeAll === 'true') {
            // Get all cleansed foods
            const snapshot = await admin.firestore().collection('cleansedFoods').get();
            foods = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
        }
        else if (selectedIds && typeof selectedIds === 'string') {
            // Get specific foods
            const ids = selectedIds.split(',').filter(id => id.trim().length > 0);
            console.log(`📤 Exporting specific foods: ${ids.length} items`);
            for (const id of ids) {
                try {
                    const doc = await admin.firestore().collection('cleansedFoods').doc(id.trim()).get();
                    if (doc.exists) {
                        foods.push({
                            id: doc.id,
                            ...doc.data()
                        });
                    }
                }
                catch (error) {
                    console.error(`Error fetching food ${id}:`, error);
                }
            }
        }
        console.log(`📤 exportCleansedFoods: Found ${foods.length} foods to export`);
        if (format === 'csv') {
            // Generate comprehensive CSV
            const csvHeaders = [
                'ID', 'Food Name', 'Brand', 'Barcode', 'Collection',
                'Ingredients', 'Allergens Contains', 'Allergens May Contain',
                'Serving Size', 'Serving Size Grams',
                // Per 100g nutrition
                'Calories per 100g', 'Protein per 100g', 'Carbs per 100g', 'Fat per 100g',
                'Fiber per 100g', 'Sugar per 100g', 'Sodium per 100g', 'Salt per 100g', 'Saturated Fat per 100g',
                // Per serving nutrition  
                'Calories per Serving', 'Protein per Serving', 'Carbs per Serving', 'Fat per Serving',
                'Fiber per Serving', 'Sugar per Serving', 'Sodium per Serving', 'Salt per Serving', 'Saturated Fat per Serving',
                // AI Analysis
                'AI Issues', 'AI Severity', 'AI Suggestions', 'Processing Score', 'Processing Grade',
                // Metadata
                'Source', 'Processed At', 'Last Modified', 'Created At',
                // Original vs Cleaned comparison
                'Original Name', 'Original Brand', 'Original Barcode', 'Original Ingredients',
                // Additional fields
                'Image URLs', 'Verification Status', 'Notes'
            ];
            const csvRows = foods.map(food => {
                const cleanedData = food.cleanedData || {};
                const nutritionData = cleanedData.nutritionData || food.nutritionData || {};
                const perServing = nutritionData.perServing || {};
                const aiAnalysis = food.aiAnalysis || {};
                const originalData = food.originalData || {};
                return [
                    food.id || '',
                    cleanedData.foodName || food.name || food.foodName || '',
                    cleanedData.brandName || food.brand || food.brandName || '',
                    cleanedData.barcode || food.barcode || '',
                    food.collection || '',
                    cleanedData.ingredients || food.ingredients || '',
                    (cleanedData.allergens?.contains || []).join(';') || '',
                    (cleanedData.allergens?.mayContain || []).join(';') || '',
                    cleanedData.servingSize || nutritionData.servingSize || '',
                    cleanedData.servingSizeGrams || '',
                    // Per 100g
                    nutritionData.calories || '',
                    nutritionData.protein || '',
                    nutritionData.carbs || '',
                    nutritionData.fat || '',
                    nutritionData.fiber || '',
                    nutritionData.sugar || '',
                    nutritionData.sodium || '',
                    nutritionData.salt || '',
                    nutritionData.saturatedFat || '',
                    // Per serving
                    perServing.calories || '',
                    perServing.protein || '',
                    perServing.carbs || '',
                    perServing.fat || '',
                    perServing.fiber || '',
                    perServing.sugar || '',
                    perServing.sodium || '',
                    perServing.salt || '',
                    perServing.saturatedFat || '',
                    // AI Analysis
                    (aiAnalysis.issues || []).join(';') || '',
                    aiAnalysis.severity || '',
                    JSON.stringify(aiAnalysis.suggestions || {}).replace(/"/g, '""') || '',
                    cleanedData.processingScore || '',
                    cleanedData.processingGrade || '',
                    // Metadata
                    food.source || '',
                    food.processedAt ? (food.processedAt.toDate ? food.processedAt.toDate().toISOString() : food.processedAt) : '',
                    food.lastModified ? (food.lastModified.toDate ? food.lastModified.toDate().toISOString() : food.lastModified) : '',
                    food.createdAt ? (food.createdAt.toDate ? food.createdAt.toDate().toISOString() : food.createdAt) : '',
                    // Original data
                    originalData.name || '',
                    originalData.brand || '',
                    originalData.barcode || '',
                    originalData.ingredients || '',
                    // Additional
                    (food.imageUrls || []).join(';') || '',
                    food.verificationStatus || '',
                    food.notes || ''
                ].map(field => {
                    // Escape CSV fields containing commas, quotes, or newlines
                    const str = String(field || '');
                    if (str.includes(',') || str.includes('"') || str.includes('\n')) {
                        return `"${str.replace(/"/g, '""')}"`;
                    }
                    return str;
                });
            });
            const csvContent = [csvHeaders, ...csvRows].map(row => row.join(',')).join('\n');
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', `attachment; filename="nutrasafe-foods-export-${new Date().toISOString().split('T')[0]}.csv"`);
            res.send(csvContent);
        }
        else if (format === 'json') {
            // Return comprehensive JSON
            const jsonData = {
                exportedAt: new Date().toISOString(),
                count: foods.length,
                format: 'json',
                foods: foods.map(food => ({
                    // Core data
                    id: food.id,
                    name: food.cleanedData?.foodName || food.name || food.foodName,
                    brand: food.cleanedData?.brandName || food.brand || food.brandName,
                    barcode: food.cleanedData?.barcode || food.barcode,
                    collection: food.collection,
                    // Detailed nutrition
                    nutrition: {
                        per100g: food.cleanedData?.nutritionData || food.nutritionData || {},
                        perServing: (food.cleanedData?.nutritionData?.perServing || food.nutritionData?.perServing || {}),
                        servingSize: food.cleanedData?.servingSize || food.nutritionData?.servingSize,
                        servingSizeGrams: food.cleanedData?.servingSizeGrams
                    },
                    // Complete ingredient and allergen data
                    ingredients: food.cleanedData?.ingredients || food.ingredients,
                    allergens: food.cleanedData?.allergens || {},
                    // AI analysis
                    aiAnalysis: food.aiAnalysis || {},
                    // Processing info
                    processing: {
                        score: food.cleanedData?.processingScore,
                        grade: food.cleanedData?.processingGrade,
                        label: food.cleanedData?.processingLabel
                    },
                    // Metadata
                    metadata: {
                        source: food.source,
                        processedAt: food.processedAt,
                        lastModified: food.lastModified,
                        createdAt: food.createdAt,
                        verificationStatus: food.verificationStatus
                    },
                    // Original data for comparison
                    originalData: food.originalData || {},
                    // Additional data
                    imageUrls: food.imageUrls || [],
                    notes: food.notes,
                    // Complete raw data (for debugging/analysis)
                    _raw: food
                }))
            };
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Content-Disposition', `attachment; filename="nutrasafe-foods-export-${new Date().toISOString().split('T')[0]}.json"`);
            res.json(jsonData);
        }
        else {
            res.status(400).json({ error: 'Unsupported format. Use csv or json.' });
        }
        console.log(`📤 exportCleansedFoods: Successfully exported ${foods.length} foods in ${format} format`);
    }
    catch (error) {
        console.error('Error exporting cleansed foods:', error);
        res.status(500).json({ error: 'Failed to export cleansed foods' });
    }
});
// Delete a cleansed food
exports.deleteCleansedFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId } = req.body;
        if (!foodId) {
            res.status(400).json({ error: 'Food ID is required' });
            return;
        }
        console.log(`🗑️ DELETE ATTEMPT: Trying to delete ${foodId} from cleansedFoods collection`);
        // ONLY check cleansedFoods collection - MUST match getCleansedFoods!
        const collections = ['cleansedFoods'];
        for (const collectionName of collections) {
            const doc = await admin.firestore().collection(collectionName).doc(foodId).get();
            if (doc.exists) {
                console.log(`🔍 FOUND: Document ${foodId} EXISTS in ${collectionName} collection`);
            }
        }
        // Delete from the collection where it actually exists
        let deleted = false;
        for (const collectionName of collections) {
            const doc = await admin.firestore().collection(collectionName).doc(foodId).get();
            if (doc.exists) {
                console.log(`🗑️ DELETE EXECUTING: Deleting ${foodId} from ${collectionName} collection`);
                await admin.firestore().collection(collectionName).doc(foodId).delete();
                // Verify deletion
                const verifyDoc = await admin.firestore().collection(collectionName).doc(foodId).get();
                if (!verifyDoc.exists) {
                    console.log(`✅ DELETE SUCCESS: Document ${foodId} deleted from ${collectionName}`);
                    deleted = true;
                }
                else {
                    console.log(`❌ DELETE FAILED: Document ${foodId} still exists in ${collectionName}`);
                }
                break;
            }
        }
        if (!deleted) {
            console.log(`❌ DOCUMENT NOT FOUND: ${foodId} doesn't exist in any collection`);
            res.status(404).json({ success: false, error: 'Food not found in any collection' });
            return;
        }
        res.json({ success: true, message: 'Food deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting cleansed food:', error);
        res.status(500).json({ error: 'Failed to delete cleansed food' });
    }
});
// Update a cleansed food
exports.updateCleansedFood = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, updatedFood } = req.body;
        if (!foodId || !updatedFood) {
            res.status(400).json({ error: 'Food ID and updated data are required' });
            return;
        }
        // Filter out undefined values to avoid Firestore errors
        const cleanData = (obj) => {
            if (obj === null || obj === undefined)
                return null;
            if (Array.isArray(obj))
                return obj.map(cleanData);
            if (typeof obj === 'object') {
                const cleaned = {};
                Object.keys(obj).forEach(key => {
                    const value = cleanData(obj[key]);
                    if (value !== undefined) {
                        cleaned[key] = value;
                    }
                });
                return cleaned;
            }
            return obj;
        };
        await admin.firestore().collection('cleansedFoods').doc(foodId).update({
            ...cleanData(updatedFood),
            lastModified: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✏️ Updated cleansed food: ${foodId}`);
        res.json({ success: true, message: 'Food updated successfully' });
    }
    catch (error) {
        console.error('Error updating cleansed food:', error);
        res.status(500).json({ error: 'Failed to update cleansed food' });
    }
});
// Emergency function to ONLY delete from cleansedFoods collection (preserves main database)
exports.emergencyCleanCleansedFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        console.log('🚨 EMERGENCY CLEANUP: ONLY deleting from cleansedFoods collection (main database preserved)');
        // ONLY delete from cleansedFoods - DO NOT TOUCH OTHER COLLECTIONS!
        const collection = admin.firestore().collection('cleansedFoods');
        const snapshot = await collection.get();
        console.log(`📊 Found ${snapshot.docs.length} documents in cleansedFoods collection`);
        let totalDeleted = 0;
        if (snapshot.docs.length > 0) {
            // Delete in batches of 500 (Firestore limit)
            const batchSize = 500;
            for (let i = 0; i < snapshot.docs.length; i += batchSize) {
                const batch = admin.firestore().batch();
                const batchDocs = snapshot.docs.slice(i, i + batchSize);
                batchDocs.forEach(doc => {
                    batch.delete(doc.ref);
                });
                await batch.commit();
                totalDeleted += batchDocs.length;
                console.log(`🗑️ cleansedFoods: Deleted batch ${totalDeleted}/${snapshot.docs.length} documents`);
            }
            console.log(`✅ cleansedFoods: Deleted ${totalDeleted} documents`);
        }
        // Verify cleanup
        const verifySnapshot = await collection.get();
        const remaining = verifySnapshot.docs.length;
        console.log(`📊 cleansedFoods: ${remaining} documents remaining`);
        console.log(`🎯 EMERGENCY CLEANUP COMPLETE: Deleted ${totalDeleted} documents from cleansedFoods only`);
        res.json({
            success: true,
            message: 'Emergency cleanup completed - ONLY cleansedFoods collection affected',
            totalDeleted,
            remainingInCleansedFoods: remaining,
            mainDatabaseIntact: true
        });
    }
    catch (error) {
        console.error('Emergency cleanup failed:', error);
        res.status(500).json({ error: 'Emergency cleanup failed', details: String(error) });
    }
});
exports.updateCleansedFoodStatus = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodId, action, cleanedData, status } = req.body;
        if (!foodId) {
            res.status(400).json({ error: 'Food ID is required' });
            return;
        }
        const docRef = admin.firestore().collection('cleansedFoods').doc(foodId);
        switch (action) {
            case 'approve':
                await docRef.update({
                    status: 'approved',
                    approvedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                break;
            case 'reject':
                await docRef.update({
                    status: 'rejected',
                    rejectedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                break;
            case 'update':
                if (cleanedData) {
                    await docRef.update({
                        cleanedData: cleanedData,
                        status: status || 'pending_review',
                        lastModified: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
                break;
            case 'delete':
                await docRef.delete();
                break;
            default:
                res.status(400).json({ error: 'Invalid action' });
                return;
        }
        console.log(`✅ Updated cleansed food ${foodId} with action: ${action}`);
        res.json({
            success: true,
            message: `Food ${action}d successfully`
        });
    }
    catch (error) {
        console.error('❌ Error updating cleansed food:', error);
        res.status(500).json({
            success: false,
            error: String(error)
        });
    }
});
//# sourceMappingURL=ai-food-cleaner.js.map