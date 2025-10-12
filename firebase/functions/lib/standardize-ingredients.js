"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.standardizeIngredients = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
exports.standardizeIngredients = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    try {
        const { ingredients } = data;
        if (!ingredients || ingredients.length === 0) {
            return {
                success: true,
                standardizedIngredients: []
            };
        }
        console.log(`🧠 Standardizing ${ingredients.length} ingredients with Gemini`);
        // Get Gemini API key
        const geminiApiKey = (_a = functions.config().gemini) === null || _a === void 0 ? void 0 : _a.api_key;
        if (!geminiApiKey) {
            throw new functions.https.HttpsError('failed-precondition', 'Gemini API key not configured');
        }
        // Create intelligent prompt for ingredient standardization
        const ingredientsList = ingredients.join('\n- ');
        const prompt = `You are an expert food ingredient standardizer. Analyze this list of ingredients and return ONLY the actual food ingredients that someone might have a reaction to. Apply these rules strictly:

REMOVE COMPLETELY:
- Vitamins and minerals (iron, calcium, niacin, thiamin, vitamin B, etc.)
- Fortifications and enrichments
- E-numbers and food additives (unless they're allergen-related like E160c which contains milk)
- Processing aids
- Allergen warning fragments ("including cereals containing gluten", "may contain", "for allergens see")
- Storage instructions ("refrigerate", "best before", "defrost", etc.)
- Cooking instructions ("pre-heat", "cooking", "prepare", etc.)
- Marketing text and brand names
- Nutritional information text
- Generic statements like "see ingredients in bold"

STANDARDIZE:
- Remove percentages and quantities: "wheat flour (50%)" → "wheat flour"
- Remove parenthetical clarifications: "wheat flour (wheat flour)" → "wheat flour"
- Simplify compound ingredients: "beef stock (yeast extract)" → "beef stock, yeast extract"
- Remove redundant modifiers: "concentrated grape must" → "grape must"
- Standardize names to common form: "rapeseed oil" → "rapeseed oil" (keep it)
- Keep sub-ingredients separate: "butter (milk)" → "butter, milk"

KEEP ONLY TRUE INGREDIENTS:
- Base ingredients (flour, sugar, salt, etc.)
- Allergens (nuts, milk, eggs, soy, sesame, gluten sources)
- Proteins (chicken, beef, fish, etc.)
- Oils and fats
- Vegetables and fruits
- Spices and herbs
- Sweeteners (sugar, molasses, etc.)

INPUT INGREDIENTS:
- ${ingredientsList}

OUTPUT INSTRUCTIONS:
- Return ONLY a comma-separated list of standardized ingredient names
- Use lowercase
- Keep ingredients that could cause allergic reactions
- Remove duplicates
- Sort roughly by importance (common allergens first)
- If all ingredients should be removed, return "NONE"

Example transformation:
Input: "wheat flour (wheat flour), calcium carbonate, iron, niacin, thiamin, including cereals containing gluten, nuts, sesame"
Output: "wheat flour, nuts, sesame"`;
        const geminiRequest = {
            contents: [{
                    parts: [{
                            text: prompt
                        }]
                }],
            generationConfig: {
                temperature: 0.1,
                maxOutputTokens: 500
            }
        };
        console.log('🔍 Sending standardization request to Gemini...');
        const geminiResponse = await axios_1.default.post(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${geminiApiKey}`, geminiRequest, {
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 15000
        });
        const standardizedText = (_h = (_g = (_f = (_e = (_d = (_c = (_b = geminiResponse.data) === null || _b === void 0 ? void 0 : _b.candidates) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.content) === null || _e === void 0 ? void 0 : _e.parts) === null || _f === void 0 ? void 0 : _f[0]) === null || _g === void 0 ? void 0 : _g.text) === null || _h === void 0 ? void 0 : _h.trim();
        if (!standardizedText || standardizedText === 'NONE') {
            console.log('ℹ️ No valid ingredients after standardization');
            return {
                success: true,
                standardizedIngredients: []
            };
        }
        console.log(`✅ Gemini standardized: ${standardizedText}`);
        // Parse into clean array
        const standardizedArray = standardizedText
            .split(',')
            .map((ing) => ing.trim().toLowerCase())
            .filter((ing) => {
            // Final cleanup - remove any that slipped through
            if (ing.length < 2)
                return false;
            if (ing.includes('none'))
                return false;
            if (ing.match(/\d+%/))
                return false; // Still has percentages
            if (ing.includes(':'))
                return false; // Still has labels
            return true;
        });
        // Remove exact duplicates
        const uniqueIngredients = Array.from(new Set(standardizedArray));
        console.log(`✨ Final standardized ingredients (${uniqueIngredients.length}): ${uniqueIngredients.join(', ')}`);
        return {
            success: true,
            standardizedIngredients: uniqueIngredients
        };
    }
    catch (error) {
        console.error('❌ Error standardizing ingredients:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        // Fallback: return original ingredients if AI fails
        console.log('⚠️ Falling back to original ingredients due to error');
        return {
            success: false,
            standardizedIngredients: data.ingredients || [],
            error: 'AI standardization failed, returning original list'
        };
    }
});
//# sourceMappingURL=standardize-ingredients.js.map