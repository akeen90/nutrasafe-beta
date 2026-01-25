"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodsAlgolia = exports.deleteNewAlgoliaIndices = exports.syncNewDatabasesToAlgolia = exports.bulkImportFoodsToAlgolia = exports.configureAlgoliaIndices = exports.syncTescoProductToAlgolia = exports.syncAIManuallyAddedFoodToAlgolia = exports.syncAIEnhancedFoodToAlgolia = exports.syncUserAddedFoodToAlgolia = exports.syncManualFoodToAlgolia = exports.syncFoodToAlgolia = exports.syncVerifiedFoodToAlgolia = void 0;
const functionsV1 = require("firebase-functions");
const admin = require("firebase-admin");
const algoliasearch_1 = require("algoliasearch");
// Algolia configuration
const ALGOLIA_APP_ID = "WK0TIF84M2";
// Use functions.config() for v1 triggers (more reliable than v2 secrets)
const getAlgoliaAdminKey = () => functionsV1.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || "";
// Index names
const VERIFIED_FOODS_INDEX = "verified_foods";
const FOODS_INDEX = "foods";
const MANUAL_FOODS_INDEX = "manual_foods";
const USER_ADDED_INDEX = "user_added";
const AI_ENHANCED_INDEX = "ai_enhanced";
const AI_MANUALLY_ADDED_INDEX = "ai_manually_added";
// NEW database indices (for testing)
const NEW_MAIN_INDEX = "new_main";
const NEW_FAST_FOOD_INDEX = "new_fast_food";
const NEW_GENERIC_INDEX = "new_generic";
// Tesco products index
const TESCO_PRODUCTS_INDEX = "tesco_products";
/**
 * Configure Algolia index settings with custom ranking rules
 * This ensures exact matches and word-start matches are prioritized
 * Example: "apple" returns "apple" before "applewood"
 */
async function configureIndexSettings(client, indexName) {
    try {
        await client.setSettings({
            indexName,
            indexSettings: {
                // Searchable attributes - unordered so word position doesn't affect ranking
                // "big mac" and "mac big" will match equally
                searchableAttributes: [
                    "unordered(name)", // Highest priority - product name
                    "unordered(brandName)", // Second - brand name
                    "barcode", // Third - exact barcode match (keep ordered)
                    "unordered(ingredients)", // Lowest - ingredient text
                ],
                // Custom ranking attributes for tie-breaking
                // These are used when relevance scores are equal
                customRanking: [
                    "desc(isGeneric)", // Boost generic/raw foods (e.g., "Apple" over "Apple Pie")
                    "asc(nameLength)", // Prefer shorter names (e.g., "Apple" over "Apple & Cinnamon Cake")
                    "desc(verified)", // Verified foods rank higher
                    "desc(score)", // Nutrition score
                ],
                // Ranking criteria - controls the overall ranking formula
                // Order matters: earlier criteria have higher weight
                ranking: [
                    "typo", // Typo tolerance
                    "words", // Number of matched query words
                    "filters", // Applied filters
                    "proximity", // Proximity of matched words
                    "attribute", // Searchable attribute order (name > brandName > etc)
                    "exact", // Exact matches boost (critical for "apple" vs "applewood")
                    "custom", // Custom ranking attributes above
                ],
                // Typo tolerance settings - RELAXED for food names with short words
                // "big mac" (3+3 chars) now gets typo tolerance
                minWordSizefor1Typo: 3, // Allow 1 typo for 3+ char words (was 4)
                minWordSizefor2Typos: 6, // Allow 2 typos for 6+ char words (was 8)
                typoTolerance: true, // Full typo tolerance (was "min")
                // Exact matching settings
                // Critical for single-word queries like "apple" or "costa"
                exactOnSingleWordQuery: "word", // Boost exact word matches on single-word queries
                // Query word handling - CRITICAL FIX
                // "allOptional" means if "big mac" has no exact match, try "big" OR "mac"
                removeWordsIfNoResults: "allOptional", // Was "lastWords" - now tries all word combinations
                queryType: "prefixLast", // Enable prefix matching - "big ma" finds "big mac"
                // Language handling
                ignorePlurals: ["en"], // "apple" matches "apples"
                removeStopWords: ["en"], // Remove common stop words in English
                // Alternative matching
                alternativesAsExact: ["ignorePlurals", "singleWordSynonym"],
                // Advanced settings
                attributeForDistinct: "name", // Deduplicate by name
                distinct: true, // Enable deduplication
                // Highlighting for UI display
                attributesToHighlight: ["name", "brandName"],
                highlightPreTag: "<em>",
                highlightPostTag: "</em>",
            },
        });
        console.log(`✅ Configured custom ranking for index: ${indexName}`);
    }
    catch (error) {
        console.error(`❌ Error configuring index ${indexName}:`, error);
        throw error;
    }
}
// ⚡ DISABLED FOR PERFORMANCE: OpenFoodFacts helper functions no longer used
// function isEnglishIngredients(ingredientsText: string): boolean {
//   if (!ingredientsText || ingredientsText.trim().length === 0) return false;
//   const nonLatinPattern = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF\u0400-\u04FF\u0370-\u03FF\u0E00-\u0E7F]/;
//   if (nonLatinPattern.test(ingredientsText)) return false;
//   const nonEnglishPattern = /[áàâäãåąčćęèéêëėįìíîïłńòóôöõøùúûüųūÿýżźñçčšž]/i;
//   if (nonEnglishPattern.test(ingredientsText)) return false;
//   const englishWords = ["water", "sugar", "salt", "flour", "oil", "butter", "milk", "wheat", "ingredients"];
//   return englishWords.some((word) => new RegExp(`\\b${word}\\b`, "i").test(ingredientsText.toLowerCase()));
// }
//
// function isUKEnglishProduct(product: any): boolean {
//   const countries = product.countries_tags || product.countries || [];
//   const countriesString = Array.isArray(countries) ? countries.join(",").toLowerCase() : String(countries).toLowerCase();
//   const isUKProduct = countriesString.includes("united-kingdom") || countriesString.includes("uk") ||
//                       countriesString.includes("great-britain") || countriesString.includes("england") ||
//                       countriesString.includes("scotland") || countriesString.includes("wales") ||
//                       countriesString.includes("northern-ireland");
//   const languages = product.languages_tags || product.languages || [];
//   const languagesString = Array.isArray(languages) ? languages.join(",").toLowerCase() : String(languages).toLowerCase();
//   const hasEnglishLanguage = languagesString.includes("en") || languagesString.includes("english");
//   const ingredientsText = product.ingredients_text_en || product.ingredients_text || "";
//   const hasEnglishIngredients = isEnglishIngredients(ingredientsText);
//   return (isUKProduct || hasEnglishLanguage) && hasEnglishIngredients;
// }
// ⚡ DISABLED FOR PERFORMANCE: This function added 2-5 seconds to every search
// async function searchOpenFoodFacts(query: string): Promise<any[]> {
//   try {
//     console.log(`🌍 Searching OpenFoodFacts for: "${query}"`);
//     const response = await axios.get("https://world.openfoodfacts.org/cgi/search.pl", {
//       params: {
//         search_terms: query,
//         search_simple: 1,
//         action: "process",
//         json: 1,
//         page_size: 10,
//       },
//       timeout: 5000,
//       headers: {
//         "User-Agent": "NutraSafe/1.0 (https://nutrasafe.co.uk)",
//       },
//     });
//     if (response.data.products && response.data.products.length > 0) {
//       const ukProducts = response.data.products.filter((product: any) => isUKEnglishProduct(product));
//       console.log(`✅ Found ${ukProducts.length} UK English products out of ${response.data.products.length} total`);
//       return ukProducts;
//     }
//     return [];
//   } catch (error) {
//     console.error("❌ OpenFoodFacts API error:", error);
//     return [];
//   }
// }
// ⚡ DISABLED FOR PERFORMANCE: Helper function no longer used after removing OpenFoodFacts
// function capitalizeWords(text: string): string {
//   if (!text) return text;
//   return text
//     .split(" ")
//     .map((word) => {
//       if (!word) return word;
//       return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
//     })
//     .join(" ");
// }
// ⚡ DISABLED FOR PERFORMANCE: OpenFoodFacts integration removed
// function transformOpenFoodFactsToAlgoliaFormat(offProduct: any): any {
//   const nutriments = offProduct.nutriments || {};
//   const ingredientsText = offProduct.ingredients_text_en || offProduct.ingredients_text || "";
//   const barcode = offProduct.code || offProduct._id || "";
//   const rawName = offProduct.product_name || offProduct.product_name_en || "Unknown Product";
//   const rawBrand = offProduct.brands || "";
//   return {
//     objectID: `off-${barcode}`,
//     name: capitalizeWords(rawName),
//     brandName: rawBrand ? capitalizeWords(rawBrand) : "",
//     ingredients: ingredientsText,
//     barcode: barcode,
//     calories: nutriments["energy-kcal_100g"] || nutriments["energy-kcal"] || 0,
//     protein: nutriments.proteins_100g || nutriments.proteins || 0,
//     carbs: nutriments.carbohydrates_100g || nutriments.carbohydrates || 0,
//     fat: nutriments.fat_100g || nutriments.fat || 0,
//     fiber: nutriments.fiber_100g || nutriments.fiber || 0,
//     sugar: nutriments.sugars_100g || nutriments.sugars || 0,
//     sodium: nutriments.sodium_100g ? nutriments.sodium_100g * 1000 : (nutriments.salt_100g ? nutriments.salt_100g * 1000 : 0),
//     servingSize: "per 100g",
//     servingSizeG: 100,
//     category: "",
//     source: "OpenFoodFacts",
//     verified: false,
//     allergens: [],
//     additives: [],
//     createdAt: Date.now() / 1000,
//     updatedAt: Date.now() / 1000,
//     nutritionGrade: offProduct.nutrition_grade || "",
//     score: 0,
//     _isOpenFoodFacts: true,
//   };
// }
/**
 * Sync verified foods to Algolia when they're created/updated/deleted
 * Using v1 functions for reliability
 */
exports.syncVerifiedFoodToAlgolia = functionsV1.firestore
    .document("verifiedFoods/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: VERIFIED_FOODS_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted verified food ${foodId} from Algolia`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: VERIFIED_FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced verified food ${foodId} to Algolia`);
});
/**
 * Sync foods collection to Algolia
 */
exports.syncFoodToAlgolia = functionsV1.firestore
    .document("foods/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: FOODS_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted food ${foodId} from Algolia`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced food ${foodId} to Algolia`);
});
/**
 * Sync manual foods to Algolia
 */
exports.syncManualFoodToAlgolia = functionsV1.firestore
    .document("manualFoods/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: MANUAL_FOODS_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted manual food ${foodId} from Algolia`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: MANUAL_FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced manual food ${foodId} to Algolia`);
});
/**
 * Sync user-added foods to Algolia
 */
exports.syncUserAddedFoodToAlgolia = functionsV1.firestore
    .document("userAdded/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: USER_ADDED_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted user-added food ${foodId} from Algolia`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: USER_ADDED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced user-added food ${foodId} to Algolia`);
});
/**
 * Sync AI-enhanced foods to Algolia
 */
exports.syncAIEnhancedFoodToAlgolia = functionsV1.firestore
    .document("aiEnhanced/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: AI_ENHANCED_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted AI-enhanced food ${foodId} from Algolia`);
        return;
    }
    // Only sync approved foods
    if (afterData.status !== "approved") {
        console.log(`Skipping AI-enhanced food ${foodId} - status: ${afterData.status}`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: AI_ENHANCED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced AI-enhanced food ${foodId} to Algolia`);
});
/**
 * Sync AI manually added foods to Algolia
 */
exports.syncAIManuallyAddedFoodToAlgolia = functionsV1.firestore
    .document("aiManuallyAdded/{foodId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const foodId = context.params.foodId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: AI_MANUALLY_ADDED_INDEX,
            objectID: foodId,
        });
        console.log(`Deleted AI manually added food ${foodId} from Algolia`);
        return;
    }
    // Create or Update
    const algoliaObject = {
        objectID: foodId,
        ...prepareForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: AI_MANUALLY_ADDED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced AI manually added food ${foodId} to Algolia`);
});
/**
 * Sync Tesco products to Algolia when they're created/updated/deleted
 */
exports.syncTescoProductToAlgolia = functionsV1.firestore
    .document("tescoProducts/{productId}")
    .onWrite(async (change, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        console.error("Algolia admin key not configured");
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const productId = context.params.productId;
    const afterData = change.after.data();
    // Delete
    if (!afterData) {
        await client.deleteObject({
            indexName: TESCO_PRODUCTS_INDEX,
            objectID: productId,
        });
        console.log(`Deleted Tesco product ${productId} from Algolia`);
        return;
    }
    // Create or Update - use Tesco-specific formatting
    const algoliaObject = {
        objectID: productId,
        ...prepareTescoForAlgolia(afterData),
    };
    await client.saveObject({
        indexName: TESCO_PRODUCTS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced Tesco product ${productId} to Algolia`);
});
/**
 * Configure custom ranking settings for all Algolia indices (HTTP endpoint)
 * Call this once to set up proper search ranking
 * This enables exact match prioritization and better search results
 */
exports.configureAlgoliaIndices = functionsV1.https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
        response.set("Access-Control-Allow-Methods", "GET, POST");
        response.set("Access-Control-Allow-Headers", "Content-Type");
        response.status(204).send("");
        return;
    }
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        response.status(500).json({ error: "Algolia admin key not configured" });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const indices = [
        VERIFIED_FOODS_INDEX,
        FOODS_INDEX,
        MANUAL_FOODS_INDEX,
        USER_ADDED_INDEX,
        AI_ENHANCED_INDEX,
        AI_MANUALLY_ADDED_INDEX,
    ];
    const results = {};
    for (const indexName of indices) {
        try {
            await configureIndexSettings(client, indexName);
            results[indexName] = "success";
        }
        catch (error) {
            results[indexName] = `failed: ${error.message}`;
            console.error(`Failed to configure ${indexName}:`, error);
        }
    }
    response.json({
        success: true,
        message: "Index configuration completed",
        results,
    });
});
/**
 * Bulk import all existing foods to Algolia
 * Call this once to migrate existing data
 */
exports.bulkImportFoodsToAlgolia = functionsV1
    .runWith({ memory: "512MB", timeoutSeconds: 300 })
    .https.onCall(async (_data, context) => {
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        throw new functionsV1.https.HttpsError("failed-precondition", "Algolia admin key not configured");
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const db = admin.firestore();
    const collections = [
        { name: "verifiedFoods", indexName: VERIFIED_FOODS_INDEX },
        { name: "foods", indexName: FOODS_INDEX },
        { name: "manualFoods", indexName: MANUAL_FOODS_INDEX },
        { name: "userAdded", indexName: USER_ADDED_INDEX },
        { name: "aiEnhanced", indexName: AI_ENHANCED_INDEX },
        { name: "aiManuallyAdded", indexName: AI_MANUALLY_ADDED_INDEX },
    ];
    const results = {
        verifiedFoods: 0,
        foods: 0,
        manualFoods: 0,
        userAdded: 0,
        aiEnhanced: 0,
        aiManuallyAdded: 0,
    };
    for (const collection of collections) {
        const snapshot = await db.collection(collection.name).get();
        let algoliaObjects = snapshot.docs.map((doc) => ({
            objectID: doc.id,
            ...prepareForAlgolia(doc.data()),
        }));
        // Filter aiEnhanced to only include approved foods
        if (collection.name === "aiEnhanced") {
            const originalCount = algoliaObjects.length;
            algoliaObjects = algoliaObjects.filter((obj) => obj.status === "approved");
            console.log(`Filtered aiEnhanced: ${originalCount} total, ${algoliaObjects.length} approved`);
        }
        if (algoliaObjects.length > 0) {
            // Batch save objects
            await client.saveObjects({
                indexName: collection.indexName,
                objects: algoliaObjects,
            });
            results[collection.name] = algoliaObjects.length;
            console.log(`Imported ${algoliaObjects.length} items to ${collection.indexName}`);
        }
    }
    return {
        success: true,
        message: "Bulk import completed",
        results,
    };
});
/**
 * Sync NEW databases to Algolia
 * Syncs: newMain -> new_main, newFastFood -> new_fast_food, newGeneric -> new_generic
 */
exports.syncNewDatabasesToAlgolia = functionsV1
    .runWith({ memory: "1GB", timeoutSeconds: 540 })
    .https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
        response.set("Access-Control-Allow-Methods", "GET, POST");
        response.set("Access-Control-Allow-Headers", "Content-Type");
        response.status(204).send("");
        return;
    }
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        response.status(500).json({ error: "Algolia admin key not configured" });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const db = admin.firestore();
    const collections = [
        { name: "newMain", indexName: NEW_MAIN_INDEX },
        { name: "newFastFood", indexName: NEW_FAST_FOOD_INDEX },
        { name: "newGeneric", indexName: NEW_GENERIC_INDEX },
    ];
    const results = {};
    for (const collection of collections) {
        console.log(`📦 Processing ${collection.name}...`);
        const snapshot = await db.collection(collection.name).get();
        const algoliaObjects = snapshot.docs.map((doc) => ({
            objectID: doc.id,
            ...prepareForAlgolia(doc.data()),
        }));
        if (algoliaObjects.length > 0) {
            // Configure index settings first
            await configureIndexSettings(client, collection.indexName);
            // Batch save in chunks of 1000 (Algolia limit)
            const BATCH_SIZE = 1000;
            for (let i = 0; i < algoliaObjects.length; i += BATCH_SIZE) {
                const batch = algoliaObjects.slice(i, i + BATCH_SIZE);
                await client.saveObjects({
                    indexName: collection.indexName,
                    objects: batch,
                });
                console.log(`  Synced ${Math.min(i + BATCH_SIZE, algoliaObjects.length)}/${algoliaObjects.length}`);
            }
            results[collection.name] = algoliaObjects.length;
            console.log(`✅ Imported ${algoliaObjects.length} items to ${collection.indexName}`);
        }
        else {
            results[collection.name] = 0;
            console.log(`⚠️ No items found in ${collection.name}`);
        }
    }
    response.json({
        success: true,
        message: "New databases synced to Algolia",
        results,
    });
});
/**
 * Delete new database indices from Algolia (cleanup function)
 */
exports.deleteNewAlgoliaIndices = functionsV1.https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
        response.set("Access-Control-Allow-Methods", "GET, POST, DELETE");
        response.set("Access-Control-Allow-Headers", "Content-Type");
        response.status(204).send("");
        return;
    }
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        response.status(500).json({ error: "Algolia admin key not configured" });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    const indicesToDelete = ["new_main", "new_fast_food", "new_generic"];
    const results = {};
    for (const indexName of indicesToDelete) {
        try {
            await client.deleteIndex({ indexName });
            results[indexName] = "deleted";
            console.log(`✅ Deleted Algolia index: ${indexName}`);
        }
        catch (err) {
            results[indexName] = `error: ${err.message}`;
            console.error(`❌ Failed to delete ${indexName}:`, err.message);
        }
    }
    response.json({ success: true, results });
});
/**
 * Search foods using Algolia with enhanced ranking
 * This provides a fast search endpoint for the iOS app with improved relevance
 */
exports.searchFoodsAlgolia = functionsV1.https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
        response.set("Access-Control-Allow-Methods", "GET, POST");
        response.set("Access-Control-Allow-Headers", "Content-Type");
        response.status(204).send("");
        return;
    }
    // Get query from URL parameter for GET requests
    const query = request.query.q;
    const hitsPerPage = parseInt(request.query.limit) || 20;
    if (!query || typeof query !== "string") {
        response.status(400).json({
            error: "Query parameter 'q' is required",
        });
        return;
    }
    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
        response.status(500).json({ error: "Algolia admin key not configured" });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
    // Determine if this is a single-word query (affects exact matching)
    const isSingleWord = query.trim().split(/\s+/).length === 1;
    // Enhanced search parameters - let index settings handle most config
    // Don't override the carefully tuned index settings!
    const searchParams = {
        query,
        hitsPerPage: hitsPerPage * 2, // Fetch more to allow for proper cross-index ranking
        // Query strategy
        // For single words like "apple" or "costa", prioritize exact matches
        exactOnSingleWordQuery: (isSingleWord ? "word" : "attribute"),
        // Typo tolerance - always enabled, let index settings control the details
        // Previously this was disabled for short queries which broke "big mac"
        typoTolerance: true,
        // CRITICAL: Use allOptional so "big mac" finds results even if only one word matches
        // This is the key fix for the search problem
        removeWordsIfNoResults: "allOptional",
        // Enable Query Rules for synonym expansion
        enableRules: true,
        // Advanced settings
        advancedSyntax: false, // Keep simple for users
        removeStopWords: true, // Remove "and", "or", "the" automatically
        // Get ranking info for cross-index sorting
        getRankingInfo: true,
    };
    // Search across all food indices
    const indices = [
        USER_ADDED_INDEX, // User-added (highest priority)
        AI_ENHANCED_INDEX, // AI-enhanced
        AI_MANUALLY_ADDED_INDEX, // AI manually added
        FOODS_INDEX, // Main database (24,150+ foods)
    ];
    const searchResults = await Promise.all(indices.map((indexName) => client.searchSingleIndex({
        indexName,
        searchParams,
    }).catch((error) => {
        // Ignore errors from non-existent indices
        console.log(`Index ${indexName} not found or error: ${error.message}`);
        return { hits: [], nbHits: 0 };
    })));
    // Combine all results from all indices
    const allHits = [
        ...searchResults[0].hits.map((h) => ({ ...h, _sourceIndex: "user_added", _sourcePriority: 0 })),
        ...searchResults[1].hits.map((h) => ({ ...h, _sourceIndex: "ai_enhanced", _sourcePriority: 1 })),
        ...searchResults[2].hits.map((h) => ({ ...h, _sourceIndex: "ai_manually_added", _sourcePriority: 2 })),
        ...searchResults[3].hits.map((h) => ({ ...h, _sourceIndex: "foods", _sourcePriority: 3 })),
    ];
    // Sort by Algolia's relevance ranking, NOT by index priority
    // This ensures "Big Mac" (matching both words) ranks before "Huel" (matching one word)
    const combinedHits = allHits.sort((a, b) => {
        const rankA = a._rankingInfo || {};
        const rankB = b._rankingInfo || {};
        // 1. More matched query words = better (MOST IMPORTANT)
        // "Big Mac" matching both "big" and "mac" beats Huel matching just one
        const wordsA = rankA.words || 0;
        const wordsB = rankB.words || 0;
        if (wordsB !== wordsA)
            return wordsB - wordsA;
        // 2. Fewer typos = better
        const typosA = rankA.nbTypos || 0;
        const typosB = rankB.nbTypos || 0;
        if (typosA !== typosB)
            return typosA - typosB;
        // 3. More exact words = better
        const exactA = rankA.nbExactWords || 0;
        const exactB = rankB.nbExactWords || 0;
        if (exactB !== exactA)
            return exactB - exactA;
        // 4. Closer proximity = better (for multi-word queries)
        const proxA = rankA.proximityDistance || 0;
        const proxB = rankB.proximityDistance || 0;
        if (proxA !== proxB)
            return proxA - proxB;
        // 5. Finally, use source priority as tiebreaker
        return a._sourcePriority - b._sourcePriority;
    });
    // ⚡ PERFORMANCE OPTIMIZATION: Removed blocking OpenFoodFacts API call
    // Previously this added 2-5 seconds to every search request
    // OpenFoodFacts enrichment can be done via separate background job if needed
    console.log(`✅ Returning ${combinedHits.length} Algolia results for query "${query}" (single word: ${isSingleWord})`);
    // Return Algolia results immediately for fast search experience
    response.json({
        hits: combinedHits.slice(0, hitsPerPage),
        nbHits: combinedHits.length,
    });
});
/**
 * Prepare food data for Algolia indexing
 * This transforms the Firebase document into an Algolia-optimized format
 */
function prepareForAlgolia(data) {
    const name = data.name || data.foodName || "";
    const brandName = data.brandName || data.brand || "";
    // Custom ranking attributes
    const nameLength = name.length; // Shorter names rank higher (e.g., "Apple" > "Apple Pie")
    const isGeneric = (brandName.toLowerCase() === "generic" || brandName === "") ? 1 : 0; // Generic/raw foods rank higher
    return {
        // Searchable fields
        name,
        brandName,
        ingredients: Array.isArray(data.ingredients) ? data.ingredients : (data.ingredients ? [data.ingredients] : []),
        barcode: data.barcode || "",
        // Nutrition data for filtering
        calories: data.calories || 0,
        protein: data.protein || 0,
        carbs: data.carbs || 0,
        fat: data.fat || 0,
        saturatedFat: data.saturatedFat || data.saturated_fat || 0,
        fiber: data.fiber || 0,
        sugar: data.sugar || 0,
        sodium: data.sodium || 0,
        // Metadata
        servingSize: data.servingDescription || data.serving_description || data.servingSize || data.serving_size || "",
        servingSizeG: data.servingSizeG || data.serving_size_g || (typeof data.servingSize === 'number' ? data.servingSize : 0),
        per_unit_nutrition: data.per_unit_nutrition || data.isPerUnit || false,
        category: data.category || "",
        source: data.source || "",
        verified: data.verified || data.isVerified || false,
        isVerified: data.isVerified || data.verified || false,
        // Allergen info
        allergens: data.allergens || [],
        additives: data.additives || [],
        // Timestamps
        createdAt: data.createdAt?._seconds || Date.now() / 1000,
        updatedAt: data.updatedAt?._seconds || Date.now() / 1000,
        // Nutrition score for ranking
        nutritionGrade: data.nutritionGrade || data.nutrition_grade || "",
        score: data.score || 0,
        // Custom ranking attributes for improved search results
        nameLength, // Shorter names = better matches (e.g., "Apple" ranks before "Apple & Cinnamon Cake")
        isGeneric, // Generic/raw foods = better matches (e.g., "Apple" ranks before "Applewood Cheese")
        // TODO: Precompute processing grade here to eliminate 50-200ms frontend calculation
        // Would require porting ProcessingScorer.swift logic to TypeScript
        // Current implementation: Frontend computes on-demand with NSCache
        processingGrade: data.processingGrade || "",
    };
}
/**
 * Prepare Tesco product data for Algolia indexing
 * Maps Tesco-specific fields to Algolia format
 *
 * Tesco Firestore structure:
 * - title (product name)
 * - brand (brand name)
 * - nutrition.energyKcal, nutrition.protein, nutrition.carbohydrate, etc.
 * - ingredients (string)
 * - gtin (barcode)
 */
function prepareTescoForAlgolia(data) {
    // Map Tesco field names to standard format
    const name = data.title || data.foodName || data.name || "";
    const brandName = data.brand || data.brandName || "Tesco";
    // Extract nutrition from nested object
    const nutrition = data.nutrition || {};
    const calories = nutrition.energyKcal || data.calories || 0;
    const protein = nutrition.protein || data.protein || 0;
    const carbs = nutrition.carbohydrate || data.carbs || 0;
    const fat = nutrition.fat || data.fat || 0;
    const saturates = nutrition.saturates || data.saturatedFat || 0;
    const fibre = nutrition.fibre || data.fiber || 0;
    const sugars = nutrition.sugars || data.sugar || 0;
    const salt = nutrition.salt || data.salt || 0;
    // Custom ranking attributes
    const nameLength = name.length;
    const isGeneric = (brandName.toLowerCase() === "generic" || brandName === "") ? 1 : 0;
    return {
        // Searchable fields - use consistent naming for admin UI
        name,
        foodName: name, // Admin UI uses foodName
        brandName,
        brand: brandName,
        ingredients: data.ingredients || "",
        barcode: data.gtin || data.barcode || "",
        gtin: data.gtin || data.barcode || "",
        // Nutrition data (per 100g) - mapped from nested nutrition object
        calories,
        protein,
        carbs,
        fat,
        saturatedFat: saturates,
        saturates,
        fiber: fibre,
        fibre,
        sugar: sugars,
        sugars,
        salt,
        sodium: salt ? salt * 400 : 0, // Convert salt to sodium
        // Tesco-specific fields
        tpnb: data.tpnb || "",
        tpnc: data.tpnc || "",
        department: data.department || "",
        superDepartment: data.superDepartment || "",
        imageUrl: data.imageUrl || "",
        // Image quality flags (from Vision AI filtering)
        imageQuality: data.imageQuality || undefined,
        imageFlags: data.imageFlags || undefined,
        flaggedAt: data.flaggedAt || undefined,
        // Metadata - extract numeric serving size from string like "250ml" or "30g"
        servingSize: data.servingSize || "per 100g",
        servingSizeG: (() => {
            const servingStr = data.servingSize || "";
            const match = servingStr.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            return match ? parseFloat(match[1]) : 100;
        })(),
        category: data.category || data.department || "",
        source: "Tesco",
        verified: true,
        isVerified: true,
        // Allergen info
        allergens: data.allergens || [],
        additives: data.additives || [],
        // Timestamps
        createdAt: data.importedAt || Date.now() / 1000,
        updatedAt: data.importedAt || Date.now() / 1000,
        // Custom ranking attributes
        nameLength,
        isGeneric,
        score: 0,
    };
}
//# sourceMappingURL=algolia-sync.js.map