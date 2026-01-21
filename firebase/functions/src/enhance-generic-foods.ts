import * as functionsV1 from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

/**
 * Enhance generic foods with real nutritional data from OpenFoodFacts
 *
 * For each generic food (e.g., "Fillet Steak"), searches OpenFoodFacts
 * for a matching UK product and copies the per 100g nutritional values.
 */

interface OpenFoodFactsNutrients {
  "energy-kcal_100g"?: number;
  "energy-kcal"?: number;
  proteins_100g?: number;
  proteins?: number;
  carbohydrates_100g?: number;
  carbohydrates?: number;
  fat_100g?: number;
  fat?: number;
  "saturated-fat_100g"?: number;
  "saturated-fat"?: number;
  fiber_100g?: number;
  fiber?: number;
  sugars_100g?: number;
  sugars?: number;
  salt_100g?: number;
  salt?: number;
  sodium_100g?: number;
  sodium?: number;
  // Micronutrients
  "vitamin-a_100g"?: number;
  "vitamin-c_100g"?: number;
  "vitamin-d_100g"?: number;
  "vitamin-e_100g"?: number;
  "vitamin-k_100g"?: number;
  "vitamin-b1_100g"?: number;
  "vitamin-b2_100g"?: number;
  "vitamin-b6_100g"?: number;
  "vitamin-b12_100g"?: number;
  "vitamin-b9_100g"?: number;  // Folate
  calcium_100g?: number;
  iron_100g?: number;
  magnesium_100g?: number;
  phosphorus_100g?: number;
  potassium_100g?: number;
  zinc_100g?: number;
  copper_100g?: number;
  manganese_100g?: number;
  selenium_100g?: number;
  iodine_100g?: number;
}

interface EnhancementResult {
  foodId: string;
  foodName: string;
  status: "enhanced" | "no_match" | "error" | "skipped";
  openFoodFactsProduct?: string;
  message?: string;
}

/**
 * Search OpenFoodFacts for a UK product matching the generic food name
 */
async function searchOpenFoodFacts(searchTerm: string): Promise<any | null> {
  try {
    // Clean up the search term - remove serving size info like "(Medium)" or "(100g)"
    const cleanedTerm = searchTerm
      .replace(/\([^)]*\)/g, "")  // Remove parenthetical content
      .replace(/,.*$/, "")        // Remove everything after comma
      .trim();

    console.log(`🔍 Searching OpenFoodFacts for: "${cleanedTerm}"`);

    const response = await axios.get("https://world.openfoodfacts.org/cgi/search.pl", {
      params: {
        search_terms: cleanedTerm,
        search_simple: 1,
        action: "process",
        json: 1,
        page_size: 20,
        // Prefer UK products
        tagtype_0: "countries",
        tag_contains_0: "contains",
        tag_0: "united-kingdom",
      },
      timeout: 10000,
      headers: {
        "User-Agent": "NutraSafe/1.0 (https://nutrasafe.co.uk) - Generic Food Enhancement",
      },
    });

    if (!response.data.products || response.data.products.length === 0) {
      // Try without UK filter
      const fallbackResponse = await axios.get("https://world.openfoodfacts.org/cgi/search.pl", {
        params: {
          search_terms: cleanedTerm,
          search_simple: 1,
          action: "process",
          json: 1,
          page_size: 10,
        },
        timeout: 10000,
        headers: {
          "User-Agent": "NutraSafe/1.0 (https://nutrasafe.co.uk) - Generic Food Enhancement",
        },
      });

      if (!fallbackResponse.data.products || fallbackResponse.data.products.length === 0) {
        console.log(`❌ No products found for: "${cleanedTerm}"`);
        return null;
      }

      return findBestMatch(fallbackResponse.data.products, cleanedTerm);
    }

    return findBestMatch(response.data.products, cleanedTerm);
  } catch (error: any) {
    console.error(`❌ OpenFoodFacts API error for "${searchTerm}":`, error.message);
    return null;
  }
}

/**
 * Find the best matching product from search results
 * Prioritizes products with:
 * 1. Complete nutrition data (especially per 100g)
 * 2. English ingredients
 * 3. Similar name to search term
 * 4. Rejecting obviously wrong matches (flavoured snacks, capsules, etc.)
 */
function findBestMatch(products: any[], searchTerm: string): any | null {
  const searchLower = searchTerm.toLowerCase();

  // Extract the core food item (remove serving info like "Baked", "Cup", "Medium", etc.)
  const coreFood = searchLower
    .replace(/\([^)]*\)/g, "")
    .replace(/\b(baked|fried|grilled|steamed|raw|cooked|boiled|roasted|medium|large|small|cup|slice|tablespoon|piece|fillet|whole|half)\b/gi, "")
    .trim()
    .split(/\s+/)
    .filter(w => w.length > 2);

  // Score each product
  const scored = products.map(product => {
    let score = 0;
    const nutriments = product.nutriments || {};
    const name = (product.product_name || "").toLowerCase();
    const categories = (product.categories_tags || []).join(",").toLowerCase();

    // Must have reasonable calories (not 0 or 1)
    const calories = nutriments["energy-kcal_100g"] || nutriments["energy-kcal"];
    if (!calories || calories < 5) {
      return { product, score: -100 };
    }

    // HARD REJECT: Products that are clearly wrong
    const rejectPatterns = [
      /capsule/i, /supplement/i, /vitamin/i, /tablet/i,  // Supplements
      /flavour/i, /flavored/i, /seasoning/i,              // Flavoured snacks
      /isn't|vegan.*(?:beef|chicken|pork|lamb)/i,         // Meat alternatives when searching for meat
      /crisps|chips|snack/i,                              // Snack foods when searching for raw ingredients
      /sauce|dressing|marinade/i,                          // Condiments
      /dog food|cat food|pet/i,                            // Pet food
    ];

    for (const pattern of rejectPatterns) {
      if (pattern.test(name) || pattern.test(categories)) {
        // Only reject if we're not actually searching for that thing
        if (!pattern.test(searchLower)) {
          return { product, score: -100 };
        }
      }
    }

    // Check if this is a meat search and reject plant-based alternatives
    const meatTerms = ["beef", "chicken", "pork", "lamb", "steak", "mince", "liver", "bacon", "sausage", "ham", "turkey"];
    const isMeatSearch = meatTerms.some(m => searchLower.includes(m));
    if (isMeatSearch) {
      const plantKeywords = ["plant", "vegan", "vegetarian", "soy", "soya", "tofu", "seitan", "quorn", "isn't"];
      if (plantKeywords.some(p => name.includes(p))) {
        return { product, score: -100 };
      }
    }

    // Bonus for having per 100g data
    if (nutriments["energy-kcal_100g"]) score += 10;
    if (nutriments.proteins_100g) score += 5;
    if (nutriments.carbohydrates_100g) score += 5;
    if (nutriments.fat_100g) score += 5;

    // Bonus for micronutrients
    if (nutriments.calcium_100g) score += 2;
    if (nutriments.iron_100g) score += 2;
    if (nutriments["vitamin-c_100g"]) score += 2;

    // Strong bonus for exact core food match
    const nameWords = name.split(/\s+/);
    const coreMatches = coreFood.filter(word => nameWords.some((n: string) => n.includes(word) || word.includes(n)));
    score += coreMatches.length * 20;

    // Bonus if name starts with the core food
    if (coreFood.length > 0 && name.startsWith(coreFood[0])) {
      score += 25;
    }

    // Bonus for UK product
    const countries = (product.countries_tags || []).join(",").toLowerCase();
    if (countries.includes("united-kingdom") || countries.includes("en:united-kingdom")) {
      score += 15;
    }

    // Bonus for simple product names (less processed = better for generic foods)
    if (nameWords.length <= 3) score += 10;
    if (nameWords.length <= 2) score += 10;

    // Bonus for English ingredients
    if (product.ingredients_text_en || (product.lang === "en")) {
      score += 5;
    }

    // Penalty for very processed items when searching for raw foods
    const rawIndicators = ["fresh", "raw", "natural", "organic", "whole"];
    if (rawIndicators.some(r => name.includes(r))) score += 10;

    // Penalty for ready meals, pies, etc. when searching for raw ingredients
    const processedIndicators = ["ready", "meal", "pie", "sandwich", "wrap", "pizza", "curry", "lasagne"];
    if (!processedIndicators.some(p => searchLower.includes(p))) {
      if (processedIndicators.some(p => name.includes(p))) {
        score -= 30;
      }
    }

    return { product, score };
  });

  // Filter out rejected products and sort by score
  const valid = scored.filter(s => s.score > -100).sort((a, b) => b.score - a.score);

  if (valid.length === 0) return null;

  // Only accept if score is reasonably high
  if (valid[0].score < 10) {
    console.log(`⚠️ Best match score too low (${valid[0].score}): "${valid[0].product.product_name}"`);
    return null;
  }

  const best = valid[0].product;
  console.log(`✅ Best match: "${best.product_name}" (score: ${valid[0].score})`);

  return best;
}

/**
 * Extract per 100g nutrition values from OpenFoodFacts product
 */
function extractNutrition(product: any): Record<string, any> {
  const n: OpenFoodFactsNutrients = product.nutriments || {};

  // Helper to get per 100g value
  const get100g = (key: string): number | null => {
    const val = n[`${key}_100g` as keyof OpenFoodFactsNutrients] ?? n[key as keyof OpenFoodFactsNutrients];
    return typeof val === "number" && !isNaN(val) ? Math.round(val * 100) / 100 : null;
  };

  const nutrition: Record<string, any> = {
    // Macros (per 100g)
    calories: get100g("energy-kcal"),
    protein: get100g("proteins"),
    carbs: get100g("carbohydrates"),
    fat: get100g("fat"),
    saturatedFat: get100g("saturated-fat"),
    fiber: get100g("fiber"),
    sugar: get100g("sugars"),
    sodium: n.sodium_100g ? Math.round(n.sodium_100g * 1000) : (n.salt_100g ? Math.round(n.salt_100g * 400) : null), // Convert to mg
    salt: get100g("salt"),

    // Micronutrients (per 100g)
    vitaminA: get100g("vitamin-a"),
    vitaminC: get100g("vitamin-c"),
    vitaminD: get100g("vitamin-d"),
    vitaminE: get100g("vitamin-e"),
    vitaminK: get100g("vitamin-k"),
    vitaminB1: get100g("vitamin-b1"),
    vitaminB2: get100g("vitamin-b2"),
    vitaminB6: get100g("vitamin-b6"),
    vitaminB12: get100g("vitamin-b12"),
    folate: get100g("vitamin-b9"),
    calcium: get100g("calcium"),
    iron: get100g("iron"),
    magnesium: get100g("magnesium"),
    phosphorus: get100g("phosphorus"),
    potassium: get100g("potassium"),
    zinc: get100g("zinc"),
    copper: get100g("copper"),
    manganese: get100g("manganese"),
    selenium: get100g("selenium"),
    iodine: get100g("iodine"),
  };

  // Remove null values
  Object.keys(nutrition).forEach(key => {
    if (nutrition[key] === null) delete nutrition[key];
  });

  return nutrition;
}

/**
 * HTTP endpoint to enhance generic foods with OpenFoodFacts data
 *
 * Query params:
 * - limit: Max foods to process (default: 10)
 * - offset: Starting position (default: 0)
 * - dryRun: If "true", just show what would be updated (default: true)
 * - foodName: Process a specific food by name (optional)
 */
export const enhanceGenericFoods = functionsV1
  .runWith({ memory: "512MB", timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    const limit = parseInt(request.query.limit as string) || 10;
    const offset = parseInt(request.query.offset as string) || 0;
    const dryRun = request.query.dryRun !== "false";
    const specificFood = request.query.foodName as string;

    const db = admin.firestore();
    const results: EnhancementResult[] = [];

    try {
      // Get generic foods from Firebase
      let query = db.collection("generic_database").orderBy("name");

      if (specificFood) {
        // Search for specific food
        const snapshot = await db.collection("generic_database")
          .where("name", ">=", specificFood)
          .where("name", "<=", specificFood + "\uf8ff")
          .limit(5)
          .get();

        if (snapshot.empty) {
          response.json({ success: false, message: `No foods found matching: ${specificFood}` });
          return;
        }

        for (const doc of snapshot.docs) {
          const result = await processFood(doc, dryRun, db);
          results.push(result);

          // Rate limit to avoid hammering OpenFoodFacts
          await sleep(500);
        }
      } else {
        // Process batch
        const snapshot = await query.offset(offset).limit(limit).get();

        console.log(`📦 Processing ${snapshot.size} generic foods (offset: ${offset}, limit: ${limit}, dryRun: ${dryRun})`);

        for (const doc of snapshot.docs) {
          const result = await processFood(doc, dryRun, db);
          results.push(result);

          // Rate limit
          await sleep(500);
        }
      }

      const enhanced = results.filter(r => r.status === "enhanced").length;
      const noMatch = results.filter(r => r.status === "no_match").length;
      const errors = results.filter(r => r.status === "error").length;

      response.json({
        success: true,
        dryRun,
        summary: {
          processed: results.length,
          enhanced,
          noMatch,
          errors,
        },
        results,
        nextOffset: offset + limit,
      });
    } catch (error: any) {
      console.error("❌ Enhancement error:", error);
      response.status(500).json({ error: error.message });
    }
  });

/**
 * Process a single food document
 */
async function processFood(
  doc: FirebaseFirestore.QueryDocumentSnapshot,
  dryRun: boolean,
  db: FirebaseFirestore.Firestore
): Promise<EnhancementResult> {
  const data = doc.data();
  const foodName = data.name || data.foodName || "";
  const foodId = doc.id;

  try {
    // Skip if already enhanced
    if (data.enhancedFromOpenFoodFacts) {
      return {
        foodId,
        foodName,
        status: "skipped",
        message: "Already enhanced from OpenFoodFacts",
      };
    }

    // Search OpenFoodFacts
    const product = await searchOpenFoodFacts(foodName);

    if (!product) {
      return {
        foodId,
        foodName,
        status: "no_match",
        message: "No matching product found in OpenFoodFacts",
      };
    }

    // Extract nutrition data
    const nutrition = extractNutrition(product);

    if (!nutrition.calories) {
      return {
        foodId,
        foodName,
        status: "no_match",
        message: "Product found but missing calorie data",
      };
    }

    // Prepare update
    const updateData = {
      // Macros
      calories: nutrition.calories,
      protein: nutrition.protein || data.protein || 0,
      carbs: nutrition.carbs || data.carbs || 0,
      fat: nutrition.fat || data.fat || 0,
      saturatedFat: nutrition.saturatedFat || data.saturatedFat,
      fiber: nutrition.fiber || data.fiber || 0,
      sugar: nutrition.sugar || data.sugar || 0,
      sodium: nutrition.sodium || data.sodium,

      // Build micronutrient profile
      micronutrientProfile: {
        vitamins: {
          ...(nutrition.vitaminA && { vitaminA: nutrition.vitaminA }),
          ...(nutrition.vitaminC && { vitaminC: nutrition.vitaminC }),
          ...(nutrition.vitaminD && { vitaminD: nutrition.vitaminD }),
          ...(nutrition.vitaminE && { vitaminE: nutrition.vitaminE }),
          ...(nutrition.vitaminK && { vitaminK: nutrition.vitaminK }),
          ...(nutrition.vitaminB1 && { thiamine: nutrition.vitaminB1 }),
          ...(nutrition.vitaminB2 && { riboflavin: nutrition.vitaminB2 }),
          ...(nutrition.vitaminB6 && { vitaminB6: nutrition.vitaminB6 }),
          ...(nutrition.vitaminB12 && { vitaminB12: nutrition.vitaminB12 }),
          ...(nutrition.folate && { folate: nutrition.folate }),
        },
        minerals: {
          ...(nutrition.calcium && { calcium: nutrition.calcium }),
          ...(nutrition.iron && { iron: nutrition.iron }),
          ...(nutrition.magnesium && { magnesium: nutrition.magnesium }),
          ...(nutrition.phosphorus && { phosphorus: nutrition.phosphorus }),
          ...(nutrition.potassium && { potassium: nutrition.potassium }),
          ...(nutrition.zinc && { zinc: nutrition.zinc }),
          ...(nutrition.copper && { copper: nutrition.copper }),
          ...(nutrition.manganese && { manganese: nutrition.manganese }),
          ...(nutrition.selenium && { selenium: nutrition.selenium }),
          ...(nutrition.iodine && { iodine: nutrition.iodine }),
        },
        confidenceScore: "high",
        dataSource: "OpenFoodFacts",
      },

      // Metadata
      enhancedFromOpenFoodFacts: true,
      openFoodFactsSource: product.product_name,
      openFoodFactsBarcode: product.code,
      enhancedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!dryRun) {
      await db.collection("generic_database").doc(foodId).update(updateData);
      console.log(`✅ Updated ${foodName} with data from "${product.product_name}"`);
    }

    return {
      foodId,
      foodName,
      status: "enhanced",
      openFoodFactsProduct: product.product_name,
      message: dryRun
        ? `Would update with: ${nutrition.calories} kcal, ${nutrition.protein}g protein, ${nutrition.carbs}g carbs, ${nutrition.fat}g fat`
        : `Updated with data from "${product.product_name}"`,
    };
  } catch (error: any) {
    console.error(`❌ Error processing ${foodName}:`, error.message);
    return {
      foodId,
      foodName,
      status: "error",
      message: error.message,
    };
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Get enhancement stats - how many foods have been enhanced
 */
export const getEnhancementStats = functionsV1.https.onRequest(async (request, response) => {
  response.set("Access-Control-Allow-Origin", "*");
  if (request.method === "OPTIONS") {
    response.set("Access-Control-Allow-Methods", "GET");
    response.set("Access-Control-Allow-Headers", "Content-Type");
    response.status(204).send("");
    return;
  }

  const db = admin.firestore();

  try {
    const totalSnapshot = await db.collection("generic_database").count().get();
    const enhancedSnapshot = await db.collection("generic_database")
      .where("enhancedFromOpenFoodFacts", "==", true)
      .count()
      .get();

    response.json({
      total: totalSnapshot.data().count,
      enhanced: enhancedSnapshot.data().count,
      remaining: totalSnapshot.data().count - enhancedSnapshot.data().count,
      percentComplete: Math.round((enhancedSnapshot.data().count / totalSnapshot.data().count) * 100),
    });
  } catch (error: any) {
    response.status(500).json({ error: error.message });
  }
});
