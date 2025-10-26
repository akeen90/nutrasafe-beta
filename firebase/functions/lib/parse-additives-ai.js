"use strict";
/**
 * AI-Powered Additive Detection
 *
 * Uses Google Gemini REST API (no SDK) to intelligently extract food additives
 * from ingredient lists, including those without E-numbers
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseAdditivesWithAICached = exports.parseAdditivesWithAI = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
exports.parseAdditivesWithAI = (0, https_1.onCall)({
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
        return { additives: [], cached: false };
    }
    try {
        const prompt = buildAdditiveExtractionPrompt(textToAnalyze);
        const additives = await callGeminiAPI(prompt, geminiApiKey.value());
        console.log(`✅ Extracted ${additives.length} additives via AI`);
        return { additives, cached: false };
    }
    catch (error) {
        console.error('❌ AI additive extraction failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to extract additives using AI', { originalError: String(error) });
    }
});
exports.parseAdditivesWithAICached = (0, https_1.onCall)({
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
        return { additives: [], cached: false };
    }
    const crypto = require('crypto');
    const cacheKey = crypto.createHash('md5').update(textToAnalyze.toLowerCase()).digest('hex');
    try {
        const admin = require('firebase-admin');
        const db = admin.firestore();
        const cacheRef = db.collection('additive_cache').doc(cacheKey);
        const cacheDoc = await cacheRef.get();
        if (cacheDoc.exists) {
            const cachedData = cacheDoc.data();
            const cacheAge = Date.now() - cachedData.timestamp;
            if (cacheAge < 30 * 24 * 60 * 60 * 1000) {
                console.log('✅ Using cached additive data');
                return {
                    additives: cachedData.additives,
                    cached: true,
                    cacheAge: Math.floor(cacheAge / (24 * 60 * 60 * 1000)),
                };
            }
        }
        const prompt = buildAdditiveExtractionPrompt(textToAnalyze);
        const additives = await callGeminiAPI(prompt, geminiApiKey.value());
        await cacheRef.set({
            additives,
            timestamp: Date.now(),
            ingredientsText: textToAnalyze,
        });
        console.log(`✅ Extracted ${additives.length} additives via AI (cached for future)`);
        return { additives, cached: false };
    }
    catch (error) {
        console.error('❌ AI additive extraction failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to extract additives using AI', { originalError: String(error) });
    }
});
function buildAdditiveExtractionPrompt(ingredientsText) {
    return `
You are a food safety expert AI. Extract ALL food additives from the following ingredient list.

INGREDIENTS:
${ingredientsText}

INSTRUCTIONS:
1. Identify every additive, preservative, color, sweetener, emulsifier, stabilizer, thickener, and flavor enhancer
2. Include BOTH E-numbered additives AND non-numbered additives (maltodextrin, lecithin, natural flavourings, etc.)
3. For E-numbered additives, use the official E-number. For non-E-numbered, use "MISC"
4. Classify safety as: "safe", "neutral", "caution", or "avoid"
5. Categorize as: colour, preservative, antioxidant, emulsifier, stabilizer, thickener, sweetener, flavor_enhancer, or other
6. IGNORE vitamins and minerals (they're nutrients, not additives)
7. Include confidence score (0.0-1.0), ONLY include if confidence ≥ 0.75

OUTPUT FORMAT (JSON only):
[
  {"name": "Sucralose", "eNumber": "E955", "category": "sweetener", "safety": "caution", "confidence": 0.98},
  {"name": "Maltodextrin", "eNumber": "MISC", "category": "thickener", "safety": "caution", "confidence": 0.95}
]

Return ONLY the JSON array. No explanations, no markdown.
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
            temperature: 0.1,
            topP: 0.8,
            topK: 20,
            maxOutputTokens: 2048,
        }
    });
    const text = ((_e = (_d = (_c = (_b = (_a = response.data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '[]';
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
            .filter((item) => item.name && item.eNumber && item.category && item.safety && typeof item.confidence === 'number' && item.confidence >= 0.75)
            .map((item) => ({
            name: String(item.name),
            eNumber: String(item.eNumber).toUpperCase(),
            category: String(item.category).toLowerCase(),
            safety: item.safety,
            confidence: Number(item.confidence),
        }));
    }
    catch (error) {
        console.error('❌ Failed to parse AI response:', error);
        return [];
    }
}
//# sourceMappingURL=parse-additives-ai.js.map