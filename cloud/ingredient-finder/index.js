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

// In-memory cache for common products (expires after 1 hour)
const productCache = new Map();
const CACHE_TTL = 60 * 60 * 1000; // 1 hour

function getCachedProduct(productName, brand) {
  const key = `${productName.toLowerCase()}_${brand?.toLowerCase() || ''}`;
  const cached = productCache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    console.log(`[CACHE HIT] ${key}`);
    return cached.data;
  }
  return null;
}

function setCachedProduct(productName, brand, data) {
  const key = `${productName.toLowerCase()}_${brand?.toLowerCase() || ''}`;
  productCache.set(key, { data, timestamp: Date.now() });

  // Clean old cache entries (keep max 100 products)
  if (productCache.size > 100) {
    const oldestKey = productCache.keys().next().value;
    productCache.delete(oldestKey);
  }
}

// Use Gemini with Google Search grounding to find ingredients and nutrition
async function searchWithGemini(productName, brand) {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

  // Use Gemini 1.5 Flash - MUCH faster than 2.0-flash-exp (2-3x speed improvement)
  const model = genAI.getGenerativeModel({
    model: 'gemini-1.5-flash',
    tools: [{
      googleSearch: {}  // Enable Google Search grounding
    }]
  });

  // Enhanced prompt - distinguishes pack size, serving size, and nutrition basis
  const prompt = `Find UK product "${productName}"${brand ? ` by ${brand}` : ''} from Tesco/Sainsburys/Asda.
Find ALL available pack sizes (single item, multipack, sharing bag, large family pack, etc).

IMPORTANT: Extract THREE distinct values:
1. pack_size: Total product weight/quantity (e.g., "51g", "400g", "6 pack")
2. serving_size_g: Single serving weight in grams (e.g., 30g, 51g)
3. nutrition_basis: How nutrition is shown - "per_100g", "per_serving", or "per_pack"

For EACH pack size variant: ingredients list + nutrition always converted to per 100g (kcal, protein, carbs, fat, fiber, sugar, salt in g).

Return JSON array:
[{"pack_size":"51g","serving_size_g":51,"servings_per_pack":1,"nutrition_basis":"per_serving","product_name":"...","brand":"...","barcode":"...","ingredients":"comma separated list","nutrition_per_100g":{"calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0,"salt":0},"source_url":"..."}]

CRITICAL: If nutrition label says "per serving" or "per bar/pack", put that value in serving_size_g. If only showing "per 100g", set serving_size_g to null.
Use null for missing fields. Convert sodium to salt (*2.5). Remove "Ingredients:" prefix. Return 2-3+ sizes if available.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    console.log('[DEBUG] Gemini response:', text);

    // Extract JSON from response (might be wrapped in markdown) - supports both array and object
    const jsonMatch = text.match(/\[[\s\S]*\]|\{[\s\S]*\}/);
    if (!jsonMatch) {
      console.log('[WARN] No JSON found in Gemini response');
      return null;
    }

    const parsed = JSON.parse(jsonMatch[0]);
    // Normalize to array (backward compatible with single object responses)
    return Array.isArray(parsed) ? parsed : [parsed];
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

    // Check in-memory cache first for instant response
    const cached = getCachedProduct(productName, brand);
    if (cached) {
      console.log(`[CACHE] Returning cached result for ${productName}`);
      return res.status(200).json(cached);
    }

    const extractedVariants = await searchWithGemini(productName, brand);

    if (!extractedVariants || extractedVariants.length === 0) {
      return res.status(200).json({
        ingredients_found: false,
        variants: []
      });
    }

    console.log(`[DEBUG] Extracted ${extractedVariants.length} variant(s):`, JSON.stringify(extractedVariants, null, 2));

    // Process each variant
    const processedVariants = extractedVariants.map(variant => {
      // Normalize ingredients
      const ingredients = variant.ingredients
        ? variant.ingredients.replace(/^ingredients\s*:\s*/i, '').trim()
        : null;

      // Validate we have at least ingredients or nutrition data
      const hasIngredients = ingredients && ingredients.includes(',');
      const hasNutrition = variant.nutrition_per_100g && Object.values(variant.nutrition_per_100g).some(v => v !== null);

      if (!hasIngredients && !hasNutrition) {
        return null;  // Skip invalid variants
      }

      return {
        size_description: variant.size_description || 'Standard pack',
        product_name: variant.product_name || null,
        brand: variant.brand || null,
        barcode: variant.barcode || null,
        ingredients_text: ingredients,
        nutrition_per_100g: variant.nutrition_per_100g || null,
        source_url: variant.source_url || null
      };
    }).filter(v => v !== null);  // Remove invalid variants

    if (processedVariants.length === 0) {
      console.log(`[DEBUG] Rejected: no valid variants found`);
      const response = {
        ingredients_found: false,
        variants: []
      };
      setCachedProduct(productName, brand, response);
      return res.status(200).json(response);
    }

    const response = {
      ingredients_found: true,
      variants: processedVariants
    };

    // Cache successful results for faster future lookups
    setCachedProduct(productName, brand, response);

    return res.status(200).json(response);
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