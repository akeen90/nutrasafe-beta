// NutraSafe Ingredient Finder Cloud Function (HTTP)
// Uses Gemini with Google Search grounding to find ingredients and nutrition

const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json());

// Environment variables
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.warn('[WARN] Missing GEMINI_API_KEY env. Set it before running.');
}

// Simple per-IP rate limiter: max 2 requests/minute
const rateBuckets = new Map();
function allowRequest(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000;
  const maxReq = 2;
  const bucket = rateBuckets.get(ip) || [];
  const recent = bucket.filter(ts => now - ts < windowMs);
  if (recent.length >= maxReq) return false;
  recent.push(now);
  rateBuckets.set(ip, recent);
  return true;
}

// Use Gemini with Google Search grounding to find ingredients and nutrition
async function searchWithGemini(productName, brand) {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

  // Use Gemini 2.0 Flash with Google Search grounding
  const model = genAI.getGenerativeModel({
    model: 'gemini-2.0-flash-exp',
    tools: [{
      googleSearch: {}  // Enable Google Search grounding
    }]
  });

  // Prioritize product name over brand in search
  const searchQuery = brand
    ? `"${productName}" ${brand} ingredients nutrition per 100g UK`
    : `${productName} ingredients nutrition per 100g UK`;

  const prompt = `
Search for the product "${searchQuery}" and extract the following information:

IMPORTANT: Focus on finding information for "${productName}" specifically. The brand "${brand || 'N/A'}" is secondary - prioritize matching the exact product name.

1. Complete ingredient list (all ingredients listed on the product)
2. Nutrition information per 100g or 100ml

Return ONLY a valid JSON object with this exact structure:
{
  "product_name": "exact product name as shown on packaging or null if not found",
  "brand": "brand name or null if not found",
  "barcode": "product barcode/EAN/UPC (numbers only) or null if not found",
  "serving_size": "serving size with units (e.g. '250ml', '30g', '1 can (330ml)') or null if not found",
  "ingredients": "complete comma-separated ingredient list or null if not found",
  "nutrition_per_100g": {
    "calories": number or null (kcal per 100g),
    "protein": number or null (g per 100g),
    "carbs": number or null (g per 100g - total carbohydrate),
    "fat": number or null (g per 100g),
    "fiber": number or null (g per 100g - fibre/fiber),
    "sugar": number or null (g per 100g),
    "salt": number or null (g per 100g - salt/sodium, convert sodium to salt if needed by multiplying sodium by 2.5)
  },
  "source_url": "URL of the page where you found this information or null"
}

CRITICAL Rules:
- Search UK supermarket websites (Tesco, Sainsbury's, Asda, Waitrose, Morrisons) and official brand websites
- Extract the COMPLETE ingredient list (don't truncate)
- Extract nutrition values PER 100g or PER 100ml ONLY (not per serving)
- If nutrition is per serving, calculate per 100g/100ml if serving size is given
- All nutrition values must be numbers (no units in the value)
- Calories in kcal, everything else in grams
- Remove prefixes like "Ingredients:", "INGREDIENTS:" from the ingredients string
- Return ONLY the JSON object, no markdown, no explanations
- If you cannot find ingredients or nutrition data, return null for those fields
`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    console.log('[DEBUG] Gemini response:', text);

    // Extract JSON from response (might be wrapped in markdown)
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      console.log('[WARN] No JSON found in Gemini response');
      return null;
    }

    return JSON.parse(jsonMatch[0]);
  } catch (err) {
    console.error('[ERROR] Gemini search failed:', err.message);
    return null;
  }
}

// Handle both root path (for Cloud Functions) and /findIngredients (for local testing)
const handler = async (req, res) => {
  try {
    const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress;
    if (!allowRequest(ip)) {
      return res.status(429).json({ error: 'Rate limit exceeded. Max 2 requests/minute.' });
    }

    const { productName, brand } = req.body || {};
    if (!productName || typeof productName !== 'string') {
      return res.status(400).json({ error: 'Missing or invalid productName' });
    }

    console.log(`[DEBUG] Searching for: ${productName} ${brand || ''}`);

    const extracted = await searchWithGemini(productName, brand);

    if (!extracted) {
      return res.status(200).json({
        ingredients_found: false,
        ingredients_text: null,
        nutrition_per_100g: null,
        source_url: null
      });
    }

    console.log(`[DEBUG] Extracted:`, JSON.stringify(extracted, null, 2));

    // Normalize ingredients
    const ingredients = extracted.ingredients
      ? extracted.ingredients.replace(/^ingredients\s*:\s*/i, '').trim()
      : null;

    // Validate we have at least ingredients or nutrition data
    const hasIngredients = ingredients && ingredients.includes(',');
    const hasNutrition = extracted.nutrition_per_100g && Object.values(extracted.nutrition_per_100g).some(v => v !== null);

    if (!hasIngredients && !hasNutrition) {
      console.log(`[DEBUG] Rejected: no valid ingredients or nutrition data`);
      return res.status(200).json({
        ingredients_found: false,
        ingredients_text: null,
        nutrition_per_100g: null,
        source_url: extracted.source_url || null
      });
    }

    return res.status(200).json({
      ingredients_found: hasIngredients || hasNutrition,
      product_name: extracted.product_name || null,
      brand: extracted.brand || null,
      barcode: extracted.barcode || null,
      serving_size: extracted.serving_size || null,
      ingredients_text: ingredients,
      nutrition_per_100g: extracted.nutrition_per_100g || null,
      source_url: extracted.source_url || null
    });
  } catch (err) {
    console.error('Error in /findIngredients:', err?.response?.data || err.message || err);
    return res.status(500).json({ error: 'Internal error while finding ingredients' });
  }
};

// Register the handler for both root and /findIngredients paths
app.post('/', handler);
app.post('/findIngredients', handler);

// Export for Cloud Functions Gen2
exports.findIngredients = app;

// For local testing
if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => {
    console.log(`NutraSafe Ingredient Finder listening on http://localhost:${PORT}/findIngredients`);
  });
}