"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findIngredients = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
/**
 * Parse serving size string to numeric grams/ml
 * Examples: "330ml" → 330, "150g" → 150, "1 bar (51g)" → 51
 */
function parseServingSizeToGrams(servingSize) {
    const patterns = [
        /(\d+(?:\.\d+)?)\s*ml/i,
        /(\d+(?:\.\d+)?)\s*g/i,
        /\((\d+(?:\.\d+)?)\s*g\)/i,
        /\((\d+(?:\.\d+)?)\s*ml\)/i
    ];
    for (const pattern of patterns) {
        const match = servingSize.match(pattern);
        if (match && match[1]) {
            return parseFloat(match[1]);
        }
    }
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
    const { productName, brand } = req.body;
    if (!productName || typeof productName !== 'string') {
        res.status(400).json({ error: 'productName is required' });
        return;
    }
    console.log(`🔍 Finding ingredients for: ${productName}${brand ? ` (${brand})` : ''}`);
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
        // Use Gemini AI to search and extract nutrition data
        const prompt = `You are a UK food nutrition data extractor. Search for "${searchQuery}" and extract:

CRITICAL REQUIREMENTS:
1. Find nutrition information that shows "per 100g" or "per 100ml" - THIS IS PRIORITY #1
2. Also find the serving size separately (e.g., "330ml", "150g", "1 bar (51g)")
3. Find the ingredients list
4. Find product name, brand, and barcode if available

UK-ONLY SEARCH PRIORITY (in order):
1. FIRST: Search manufacturer's official UK website (.co.uk domain)
   - Examples: huel.com, cadbury.co.uk, kelloggs.co.uk, graze.com
2. FALLBACK: Search UK supermarket websites if manufacturer data not found
   - Tesco, Sainsbury's, Asda, Morrisons, Waitrose, Ocado

IMPORTANT: Only use UK-based sources. Do not use international manufacturer sites (.com unless UK brand).

NUTRITION TABLE PRIORITY:
1. FIRST: Look for "Typical values per 100g" or "Per 100ml" table
2. ONLY IF NOT FOUND: Look for "per serving" and the serving size, then I will convert it

Return JSON in this EXACT format:
{
  "found": true/false,
  "product_name": "Full product name",
  "brand": "Brand name",
  "barcode": "barcode number or null",
  "ingredients_text": "Complete ingredients list",
  "nutrition_source": "per_100g" or "per_serving",
  "nutrition_per_100g": {
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number,
    "fiber": number or null,
    "sugar": number or null,
    "salt": number or null
  },
  "per_serving_nutrition": {
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number,
    "fiber": number or null,
    "sugar": number or null,
    "salt": number or null,
    "serving_size": "e.g. 330ml or 150g"
  } or null,
  "serving_size": "typical serving e.g. 330ml, 150g, 1 bar (51g)",
  "source_url": "URL where data was found"
}

IMPORTANT:
- If you find "per 100g" nutrition, use it directly for nutrition_per_100g
- If you only find "per serving", put it in per_serving_nutrition and I'll convert it
- Calories should be kcal (kilocalories)
- All weights in grams, volumes in ml
- Set found=false if you cannot find nutrition data from UK sources

Return ONLY the JSON, no other text.`;
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