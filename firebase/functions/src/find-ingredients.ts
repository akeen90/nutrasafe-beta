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
  serving_size_g: number | null;
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

    const { productName, brand, barcode } = req.body;

    if (!productName || typeof productName !== 'string') {
      res.status(400).json({ error: 'productName is required' });
      return;
    }

    console.log(`🔍 Finding ingredients for: ${productName}${brand ? ` (${brand})` : ''}${barcode ? ` [Barcode: ${barcode}]` : ''}`);

    try {
      // Build search query prioritizing barcode, then manufacturer, then UK supermarkets
      const searchQuery = barcode
        ? `barcode ${barcode} UK supermarket nutrition ingredients`
        : brand
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

      // Use Gemini 2.0 Flash Experimental - fast and accurate with improved prompt
      const model = genAI.getGenerativeModel({
        model: 'gemini-2.0-flash-exp'
      });

      const prompt = barcode
        ? `IMPORTANT: Search UK supermarket websites (Tesco.com, Sainsburys.co.uk, Asda.com) for a product with barcode: "${barcode}".

CRITICAL: Only return data you can VERIFY from real supermarket websites. DO NOT make up or guess any data.

If you find the product on a supermarket website:
1. Extract ALL available pack sizes (e.g., single bar, multipack, sharing bag)
2. For EACH size found, extract:
   - Ingredients list
   - Nutrition PER 100g (energy in kcal, protein, carbs, fat, fiber, sugar, salt - all in grams)
   - Serving size in grams if shown on the website (e.g., "per 30g serving" → serving_size_g: 30)
3. Include the source URL you used

CRITICAL NUTRITION EXTRACTION RULES:
- ALWAYS return nutrition per 100g
- If website shows "per serving" (e.g., per 30g), CONVERT to per 100g: (value × 100 / 30)
- If website shows "per pack" (e.g., per 500g), CONVERT to per 100g: (value × 100 / 500)
- Extract serving_size_g separately (e.g., if website says "per 30g serving", set serving_size_g: 30)

PACK SIZE vs SERVING SIZE (DO NOT CONFUSE):
- size_description = total pack weight (e.g., "500g bag", "330ml can", "6x45g bars")
- serving_size_g = recommended serving in grams (e.g., 30 for a 30g serving)

Return ONLY valid JSON (no explanatory text):
[{"size_description":"100g bar","product_name":"...","brand":"...","barcode":"...","serving_size_g":30,"ingredients_text":"milk, sugar, cocoa butter, ...","nutrition_per_100g":{"calories":530,"protein":7.3,"carbs":57,"fat":30,"fiber":2.1,"sugar":56,"salt":0.24},"source_url":"https://..."}]

Rules:
- Use null for any missing fields (including serving_size_g if not shown)
- Convert sodium to salt (multiply by 2.5)
- Remove "Ingredients:" prefix from ingredients text
- Return 2-3+ sizes if multiple are available on the website
- If you cannot find REAL data from UK supermarkets, return an empty array []`
        : `IMPORTANT: Search the actual UK supermarket websites (Tesco.com, Sainsburys.co.uk, Asda.com) for this EXACT product: "${productName}"${brand ? ` by ${brand}` : ''}.

CRITICAL: Only return data you can VERIFY from real supermarket websites. DO NOT make up or guess any data.

If you find the product on a supermarket website:
1. Extract ALL available pack sizes (e.g., single bar, multipack, sharing bag)
2. For EACH size found, extract:
   - Ingredients list
   - Nutrition PER 100g (energy in kcal, protein, carbs, fat, fiber, sugar, salt - all in grams)
   - Serving size in grams if shown on the website (e.g., "per 30g serving" → serving_size_g: 30)
3. Include the source URL you used

CRITICAL NUTRITION EXTRACTION RULES:
- ALWAYS return nutrition per 100g
- If website shows "per serving" (e.g., per 30g), CONVERT to per 100g: (value × 100 / 30)
- If website shows "per pack" (e.g., per 500g), CONVERT to per 100g: (value × 100 / 500)
- Extract serving_size_g separately (e.g., if website says "per 30g serving", set serving_size_g: 30)

PACK SIZE vs SERVING SIZE (DO NOT CONFUSE):
- size_description = total pack weight (e.g., "500g bag", "330ml can", "6x45g bars")
- serving_size_g = recommended serving in grams (e.g., 30 for a 30g serving)

Return ONLY valid JSON (no explanatory text):
[{"size_description":"100g bar","product_name":"...","brand":"...","barcode":"...","serving_size_g":30,"ingredients_text":"milk, sugar, cocoa butter, ...","nutrition_per_100g":{"calories":530,"protein":7.3,"carbs":57,"fat":30,"fiber":2.1,"sugar":56,"salt":0.24},"source_url":"https://..."}]

Rules:
- Use null for any missing fields (including serving_size_g if not shown)
- Convert sodium to salt (multiply by 2.5)
- Remove "Ingredients:" prefix from ingredients text
- Return 2-3+ sizes if multiple are available on the website
- If you cannot find REAL data from UK supermarkets, return an empty array []`;

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
          serving_size_g: variant.serving_size_g || null,
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
