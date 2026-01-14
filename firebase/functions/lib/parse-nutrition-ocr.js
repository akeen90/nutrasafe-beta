"use strict";
/**
 * AI-Powered Nutrition Label OCR Parser
 *
 * Uses Google Gemini to intelligently extract nutrition values from OCR text,
 * handling varied label formats, multi-column layouts, and OCR errors
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseNutritionOCRCached = exports.parseNutritionOCR = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
// Define the Gemini API key as a secret
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
/**
 * Cloud Function: Parse nutrition label OCR text using AI
 */
exports.parseNutritionOCR = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 30,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ocrText, preferPer100g = true } = request.data;
    if (!ocrText || ocrText.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'ocrText must be provided');
    }
    try {
        const prompt = buildNutritionExtractionPrompt(ocrText, preferPer100g);
        const result = await callGeminiAPI(prompt, geminiApiKey.value());
        console.log(`✅ Extracted nutrition data with ${result.confidence * 100}% confidence`);
        return result;
    }
    catch (error) {
        console.error('❌ AI nutrition OCR parsing failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to parse nutrition label', { originalError: String(error) });
    }
});
/**
 * Cached version with Firestore caching
 */
exports.parseNutritionOCRCached = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 30,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ocrText, preferPer100g = true } = request.data;
    if (!ocrText || ocrText.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'ocrText must be provided');
    }
    const crypto = require('crypto');
    const cacheKey = crypto.createHash('md5').update(ocrText.toLowerCase()).digest('hex');
    try {
        const admin = require('firebase-admin');
        const db = admin.firestore();
        const cacheRef = db.collection('nutrition_ocr_cache').doc(cacheKey);
        const cacheDoc = await cacheRef.get();
        // Check cache (valid for 7 days)
        if (cacheDoc.exists) {
            const cachedData = cacheDoc.data();
            const cacheAge = Date.now() - cachedData.timestamp;
            if (cacheAge < 7 * 24 * 60 * 60 * 1000) {
                console.log('✅ Using cached nutrition OCR data');
                return Object.assign(Object.assign({}, cachedData.result), { cached: true });
            }
        }
        const prompt = buildNutritionExtractionPrompt(ocrText, preferPer100g);
        const result = await callGeminiAPI(prompt, geminiApiKey.value());
        // Cache the result
        await cacheRef.set({
            result,
            timestamp: Date.now(),
            ocrText: ocrText.substring(0, 500), // Store truncated for reference
        });
        console.log(`✅ Extracted nutrition data (cached for future)`);
        return Object.assign(Object.assign({}, result), { cached: false });
    }
    catch (error) {
        console.error('❌ AI nutrition OCR parsing failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to parse nutrition label', { originalError: String(error) });
    }
});
function buildNutritionExtractionPrompt(ocrText, preferPer100g) {
    return `
You are a nutrition label expert AI. Extract nutrition values from this OCR text of a UK/EU food label.

OCR TEXT:
${ocrText}

INSTRUCTIONS:
1. UK/EU labels typically show "per 100g" or "per 100ml" AND "per serving" columns
2. ${preferPer100g ? 'PREFER extracting "per 100g" or "per 100ml" values' : 'PREFER extracting "per serving" values'}
3. Handle common OCR errors:
   - "0" misread as "O" or "o"
   - "1" misread as "l" or "I"
   - Missing decimal points
   - Merged/split words
4. Convert units consistently:
   - Energy: return kcal (convert from kJ if needed: kJ ÷ 4.184 = kcal)
   - Salt: return grams (convert from sodium mg if needed: sodium mg × 2.5 ÷ 1000 = salt g)
   - All macros: return grams
5. Set confidence based on OCR quality and how clearly values were found

CRITICAL: SERVING SIZE vs PACK SIZE - DO NOT CONFUSE THESE:

SERVING SIZE (what we want for servingSize field):
- The RECOMMENDED PORTION someone would eat in one sitting
- Look for: "per serving", "serving size", "1 portion", "per slice", "per biscuit", "each (Xg)"
- Typical ranges: 15-100g for snacks/cereals, 100-250g for meals, 150-330ml for drinks
- Examples: "per 30g serving", "serving size: 40g", "1 portion = 25g", "per biscuit (12.5g)"

PACK SIZE (IGNORE - do NOT use as servingSize):
- The TOTAL WEIGHT of the entire product/package
- Look for: "Net weight", "Net contents", "Pack size", "e" symbol (estimated weight)
- Usually printed on front of pack or near barcode
- Examples: "Net weight: 500g", "400g e", "Contents: 6x40g bars", "750ml"

SANITY CHECK for servingSize:
- If servingSize > 200g for a snack/cereal/chocolate, it's probably the PACK size - reject it
- If servingSize matches "Net weight" or appears on front of pack, it's PACK size - reject it
- If nutrition table header says "per Xg" where X is large (300+), that's likely pack size
- When in doubt, look for the SMALLER number that appears in "per serving" context

VALID NUTRIENT KEYS:
- calories (kcal)
- protein (g)
- carbohydrates (g) - total carbs
- fat (g) - total fat
- fiber OR fibre (g)
- sugar (g) - "of which sugars"
- salt (g)
- saturatedFat (g) - "of which saturates"
- servingSize (number only, e.g., 30 for "30g")
- servingUnit (g, ml, or serving)
- servingsPerContainer (if present)

OUTPUT FORMAT (JSON only):
{
  "calories": 250,
  "protein": 8.5,
  "carbohydrates": 35.2,
  "fat": 9.1,
  "fiber": 2.3,
  "sugar": 12.0,
  "salt": 1.2,
  "saturatedFat": 3.5,
  "servingSize": 100,
  "servingUnit": "g",
  "isPerServing": false,
  "confidence": 0.92,
  "warnings": ["Sugar value unclear - estimated from context"]
}

IMPORTANT:
- Return ONLY the JSON object
- Omit fields if not found (don't include null values)
- confidence should be 0.0-1.0 based on OCR quality
- Add warnings array for any values that were estimated or unclear
- If values seem unrealistic (e.g., >1000 kcal per 100g), flag in warnings

Return ONLY the JSON. No explanations, no markdown.
`.trim();
}
async function callGeminiAPI(prompt, apiKey) {
    var _a, _b, _c, _d, _e;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`;
    const response = await axios_1.default.post(url, {
        contents: [{
                parts: [{ text: prompt }]
            }],
        generationConfig: {
            temperature: 0.1, // Low temperature for precise extraction
            topP: 0.8,
            topK: 20,
            maxOutputTokens: 1024,
        }
    });
    const text = ((_e = (_d = (_c = (_b = (_a = response.data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '{}';
    return parseAIResponse(text);
}
function parseAIResponse(responseText) {
    var _a;
    try {
        let cleanedText = responseText.trim();
        // Remove markdown code blocks if present
        cleanedText = cleanedText.replace(/^```json\s*/i, '');
        cleanedText = cleanedText.replace(/^```\s*/i, '');
        cleanedText = cleanedText.replace(/\s*```$/i, '');
        cleanedText = cleanedText.trim();
        const parsed = JSON.parse(cleanedText);
        // Validate and normalize the response
        const result = {
            isPerServing: (_a = parsed.isPerServing) !== null && _a !== void 0 ? _a : false,
            confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
        };
        // Extract numeric values with validation
        if (typeof parsed.calories === 'number' && parsed.calories >= 0 && parsed.calories <= 2000) {
            result.calories = parsed.calories;
        }
        if (typeof parsed.protein === 'number' && parsed.protein >= 0 && parsed.protein <= 100) {
            result.protein = parsed.protein;
        }
        if (typeof parsed.carbohydrates === 'number' && parsed.carbohydrates >= 0 && parsed.carbohydrates <= 100) {
            result.carbohydrates = parsed.carbohydrates;
        }
        if (typeof parsed.fat === 'number' && parsed.fat >= 0 && parsed.fat <= 100) {
            result.fat = parsed.fat;
        }
        if (typeof parsed.fiber === 'number' && parsed.fiber >= 0 && parsed.fiber <= 50) {
            result.fiber = parsed.fiber;
        }
        if (typeof parsed.sugar === 'number' && parsed.sugar >= 0 && parsed.sugar <= 100) {
            result.sugar = parsed.sugar;
        }
        if (typeof parsed.salt === 'number' && parsed.salt >= 0 && parsed.salt <= 20) {
            result.salt = parsed.salt;
        }
        if (typeof parsed.saturatedFat === 'number' && parsed.saturatedFat >= 0 && parsed.saturatedFat <= 50) {
            result.saturatedFat = parsed.saturatedFat;
        }
        // Validate serving size - reject values that look like pack sizes
        if (typeof parsed.servingSize === 'number' && parsed.servingSize > 0) {
            // Sanity check: typical serving sizes are 15-250g, anything > 300g is likely pack size
            if (parsed.servingSize <= 300) {
                result.servingSize = parsed.servingSize;
            }
            else {
                // Add warning that we rejected a suspicious serving size
                if (!result.warnings)
                    result.warnings = [];
                result.warnings.push(`Rejected suspicious serving size (${parsed.servingSize}g) - likely pack size`);
            }
        }
        if (typeof parsed.servingUnit === 'string') {
            result.servingUnit = parsed.servingUnit;
        }
        if (typeof parsed.servingsPerContainer === 'number') {
            result.servingsPerContainer = parsed.servingsPerContainer;
        }
        if (Array.isArray(parsed.warnings)) {
            result.warnings = parsed.warnings.filter((w) => typeof w === 'string');
        }
        return result;
    }
    catch (error) {
        console.error('❌ Failed to parse AI response:', error, 'Response:', responseText);
        return {
            isPerServing: false,
            confidence: 0,
            warnings: ['Failed to parse nutrition data from OCR text'],
        };
    }
}
//# sourceMappingURL=parse-nutrition-ocr.js.map