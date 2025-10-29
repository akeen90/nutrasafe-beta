"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findIngredients = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
/**
 * Parse serving size string to numeric grams/ml
 * Examples: "330ml" → 330, "150g" → 150, "1 bar (51g)" → 51, "1 slice (30g)" → 30
 * CRITICAL: Always extracts grams from parentheses first (e.g., "1 slice (30g)" → 30, NOT 1)
 */
function parseServingSizeToGrams(servingSize) {
    // PRIORITY 1: Look for grams in parentheses first (e.g., "1 slice (30g)" should extract 30, not 1)
    // This ensures we use actual weight instead of slice/piece count
    const patterns = [
        /\((\d+(?:\.\d+)?)\s*g\)/i, // "(30g)" - HIGHEST PRIORITY for slice descriptions
        /\((\d+(?:\.\d+)?)\s*ml\)/i, // "(330ml)"
        /(\d+(?:\.\d+)?)\s*g\b/i, // "150g" - standalone grams
        /(\d+(?:\.\d+)?)\s*ml\b/i, // "330ml" - standalone ml
    ];
    for (const pattern of patterns) {
        const match = servingSize.match(pattern);
        if (match && match[1]) {
            const grams = parseFloat(match[1]);
            console.log(`✅ Extracted ${grams}g from serving size: "${servingSize}"`);
            return grams;
        }
    }
    console.log(`⚠️ Could not extract grams from serving size: "${servingSize}"`);
    return null;
}
/**
 * Convert per-serving nutrition to per-100g
 */
function convertToPerHundredGrams(servingNutrition) {
    const servingGrams = parseServingSizeToGrams(servingNutrition.servingSize);
    if (!servingGrams || servingGrams <= 0) {
        console.log(`⚠️ Cannot convert: invalid serving size "${servingNutrition.servingSize}"`);
        return null;
    }
    const ratio = 100 / servingGrams;
    const per100g = {
        calories: Math.round(servingNutrition.calories * ratio * 10) / 10,
        protein: Math.round(servingNutrition.protein * ratio * 10) / 10,
        carbs: Math.round(servingNutrition.carbs * ratio * 10) / 10,
        fat: Math.round(servingNutrition.fat * ratio * 10) / 10,
    };
    if (servingNutrition.fiber !== undefined) {
        per100g.fiber = Math.round(servingNutrition.fiber * ratio * 10) / 10;
    }
    if (servingNutrition.sugar !== undefined) {
        per100g.sugar = Math.round(servingNutrition.sugar * ratio * 10) / 10;
    }
    if (servingNutrition.salt !== undefined) {
        per100g.salt = Math.round(servingNutrition.salt * ratio * 10) / 10;
    }
    console.log(`✅ Converted ${servingGrams}g/ml to per-100g/ml: ${JSON.stringify(per100g)}`);
    return per100g;
}
/**
 * Cloud Function: Find ingredients and nutrition for UK products
 *
 * CRITICAL: Always returns nutrition as per-100g, never per-serving!
 * If only per-serving data found, converts to per-100g automatically.
 */
exports.findIngredients = functions
    .region('us-central1')
    .https.onRequest(async (req, res) => {
    var _a, _b, _c, _d, _e, _f;
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const { productName, brand, maxResults = 1, refinementContext } = req.body;
    // Note: skipCache parameter not needed here - caching is handled client-side only
    // maxResults: 1 (default, fastest) or 2-3 for multiple options
    // refinementContext: optional { store, packageSize, additionalDetails }
    if (!productName || typeof productName !== 'string') {
        res.status(400).json({ error: 'productName is required' });
        return;
    }
    const refContext = refinementContext;
    console.log(`🔍 Finding ingredients for: ${productName}${brand ? ` (${brand})` : ''}`);
    if (refContext) {
        console.log(`🎯 Refinement context: ${JSON.stringify(refContext)}`);
    }
    console.log(`📊 Requesting ${maxResults} result(s)`);
    try {
        // Build search query prioritizing manufacturer then UK supermarkets
        const searchQuery = brand
            ? `${brand} ${productName} UK nutrition per 100g ingredients`
            : `${productName} UK nutrition per 100g ingredients`;
        console.log(`🌐 Search query: ${searchQuery}`);
        // Get Gemini API key
        const geminiApiKey = (_a = functions.config().gemini) === null || _a === void 0 ? void 0 : _a.api_key;
        if (!geminiApiKey) {
            throw new Error('Gemini API key not configured');
        }
        // Build refinement hint for prompt
        let refinementHint = '';
        if (refContext) {
            const hints = [];
            if (refContext.store)
                hints.push(`from ${refContext.store}`);
            if (refContext.packageSize)
                hints.push(`${refContext.packageSize} size`);
            if (refContext.additionalDetails)
                hints.push(refContext.additionalDetails);
            if (hints.length > 0) {
                refinementHint = `\nUSER SPECIFIED: Looking specifically for ${hints.join(', ')}. Prioritize this exact variant.`;
            }
        }
        // Use Gemini AI to search and extract nutrition data
        const multiResultInstruction = maxResults > 1
            ? `\nFIND ${maxResults} DIFFERENT VARIANTS if available (e.g., different stores, sizes, or brands). Return array of matches with confidence scores (0-100).`
            : '';
        const prompt = `UK food nutrition extractor. Search: "${searchQuery}"${refinementHint}${multiResultInstruction}

REQUIREMENTS:
1. Find "per 100g/ml" nutrition (PRIORITY) or "per serving" (convert later)
2. Serving size with grams: "1 slice (30g)" NOT "1 slice"
3. Full ingredients list
4. Product name, brand, barcode

SOURCES (priority order):
1. Manufacturer UK website (.co.uk)
2. UK supermarkets: Tesco, Sainsbury's, Asda, Morrisons, Waitrose, Ocado

NUTRITION HANDLING:
- "per 100g" found → use directly in nutrition_per_100g, set nutrition_source="per_100g"
- Only "per serving" found → use per_serving_nutrition, set nutrition_source="per_serving"
- Never mix: per-serving data must NOT go in nutrition_per_100g

${maxResults > 1 ? `RETURN JSON ARRAY (${maxResults} matches):
[{
  "confidence_score": 0-100,
  "source_name": "Tesco/Sainsbury's/etc",
  "found": true,
  "product_name": "...",
  "brand": "...",
  "barcode": "..." or null,
  "ingredients_text": "...",
  "nutrition_source": "per_100g" or "per_serving",
  "nutrition_per_100g": {...} or null,
  "per_serving_nutrition": {...} or null,
  "serving_size": "330ml, 1 bar (51g)",
  "source_url": "..."
}]` : `RETURN SINGLE JSON:
{
  "found": true/false,
  "product_name": "...",
  "brand": "...",
  "barcode": "..." or null,
  "ingredients_text": "...",
  "nutrition_source": "per_100g" or "per_serving",
  "nutrition_per_100g": {...} or null,
  "per_serving_nutrition": {...} or null,
  "serving_size": "330ml, 1 bar (51g)",
  "source_url": "..."
}`}

Nutrition format: {"calories": kcal, "protein": g, "carbs": g, "fat": g, "fiber": g|null, "sugar": g|null, "salt": g|null}
Return ONLY JSON, no other text.`;
        // Call Gemini API
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`;
        const geminiResponse = await axios_1.default.post(geminiUrl, {
            contents: [{
                    parts: [{
                            text: prompt
                        }]
                }],
            generationConfig: {
                temperature: 0.3,
                maxOutputTokens: 4096
            }
        });
        const responseText = ((_f = (_e = (_d = (_c = (_b = geminiResponse.data.candidates) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.content) === null || _d === void 0 ? void 0 : _d.parts) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.text) || '';
        console.log(`🤖 AI Response: ${responseText.substring(0, 500)}...`);
        // Extract JSON from response (remove markdown code blocks if present)
        let jsonText = responseText.trim();
        if (jsonText.startsWith('```json')) {
            jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
        }
        else if (jsonText.startsWith('```')) {
            jsonText = jsonText.replace(/```\n?/g, '');
        }
        const aiData = JSON.parse(jsonText);
        // Handle multi-result response (array)
        if (Array.isArray(aiData)) {
            console.log(`📦 Received ${aiData.length} matches from AI`);
            const processedMatches = [];
            for (const match of aiData) {
                if (!match.found)
                    continue;
                // Process nutrition for each match
                let finalPer100g = null;
                if (match.nutrition_source === 'per_100g' && match.nutrition_per_100g) {
                    finalPer100g = match.nutrition_per_100g;
                }
                else if (match.per_serving_nutrition) {
                    const servingNutrition = Object.assign(Object.assign({}, match.per_serving_nutrition), { servingSize: match.per_serving_nutrition.serving_size });
                    finalPer100g = convertToPerHundredGrams(servingNutrition);
                }
                if (finalPer100g) {
                    processedMatches.push({
                        product_name: match.product_name,
                        brand: match.brand,
                        barcode: match.barcode,
                        ingredients_text: match.ingredients_text,
                        nutrition_per_100g: finalPer100g,
                        serving_size: match.serving_size,
                        source_url: match.source_url,
                        confidence_score: match.confidence_score,
                        source_name: match.source_name
                    });
                }
            }
            if (processedMatches.length === 0) {
                console.log('❌ No valid matches found in multi-result response');
                res.json({
                    ingredients_found: false,
                    error: 'Could not find this product on UK supermarket websites. Please enter nutrition manually.'
                });
                return;
            }
            // Sort by confidence score (highest first)
            processedMatches.sort((a, b) => (b.confidence_score || 0) - (a.confidence_score || 0));
            console.log(`✅ Returning ${processedMatches.length} processed matches`);
            res.json({
                ingredients_found: true,
                matches: processedMatches,
                // Include first match as legacy single result for backwards compatibility
                product_name: processedMatches[0].product_name,
                brand: processedMatches[0].brand,
                barcode: processedMatches[0].barcode,
                ingredients_text: processedMatches[0].ingredients_text,
                nutrition_per_100g: processedMatches[0].nutrition_per_100g,
                serving_size: processedMatches[0].serving_size,
                source_url: processedMatches[0].source_url
            });
            return;
        }
        // Handle single result response (object)
        if (!aiData.found) {
            console.log('❌ AI could not find product data');
            const response = {
                ingredients_found: false,
                error: 'Could not find this product on UK supermarket websites. Please enter nutrition manually.'
            };
            res.json(response);
            return;
        }
        // Determine final per-100g nutrition
        let finalPer100g = null;
        let finalServingSize = aiData.serving_size;
        if (aiData.nutrition_source === 'per_100g' && aiData.nutrition_per_100g) {
            // PRIORITY 1: Use per-100g data directly
            console.log('✅ Found per-100g nutrition data directly');
            finalPer100g = aiData.nutrition_per_100g;
            // VALIDATION: Check if values seem reasonable for per-100g
            // Per-100g calories should typically be between 20-900 kcal
            // If serving size suggests large serving (e.g., 500ml) but calories are very high (e.g., 1600+)
            // this might be per-serving data mislabeled as per-100g
            if (finalPer100g) {
                const calories = finalPer100g.calories || 0;
                if (calories > 900) {
                    console.log(`⚠️ WARNING: Per-100g calories seem unusually high (${calories} kcal)`);
                    console.log(`⚠️ Serving size: ${finalServingSize}`);
                    console.log(`⚠️ This might be per-serving data mislabeled as per-100g!`);
                    // If we have a serving size > 100g/ml, try to convert
                    const servingGrams = parseServingSizeToGrams(finalServingSize || '');
                    if (servingGrams && servingGrams > 100) {
                        console.log(`🔧 Attempting to fix: Converting suspected per-${servingGrams}g data to per-100g`);
                        const ratio = 100 / servingGrams;
                        finalPer100g = {
                            calories: Math.round((finalPer100g.calories || 0) * ratio * 10) / 10,
                            protein: Math.round((finalPer100g.protein || 0) * ratio * 10) / 10,
                            carbs: Math.round((finalPer100g.carbs || 0) * ratio * 10) / 10,
                            fat: Math.round((finalPer100g.fat || 0) * ratio * 10) / 10,
                            fiber: finalPer100g.fiber ? Math.round(finalPer100g.fiber * ratio * 10) / 10 : undefined,
                            sugar: finalPer100g.sugar ? Math.round(finalPer100g.sugar * ratio * 10) / 10 : undefined,
                            salt: finalPer100g.salt ? Math.round(finalPer100g.salt * ratio * 10) / 10 : undefined,
                        };
                        console.log(`✅ Fixed nutrition to proper per-100g: ${JSON.stringify(finalPer100g)}`);
                    }
                }
            }
        }
        else if (aiData.per_serving_nutrition) {
            // FALLBACK: Convert per-serving to per-100g
            console.log('⚠️ Only found per-serving nutrition, converting to per-100g...');
            const servingNutrition = Object.assign(Object.assign({}, aiData.per_serving_nutrition), { servingSize: aiData.per_serving_nutrition.serving_size });
            finalPer100g = convertToPerHundredGrams(servingNutrition);
            if (!finalPer100g) {
                console.log('❌ Failed to convert per-serving to per-100g');
                const response = {
                    ingredients_found: false,
                    error: 'Found nutrition data but could not convert to per-100g format. Please enter manually.'
                };
                res.json(response);
                return;
            }
        }
        else {
            console.log('❌ No usable nutrition data found');
            const response = {
                ingredients_found: false,
                error: 'Found product but nutrition data is incomplete. Please enter manually.'
            };
            res.json(response);
            return;
        }
        // Build successful response
        const response = {
            ingredients_found: true,
            product_name: aiData.product_name,
            brand: aiData.brand,
            barcode: aiData.barcode || undefined,
            ingredients_text: aiData.ingredients_text,
            nutrition_per_100g: finalPer100g || undefined,
            serving_size: finalServingSize,
            source_url: aiData.source_url
        };
        console.log(`✅ Success! Returning per-100g nutrition for ${aiData.product_name}`);
        res.json(response);
    }
    catch (error) {
        console.error('❌ Error finding ingredients:', error);
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        res.status(500).json({
            ingredients_found: false,
            error: `Failed to find ingredients: ${errorMessage}`
        });
    }
});
//# sourceMappingURL=find-ingredients.js.map