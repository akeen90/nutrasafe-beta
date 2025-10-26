// NutraSafe Ingredient Finder Cloud Function (HTTP)
// Uses Google Custom Search API and Gemini to extract clean ingredients

const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Environment variables
// GOOGLE_CSE_KEY: Google Custom Search API key
// GOOGLE_CSE_CX: Google Custom Search engine ID
// GEMINI_API_KEY: Generative Language API key for Gemini
const CSE_KEY = process.env.GOOGLE_CSE_KEY;
const CSE_CX = process.env.GOOGLE_CSE_CX;
const GEMINI_KEY = process.env.GEMINI_API_KEY;

if (!CSE_KEY || !CSE_CX) {
  console.warn('[WARN] Missing GOOGLE_CSE_KEY or GOOGLE_CSE_CX env. Set them before running.');
}
if (!GEMINI_KEY) {
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

function brandToDomain(brand) {
  if (!brand) return null;
  const cleaned = brand.toLowerCase().replace(/[^a-z0-9]/g, '');
  return cleaned ? `${cleaned}.com` : null;
}

function buildSearchQuery(productName, brand) {
  const domain = brandToDomain(brand);
  const official = domain ? `site:${domain}.co.uk OR site:${domain}.com` : '';
  const ukSupermarkets = 'site:tesco.com OR site:asda.com OR site:sainsburys.co.uk OR site:waitrose.com OR site:ocado.com OR site:morrisons.com OR site:iceland.co.uk';
  const sources = [official, ukSupermarkets].filter(Boolean).join(' OR ');
  const base = `${productName} ${brand || ''} ingredients`;
  return `${base} ${sources}`.trim();
}

async function searchCSE(query) {
  const url = 'https://www.googleapis.com/customsearch/v1';
  const params = { key: CSE_KEY, cx: CSE_CX, q: query, num: 5 };
  const { data } = await axios.get(url, { params });
  return data.items || [];
}

function extractSnippetAndURL(items) {
  let bestMatch = null;
  let bestScore = 0;

  for (const item of items) {
    const snippet = (item.snippet || '').trim();
    const title = (item.title || '').toLowerCase();
    if (!snippet) continue;

    // Score the snippet based on quality indicators
    let score = 0;

    // Must contain "ingredients" keyword
    const hasIngredientsWord = /ingredients?/i.test(snippet) || /ingredients?/i.test(title);
    if (!hasIngredientsWord) continue;
    score += 10;

    // Prefer snippets with actual ingredient lists (multiple commas)
    const commaCount = (snippet.match(/,/g) || []).length;
    score += commaCount * 5;

    // Prefer snippets with food/ingredient keywords
    const foodKeywords = /water|sugar|salt|flour|milk|oil|acid|extract|flavor|colour|preservative/i;
    if (foodKeywords.test(snippet)) score += 15;

    // Penalize metadata-like snippets
    if (/allergens, additives, nutrition facts/i.test(snippet)) score -= 20;
    if (/information on product/i.test(snippet)) score -= 15;

    // Track best match
    if (score > bestScore) {
      bestScore = score;
      bestMatch = { snippet, url: item.link };
    }
  }

  return bestMatch;
}

async function cleanWithGemini(snippet) {
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}`;
  const prompt = [
    'Extract only the ingredients list as a clean, comma-separated string. ',
    'Remove prefixes like "Ingredients:" and any irrelevant text or marketing. ',
    'Remove duplicates and keep simple ingredient names only. ',
    'Only output the final comma-separated ingredients string.'
  ].join('');

  const payload = {
    contents: [
      {
        parts: [
          { text: `${prompt}\n\nText:\n${snippet}` }
        ]
      }
    ]
  };

  const { data } = await axios.post(endpoint, payload, {
    headers: { 'Content-Type': 'application/json' }
  });

  const candidates = data.candidates || [];
  const first = candidates[0];
  const text = first?.content?.parts?.[0]?.text || '';
  return text.trim();
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

    const query = buildSearchQuery(productName, brand);
    const items = await searchCSE(query);

    const best = extractSnippetAndURL(items);
    if (!best) {
      return res.status(200).json({
        ingredients_found: false,
        ingredients_text: null,
        source_url: null
      });
    }

    console.log(`[DEBUG] Best snippet found: "${best.snippet}"`);
    console.log(`[DEBUG] From URL: ${best.url}`);
    const cleaned = await cleanWithGemini(best.snippet);

    // Fail-safe: ensure we got a non-empty result with at least 2 ingredients
    const normalized = cleaned
      .replace(/^ingredients\s*:\s*/i, '')
      .trim();

    console.log(`[DEBUG] Gemini returned: "${cleaned}"`);
    console.log(`[DEBUG] Normalized: "${normalized}"`);

    // Check if we have at least 2 ingredients (comma-separated or otherwise)
    const hasComma = normalized.includes(',');
    const wordCount = normalized.split(/\s+/).length;

    if (!normalized || (!hasComma && wordCount < 3)) {
      console.log(`[DEBUG] Rejected: hasComma=${hasComma}, wordCount=${wordCount}`);
      // Return not found to avoid misleading auto-fill
      return res.status(200).json({
        ingredients_found: false,
        ingredients_text: null,
        source_url: best.url || null
      });
    }

    return res.status(200).json({
      ingredients_found: true,
      ingredients_text: normalized,
      source_url: best.url || null
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