"use strict";
/**
 * AI-Powered Ingredients Label OCR Parser
 *
 * Uses Google Gemini to intelligently extract and clean ingredients from OCR text,
 * handling varied label formats, wrapped text, addresses, and OCR errors
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseIngredientsOCRCached = exports.parseIngredientsOCR = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
// Define the Gemini API key as a secret
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
/**
 * Cloud Function: Parse ingredients label OCR text using AI
 */
exports.parseIngredientsOCR = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 30,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ocrText, productName, brand } = request.data;
    if (!ocrText || ocrText.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'ocrText must be provided');
    }
    try {
        const prompt = buildIngredientsExtractionPrompt(ocrText, productName, brand);
        const result = await callGeminiAPI(prompt, geminiApiKey.value());
        console.log(`✅ Extracted ${result.ingredients.length} ingredients with ${result.confidence * 100}% confidence`);
        return result;
    }
    catch (error) {
        console.error('❌ AI ingredients OCR parsing failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to parse ingredients label', { originalError: String(error) });
    }
});
/**
 * Cached version with Firestore caching
 */
exports.parseIngredientsOCRCached = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 30,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ocrText, productName, brand } = request.data;
    if (!ocrText || ocrText.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'ocrText must be provided');
    }
    const crypto = require('crypto');
    const cacheKey = crypto.createHash('md5').update(ocrText.toLowerCase()).digest('hex');
    try {
        const admin = require('firebase-admin');
        const db = admin.firestore();
        const cacheRef = db.collection('ingredients_ocr_cache').doc(cacheKey);
        const cacheDoc = await cacheRef.get();
        // Check cache (valid for 7 days)
        if (cacheDoc.exists) {
            const cachedData = cacheDoc.data();
            const cacheAge = Date.now() - cachedData.timestamp;
            if (cacheAge < 7 * 24 * 60 * 60 * 1000) {
                console.log('✅ Using cached ingredients OCR data');
                return Object.assign(Object.assign({}, cachedData.result), { cached: true });
            }
        }
        const prompt = buildIngredientsExtractionPrompt(ocrText, productName, brand);
        const result = await callGeminiAPI(prompt, geminiApiKey.value());
        // Cache the result
        await cacheRef.set({
            result,
            timestamp: Date.now(),
            ocrText: ocrText.substring(0, 500), // Store truncated for reference
        });
        console.log(`✅ Extracted ingredients (cached for future)`);
        return Object.assign(Object.assign({}, result), { cached: false });
    }
    catch (error) {
        console.error('❌ AI ingredients OCR parsing failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to parse ingredients label', { originalError: String(error) });
    }
});
function buildIngredientsExtractionPrompt(ocrText, productName, brand) {
    const context = productName ? `Product: ${brand ? brand + ' ' : ''}${productName}` : '';
    return `
You are a UK food label expert AI. Extract the ingredients list from this OCR text of a food product label.

${context ? `CONTEXT: ${context}` : ''}

OCR TEXT:
${ocrText}

INSTRUCTIONS:
1. Extract ONLY the ingredients list - ignore everything else
2. REMOVE these non-ingredient items:
   - Company names, addresses, postcodes (e.g., "London SW1A 1AA", "Ltd", "Company Name")
   - Phone numbers, websites, email addresses
   - Storage instructions ("Store in a cool dry place")
   - Best before/use by dates
   - Batch codes, barcodes
   - Nutrition information
   - "Produced in", "Manufactured by", "Distributed by" statements
   - Weight/volume information
3. Handle OCR errors intelligently:
   - "0" misread as "O" in ingredients context
   - "1" misread as "l" or "I"
   - Split/merged words
4. Normalize ingredients:
   - Use UK spelling (colour not color, flavour not flavor)
   - Capitalize first letter of each ingredient
   - Keep E-numbers in format "E621" (uppercase E)
   - Expand abbreviations (vit. → Vitamin)
5. Extract allergens mentioned (wheat, milk, eggs, nuts, soya, etc.)
6. Find "May contain" or "Contains" statements if present

OUTPUT FORMAT (JSON only):
{
  "ingredients": ["Water", "Sugar", "Wheat Flour", "E621"],
  "ingredientsText": "Water, Sugar, Wheat Flour, E621",
  "allergens": ["Wheat", "Milk"],
  "containsStatement": "May contain traces of nuts",
  "confidence": 0.92,
  "warnings": ["Some text was unclear"]
}

IMPORTANT:
- Return ONLY the JSON object
- ingredients should be an array of individual ingredients
- ingredientsText should be comma-separated string
- allergens should be standardized (Wheat not WHEAT, Milk not MILK)
- Omit containsStatement if not found
- confidence 0.0-1.0 based on OCR quality
- Add warnings for any issues encountered

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
            maxOutputTokens: 2048,
        }
    });
    const text = ((_e = (_d = (_c = (_b = (_a = response.data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '{}';
    return parseAIResponse(text);
}
function parseAIResponse(responseText) {
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
            ingredients: [],
            ingredientsText: '',
            allergens: [],
            confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
        };
        // Extract ingredients array
        if (Array.isArray(parsed.ingredients)) {
            result.ingredients = parsed.ingredients
                .filter((i) => typeof i === 'string' && i.trim().length > 0)
                .map((i) => i.trim());
        }
        // Generate ingredientsText from array if not provided
        if (typeof parsed.ingredientsText === 'string' && parsed.ingredientsText.trim()) {
            result.ingredientsText = parsed.ingredientsText.trim();
        }
        else if (result.ingredients.length > 0) {
            result.ingredientsText = result.ingredients.join(', ');
        }
        // Extract allergens
        if (Array.isArray(parsed.allergens)) {
            result.allergens = parsed.allergens
                .filter((a) => typeof a === 'string' && a.trim().length > 0)
                .map((a) => a.trim());
        }
        // Extract contains statement
        if (typeof parsed.containsStatement === 'string' && parsed.containsStatement.trim()) {
            result.containsStatement = parsed.containsStatement.trim();
        }
        // Extract warnings
        if (Array.isArray(parsed.warnings)) {
            result.warnings = parsed.warnings.filter((w) => typeof w === 'string');
        }
        return result;
    }
    catch (error) {
        console.error('❌ Failed to parse AI response:', error, 'Response:', responseText);
        return {
            ingredients: [],
            ingredientsText: '',
            allergens: [],
            confidence: 0,
            warnings: ['Failed to parse ingredients from OCR text'],
        };
    }
}
//# sourceMappingURL=parse-ingredients-ocr.js.map