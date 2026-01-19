/**
 * AI-Inferred Meal Ingredient Analysis
 *
 * IMPORTANT DISCLAIMERS:
 * - This system provides EDUCATED GUESSES only
 * - This is NOT medical advice
 * - AI-inferred ingredients may be INCOMPLETE or INCORRECT
 * - Some real ingredients may be completely MISSED
 * - Users must be able to EDIT inferred ingredients
 *
 * PURPOSE:
 * For foods without ingredient labels (takeaway, restaurant, generic),
 * this service estimates LIKELY ingredients and exposures for pattern analysis.
 *
 * CRITICAL INFERENCE RULE:
 * - Do NOT list all possible ingredients
 * - Do NOT guess exact recipes
 * - ONLY include ingredients that are COMMON and HIGH-PROBABILITY
 * - Items that appear in the MAJORITY of UK versions of that food
 */

import * as functions from 'firebase-functions';
import axios from 'axios';

// Interfaces matching Swift InferredIngredient model
interface InferredIngredient {
  id: string;
  name: string;
  category: 'allergen' | 'preparation' | 'additive' | 'histamine' | 'base' | 'crossContact';
  confidence: 'high' | 'medium' | 'low';
  source: 'exact' | 'estimated' | 'userEdited';
  explanation: string | null;
  isUserEdited: boolean;
}

interface InferredMealAnalysis {
  foodName: string;
  analysisDate: string;
  isGenericFood: boolean;
  likelyIngredients: InferredIngredient[];
  preparationExposures: InferredIngredient[];
  possibleCrossContamination: InferredIngredient[];
  uncertaintyNotice: string;
}

interface InferenceRequest {
  foodName: string;
  foodDescription?: string;  // Optional additional context (e.g., "from chip shop", "restaurant curry")
  preparationMethod?: string;  // Optional: "fried", "grilled", "baked"
}

/**
 * Cloud Function: Infer likely ingredients for generic foods
 */
export const inferMealIngredients = functions
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
    secrets: ['GEMINI_API_KEY']
  })
  .https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
    // Handle CORS preflight
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

    const { foodName, foodDescription, preparationMethod } = req.body as InferenceRequest;

    if (!foodName || typeof foodName !== 'string' || foodName.trim().length === 0) {
      res.status(400).json({ error: 'Food name is required' });
      return;
    }

    // Get API key from secrets
    const geminiApiKey = process.env.GEMINI_API_KEY || '';
    if (!geminiApiKey) {
      console.error('Missing GEMINI_API_KEY');
      res.status(500).json({ error: 'Server configuration error' });
      return;
    }

    try {
      console.log(`🔍 Inferring ingredients for: "${foodName}"`);
      if (foodDescription) console.log(`   Context: ${foodDescription}`);
      if (preparationMethod) console.log(`   Preparation: ${preparationMethod}`);

      const analysis = await inferIngredientsWithAI(
        foodName.trim(),
        foodDescription?.trim(),
        preparationMethod?.trim(),
        geminiApiKey
      );

      console.log(`✅ Inferred ${analysis.likelyIngredients.length} ingredients, ${analysis.preparationExposures.length} preparation exposures`);

      res.status(200).json(analysis);
    } catch (error) {
      console.error('❌ Ingredient inference failed:', error);
      res.status(500).json({
        error: 'Failed to infer ingredients',
        details: String(error),
      });
    }
  });

/**
 * Build the prompt for ingredient inference
 * CRITICAL: This prompt enforces the signal-over-completeness rule
 */
function buildInferencePrompt(foodName: string, foodDescription?: string, preparationMethod?: string): string {
  const contextInfo = [
    foodDescription ? `Context: ${foodDescription}` : '',
    preparationMethod ? `Preparation: ${preparationMethod}` : '',
  ].filter(Boolean).join('\n');

  return `You are an expert food analyst for a UK food diary app. Your task is to estimate LIKELY ingredients and exposures for a food item WITHOUT a known ingredient label.

## CRITICAL RULES - YOU MUST FOLLOW THESE

1. This is NOT medical advice. You are providing EDUCATED GUESSES only.
2. You MUST clearly communicate UNCERTAINTY.
3. AI-inferred ingredients may COMPLETELY MISS real ingredients.
4. Users will be able to EDIT your suggestions.

## WHAT TO INCLUDE

ONLY include ingredients or exposures that:
- Are COMMON and HIGH-PROBABILITY
- Appear in the MAJORITY of UK versions of that food
- Are almost certainly present based on the food type

## WHAT TO EXCLUDE OR MARK AS LOW CONFIDENCE

If an ingredient:
- Is brand-specific → EXCLUDE or mark LOW confidence
- Is recipe-specific → EXCLUDE or mark LOW confidence
- Appears only occasionally → EXCLUDE or mark LOW confidence

The goal is SIGNAL, not completeness. Better to miss an ingredient than to guess wrong.

## FOOD TO ANALYSE

Food name: ${foodName}
${contextInfo}

## OUTPUT CATEGORIES

For each inferred item, provide:
- name: Ingredient name (e.g., "wheat", "vegetable oil", "MSG")
- category: One of: allergen, preparation, additive, histamine, base, crossContact
- confidence: "high" (appears in almost all UK versions), "medium" (appears in most), "low" (appears in some)
- explanation: Brief reason why this is likely present (1 sentence max)

### Category Definitions:
- allergen: Major allergens (wheat, dairy, eggs, nuts, soy, fish, shellfish, celery, mustard, sesame, lupin, molluscs, sulphites)
- preparation: Cooking method exposures (fried in oil, reused fryer oil, charred/grilled, smoked)
- additive: Common additive classes (MSG, preservatives, nitrates, sulfites, artificial colours)
- histamine: Histamine-related (aged/fermented, processed meats, certain fish)
- base: Core ingredients (meat type, flour, vegetables, sauces)
- crossContact: Cross-contamination risks (shared fryer with fish/gluten, shared grill)

## RESPONSE FORMAT

Respond with ONLY valid JSON (no markdown code blocks):
{
  "likelyIngredients": [
    {"name": "string", "category": "string", "confidence": "high|medium|low", "explanation": "string"}
  ],
  "preparationExposures": [
    {"name": "string", "category": "preparation", "confidence": "high|medium|low", "explanation": "string"}
  ],
  "possibleCrossContamination": [
    {"name": "string", "category": "crossContact", "confidence": "high|medium|low", "explanation": "string"}
  ]
}

## EXAMPLES

### Example 1: "Sausage"
{
  "likelyIngredients": [
    {"name": "Pork", "category": "base", "confidence": "high", "explanation": "UK sausages are predominantly pork-based"},
    {"name": "Salt", "category": "base", "confidence": "high", "explanation": "Essential preservative and flavouring in all sausages"},
    {"name": "Wheat/rusk", "category": "allergen", "confidence": "medium", "explanation": "Common filler in UK sausages but varies by brand"},
    {"name": "Sulphites", "category": "additive", "confidence": "medium", "explanation": "Common preservative in processed meats"}
  ],
  "preparationExposures": [],
  "possibleCrossContamination": []
}

### Example 2: "Battered fish from chip shop"
{
  "likelyIngredients": [
    {"name": "White fish (cod/haddock)", "category": "allergen", "confidence": "high", "explanation": "Standard UK chip shop fish is cod or haddock"},
    {"name": "Wheat flour", "category": "allergen", "confidence": "high", "explanation": "Batter is always wheat-based"},
    {"name": "Salt", "category": "base", "confidence": "high", "explanation": "Added to batter and cooking"}
  ],
  "preparationExposures": [
    {"name": "Deep-fried in vegetable oil", "category": "preparation", "confidence": "high", "explanation": "Standard chip shop cooking method"},
    {"name": "Reused fryer oil", "category": "preparation", "confidence": "high", "explanation": "Chip shops typically reuse oil multiple times"}
  ],
  "possibleCrossContamination": [
    {"name": "Shared fryer with chips", "category": "crossContact", "confidence": "high", "explanation": "Most chip shops use same fryer for fish and chips"},
    {"name": "Shared fryer with other battered items", "category": "crossContact", "confidence": "medium", "explanation": "Sausages, pies may be fried in same oil"}
  ]
}

Now analyse: ${foodName}`;
}

/**
 * Call Gemini to infer ingredients
 */
async function inferIngredientsWithAI(
  foodName: string,
  foodDescription: string | undefined,
  preparationMethod: string | undefined,
  apiKey: string
): Promise<InferredMealAnalysis> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

  const response = await axios.post(url, {
    contents: [{
      parts: [{ text: buildInferencePrompt(foodName, foodDescription, preparationMethod) }],
    }],
    generationConfig: {
      temperature: 0.2,  // Low temperature for consistent, conservative inference
      topP: 0.8,
      topK: 20,
      maxOutputTokens: 2048,
    },
  });

  const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
  return parseInferenceResponse(text, foodName);
}

/**
 * Parse and validate the AI response
 */
function parseInferenceResponse(responseText: string, foodName: string): InferredMealAnalysis {
  const defaultAnalysis: InferredMealAnalysis = {
    foodName,
    analysisDate: new Date().toISOString(),
    isGenericFood: true,
    likelyIngredients: [],
    preparationExposures: [],
    possibleCrossContamination: [],
    uncertaintyNotice: 'These ingredients are estimated and may be incomplete. Some real ingredients may be missing. You can edit them if you know more details.',
  };

  try {
    // Clean up response text
    let cleanedText = responseText.trim();
    cleanedText = cleanedText.replace(/^```json\s*/i, '');
    cleanedText = cleanedText.replace(/^```\s*/i, '');
    cleanedText = cleanedText.replace(/\s*```$/i, '');
    cleanedText = cleanedText.trim();

    const parsed = JSON.parse(cleanedText);

    // Validate and transform ingredients
    const validCategories = ['allergen', 'preparation', 'additive', 'histamine', 'base', 'crossContact'];
    const validConfidences = ['high', 'medium', 'low'];

    const transformIngredient = (item: unknown, index: number): InferredIngredient | null => {
      if (typeof item !== 'object' || item === null) return null;
      const obj = item as Record<string, unknown>;

      const name = typeof obj.name === 'string' ? obj.name.trim() : '';
      if (!name) return null;

      const category = validCategories.includes(obj.category as string)
        ? (obj.category as InferredIngredient['category'])
        : 'base';

      const confidence = validConfidences.includes(obj.confidence as string)
        ? (obj.confidence as InferredIngredient['confidence'])
        : 'medium';

      const explanation = typeof obj.explanation === 'string' ? obj.explanation.trim() : null;

      return {
        id: `inferred-${Date.now()}-${index}`,
        name,
        category,
        confidence,
        source: 'estimated',
        explanation,
        isUserEdited: false,
      };
    };

    // Parse likely ingredients
    if (Array.isArray(parsed.likelyIngredients)) {
      defaultAnalysis.likelyIngredients = parsed.likelyIngredients
        .map((item: unknown, idx: number) => transformIngredient(item, idx))
        .filter((item: unknown): item is InferredIngredient => item !== null);
    }

    // Parse preparation exposures
    if (Array.isArray(parsed.preparationExposures)) {
      defaultAnalysis.preparationExposures = parsed.preparationExposures
        .map((item: unknown, idx: number) => transformIngredient(item, 100 + idx))
        .filter((item: unknown): item is InferredIngredient => item !== null);
    }

    // Parse cross-contamination risks
    if (Array.isArray(parsed.possibleCrossContamination)) {
      defaultAnalysis.possibleCrossContamination = parsed.possibleCrossContamination
        .map((item: unknown, idx: number) => transformIngredient(item, 200 + idx))
        .filter((item: unknown): item is InferredIngredient => item !== null);
    }

    return defaultAnalysis;
  } catch (error) {
    console.error('Failed to parse inference response:', responseText, error);
    return defaultAnalysis;
  }
}
