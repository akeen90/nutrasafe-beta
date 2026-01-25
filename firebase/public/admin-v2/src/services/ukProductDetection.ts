/**
 * UK Product Detection Service
 * Detects non-UK products by analyzing spelling, language, and product names
 */

// US vs UK spelling patterns
const US_SPELLING_PATTERNS = [
  // Common word endings
  { us: /\bcolor\b/gi, uk: 'colour' },
  { us: /\bflavor\b/gi, uk: 'flavour' },
  { us: /\bfavorite\b/gi, uk: 'favourite' },
  { us: /\bhonor\b/gi, uk: 'honour' },
  { us: /\btheater\b/gi, uk: 'theatre' },
  { us: /\bcenter\b/gi, uk: 'centre' },
  { us: /\bmeter\b/gi, uk: 'metre' },
  { us: /\bliter\b/gi, uk: 'litre' },
  { us: /\bfiber\b/gi, uk: 'fibre' },
  { us: /\bdefense\b/gi, uk: 'defence' },
  { us: /\bpractice\b/gi, uk: 'practise' }, // when used as verb
  { us: /\banalyze\b/gi, uk: 'analyse' },
  { us: /\borganize\b/gi, uk: 'organise' },
  { us: /\brealize\b/gi, uk: 'realise' },
  { us: /\bcriticize\b/gi, uk: 'criticise' },
  { us: /\bspecialize\b/gi, uk: 'specialise' },

  // Food-specific terms
  { us: /\bcandy\b/gi, uk: 'sweets' },
  { us: /\bcookies?\b/gi, uk: 'biscuits' },
  { us: /\bfries\b/gi, uk: 'chips' },
  { us: /\bchips\b/gi, uk: 'crisps' },
  { us: /\beggplant\b/gi, uk: 'aubergine' },
  { us: /\bzucchini\b/gi, uk: 'courgette' },
  { us: /\bcilantro\b/gi, uk: 'coriander' },
  { us: /\barugula\b/gi, uk: 'rocket' },
  { us: /\bbell pepper\b/gi, uk: 'pepper' },
];

// Common US-only brand indicators
const US_BRAND_KEYWORDS = [
  'kraft singles', 'jell-o', 'cool whip', 'velveeta', 'cheez whiz',
  'pop tarts', 'goldfish crackers', 'cheetos', 'doritos nacho cheese',
  'mountain dew', 'dr pepper', 'root beer', 'gatorade', 'big red',
  'saltines', 'graham crackers', 'hershey', 'reese\'s', 'butterfinger',
  'twinkie', 'hostess', 'wonder bread', 'hawaiian punch', 'kool-aid',
];

// UK brand indicators (to counterbalance false positives)
const UK_BRAND_KEYWORDS = [
  'tesco', 'sainsbury', 'asda', 'waitrose', 'morrisons', 'co-op',
  'marks & spencer', 'boots', 'greggs', 'pret', 'costa',
  'walkers', 'cadbury', 'mcvitie', 'hobnob', 'jaffa cake', 'penguin',
  'yorkshire', 'tetley', 'pg tips', 'hovis', 'warburtons', 'kingsmill',
  'heinz beans', 'branston', 'marmite', 'bovril', 'oxo', 'bisto',
  'robinsons', 'ribena', 'lucozade', 'irn-bru', 'vimto',
  'quorn', 'linda mccartney', 'richmond', 'birds eye',
  'galaxy', 'wispa', 'crunchie', 'dairy milk', 'flake', 'curly wurly',
];

// Foreign language character patterns (excluding common French accents for UK products)
const FOREIGN_CHAR_PATTERNS = {
  // Eastern European
  easternEuropean: /[ąćęłńóśźżěščřžůďťň]/gi,

  // Asian characters
  asian: /[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]/g,

  // Cyrillic
  cyrillic: /[а-яА-ЯЁё]/g,

  // Arabic
  arabic: /[\u0600-\u06FF]/g,

  // Excessive accents (likely foreign, not UK French products)
  excessiveAccents: /[àáâãäåèéêëìíîïòóôõöùúûüýÿ]/gi,
};

export interface ProductAnalysis {
  isLikelyUK: boolean;
  confidence: number; // 0-100
  flags: string[];
  usSpellingCount: number;
  foreignCharCount: number;
  ukBrandMatch: boolean;
  usBrandMatch: boolean;
}

/**
 * Analyze if a product is likely a UK product
 */
export function analyzeProductOrigin(
  productName: string,
  brandName?: string | null,
  ingredients?: string | null
): ProductAnalysis {
  const fullText = `${brandName || ''} ${productName}`.toLowerCase();
  const flags: string[] = [];
  let confidence = 50; // Start neutral

  // Check for UK brand indicators (strong positive signal)
  const ukBrandMatch = UK_BRAND_KEYWORDS.some(keyword => fullText.includes(keyword.toLowerCase()));
  if (ukBrandMatch) {
    confidence += 40;
    flags.push('UK brand detected');
  }

  // Check for US brand indicators (strong negative signal)
  const usBrandMatch = US_BRAND_KEYWORDS.some(keyword => fullText.includes(keyword.toLowerCase()));
  if (usBrandMatch) {
    confidence -= 40;
    flags.push('US brand detected');
  }

  // Check for US spelling patterns
  let usSpellingCount = 0;
  for (const pattern of US_SPELLING_PATTERNS) {
    const matches = fullText.match(pattern.us);
    if (matches) {
      usSpellingCount += matches.length;
      flags.push(`US spelling: "${matches[0]}" (UK: ${pattern.uk})`);
    }
  }

  if (usSpellingCount > 0) {
    confidence -= usSpellingCount * 15; // Each US spelling reduces confidence
  }

  // Check ingredients for US spelling (CRITICAL FILTER)
  if (ingredients && typeof ingredients === 'string') {
    const ingredientText = ingredients.toLowerCase();

    // Parse ingredients into individual words (remove common separators)
    const words = ingredientText
      .replace(/[,()[\].:;]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2); // Ignore very short words

    let ingredientUSSpellingCount = 0;
    const usWordsFound: string[] = [];

    for (const pattern of US_SPELLING_PATTERNS) {
      const matches = ingredientText.match(pattern.us);
      if (matches) {
        ingredientUSSpellingCount += matches.length;
        usWordsFound.push(...matches);
      }
    }

    if (words.length > 0) {
      const usSpellingPercentage = (ingredientUSSpellingCount / words.length) * 100;

      if (usSpellingPercentage > 5) {
        // More than 5% US spelling in ingredients - REJECT
        confidence = 0; // Force rejection
        flags.push(`REJECT: ${Math.round(usSpellingPercentage)}% of ingredients use US spelling (${ingredientUSSpellingCount}/${words.length} words: ${usWordsFound.join(', ')})`);
      } else if (usSpellingPercentage > 2) {
        // 2-5% US spelling - suspicious
        confidence -= 25;
        flags.push(`Ingredients contain ${Math.round(usSpellingPercentage)}% US spelling (${ingredientUSSpellingCount}/${words.length} words: ${usWordsFound.join(', ')})`);
      } else if (ingredientUSSpellingCount > 0) {
        // <2% US spelling - minor penalty
        confidence -= 10;
        flags.push(`Some US spelling in ingredients: ${usWordsFound.join(', ')}`);
      }
    }
  }

  // Check for foreign language characters
  let foreignCharCount = 0;

  // Eastern European characters (likely not UK)
  const easternEuropeanMatches = fullText.match(FOREIGN_CHAR_PATTERNS.easternEuropean);
  if (easternEuropeanMatches) {
    foreignCharCount += easternEuropeanMatches.length;
    flags.push(`Eastern European characters: ${easternEuropeanMatches.join(', ')}`);
  }

  // Asian characters (likely not UK)
  const asianMatches = fullText.match(FOREIGN_CHAR_PATTERNS.asian);
  if (asianMatches) {
    foreignCharCount += asianMatches.length * 2; // Weight higher
    flags.push(`Asian characters detected`);
  }

  // Cyrillic characters (likely not UK)
  const cyrillicMatches = fullText.match(FOREIGN_CHAR_PATTERNS.cyrillic);
  if (cyrillicMatches) {
    foreignCharCount += cyrillicMatches.length * 2; // Weight higher
    flags.push(`Cyrillic characters detected`);
  }

  // Arabic characters (likely not UK)
  const arabicMatches = fullText.match(FOREIGN_CHAR_PATTERNS.arabic);
  if (arabicMatches) {
    foreignCharCount += arabicMatches.length * 2; // Weight higher
    flags.push(`Arabic characters detected`);
  }

  // French accents - allow small amounts (UK products like "crème fraîche")
  const accentMatches = fullText.match(FOREIGN_CHAR_PATTERNS.excessiveAccents);
  if (accentMatches) {
    const accentRatio = accentMatches.length / fullText.length;

    if (accentRatio > 0.15) {
      // More than 15% accented chars - likely foreign
      foreignCharCount += accentMatches.length;
      flags.push(`Excessive accents (${Math.round(accentRatio * 100)}% of text)`);
    } else if (accentRatio > 0.05 && accentRatio <= 0.15) {
      // 5-15% accented chars - possibly UK French product, slight reduction
      confidence -= 10;
      flags.push(`Some French accents (${Math.round(accentRatio * 100)}% - possibly UK French product)`);
    }
    // < 5% accented chars - likely UK product with French name, no penalty
  }

  if (foreignCharCount > 0) {
    confidence -= foreignCharCount * 5; // Each foreign char reduces confidence
  }

  // Additional heuristics

  // Common UK measurements
  if (/\b(ml|cl|litre|gramme?s?)\b/gi.test(fullText)) {
    confidence += 5;
  }

  // Common US measurements
  if (/\b(fl oz|fluid ounce|oz|ounce)\b/gi.test(fullText)) {
    confidence -= 10;
    flags.push('US measurements detected');
  }

  // UK-specific terms
  if (/\b(crisps|biscuits|courgette|aubergine)\b/gi.test(fullText)) {
    confidence += 10;
    flags.push('UK terminology detected');
  }

  // Clamp confidence between 0-100
  confidence = Math.max(0, Math.min(100, confidence));

  // Determine if likely UK (threshold: 40% confidence)
  const isLikelyUK = confidence >= 40;

  return {
    isLikelyUK,
    confidence,
    flags,
    usSpellingCount,
    foreignCharCount,
    ukBrandMatch,
    usBrandMatch,
  };
}

/**
 * Filter products to only UK products
 * Returns filtered list and statistics
 */
export function filterUKProducts<T extends { name: string; brandName?: string | null; ingredients?: string | null }>(
  products: T[],
  confidenceThreshold: number = 40
): {
  ukProducts: T[];
  nonUkProducts: T[];
  stats: {
    total: number;
    ukCount: number;
    nonUkCount: number;
    ukPercentage: number;
    nonUkPercentage: number;
  };
} {
  const ukProducts: T[] = [];
  const nonUkProducts: T[] = [];

  for (const product of products) {
    const analysis = analyzeProductOrigin(
      product.name,
      product.brandName,
      product.ingredients || null
    );

    if (analysis.confidence >= confidenceThreshold) {
      ukProducts.push(product);
    } else {
      nonUkProducts.push(product);
    }
  }

  const total = products.length;
  const ukCount = ukProducts.length;
  const nonUkCount = nonUkProducts.length;

  return {
    ukProducts,
    nonUkProducts,
    stats: {
      total,
      ukCount,
      nonUkCount,
      ukPercentage: total > 0 ? Math.round((ukCount / total) * 100) : 0,
      nonUkPercentage: total > 0 ? Math.round((nonUkCount / total) * 100) : 0,
    },
  };
}
