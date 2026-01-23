/**
 * OpenFoodFacts Service
 * UK-only product lookup with smart image selection
 */

// OpenFoodFacts API endpoints
const OFF_UK_API = 'https://uk.openfoodfacts.org/api/v2';
const OFF_WORLD_API = 'https://world.openfoodfacts.org/api/v2';

// Image scoring simplified - just use available URLs directly

// UK country tags
const UK_COUNTRY_TAGS = [
  'en:united-kingdom',
  'en:great-britain',
  'en:england',
  'en:scotland',
  'en:wales',
  'en:northern-ireland',
  'en:uk',
];

// UK barcode prefixes (GS1 country codes)
const UK_BARCODE_PREFIXES = ['50', '539']; // 50 = UK, 539 = Ireland

// UK retailer brands
const UK_RETAILERS = [
  'tesco', 'sainsbury', 'sainsburys', "sainsbury's", 'asda', 'morrisons',
  'waitrose', 'aldi', 'lidl', 'co-op', 'coop', 'marks & spencer', 'm&s',
  'iceland', 'ocado', 'booths', 'budgens', 'costcutter', 'spar', 'londis',
  'nisa', 'premier', 'one stop', 'farmfoods', 'heron foods', 'b&m',
  'home bargains', 'poundland', 'wilko', 'superdrug', 'boots',
];

// UK-specific store tags
const UK_STORE_TAGS = [
  'en:tesco', 'en:sainsburys', 'en:asda', 'en:morrisons', 'en:waitrose',
  'en:aldi', 'en:lidl', 'en:co-op', 'en:marks-and-spencer', 'en:iceland',
  'en:ocado', 'en:boots', 'en:superdrug', 'en:holland-and-barrett',
];

// UK spelling patterns
const UK_SPELLINGS: [string, string][] = [
  ['colour', 'color'],
  ['flavour', 'flavor'],
  ['fibre', 'fiber'],
  ['centre', 'center'],
  ['litre', 'liter'],
  ['grey', 'gray'],
  ['organise', 'organize'],
  ['recognise', 'recognize'],
  ['favourite', 'favorite'],
  ['honour', 'honor'],
  ['defence', 'defense'],
  ['licence', 'license'],
  ['stabiliser', 'stabilizer'],
  ['pasteurised', 'pasteurized'],
  ['homogenised', 'homogenized'],
  ['flavouring', 'flavoring'],
  ['colouring', 'coloring'],
  ['sulphur', 'sulfur'],
  ['sulphite', 'sulfite'],
];

// UK-specific terms in ingredients
const UK_SPECIFIC_TERMS = [
  'skimmed milk', 'semi-skimmed', 'full fat milk', 'double cream',
  'single cream', 'clotted cream', 'cornflour', 'bicarbonate of soda',
  'caster sugar', 'demerara', 'muscovado', 'golden syrup', 'treacle',
  'marmite', 'bovril', 'hp sauce', 'worcestershire',
  'crisps', 'biscuit', 'aubergine', 'courgette', 'coriander',
  'rocket', 'swede', 'spring onion', 'porridge',
];

export interface OFFProduct {
  code: string;
  product_name?: string;
  product_name_en?: string;
  brands?: string;
  brands_tags?: string[];
  ingredients_text?: string;
  ingredients_text_en?: string;
  nutriments?: {
    'energy-kcal_100g'?: number;
    'energy-kj_100g'?: number;
    proteins_100g?: number;
    carbohydrates_100g?: number;
    fat_100g?: number;
    'saturated-fat_100g'?: number;
    fiber_100g?: number;
    fibre_100g?: number;  // UK spelling
    sugars_100g?: number;
    sodium_100g?: number;
    salt_100g?: number;
  };
  countries_tags?: string[];
  countries?: string;
  stores?: string;
  stores_tags?: string[];
  purchase_places?: string;
  purchase_places_tags?: string[];
  origins?: string;
  origins_tags?: string[];
  manufacturing_places?: string;
  manufacturing_places_tags?: string[];
  labels?: string;
  labels_tags?: string[];
  categories?: string;
  categories_tags?: string[];
  packaging?: string;
  quantity?: string;
  serving_size?: string;
  nutrition_grades?: string;  // Nutri-Score
  nova_group?: number;
  ecoscore_grade?: string;
  image_front_url?: string;
  image_front_small_url?: string;
  selected_images?: {
    front?: {
      display?: Record<string, string>;
      small?: Record<string, string>;
      thumb?: Record<string, string>;
    };
  };
  images?: Record<string, {
    uploader?: string;
    uploaded_t?: number;
    sizes?: {
      full?: { w: number; h: number };
      '400'?: { w: number; h: number };
      '200'?: { w: number; h: number };
      '100'?: { w: number; h: number };
    };
  }>;
}

export interface OFFImageScore {
  url: string;
  score: number;           // 0-10
  isRegionMatch: boolean;
  disqualified: boolean;
  disqualifyReason?: string;
}

export interface UKDetectionResult {
  isUKProduct: boolean;
  confidenceScore: number;  // 0-100
  signals: {
    signal: string;
    matched: boolean;
    weight: number;
    details?: string;
  }[];
}

export interface OFFLookupResult {
  product: OFFProduct | null;
  isUKProduct: boolean;
  ukConfidenceScore: number;
  ukSignals: UKDetectionResult['signals'];
  bestImageUrl: string | null;
  imageConfidenceScore: number;
  isRegionMatch: boolean;
  error?: string;
}

/**
 * Comprehensive UK product detection using multiple signals
 */
function detectUKProduct(product: OFFProduct): UKDetectionResult {
  const signals: UKDetectionResult['signals'] = [];
  let totalWeight = 0;
  let matchedWeight = 0;

  // 1. Country tags (weight: 30) - strongest signal
  const countryWeight = 30;
  totalWeight += countryWeight;
  const countries = product.countries_tags || [];
  const hasUKCountry = countries.some(tag => UK_COUNTRY_TAGS.includes(tag.toLowerCase()));
  if (hasUKCountry) {
    matchedWeight += countryWeight;
    signals.push({
      signal: 'Country tags include UK',
      matched: true,
      weight: countryWeight,
      details: countries.filter(c => UK_COUNTRY_TAGS.includes(c.toLowerCase())).join(', '),
    });
  } else {
    signals.push({
      signal: 'Country tags include UK',
      matched: false,
      weight: countryWeight,
      details: countries.length > 0 ? `Found: ${countries.slice(0, 3).join(', ')}` : 'No country tags',
    });
  }

  // 2. Barcode prefix (weight: 25) - very strong signal
  const barcodeWeight = 25;
  totalWeight += barcodeWeight;
  const barcode = product.code || '';
  const hasUKBarcode = UK_BARCODE_PREFIXES.some(prefix => barcode.startsWith(prefix));
  if (hasUKBarcode) {
    matchedWeight += barcodeWeight;
    signals.push({
      signal: 'UK barcode prefix (50/539)',
      matched: true,
      weight: barcodeWeight,
      details: `Barcode: ${barcode}`,
    });
  } else {
    signals.push({
      signal: 'UK barcode prefix (50/539)',
      matched: false,
      weight: barcodeWeight,
      details: barcode ? `Barcode starts with: ${barcode.substring(0, 3)}` : 'No barcode',
    });
  }

  // 3. UK retailer brand (weight: 20)
  const retailerWeight = 20;
  totalWeight += retailerWeight;
  const brands = (product.brands || '').toLowerCase();
  const brandTags = (product.brands_tags || []).map(t => t.toLowerCase());
  const matchedRetailer = UK_RETAILERS.find(r =>
    brands.includes(r) || brandTags.some(bt => bt.includes(r.replace(/[^a-z]/g, '')))
  );
  if (matchedRetailer) {
    matchedWeight += retailerWeight;
    signals.push({
      signal: 'UK retailer brand',
      matched: true,
      weight: retailerWeight,
      details: `Matched: ${matchedRetailer}`,
    });
  } else {
    signals.push({
      signal: 'UK retailer brand',
      matched: false,
      weight: retailerWeight,
      details: brands || 'No brand',
    });
  }

  // 4. UK store tags (weight: 15)
  const storeWeight = 15;
  totalWeight += storeWeight;
  const stores = product.stores_tags || [];
  const purchasePlaces = product.purchase_places_tags || [];
  const allStores = [...stores, ...purchasePlaces].map(s => s.toLowerCase());
  const hasUKStore = allStores.some(s =>
    UK_STORE_TAGS.some(uk => s.includes(uk.replace('en:', '')))
  ) || allStores.some(s => UK_RETAILERS.some(r => s.includes(r.replace(/[^a-z]/g, ''))));
  if (hasUKStore) {
    matchedWeight += storeWeight;
    signals.push({
      signal: 'UK store/purchase location',
      matched: true,
      weight: storeWeight,
      details: allStores.slice(0, 3).join(', '),
    });
  } else {
    signals.push({
      signal: 'UK store/purchase location',
      matched: false,
      weight: storeWeight,
      details: allStores.length > 0 ? allStores.slice(0, 3).join(', ') : 'No store data',
    });
  }

  // 5. UK spelling in ingredients (weight: 10)
  const spellingWeight = 10;
  totalWeight += spellingWeight;
  const ingredients = ((product.ingredients_text || '') + ' ' + (product.ingredients_text_en || '')).toLowerCase();
  const productName = ((product.product_name || '') + ' ' + (product.product_name_en || '')).toLowerCase();
  const allText = ingredients + ' ' + productName;

  const ukSpellingsFound = UK_SPELLINGS.filter(([uk]) => allText.includes(uk)).map(([uk]) => uk);
  const usSpellingsFound = UK_SPELLINGS.filter(([, us]) => allText.includes(us)).map(([, us]) => us);

  if (ukSpellingsFound.length > 0 && ukSpellingsFound.length >= usSpellingsFound.length) {
    matchedWeight += spellingWeight;
    signals.push({
      signal: 'UK spelling patterns',
      matched: true,
      weight: spellingWeight,
      details: ukSpellingsFound.slice(0, 3).join(', '),
    });
  } else if (usSpellingsFound.length > ukSpellingsFound.length) {
    signals.push({
      signal: 'UK spelling patterns',
      matched: false,
      weight: spellingWeight,
      details: `US spellings found: ${usSpellingsFound.slice(0, 3).join(', ')}`,
    });
  } else {
    signals.push({
      signal: 'UK spelling patterns',
      matched: false,
      weight: spellingWeight,
      details: 'No distinctive spelling found',
    });
  }

  // 6. UK-specific ingredients/terms (weight: 10)
  const termsWeight = 10;
  totalWeight += termsWeight;
  const ukTermsFound = UK_SPECIFIC_TERMS.filter(term => allText.includes(term.toLowerCase()));
  if (ukTermsFound.length > 0) {
    matchedWeight += termsWeight;
    signals.push({
      signal: 'UK-specific terms',
      matched: true,
      weight: termsWeight,
      details: ukTermsFound.slice(0, 3).join(', '),
    });
  } else {
    signals.push({
      signal: 'UK-specific terms',
      matched: false,
      weight: termsWeight,
      details: 'No UK-specific terms found',
    });
  }

  // 7. Salt instead of sodium in nutriments (weight: 5) - UK uses salt not sodium
  const saltWeight = 5;
  totalWeight += saltWeight;
  const nutriments = product.nutriments || {};
  const hasSalt = nutriments.salt_100g !== undefined && nutriments.salt_100g > 0;
  const hasSodiumOnly = nutriments.sodium_100g !== undefined && !hasSalt;
  if (hasSalt) {
    matchedWeight += saltWeight;
    signals.push({
      signal: 'Salt labeling (UK style)',
      matched: true,
      weight: saltWeight,
      details: `Salt: ${nutriments.salt_100g}g per 100g`,
    });
  } else if (hasSodiumOnly) {
    signals.push({
      signal: 'Salt labeling (UK style)',
      matched: false,
      weight: saltWeight,
      details: 'Sodium only (US style)',
    });
  } else {
    signals.push({
      signal: 'Salt labeling (UK style)',
      matched: false,
      weight: saltWeight,
      details: 'No salt/sodium data',
    });
  }

  // 8. Manufacturing/origin in UK (weight: 10)
  const originWeight = 10;
  totalWeight += originWeight;
  const origins = (product.origins || '').toLowerCase();
  const originTags = (product.origins_tags || []).map(t => t.toLowerCase());
  const manufacturing = (product.manufacturing_places || '').toLowerCase();
  const manufacturingTags = (product.manufacturing_places_tags || []).map(t => t.toLowerCase());
  const allOrigins = [origins, ...originTags, manufacturing, ...manufacturingTags].join(' ');
  const ukOriginTerms = ['united kingdom', 'uk', 'britain', 'england', 'scotland', 'wales', 'northern ireland'];
  const hasUKOrigin = ukOriginTerms.some(term => allOrigins.includes(term));
  if (hasUKOrigin) {
    matchedWeight += originWeight;
    signals.push({
      signal: 'UK manufacturing/origin',
      matched: true,
      weight: originWeight,
      details: allOrigins.substring(0, 50),
    });
  } else {
    signals.push({
      signal: 'UK manufacturing/origin',
      matched: false,
      weight: originWeight,
      details: allOrigins.length > 0 ? allOrigins.substring(0, 50) : 'No origin data',
    });
  }

  // Calculate confidence score
  const confidenceScore = Math.round((matchedWeight / totalWeight) * 100);

  // Determine if UK product (threshold: 40% confidence OR country tag match OR UK barcode)
  const isUKProduct = confidenceScore >= 40 || hasUKCountry || hasUKBarcode;

  return {
    isUKProduct,
    confidenceScore,
    signals: signals.sort((a, b) => b.weight - a.weight), // Sort by weight descending
  };
}

// Note: Complex image scoring functions removed due to CORS issues
// Using simplified selectBestOFFImage instead

/**
 * Select best image from OFF product
 * Simplified version that doesn't require loading images (CORS issues)
 */
async function selectBestOFFImage(
  product: OFFProduct,
  _targetRegion: 'UK' | 'EU' | 'any' = 'UK'
): Promise<{
  best_image_url: string | null;
  image_confidence_score: number;
  is_region_match: boolean;
}> {
  // Simple approach: just get the best available image URL without loading it
  // Priority: 1) English front image, 2) Any selected front image, 3) Main front image

  // Check for English front image in selected_images
  const enFrontUrl = product.selected_images?.front?.display?.en;
  if (enFrontUrl) {
    return {
      best_image_url: enFrontUrl,
      image_confidence_score: 8,
      is_region_match: true,
    };
  }

  // Check for any language front image in selected_images
  if (product.selected_images?.front?.display) {
    const displays = product.selected_images.front.display;
    // Prefer UK-related languages
    for (const lang of ['en', 'uk', 'gb']) {
      if (displays[lang]) {
        return {
          best_image_url: displays[lang],
          image_confidence_score: 7,
          is_region_match: lang === 'en',
        };
      }
    }
    // Take any available
    const firstLang = Object.keys(displays)[0];
    if (firstLang && displays[firstLang]) {
      return {
        best_image_url: displays[firstLang],
        image_confidence_score: 6,
        is_region_match: false,
      };
    }
  }

  // Fall back to main front image
  if (product.image_front_url) {
    const isRegionMatch = product.image_front_url.includes('front_en') ||
                          product.image_front_url.includes('front_uk');
    return {
      best_image_url: product.image_front_url,
      image_confidence_score: 5,
      is_region_match: isRegionMatch,
    };
  }

  // No image available
  return { best_image_url: null, image_confidence_score: 0, is_region_match: false };
}


/**
 * Look up product by barcode in OpenFoodFacts
 */
export async function lookupByBarcode(
  barcode: string,
  targetRegion: 'UK' | 'EU' | 'any' = 'UK'
): Promise<OFFLookupResult> {
  // Clean barcode
  const cleanBarcode = barcode.replace(/\D/g, '');

  if (!cleanBarcode || cleanBarcode.length < 8) {
    return {
      product: null,
      isUKProduct: false,
      ukConfidenceScore: 0,
      ukSignals: [],
      bestImageUrl: null,
      imageConfidenceScore: 0,
      isRegionMatch: false,
      error: 'Invalid barcode',
    };
  }

  try {
    // Try UK database first
    let response = await fetch(`${OFF_UK_API}/product/${cleanBarcode}.json`);
    let data = await response.json();

    // Fallback to world database if not found
    if (data.status !== 1 || !data.product) {
      response = await fetch(`${OFF_WORLD_API}/product/${cleanBarcode}.json`);
      data = await response.json();
    }

    if (data.status !== 1 || !data.product) {
      return {
        product: null,
        isUKProduct: false,
        ukConfidenceScore: 0,
        ukSignals: [],
        bestImageUrl: null,
        imageConfidenceScore: 0,
        isRegionMatch: false,
        error: 'Product not found',
      };
    }

    const product = data.product as OFFProduct;

    // Comprehensive UK detection
    const ukDetection = detectUKProduct(product);

    // Get best image
    const imageResult = await selectBestOFFImage(product, targetRegion);

    return {
      product,
      isUKProduct: ukDetection.isUKProduct,
      ukConfidenceScore: ukDetection.confidenceScore,
      ukSignals: ukDetection.signals,
      bestImageUrl: imageResult.best_image_url,
      imageConfidenceScore: imageResult.image_confidence_score,
      isRegionMatch: imageResult.is_region_match,
    };
  } catch (error) {
    console.error('Error looking up product:', error);
    return {
      product: null,
      isUKProduct: false,
      ukConfidenceScore: 0,
      ukSignals: [],
      bestImageUrl: null,
      imageConfidenceScore: 0,
      isRegionMatch: false,
      error: String(error),
    };
  }
}

/**
 * Search products by name in OpenFoodFacts
 */
export async function searchByName(
  query: string,
  options: {
    page?: number;
    pageSize?: number;
    targetRegion?: 'UK' | 'EU' | 'any';
  } = {}
): Promise<{ products: OFFProduct[]; total: number }> {
  const { page = 1, pageSize = 20, targetRegion = 'UK' } = options;

  try {
    // Use UK database first
    const params = new URLSearchParams({
      search_terms: query,
      search_simple: '1',
      action: 'process',
      json: '1',
      page_size: String(pageSize),
      page: String(page),
    });

    const response = await fetch(`${OFF_UK_API}/cgi/search.pl?${params}`);
    const data = await response.json();

    if (!data.products) {
      return { products: [], total: 0 };
    }

    // Filter to UK products if target is UK
    let products = data.products as OFFProduct[];
    if (targetRegion === 'UK') {
      products = products.filter(p => detectUKProduct(p).isUKProduct);
    }

    return {
      products,
      total: data.count || products.length,
    };
  } catch (error) {
    console.error('Error searching products:', error);
    return { products: [], total: 0 };
  }
}

/**
 * Transform OFF product to our format
 */
export function transformOFFProduct(product: OFFProduct): {
  name: string;
  brandName: string | null;
  barcode: string;
  ingredientsText: string | null;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  saturatedFat: number | null;
  fiber: number;
  sugar: number;
  sodium: number;
  salt: number | null;
} {
  const nutriments = product.nutriments || {};

  return {
    name: product.product_name_en || product.product_name || 'Unknown Product',
    brandName: product.brands || null,
    barcode: product.code,
    ingredientsText: product.ingredients_text_en || product.ingredients_text || null,
    calories: nutriments['energy-kcal_100g'] || 0,
    protein: nutriments.proteins_100g || 0,
    carbs: nutriments.carbohydrates_100g || 0,
    fat: nutriments.fat_100g || 0,
    saturatedFat: nutriments['saturated-fat_100g'] ?? null,
    fiber: nutriments.fiber_100g || 0,
    sugar: nutriments.sugars_100g || 0,
    sodium: nutriments.sodium_100g ? nutriments.sodium_100g * 1000 : 0, // Convert to mg
    salt: nutriments.salt_100g ?? null,
  };
}
