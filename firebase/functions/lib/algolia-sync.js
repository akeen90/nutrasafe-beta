"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodsAlgolia = exports.bulkImportFoodsToAlgolia = exports.syncAIManuallyAddedFoodToAlgolia = exports.syncAIEnhancedFoodToAlgolia = exports.syncUserAddedFoodToAlgolia = exports.syncManualFoodToAlgolia = exports.syncFoodToAlgolia = exports.syncVerifiedFoodToAlgolia = void 0;
const functions = require("firebase-functions/v2");
const firestore_1 = require("firebase-functions/v2/firestore");
const params_1 = require("firebase-functions/params");
const admin = require("firebase-admin");
const algoliasearch_1 = require("algoliasearch");
// import axios from "axios"; // ⚡ Disabled: No longer used after removing OpenFoodFacts
// Algolia configuration
const ALGOLIA_APP_ID = "WK0TIF84M2";
const algoliaAdminKey = (0, params_1.defineSecret)("ALGOLIA_ADMIN_API_KEY");
// Index names
const VERIFIED_FOODS_INDEX = "verified_foods";
const FOODS_INDEX = "foods";
const MANUAL_FOODS_INDEX = "manual_foods";
const USER_ADDED_INDEX = "user_added";
const AI_ENHANCED_INDEX = "ai_enhanced";
const AI_MANUALLY_ADDED_INDEX = "ai_manually_added";
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
 */
exports.syncVerifiedFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "verifiedFoods/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: VERIFIED_FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced verified food ${foodId} to Algolia`);
});
/**
 * Sync foods collection to Algolia
 */
exports.syncFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "foods/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced food ${foodId} to Algolia`);
});
/**
 * Sync manual foods to Algolia
 */
exports.syncManualFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "manualFoods/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: MANUAL_FOODS_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced manual food ${foodId} to Algolia`);
});
/**
 * Sync user-added foods to Algolia
 */
exports.syncUserAddedFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "userAdded/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: USER_ADDED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced user-added food ${foodId} to Algolia`);
});
/**
 * Sync AI-enhanced foods to Algolia
 */
exports.syncAIEnhancedFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "aiEnhanced/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: AI_ENHANCED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced AI-enhanced food ${foodId} to Algolia`);
});
/**
 * Sync AI manually added foods to Algolia
 */
exports.syncAIManuallyAddedFoodToAlgolia = (0, firestore_1.onDocumentWritten)({
    document: "aiManuallyAdded/{foodId}",
    secrets: [algoliaAdminKey],
}, async (event) => {
    var _a, _b;
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const foodId = event.params.foodId;
    const afterData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
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
    const algoliaObject = Object.assign({ objectID: foodId }, prepareForAlgolia(afterData));
    await client.saveObject({
        indexName: AI_MANUALLY_ADDED_INDEX,
        body: algoliaObject,
    });
    console.log(`Synced AI manually added food ${foodId} to Algolia`);
});
/**
 * Bulk import all existing foods to Algolia
 * Call this once to migrate existing data
 */
exports.bulkImportFoodsToAlgolia = functions.https.onCall({
    secrets: [algoliaAdminKey],
    memory: "512MiB", // Increased memory for bulk operations
    timeoutSeconds: 300, // 5 minutes timeout for large datasets
}, async (request) => {
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
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
        let algoliaObjects = snapshot.docs.map((doc) => (Object.assign({ objectID: doc.id }, prepareForAlgolia(doc.data()))));
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
 * Search foods using Algolia
 * This provides a fast search endpoint for the iOS app
 */
exports.searchFoodsAlgolia = functions.https.onRequest({
    secrets: [algoliaAdminKey],
    cors: true,
}, async (request, response) => {
    // Get query from URL parameter for GET requests
    const query = request.query.q;
    const hitsPerPage = parseInt(request.query.limit) || 20;
    if (!query || typeof query !== "string") {
        response.status(400).json({
            error: "Query parameter 'q' is required",
        });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    // Search across all food indices
    const indices = [
        USER_ADDED_INDEX, // User-added (highest priority)
        AI_ENHANCED_INDEX, // AI-enhanced
        AI_MANUALLY_ADDED_INDEX, // AI manually added
        FOODS_INDEX, // Main database (24,150+ foods)
    ];
    const searchResults = await Promise.all(indices.map((indexName) => client.searchSingleIndex({
        indexName,
        searchParams: {
            query,
            hitsPerPage,
        },
    }).catch((error) => {
        // Ignore errors from non-existent indices
        console.log(`Index ${indexName} not found or error: ${error.message}`);
        return { hits: [], nbHits: 0 };
    })));
    // Combine results with priority: user-added > AI-enhanced > AI-manual > foods
    const combinedHits = [
        ...searchResults[0].hits, // User-added first
        ...searchResults[1].hits, // AI-enhanced
        ...searchResults[2].hits, // AI manually added
        ...searchResults[3].hits, // Main foods
    ];
    // ⚡ PERFORMANCE OPTIMIZATION: Removed blocking OpenFoodFacts API call
    // Previously this added 2-5 seconds to every search request
    // OpenFoodFacts enrichment can be done via separate background job if needed
    console.log(`✅ Returning ${combinedHits.length} Algolia results (OpenFoodFacts disabled for performance)`);
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
    var _a, _b;
    return {
        // Searchable fields
        name: data.name || data.foodName || "",
        brandName: data.brandName || data.brand || "",
        ingredients: data.ingredients || "",
        barcode: data.barcode || "",
        // Nutrition data for filtering
        calories: data.calories || 0,
        protein: data.protein || 0,
        carbs: data.carbs || 0,
        fat: data.fat || 0,
        fiber: data.fiber || 0,
        sugar: data.sugar || 0,
        sodium: data.sodium || 0,
        // Metadata
        servingSize: data.servingSize || data.serving_size || data.servingDescription || data.serving_description || "",
        servingSizeG: data.servingSizeG || data.serving_size_g || 0,
        per_unit_nutrition: data.per_unit_nutrition || false,
        category: data.category || "",
        source: data.source || "",
        verified: data.verified || false,
        // Allergen info
        allergens: data.allergens || [],
        additives: data.additives || [],
        // Timestamps
        createdAt: ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a._seconds) || Date.now() / 1000,
        updatedAt: ((_b = data.updatedAt) === null || _b === void 0 ? void 0 : _b._seconds) || Date.now() / 1000,
        // Nutrition score for ranking
        nutritionGrade: data.nutritionGrade || data.nutrition_grade || "",
        score: data.score || 0,
        // TODO: Precompute processing grade here to eliminate 50-200ms frontend calculation
        // Would require porting ProcessingScorer.swift logic to TypeScript
        // Current implementation: Frontend computes on-demand with NSCache
        processingGrade: data.processingGrade || "",
    };
}
//# sourceMappingURL=algolia-sync.js.map