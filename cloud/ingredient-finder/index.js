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

  // Optimized concise prompt for faster processing
  const prompt = `Find UK product "${productName}"${brand ? ` by ${brand}` : ''} from Tesco/Sainsburys/Asda.
Extract: ingredients list + nutrition per 100g (kcal, protein, carbs, fat, fiber, sugar, salt in g).
Return JSON only:
{"product_name":"...","brand":"...","barcode":"...","serving_size":"...","ingredients":"comma separated list","nutrition_per_100g":{"calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0,"salt":0},"source_url":"..."}
Use null for missing fields. Convert sodium to salt (*2.5). Remove "Ingredients:" prefix.`;

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

    // Check in-memory cache first for instant response
    const cached = getCachedProduct(productName, brand);
    if (cached) {
      console.log(`[CACHE] Returning cached result for ${productName}`);
      return res.status(200).json(cached);
    }

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
      const response = {
        ingredients_found: false,
        ingredients_text: null,
        nutrition_per_100g: null,
        source_url: extracted.source_url || null
      };
      // Cache negative results too to avoid repeated failed searches
      setCachedProduct(productName, brand, response);
      return res.status(200).json(response);
    }

    const response = {
      ingredients_found: hasIngredients || hasNutrition,
      product_name: extracted.product_name || null,
      brand: extracted.brand || null,
      barcode: extracted.barcode || null,
      serving_size: extracted.serving_size || null,
      ingredients_text: ingredients,
      nutrition_per_100g: extracted.nutrition_per_100g || null,
      source_url: extracted.source_url || null
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