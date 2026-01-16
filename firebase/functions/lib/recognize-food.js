"use strict";
/**
 * AI-Powered Food Recognition with Database Lookup
 *
 * Hybrid approach:
 * 1. Gemini 1.5 Pro identifies foods + estimates portion sizes
 * 2. Algolia searches for verified nutrition data
 * 3. Falls back to AI estimates only when no database match
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.recognizeFood = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
const algoliasearch_1 = require("algoliasearch");
// Secrets
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
const algoliaAdminKey = (0, params_1.defineSecret)('ALGOLIA_ADMIN_API_KEY');
// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
// Database indices - new cleaned databases
const SEARCH_INDICES = ['uk_foods_cleaned', 'fast_foods_database', 'generic_database'];
/**
 * Cloud Function: Recognize food items using Gemini + Algolia hybrid approach
 */
exports.recognizeFood = (0, https_1.onRequest)({
    cors: true,
    timeoutSeconds: 90, // Increased for database lookups
    memory: '1GiB',
    secrets: [geminiApiKey, algoliaAdminKey],
}, async (req, res) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u;
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const { image } = req.body;
    if (!image || typeof image !== 'string') {
        res.status(400).json({ error: 'Base64 encoded image is required' });
        return;
    }
    try {
        // Step 1: Identify foods with Gemini
        console.log('🔍 Step 1: Identifying foods with Gemini...');
        const identifiedFoods = await identifyFoodsWithGemini(image, geminiApiKey.value());
        console.log(`✅ Gemini identified ${identifiedFoods.length} foods`);
        if (identifiedFoods.length === 0) {
            res.set('Access-Control-Allow-Origin', '*');
            res.status(200).json({ foods: [] });
            return;
        }
        // Step 2: Look up packaged foods in database, use AI estimates for plated food
        console.log('📚 Step 2: Processing foods (DB lookup for packaging, AI for plated)...');
        const algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
        const finalFoods = [];
        for (const identified of identifiedFoods) {
            const portionMultiplier = identified.portionGrams / 100;
            // Only search database for packaged products with branding visible
            // Plated/prepared food uses AI estimates directly (more accurate for generic items)
            if (identified.isPackaging && identified.brand) {
                const dbMatch = await searchDatabaseForFood(algoliaClient, identified);
                if (dbMatch) {
                    // Extract nutrition with fallbacks for different field naming conventions
                    const caloriesVal = (_c = (_b = (_a = dbMatch.calories) !== null && _a !== void 0 ? _a : dbMatch.Calories) !== null && _b !== void 0 ? _b : dbMatch.energy) !== null && _c !== void 0 ? _c : 0;
                    const proteinVal = (_e = (_d = dbMatch.protein) !== null && _d !== void 0 ? _d : dbMatch.Protein) !== null && _e !== void 0 ? _e : 0;
                    const carbsVal = (_h = (_g = (_f = dbMatch.carbs) !== null && _f !== void 0 ? _f : dbMatch.Carbs) !== null && _g !== void 0 ? _g : dbMatch.carbohydrates) !== null && _h !== void 0 ? _h : 0;
                    const fatVal = (_k = (_j = dbMatch.fat) !== null && _j !== void 0 ? _j : dbMatch.Fat) !== null && _k !== void 0 ? _k : 0;
                    const fiberVal = (_o = (_m = (_l = dbMatch.fiber) !== null && _l !== void 0 ? _l : dbMatch.Fiber) !== null && _m !== void 0 ? _m : dbMatch.fibre) !== null && _o !== void 0 ? _o : 0;
                    const sugarVal = (_q = (_p = dbMatch.sugar) !== null && _p !== void 0 ? _p : dbMatch.Sugar) !== null && _q !== void 0 ? _q : 0;
                    const sodiumVal = (_s = (_r = dbMatch.sodium) !== null && _r !== void 0 ? _r : dbMatch.Sodium) !== null && _s !== void 0 ? _s : 0;
                    const brandVal = (_u = (_t = dbMatch.brandName) !== null && _t !== void 0 ? _t : dbMatch.brand) !== null && _u !== void 0 ? _u : identified.brand;
                    // Log the raw database record for debugging
                    console.log(`  📦 DB record fields: ${Object.keys(dbMatch).join(', ')}`);
                    console.log(`  📊 Nutrition values - cal: ${caloriesVal}, prot: ${proteinVal}, carbs: ${carbsVal}, fat: ${fatVal}`);
                    // Database match found - use verified nutrition scaled to portion
                    finalFoods.push({
                        name: dbMatch.name,
                        brand: brandVal,
                        calories: Math.round(caloriesVal * portionMultiplier),
                        protein: Math.round(proteinVal * portionMultiplier * 10) / 10,
                        carbs: Math.round(carbsVal * portionMultiplier * 10) / 10,
                        fat: Math.round(fatVal * portionMultiplier * 10) / 10,
                        fiber: Math.round(fiberVal * portionMultiplier * 10) / 10,
                        sugar: Math.round(sugarVal * portionMultiplier * 10) / 10,
                        sodium: Math.round(sodiumVal * portionMultiplier * 10) / 10,
                        portionGrams: identified.portionGrams,
                        confidence: identified.confidence,
                        isFromDatabase: true,
                        databaseId: dbMatch.objectID,
                        ingredients: Array.isArray(dbMatch.ingredients)
                            ? dbMatch.ingredients.join(', ')
                            : (dbMatch.ingredients || null),
                    });
                    console.log(`  ✅ [Packaging] "${identified.name}" → DB match: "${dbMatch.name}" (${caloriesVal} kcal/100g)`);
                    continue;
                }
                // If no DB match for packaging, fall through to AI estimate
                console.log(`  ⚠️ [Packaging] "${identified.name}" → No DB match, using AI estimate`);
            }
            else {
                console.log(`  🍽️ [Plated] "${identified.name}" → Using AI estimate (generic food)`);
            }
            // Use AI estimates for plated food or when no DB match found
            finalFoods.push({
                name: identified.name,
                brand: identified.brand,
                calories: Math.round(identified.estimatedCaloriesPer100g * portionMultiplier),
                protein: Math.round(identified.estimatedProteinPer100g * portionMultiplier * 10) / 10,
                carbs: Math.round(identified.estimatedCarbsPer100g * portionMultiplier * 10) / 10,
                fat: Math.round(identified.estimatedFatPer100g * portionMultiplier * 10) / 10,
                fiber: 0,
                sugar: 0,
                sodium: 0,
                portionGrams: identified.portionGrams,
                confidence: identified.isPackaging ? identified.confidence * 0.8 : identified.confidence, // Lower confidence only for failed DB lookups
                isFromDatabase: false,
                databaseId: null,
                ingredients: null,
            });
        }
        const dbMatches = finalFoods.filter(f => f.isFromDatabase).length;
        const platedCount = identifiedFoods.filter(f => !f.isPackaging).length;
        console.log(`✅ Complete: ${dbMatches} from database, ${platedCount} plated (AI estimates)`);
        res.set('Access-Control-Allow-Origin', '*');
        res.status(200).json({ foods: finalFoods });
    }
    catch (error) {
        console.error('❌ Food recognition failed:', error);
        res.status(500).json({
            error: 'Failed to recognize food',
            details: String(error)
        });
    }
});
/**
 * Build the prompt for food identification with enhanced image analysis
 */
function buildIdentificationPrompt() {
    return `You are an expert food identification AI with advanced visual analysis. Analyse this photo comprehensively.

## STEP 1: IMAGE QUALITY ASSESSMENT
First, mentally assess the image quality to adjust your confidence:
- Lighting: Well-lit, dark, overexposed, or colour-cast (warm restaurant lighting, flash)?
- Focus: Sharp, slightly blurry, or very blurry?
- Angle: Top-down (best for portions), angled, or side view?
- Obstructions: Any food partially hidden or cut off?
Reduce confidence for poor quality images. Account for colour casts when identifying foods.

## STEP 2: REFERENCE OBJECT DETECTION FOR PORTION SIZING
CRITICAL: Look for reference objects to calibrate portion sizes accurately:

COMMON REFERENCE OBJECTS:
- Standard dinner plate: 26-28cm diameter → food covering half = ~150-200g meat or ~200g carbs
- Side plate: 18-20cm diameter
- Bowl (standard): 15-18cm diameter
- Adult hand/fingers visible: palm ≈ 100g meat, fist ≈ 150g carbs
- Fork length: ~19-20cm (use to gauge food size)
- Knife length: ~22-24cm
- Standard mug: 250-300ml
- iPhone/smartphone: ~15cm tall
- £1/£2 coin: 2.3cm/2.8cm diameter
- Takeaway container: small ~300ml, medium ~500ml, large ~750ml

PORTION CALIBRATION METHOD:
1. Identify any reference objects in the image
2. Estimate plate/container size from reference
3. Estimate food coverage area on plate (quarter, half, full)
4. Calculate portion weight from coverage + food density

## STEP 3: FOOD IDENTIFICATION
For EACH food item, provide:
1. name: Specific name WITH cooking method (e.g., "pan-fried salmon fillet" not just "fish")
2. brand: Brand name if visible on packaging, otherwise null
3. portionGrams: Weight calibrated using detected reference objects
4. searchTerms: 2-3 alternative database search terms
5. confidence: 0.0-1.0 (reduce for blurry/obscured/poor lighting)
6. isPackaging: true if product packaging visible, false if plated food
7. estimatedCaloriesPer100g, estimatedProteinPer100g, estimatedCarbsPer100g, estimatedFatPer100g

## FOOD RECOGNITION - BE SPECIFIC

IDENTIFY COOKING METHODS (affects calories significantly):
- "grilled chicken breast" (165 kcal) vs "fried chicken breast" (220 kcal)
- "steamed vegetables" vs "roasted vegetables with oil"
- "boiled rice" vs "egg fried rice" vs "pilau rice"
- "oven chips" (200 kcal) vs "deep-fried chips" (280 kcal)
- "poached egg" vs "fried egg"

IDENTIFY SPECIFIC FOOD TYPES:
- Proteins: Cut (breast/thigh/fillet), cooking method, skin on/off, breaded/plain
- Carbs: White/brown rice, regular/sweet potato, bread type, pasta shape
- Vegetables: Raw/cooked, fresh/frozen, with oil or plain
- Sauces: Cream-based/tomato-based, amount visible

RECOGNISE CUISINES:
- British: Fish and chips, full English, roast dinner, pie and mash, Sunday roast
- Italian: Pasta (penne/spaghetti/lasagne), risotto, pizza
- Asian: Stir-fry, curry (Thai/Chinese/Japanese), sushi, noodles (rice/egg)
- Indian: Curry type (tikka/korma/madras), rice type, naan/chapati/roti
- Mexican: Tacos, burritos, nachos, fajitas
- Fast food: Recognise chains (McDonald's, KFC, Nando's, Greggs, etc.)

RECOGNISE SNACKS AND DRINKS:
- Crisps, chocolate bars, biscuits, cakes, pastries
- Coffee drinks (latte/cappuccino/americano), smoothies, soft drinks
- Alcoholic drinks: beer, wine, spirits with mixers

## PACKAGING vs PLATED FOOD
- isPackaging = true: Product in original packaging with labels/branding visible
- isPackaging = false: Food on plate, in bowl, takeaway container, or being eaten

## CRITICAL - BREAK DOWN MEALS INTO COMPONENTS
For plated food, list EACH component SEPARATELY:
- "Sausage and mash" → "pork sausages", "mashed potato", "onion gravy"
- "Full English" → "bacon rashers", "fried eggs", "pork sausages", "baked beans", "toast", "grilled tomato", "mushrooms"
- "Roast dinner" → "roast chicken", "roast potatoes", "carrots", "peas", "gravy", "Yorkshire pudding"
- "Curry and rice" → "chicken tikka masala", "pilau rice", "naan bread"
- "Fish and chips" → "battered cod", "chips", "mushy peas" (if visible)

## PORTION SIZE GUIDELINES

PROTEINS (calibrated to palm/plate coverage):
- Chicken breast: small 120g, medium 165g, large 200g
- Chicken thigh (boneless): 80-100g each
- Steak: small 150g, medium 200g, large 280g
- Salmon fillet: 120-150g typical
- Pork sausage: 50-60g each
- Bacon rasher: 20-25g each
- Burger patty: 100g (fast food) to 150g (restaurant)
- Fried egg: 50g each

CARBOHYDRATES:
- Rice (cooked): small 120g, medium 180g, large 250g
- Chips: small 100g, medium 150g, large 200g
- Mashed potato: 150-200g serving
- Baked potato: medium 200g, large 300g
- Pasta (cooked): 180-250g restaurant portion
- Bread slice: 30-40g, burger bun: 50-60g
- Naan bread: 150-180g, chapati: 40g

VEGETABLES:
- Side portion: 80-100g
- Half plate of veg: 150g
- Side salad: 80-100g, large salad: 150-200g

SAUCES:
- Gravy: 50-80ml
- Curry sauce: 150-200g
- Pasta sauce: 100-150g

## NUTRITIONAL VALUES (per 100g UK)

PROTEINS:
- Grilled chicken breast: 165 kcal, 31g protein, 0g carbs, 4g fat
- Fried chicken breast: 220 kcal, 28g protein, 2g carbs, 11g fat
- Roast chicken with skin: 190 kcal, 25g protein, 0g carbs, 10g fat
- Sirloin steak: 160 kcal, 25g protein, 0g carbs, 7g fat
- Ribeye steak: 200 kcal, 23g protein, 0g carbs, 12g fat
- Grilled salmon: 200 kcal, 22g protein, 0g carbs, 12g fat
- Battered fish: 230 kcal, 15g protein, 12g carbs, 13g fat
- Pork sausage: 250 kcal, 12g protein, 3g carbs, 20g fat
- Bacon: 270 kcal, 25g protein, 0g carbs, 19g fat
- Beef mince (cooked): 210 kcal, 21g protein, 0g carbs, 14g fat

CARBOHYDRATES:
- White rice (boiled): 130 kcal, 3g protein, 28g carbs, 0.5g fat
- Egg fried rice: 180 kcal, 4g protein, 25g carbs, 7g fat
- Pilau rice: 145 kcal, 3g protein, 27g carbs, 3g fat
- Oven chips: 200 kcal, 3g protein, 30g carbs, 8g fat
- Deep-fried chips: 280 kcal, 3g protein, 35g carbs, 14g fat
- Mashed potato: 100 kcal, 2g protein, 15g carbs, 4g fat
- Roast potatoes: 150 kcal, 2g protein, 22g carbs, 6g fat
- Pasta (cooked): 130 kcal, 5g protein, 25g carbs, 1g fat
- Naan bread: 290 kcal, 9g protein, 50g carbs, 6g fat
- White bread: 245 kcal, 9g protein, 47g carbs, 3g fat

SAUCES:
- Gravy: 35 kcal, 1g protein, 4g carbs, 2g fat
- Tikka masala sauce: 120 kcal, 3g protein, 6g carbs, 9g fat
- Korma sauce: 150 kcal, 2g protein, 8g carbs, 12g fat
- Tomato pasta sauce: 45 kcal, 1g protein, 7g carbs, 1g fat
- Creamy pasta sauce: 120 kcal, 2g protein, 5g carbs, 10g fat

VEGETABLES:
- Mixed vegetables: 50 kcal, 2g protein, 8g carbs, 1g fat
- Roasted vegetables: 80 kcal, 2g protein, 10g carbs, 4g fat

## REALISTIC MEAL TOTALS
- Steak (200g) + chips (150g): 320 + 420 = 740 kcal
- Chicken breast + rice + veg: 270 + 260 + 50 = 580 kcal
- Fish and chips: 350 + 400 = 750 kcal
- Full English breakfast: 800-1000 kcal
- Curry + rice + naan: 350 + 320 + 480 = 1150 kcal
- Burger + bun + chips: 300 + 150 + 350 = 800 kcal

DO NOT estimate over 1000 kcal unless clearly large portions or high-calorie items.

## RESPONSE FORMAT
Respond with ONLY valid JSON (no markdown):
{
  "foods": [
    {
      "name": "specific food name with cooking method",
      "brand": "brand or null",
      "portionGrams": number,
      "searchTerms": ["term1", "term2", "term3"],
      "confidence": 0.0-1.0,
      "isPackaging": true/false,
      "estimatedCaloriesPer100g": number,
      "estimatedProteinPer100g": number,
      "estimatedCarbsPer100g": number,
      "estimatedFatPer100g": number
    }
  ]
}

If no food is visible, return: {"foods": []}`;
}
/**
 * Identify foods using Gemini 2.0 Flash (best balance of speed and accuracy)
 */
async function identifyFoodsWithGemini(base64Image, apiKey) {
    var _a, _b, _c, _d, _e;
    // Using gemini-2.0-flash for best multimodal performance
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
    const response = await axios_1.default.post(url, {
        contents: [{
                parts: [
                    { text: buildIdentificationPrompt() },
                    {
                        inline_data: {
                            mime_type: 'image/jpeg',
                            data: base64Image
                        }
                    }
                ]
            }],
        generationConfig: {
            temperature: 0.1, // Very low for consistent, accurate identification
            topP: 0.8,
            topK: 20,
            maxOutputTokens: 4096,
        }
    });
    const text = ((_e = (_d = (_c = (_b = (_a = response.data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '{"foods": []}';
    return parseGeminiResponse(text);
}
/**
 * Parse Gemini's identification response
 */
function parseGeminiResponse(responseText) {
    try {
        let cleanedText = responseText.trim();
        cleanedText = cleanedText.replace(/^```json\s*/i, '');
        cleanedText = cleanedText.replace(/^```\s*/i, '');
        cleanedText = cleanedText.replace(/\s*```$/i, '');
        cleanedText = cleanedText.trim();
        const parsed = JSON.parse(cleanedText);
        const foods = [];
        if (Array.isArray(parsed.foods)) {
            for (const item of parsed.foods) {
                if (typeof item.name === 'string' && item.name.length > 0) {
                    foods.push({
                        name: item.name,
                        brand: typeof item.brand === 'string' ? item.brand : null,
                        portionGrams: typeof item.portionGrams === 'number' && item.portionGrams > 0
                            ? Math.round(item.portionGrams)
                            : 100,
                        searchTerms: Array.isArray(item.searchTerms)
                            ? item.searchTerms.filter((t) => typeof t === 'string')
                            : [item.name],
                        confidence: typeof item.confidence === 'number'
                            ? Math.min(1, Math.max(0, item.confidence))
                            : 0.5,
                        isPackaging: item.isPackaging === true, // Default to false (plated food) if not specified
                        estimatedCaloriesPer100g: typeof item.estimatedCaloriesPer100g === 'number'
                            ? Math.max(0, item.estimatedCaloriesPer100g)
                            : 100,
                        estimatedProteinPer100g: typeof item.estimatedProteinPer100g === 'number'
                            ? Math.max(0, item.estimatedProteinPer100g)
                            : 5,
                        estimatedCarbsPer100g: typeof item.estimatedCarbsPer100g === 'number'
                            ? Math.max(0, item.estimatedCarbsPer100g)
                            : 10,
                        estimatedFatPer100g: typeof item.estimatedFatPer100g === 'number'
                            ? Math.max(0, item.estimatedFatPer100g)
                            : 5,
                    });
                }
            }
        }
        return foods;
    }
    catch (error) {
        console.error('Failed to parse Gemini response:', responseText, error);
        return [];
    }
}
/**
 * Search Algolia database for a food match
 */
async function searchDatabaseForFood(client, food) {
    // Build search queries from the identified food
    const searchQueries = [
        food.name, // Primary name
        ...(food.searchTerms || []), // Alternative terms
    ];
    // If brand is specified, try brand + name first
    if (food.brand) {
        searchQueries.unshift(`${food.brand} ${food.name}`);
    }
    // Try each search query across indices
    for (const query of searchQueries) {
        for (const indexName of SEARCH_INDICES) {
            try {
                const result = await client.searchSingleIndex({
                    indexName,
                    searchParams: {
                        query,
                        hitsPerPage: 3,
                        // Retrieve all attributes to handle different field naming conventions
                        // CSV imports may use different cases or spellings
                        attributesToRetrieve: ['*'],
                    },
                });
                if (result.hits && result.hits.length > 0) {
                    const hit = result.hits[0];
                    // Check if it's a reasonable match (basic validation)
                    const queryWords = query.toLowerCase().split(' ');
                    const hitName = hit.name.toLowerCase();
                    const matchScore = queryWords.filter(word => hitName.includes(word)).length / queryWords.length;
                    // Accept if at least 50% of query words match
                    if (matchScore >= 0.5) {
                        return hit;
                    }
                }
            }
            catch (error) {
                // Continue to next index if this one fails
                console.warn(`Search failed for "${query}" in ${indexName}:`, error);
            }
        }
    }
    return null;
}
//# sourceMappingURL=recognize-food.js.map