"use strict";
/**
 * AI-Powered Micronutrient Extraction
 *
 * Uses Google Gemini REST API (no SDK) to intelligently extract vitamins and minerals
 * from complex ingredient lists, especially fortified foods
 *
 * Part of Phase 2 of the Hybrid Micronutrient Detection System
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseMicronutrientsWithAICached = exports.parseMicronutrientsWithAI = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
// Define the Gemini API key as a secret
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
/**
 * Cloud Function: Parse ingredients using AI to extract micronutrients
 */
exports.parseMicronutrientsWithAI = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ingredientsText, ingredientsArray } = request.data;
    if (!ingredientsText && !ingredientsArray) {
        throw new https_1.HttpsError('invalid-argument', 'Either ingredientsText or ingredientsArray must be provided');
    }
    const textToAnalyze = ingredientsText || (ingredientsArray || []).join(', ');
    if (textToAnalyze.length === 0) {
        return { nutrients: [], cached: false };
    }
    try {
        const prompt = buildMicronutrientExtractionPrompt(textToAnalyze);
        const nutrients = await callGeminiAPI(prompt, geminiApiKey.value());
        console.log(`✅ Extracted ${nutrients.length} micronutrients via AI`);
        return { nutrients, cached: false };
    }
    catch (error) {
        console.error('❌ AI micronutrient extraction failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to extract micronutrients using AI', { originalError: String(error) });
    }
});
/**
 * Cached version with Firestore caching
 */
exports.parseMicronutrientsWithAICached = (0, https_1.onCall)({
    cors: true,
    timeoutSeconds: 60,
    memory: '512MiB',
    secrets: [geminiApiKey],
}, async (request) => {
    const { ingredientsText, ingredientsArray } = request.data;
    if (!ingredientsText && !ingredientsArray) {
        throw new https_1.HttpsError('invalid-argument', 'Either ingredientsText or ingredientsArray must be provided');
    }
    const textToAnalyze = ingredientsText || (ingredientsArray || []).join(', ');
    if (textToAnalyze.length === 0) {
        return { nutrients: [], cached: false };
    }
    const crypto = require('crypto');
    const cacheKey = crypto.createHash('md5').update(textToAnalyze.toLowerCase()).digest('hex');
    try {
        const admin = require('firebase-admin');
        const db = admin.firestore();
        const cacheRef = db.collection('micronutrient_cache').doc(cacheKey);
        const cacheDoc = await cacheRef.get();
        if (cacheDoc.exists) {
            const cachedData = cacheDoc.data();
            const cacheAge = Date.now() - cachedData.timestamp;
            if (cacheAge < 30 * 24 * 60 * 60 * 1000) {
                console.log('✅ Using cached micronutrient data');
                return {
                    nutrients: cachedData.nutrients,
                    cached: true,
                    cacheAge: Math.floor(cacheAge / (24 * 60 * 60 * 1000)),
                };
            }
        }
        const prompt = buildMicronutrientExtractionPrompt(textToAnalyze);
        const nutrients = await callGeminiAPI(prompt, geminiApiKey.value());
        await cacheRef.set({
            nutrients,
            timestamp: Date.now(),
            ingredientsText: textToAnalyze,
        });
        console.log(`✅ Extracted ${nutrients.length} micronutrients via AI (cached for future)`);
        return { nutrients, cached: false };
    }
    catch (error) {
        console.error('❌ AI micronutrient extraction failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to extract micronutrients using AI', { originalError: String(error) });
    }
});
function buildMicronutrientExtractionPrompt(ingredientsText) {
    return `
You are a nutrition expert AI. Extract ALL vitamins and minerals from the following ingredient list.

INGREDIENTS:
${ingredientsText}

INSTRUCTIONS:
1. Identify every vitamin and mineral mentioned (including fortified nutrients)
2. Classify strength as:
   - "strong": Explicitly fortified OR primary ingredient
   - "moderate": Secondary ingredient OR moderate natural source
   - "trace": Minor ingredient OR trace amounts
3. Use standardized nutrient IDs:
   - Vitamins: vitamin_a, vitamin_b1, vitamin_b2, vitamin_b3, vitamin_b5, vitamin_b6, vitamin_b7, vitamin_b9, vitamin_b12, vitamin_c, vitamin_d, vitamin_e, vitamin_k
   - Minerals: calcium, iron, magnesium, zinc, potassium, iodine, selenium, phosphorus, copper, manganese, chromium, molybdenum, sodium
   - Others: omega_3, lutein, lycopene, choline
4. Include confidence score (0.0-1.0)
5. ONLY include nutrients with confidence ≥ 0.80
6. IGNORE macronutrients (protein, fat, carbohydrates, sugar, fiber)

OUTPUT FORMAT (JSON only):
[
  {"nutrient": "vitamin_c", "strength": "strong", "source": "l-ascorbic acid", "confidence": 0.98},
  {"nutrient": "calcium", "strength": "strong", "source": "calcium carbonate", "confidence": 0.95}
]

Return ONLY the JSON array. No explanations, no markdown.
`.trim();
}
async function callGeminiAPI(prompt, apiKey) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`;
    const response = await axios_1.default.post(url, {
        contents: [{
                parts: [{ text: prompt }]
            }],
        generationConfig: {
            temperature: 0.1,
            topP: 0.8,
            topK: 20,
            maxOutputTokens: 2048,
        }
    });
    const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text || '[]';
    return parseAIResponse(text);
}
function parseAIResponse(responseText) {
    try {
        let cleanedText = responseText.trim();
        cleanedText = cleanedText.replace(/^```json\s*/i, '');
        cleanedText = cleanedText.replace(/^```\s*/i, '');
        cleanedText = cleanedText.replace(/\s*```$/i, '');
        cleanedText = cleanedText.trim();
        const parsed = JSON.parse(cleanedText);
        if (!Array.isArray(parsed)) {
            console.error('❌ AI response is not an array:', parsed);
            return [];
        }
        return parsed
            .filter((item) => item.nutrient && item.strength && item.source && typeof item.confidence === 'number' && item.confidence >= 0.80)
            .map((item) => ({
            nutrient: String(item.nutrient).toLowerCase(),
            strength: item.strength,
            source: String(item.source),
            confidence: Number(item.confidence),
        }));
    }
    catch (error) {
        console.error('❌ Failed to parse AI response:', error);
        return [];
    }
}
//# sourceMappingURL=parse-micronutrients-ai.js.map