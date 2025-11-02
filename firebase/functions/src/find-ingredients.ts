import * as functions from 'firebase-functions';
import { GoogleGenerativeAI } from '@google/generative-ai';

interface NutritionPer100g {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
  sugar?: number;
  salt?: number;
}

interface ProductVariant {
  size_description: string;
  product_name: string | null;
  brand: string | null;
  barcode: string | null;
  ingredients_text: string | null;
  nutrition_per_100g: NutritionPer100g | null;
  source_url: string | null;
}

interface FindIngredientsResponse {
  ingredients_found: boolean;
  variants: ProductVariant[];
  error?: string;
}

/**
 * Cloud Function: Find ingredients and nutrition for UK products in multiple pack sizes
 *
 * Returns an array of product variants (e.g., single item, multipack, sharing bag).
 * All nutrition values are per-100g as requested from the AI.
 */
export const findIngredients = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
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
      const geminiApiKey = functions.config().gemini?.api_key;
      if (!geminiApiKey) {
        throw new Error('Gemini API key not configured');
      }

      // Initialize Google Generative AI client
      const genAI = new GoogleGenerativeAI(geminiApiKey);

      // Use Gemini 2.5 Flash (latest stable model - 1.5 series has been retired)
      const model = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash'
      });

      const prompt = `Find UK product "${productName}"${brand ? ` by ${brand}` : ''} from Tesco/Sainsburys/Asda.

Find ALL available pack sizes (single item, multipack, sharing bag, large family pack, etc).

For EACH size: ingredients list + nutrition per 100g (kcal, protein, carbs, fat, fiber, sugar, salt in g).

Return JSON array:
[{"size_description":"10 sweets (10g)","product_name":"...","brand":"...","barcode":"...","ingredients_text":"comma separated list","nutrition_per_100g":{"calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0,"salt":0},"source_url":"..."}]

Use null for missing fields. Convert sodium to salt (*2.5). Remove "Ingredients:" prefix. Return 2-3+ sizes if available.`;

      // Generate content with Google Search grounding
      const result = await model.generateContent(prompt);
      const aiResponse = result.response;
      const responseText = aiResponse.text();
      console.log(`🤖 AI Response: ${responseText.substring(0, 500)}...`);

      // Extract JSON from response (remove markdown code blocks if present)
      let jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.replace(/```\n?/g, '');
      }

      const aiData = JSON.parse(jsonText);

      // Check if response is an array of variants
      if (!Array.isArray(aiData)) {
        console.log('❌ AI response is not an array');
        const response: FindIngredientsResponse = {
          ingredients_found: false,
          variants: [],
          error: 'Invalid response format from AI. Please try again.'
        };
        res.json(response);
        return;
      }

      // Check if AI indicated it couldn't find data
      if (aiData.length === 0 || (aiData.length === 1 && aiData[0].found === false)) {
        console.log('❌ AI could not find product data');
        const response: FindIngredientsResponse = {
          ingredients_found: false,
          variants: [],
          error: 'Could not find this product on UK supermarket websites. Please enter nutrition manually.'
        };
        res.json(response);
        return;
      }

      // Process and validate variants
      const processedVariants: ProductVariant[] = aiData
        .filter((variant: any) => {
          // Must have at least ingredients or nutrition
          const hasIngredients = variant.ingredients_text && variant.ingredients_text.includes(',');
          const hasNutrition = variant.nutrition_per_100g &&
            Object.values(variant.nutrition_per_100g).some((v: any) => v !== null && v !== undefined);
          return hasIngredients || hasNutrition;
        })
        .map((variant: any) => ({
          size_description: variant.size_description || 'Standard pack',
          product_name: variant.product_name || null,
          brand: variant.brand || null,
          barcode: variant.barcode || null,
          ingredients_text: variant.ingredients_text ?
            variant.ingredients_text.replace(/^ingredients\s*:\s*/i, '').trim() : null,
          nutrition_per_100g: variant.nutrition_per_100g || null,
          source_url: variant.source_url || null
        }));

      if (processedVariants.length === 0) {
        console.log('❌ No valid variants found');
        const response: FindIngredientsResponse = {
          ingredients_found: false,
          variants: [],
          error: 'Found product but data is incomplete. Please enter nutrition manually.'
        };
        res.json(response);
        return;
      }

      const response: FindIngredientsResponse = {
        ingredients_found: true,
        variants: processedVariants
      };

      console.log(`✅ Success! Returning ${processedVariants.length} variant(s)`);
      res.json(response);

    } catch (error) {
      console.error('❌ Error finding ingredients:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      res.status(500).json({
        ingredients_found: false,
        variants: [],
        error: `Failed to find ingredients: ${errorMessage}`
      });
    }
  });
