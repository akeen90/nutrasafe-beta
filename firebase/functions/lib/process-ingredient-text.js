"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processIngredientText = void 0;
const functions = require("firebase-functions");
const generative_ai_1 = require("@google/generative-ai");
const cors = require("cors");
const corsHandler = cors({ origin: true });
// Initialize Gemini AI using existing API key
const genAI = new generative_ai_1.GoogleGenerativeAI(functions.config().gemini.api_key);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
exports.processIngredientText = functions.https.onRequest(async (req, res) => {
    corsHandler(req, res, async () => {
        try {
            if (req.method !== 'POST') {
                res.status(405).json({ success: false, error: 'Method not allowed' });
                return;
            }
            const { textChunks, sessionId, scanType, finalProcess } = req.body;
            if (!textChunks || !Array.isArray(textChunks) || !sessionId) {
                res.status(400).json({
                    success: false,
                    error: 'Missing required fields: textChunks (array), sessionId'
                });
                return;
            }
            // Combine all text chunks
            const combinedText = textChunks.join(' ').trim();
            if (!combinedText) {
                res.json({
                    success: true,
                    processedText: '',
                    confidence: 0,
                    sessionId
                });
                return;
            }
            // Process with Gemini based on scan type
            let prompt;
            if (scanType === 'ingredients') {
                prompt = createIngredientsPrompt(combinedText, finalProcess);
            }
            else {
                prompt = createNutritionPrompt(combinedText, finalProcess);
            }
            // Generate content using Gemini API
            const result = await model.generateContent(prompt);
            const response = await result.response;
            const text = response.text();
            // Parse the structured response from Gemini
            const structuredData = parseGeminiResponse(text, scanType);
            const processResponse = {
                success: true,
                processedText: text,
                structuredData,
                confidence: 0.95, // Gemini provides high-quality processing
                sessionId
            };
            res.json(processResponse);
        }
        catch (error) {
            console.error('Gemini processing error:', error);
            res.status(500).json({
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error occurred',
                sessionId: req.body.sessionId || 'unknown'
            });
        }
    });
});
function createIngredientsPrompt(text, finalProcess) {
    const basePrompt = `
You are an expert food ingredient analyst. Your task is to extract and structure ingredient information from OCR text that may contain errors or be incomplete.

Input text: "${text}"

Please analyze this text and provide:
1. A cleaned list of ingredients in order
2. Identification of any allergens (nuts, dairy, gluten, etc.)
3. Identification of any additives (E-numbers, preservatives, etc.)
4. Confidence assessment of the extraction

${finalProcess ?
        'This is the FINAL processing - provide the most complete and accurate analysis possible.' :
        'This is intermediate processing - focus on identifying clear ingredients and note any incomplete sections.'}

Return your response in this JSON format:
{
  "ingredients": ["ingredient1", "ingredient2", ...],
  "allergens": ["allergen1", "allergen2", ...],
  "additives": ["additive1", "additive2", ...],
  "confidence": 0.XX,
  "notes": "Any observations about text quality or missing information"
}

Focus on accuracy over completeness. If text is unclear, note it in the response.`;
    return basePrompt;
}
function createNutritionPrompt(text, finalProcess) {
    const basePrompt = `
You are an expert nutritional information analyst. Your task is to extract and structure nutrition facts from OCR text that may contain errors or be incomplete.

Input text: "${text}"

Please analyze this text and provide:
1. Nutritional values with units (per 100g where possible)
2. Serving size information
3. Energy values (calories/kJ)
4. Macronutrients (protein, carbs, fat, fiber, sugar, sodium)
5. Any micronutrients mentioned

${finalProcess ?
        'This is the FINAL processing - provide the most complete nutritional analysis possible.' :
        'This is intermediate processing - extract clear nutritional values and note incomplete sections.'}

Return your response in this JSON format:
{
  "nutrition": {
    "energy": {"value": XXX, "unit": "kcal", "per100g": XXX},
    "protein": {"value": XXX, "unit": "g", "per100g": XXX},
    "carbohydrates": {"value": XXX, "unit": "g", "per100g": XXX},
    "fat": {"value": XXX, "unit": "g", "per100g": XXX},
    "fiber": {"value": XXX, "unit": "g", "per100g": XXX},
    "sugar": {"value": XXX, "unit": "g", "per100g": XXX},
    "sodium": {"value": XXX, "unit": "mg", "per100g": XXX}
  },
  "servingSize": "XXXg",
  "confidence": 0.XX,
  "notes": "Any observations about data quality or missing values"
}

Focus on accuracy and convert all values to per-100g equivalents where possible.`;
    return basePrompt;
}
function parseGeminiResponse(text, scanType) {
    try {
        // Try to extract JSON from the response
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        // If no JSON found, create structured data from text
        if (scanType === 'ingredients') {
            return parseIngredientsFromText(text);
        }
        else {
            return parseNutritionFromText(text);
        }
    }
    catch (error) {
        console.error('Error parsing Gemini response:', error);
        return { error: 'Failed to parse response', rawText: text };
    }
}
function parseIngredientsFromText(text) {
    // Fallback parsing for non-JSON responses
    const lines = text.split('\n');
    const ingredients = [];
    const allergens = [];
    const additives = [];
    for (const line of lines) {
        const lowerLine = line.toLowerCase();
        if (lowerLine.includes('ingredient')) {
            const match = line.match(/ingredients?:?\s*(.+)/i);
            if (match) {
                ingredients.push(...match[1].split(',').map(i => i.trim()));
            }
        }
        else if (lowerLine.includes('allergen')) {
            const match = line.match(/allergens?:?\s*(.+)/i);
            if (match) {
                allergens.push(...match[1].split(',').map(a => a.trim()));
            }
        }
        else if (lowerLine.includes('additive') || lowerLine.includes('e-')) {
            additives.push(line.trim());
        }
    }
    return { ingredients, allergens, additives, confidence: 0.8 };
}
function parseNutritionFromText(text) {
    // Fallback parsing for nutrition text
    const nutrition = {};
    const lines = text.split('\n');
    const nutritionMapping = {
        'energy': ['calories', 'kcal', 'energy', 'cal'],
        'protein': ['protein'],
        'carbohydrates': ['carbohydrate', 'carbs', 'carb'],
        'fat': ['fat', 'total fat'],
        'fiber': ['fiber', 'fibre', 'dietary fiber'],
        'sugar': ['sugar', 'sugars', 'total sugar'],
        'sodium': ['sodium', 'salt']
    };
    for (const line of lines) {
        for (const [nutrient, keywords] of Object.entries(nutritionMapping)) {
            for (const keyword of keywords) {
                if (line.toLowerCase().includes(keyword)) {
                    const match = line.match(/(\d+(?:\.\d+)?)\s*([a-z]+)/i);
                    if (match) {
                        nutrition[nutrient] = {
                            value: parseFloat(match[1]),
                            unit: match[2],
                            per100g: parseFloat(match[1]) // Assume per 100g for now
                        };
                    }
                }
            }
        }
    }
    return { nutrition, confidence: 0.8 };
}
//# sourceMappingURL=process-ingredient-text.js.map