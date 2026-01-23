/**
 * Duplicate Detection Utilities
 * Multi-signal matching algorithm for finding duplicate foods across indices
 */

import Fuse from 'fuse.js';
import { UnifiedFood, DuplicateGroup } from '../types';

// UK Retailer brands for matching bonus
const UK_RETAILER_BRANDS = [
  'tesco', 'sainsbury', 'sainsburys', "sainsbury's", 'asda', 'morrisons',
  'waitrose', 'aldi', 'lidl', 'co-op', 'coop', 'marks & spencer', 'm&s',
  'iceland', 'ocado', 'booths', 'budgens', 'costcutter', 'spar', 'londis',
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
];

// Signal weights for matching
const SIGNAL_WEIGHTS = {
  barcodeExact: 50,      // Strongest identifier
  barcodePresent: 10,    // Having any barcode
  nameExact: 20,         // Case-insensitive exact match
  nameFuzzy: 15,         // Levenshtein scaled (max 15)
  brandExact: 10,        // Brand match
  ukRetailerBrand: 5,    // UK retailer bonus
  ingredientOverlap: 10, // Jaccard similarity scaled
  ukSpelling: 5,         // UK spelling detected
};

/**
 * Normalize text for comparison
 */
function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ');
}

/**
 * Check if brand is a UK retailer
 */
function isUKRetailerBrand(brand: string | null): boolean {
  if (!brand) return false;
  const normalizedBrand = normalizeText(brand);
  return UK_RETAILER_BRANDS.some(retailer => normalizedBrand.includes(retailer));
}

/**
 * Check if text contains UK spelling
 */
function hasUKSpelling(text: string): boolean {
  const normalizedText = normalizeText(text);
  return UK_SPELLINGS.some(([uk]) => normalizedText.includes(uk));
}

/**
 * Calculate Jaccard similarity between two sets
 */
function jaccardSimilarity(set1: Set<string>, set2: Set<string>): number {
  if (set1.size === 0 && set2.size === 0) return 0;

  const intersection = new Set([...set1].filter(x => set2.has(x)));
  const union = new Set([...set1, ...set2]);

  return intersection.size / union.size;
}

/**
 * Calculate ingredient overlap score
 */
function calculateIngredientOverlap(food1: UnifiedFood, food2: UnifiedFood): number {
  const ingredients1 = new Set(
    food1.ingredients.map(i => normalizeText(i)).filter(i => i.length > 2)
  );
  const ingredients2 = new Set(
    food2.ingredients.map(i => normalizeText(i)).filter(i => i.length > 2)
  );

  const similarity = jaccardSimilarity(ingredients1, ingredients2);
  return similarity * SIGNAL_WEIGHTS.ingredientOverlap;
}

/**
 * Calculate match score between two foods
 */
function calculateMatchScore(food1: UnifiedFood, food2: UnifiedFood): {
  score: number;
  reasons: string[];
} {
  let score = 0;
  const reasons: string[] = [];

  // Barcode exact match (strongest signal)
  if (food1.barcode && food2.barcode && food1.barcode === food2.barcode) {
    score += SIGNAL_WEIGHTS.barcodeExact;
    reasons.push(`Exact barcode match: ${food1.barcode}`);
  }

  // Both have barcodes
  if (food1.barcode && food2.barcode) {
    score += SIGNAL_WEIGHTS.barcodePresent;
  }

  // Name comparison
  const name1 = normalizeText(food1.name);
  const name2 = normalizeText(food2.name);

  if (name1 === name2) {
    score += SIGNAL_WEIGHTS.nameExact;
    reasons.push('Exact name match');
  } else {
    // Fuzzy name matching using Fuse.js
    const fuse = new Fuse([name1], {
      threshold: 0.4,
      includeScore: true,
    });
    const result = fuse.search(name2);
    if (result.length > 0 && result[0].score !== undefined) {
      const fuzzyScore = (1 - result[0].score) * SIGNAL_WEIGHTS.nameFuzzy;
      if (fuzzyScore > 5) {
        score += fuzzyScore;
        reasons.push(`Fuzzy name match (${Math.round(fuzzyScore)} pts)`);
      }
    }
  }

  // Brand comparison
  if (food1.brandName && food2.brandName) {
    const brand1 = normalizeText(food1.brandName);
    const brand2 = normalizeText(food2.brandName);

    if (brand1 === brand2) {
      score += SIGNAL_WEIGHTS.brandExact;
      reasons.push('Exact brand match');
    }
  }

  // UK retailer brand bonus
  if (isUKRetailerBrand(food1.brandName) && isUKRetailerBrand(food2.brandName)) {
    score += SIGNAL_WEIGHTS.ukRetailerBrand;
    reasons.push('Both are UK retailer products');
  }

  // Ingredient overlap
  if (food1.ingredients.length > 0 && food2.ingredients.length > 0) {
    const ingredientScore = calculateIngredientOverlap(food1, food2);
    if (ingredientScore > 2) {
      score += ingredientScore;
      reasons.push(`Ingredient overlap (${Math.round(ingredientScore)} pts)`);
    }
  }

  // UK spelling bonus
  const text1 = `${food1.name} ${food1.ingredientsText || ''}`;
  const text2 = `${food2.name} ${food2.ingredientsText || ''}`;
  if (hasUKSpelling(text1) && hasUKSpelling(text2)) {
    score += SIGNAL_WEIGHTS.ukSpelling;
    reasons.push('Both have UK spelling');
  }

  return { score, reasons };
}

/**
 * Build barcode index for fast lookups
 */
function buildBarcodeIndex(foods: UnifiedFood[]): Map<string, UnifiedFood[]> {
  const index = new Map<string, UnifiedFood[]>();

  foods.forEach(food => {
    if (food.barcode) {
      const existing = index.get(food.barcode) || [];
      existing.push(food);
      index.set(food.barcode, existing);
    }
  });

  return index;
}

/**
 * Build normalized name index for fast lookups
 */
function buildNameIndex(foods: UnifiedFood[]): Map<string, UnifiedFood[]> {
  const index = new Map<string, UnifiedFood[]>();

  foods.forEach(food => {
    const normalizedName = normalizeText(food.name);
    const key = food.brandName
      ? `${normalizedName}|${normalizeText(food.brandName)}`
      : normalizedName;

    const existing = index.get(key) || [];
    existing.push(food);
    index.set(key, existing);
  });

  return index;
}

/**
 * Detect duplicates across all foods
 */
export function detectDuplicates(
  foods: UnifiedFood[],
  options: {
    minScore?: number;
    maxGroups?: number;
  } = {}
): DuplicateGroup[] {
  const { minScore = 30, maxGroups = 500 } = options;
  const duplicateGroups: DuplicateGroup[] = [];
  const processedPairs = new Set<string>();
  const foodsInGroups = new Set<string>();

  // Build indices
  const barcodeIndex = buildBarcodeIndex(foods);
  const nameIndex = buildNameIndex(foods);

  // Find barcode duplicates first (highest confidence)
  barcodeIndex.forEach((barcodeMatches, barcode) => {
    if (barcodeMatches.length > 1) {
      // These are definite duplicates
      const groupId = `barcode-${barcode}`;

      // Find the "best" version (verified, most complete)
      const sorted = [...barcodeMatches].sort((a, b) => {
        // Prefer verified
        if (a.isVerified !== b.isVerified) return a.isVerified ? -1 : 1;
        // Prefer higher confidence
        return b._confidenceScore - a._confidenceScore;
      });

      const masterFood = sorted[0];
      const duplicateIds = sorted.slice(1).map(f => f._id);

      duplicateGroups.push({
        id: groupId,
        masterFoodId: masterFood._id,
        duplicateIds,
        matchScore: 100, // Barcode match is certain
        matchReasons: [`Exact barcode match: ${barcode}`],
      });

      // Mark all as in a group
      barcodeMatches.forEach(f => foodsInGroups.add(f._id));
    }
  });

  // Find name+brand duplicates
  nameIndex.forEach((nameMatches) => {
    if (nameMatches.length > 1) {
      // Filter out foods already in barcode groups
      const unGrouped = nameMatches.filter(f => !foodsInGroups.has(f._id));

      if (unGrouped.length > 1) {
        // Calculate cross-index matches
        for (let i = 0; i < unGrouped.length; i++) {
          for (let j = i + 1; j < unGrouped.length; j++) {
            const food1 = unGrouped[i];
            const food2 = unGrouped[j];

            // Skip same-index pairs (those are not cross-index duplicates)
            if (food1._sourceIndex === food2._sourceIndex) continue;

            const pairKey = [food1._id, food2._id].sort().join('|');
            if (processedPairs.has(pairKey)) continue;
            processedPairs.add(pairKey);

            const { score, reasons } = calculateMatchScore(food1, food2);

            if (score >= minScore) {
              const masterFood = food1._confidenceScore >= food2._confidenceScore ? food1 : food2;
              const duplicateFood = masterFood === food1 ? food2 : food1;

              duplicateGroups.push({
                id: `name-${pairKey}`,
                masterFoodId: masterFood._id,
                duplicateIds: [duplicateFood._id],
                matchScore: Math.min(100, score),
                matchReasons: reasons,
              });

              foodsInGroups.add(food1._id);
              foodsInGroups.add(food2._id);
            }
          }
        }
      }
    }
  });

  // Sort by match score descending
  duplicateGroups.sort((a, b) => b.matchScore - a.matchScore);

  // Limit results
  return duplicateGroups.slice(0, maxGroups);
}

/**
 * Merge duplicate foods - returns the merged food data
 */
export function mergeDuplicates(
  masterFood: UnifiedFood,
  duplicates: UnifiedFood[]
): UnifiedFood {
  const merged = { ...masterFood };

  // Merge barcodes
  const allBarcodes = new Set<string>();
  if (masterFood.barcode) allBarcodes.add(masterFood.barcode);
  duplicates.forEach(d => {
    if (d.barcode) allBarcodes.add(d.barcode);
  });
  merged.barcodes = [...allBarcodes];
  merged.barcode = merged.barcodes[0] || null;

  // Use best image (prefer one with image if master doesn't have one)
  if (!merged.imageUrl) {
    const withImage = duplicates.find(d => d.imageUrl);
    if (withImage) merged.imageUrl = withImage.imageUrl;
  }

  // Use most complete ingredients
  if (!merged.ingredientsText || merged.ingredientsText.length < 20) {
    const withIngredients = duplicates.find(d => d.ingredientsText && d.ingredientsText.length > (merged.ingredientsText?.length || 0));
    if (withIngredients) {
      merged.ingredientsText = withIngredients.ingredientsText;
      merged.ingredients = withIngredients.ingredients;
    }
  }

  // Mark as dirty since we merged data
  merged._isDirty = true;

  return merged;
}
