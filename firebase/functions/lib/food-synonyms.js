"use strict";
/**
 * Food Synonyms for Algolia Search
 * Practical synonyms to improve food search relevance
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearSynonymsFromAlgolia = exports.getSynonymStats = exports.syncSynonymsToAlgolia = void 0;
const functions = require("firebase-functions/v2");
const params_1 = require("firebase-functions/params");
const algoliasearch_1 = require("algoliasearch");
const ALGOLIA_APP_ID = "WK0TIF84M2";
const algoliaAdminKey = (0, params_1.defineSecret)("ALGOLIA_ADMIN_API_KEY");
// All indices to sync synonyms to
const ALL_INDICES = [
    "verified_foods",
    "foods",
    "manual_foods",
    "user_added",
    "ai_enhanced",
    "ai_manually_added",
];
/**
 * A. Fast Food Menu Items (One-way synonyms)
 * When user searches "big mac", also search for McDonald's products
 */
const FAST_FOOD_MENU_SYNONYMS = [
    // McDonald's
    { objectID: "menu-big-mac", type: "onewaysynonym", input: "big mac", synonyms: ["mcdonald's big mac", "mcdonalds big mac"] },
    { objectID: "menu-quarter-pounder", type: "onewaysynonym", input: "quarter pounder", synonyms: ["mcdonald's quarter pounder", "mcdonalds quarter pounder"] },
    { objectID: "menu-mcflurry", type: "onewaysynonym", input: "mcflurry", synonyms: ["mcdonald's mcflurry", "mcdonalds mcflurry"] },
    { objectID: "menu-mcnuggets", type: "onewaysynonym", input: "mcnuggets", synonyms: ["mcdonald's chicken mcnuggets", "mcdonalds mcnuggets"] },
    { objectID: "menu-filet-o-fish", type: "onewaysynonym", input: "filet o fish", synonyms: ["mcdonald's filet-o-fish", "mcdonalds filet o fish"] },
    { objectID: "menu-egg-mcmuffin", type: "onewaysynonym", input: "egg mcmuffin", synonyms: ["mcdonald's egg mcmuffin", "mcdonalds mcmuffin"] },
    { objectID: "menu-happy-meal", type: "onewaysynonym", input: "happy meal", synonyms: ["mcdonald's happy meal", "mcdonalds happy meal"] },
    { objectID: "menu-mcchicken", type: "onewaysynonym", input: "mcchicken", synonyms: ["mcdonald's mcchicken", "mcdonalds mcchicken"] },
    // Burger King
    { objectID: "menu-whopper", type: "onewaysynonym", input: "whopper", synonyms: ["burger king whopper"] },
    { objectID: "menu-whopper-jr", type: "onewaysynonym", input: "whopper jr", synonyms: ["burger king whopper jr", "burger king whopper junior"] },
    // KFC
    { objectID: "menu-zinger", type: "onewaysynonym", input: "zinger", synonyms: ["kfc zinger", "kfc zinger burger"] },
    { objectID: "menu-popcorn-chicken", type: "onewaysynonym", input: "popcorn chicken", synonyms: ["kfc popcorn chicken"] },
    // Subway
    { objectID: "menu-footlong", type: "onewaysynonym", input: "footlong", synonyms: ["subway footlong", "subway 12 inch"] },
    { objectID: "menu-bmt", type: "onewaysynonym", input: "italian bmt", synonyms: ["subway italian bmt", "subway bmt"] },
    { objectID: "menu-meatball-marinara", type: "onewaysynonym", input: "meatball marinara", synonyms: ["subway meatball marinara"] },
    // Greggs
    { objectID: "menu-sausage-roll", type: "onewaysynonym", input: "sausage roll", synonyms: ["greggs sausage roll"] },
    { objectID: "menu-steak-bake", type: "onewaysynonym", input: "steak bake", synonyms: ["greggs steak bake"] },
    { objectID: "menu-festive-bake", type: "onewaysynonym", input: "festive bake", synonyms: ["greggs festive bake"] },
    { objectID: "menu-vegan-sausage-roll", type: "onewaysynonym", input: "vegan sausage roll", synonyms: ["greggs vegan sausage roll"] },
    // Nando's
    { objectID: "menu-peri-peri", type: "onewaysynonym", input: "peri peri", synonyms: ["nando's peri peri", "nandos peri peri"] },
    // Costa
    { objectID: "menu-costa-flat-white", type: "onewaysynonym", input: "flat white", synonyms: ["costa flat white", "costa coffee flat white"] },
    { objectID: "menu-costa-latte", type: "onewaysynonym", input: "latte", synonyms: ["costa latte", "costa coffee latte"] },
    // Starbucks
    { objectID: "menu-frappuccino", type: "onewaysynonym", input: "frappuccino", synonyms: ["starbucks frappuccino"] },
    { objectID: "menu-caramel-macchiato", type: "onewaysynonym", input: "caramel macchiato", synonyms: ["starbucks caramel macchiato"] },
    // Domino's
    { objectID: "menu-stuffed-crust", type: "onewaysynonym", input: "stuffed crust", synonyms: ["domino's stuffed crust", "dominos stuffed crust"] },
    // Wagamama
    { objectID: "menu-katsu-curry", type: "onewaysynonym", input: "katsu curry", synonyms: ["wagamama katsu curry"] },
];
/**
 * B. Brand Spelling Variations (Two-way synonyms)
 * Handle apostrophe differences and common variations
 */
const BRAND_SPELLING_SYNONYMS = [
    { objectID: "brand-mcdonalds", type: "synonym", synonyms: ["mcdonald's", "mcdonalds"] },
    { objectID: "brand-kfc", type: "synonym", synonyms: ["kfc", "kentucky fried chicken"] },
    { objectID: "brand-nandos", type: "synonym", synonyms: ["nando's", "nandos"] },
    { objectID: "brand-sainsburys", type: "synonym", synonyms: ["sainsbury's", "sainsburys"] },
    { objectID: "brand-tescos", type: "synonym", synonyms: ["tesco's", "tesco", "tescos"] },
    { objectID: "brand-dominos", type: "synonym", synonyms: ["domino's", "dominos"] },
    { objectID: "brand-bighams", type: "synonym", synonyms: ["charlie bigham's", "charlie bighams", "bighams"] },
    { objectID: "brand-ms", type: "synonym", synonyms: ["marks & spencer", "marks and spencer", "m&s"] },
    { objectID: "brand-pret", type: "synonym", synonyms: ["pret a manger", "pret"] },
    { objectID: "brand-costa", type: "synonym", synonyms: ["costa coffee", "costa"] },
    { objectID: "brand-morrisons", type: "synonym", synonyms: ["morrisons", "morrison's"] },
    { objectID: "brand-asda", type: "synonym", synonyms: ["asda", "asda's"] },
    { objectID: "brand-waitrose", type: "synonym", synonyms: ["waitrose", "waitrose & partners"] },
];
/**
 * C. UK/US Spelling Variations (Two-way synonyms)
 * Critical for a UK food app
 */
const UK_US_SPELLING_SYNONYMS = [
    // Food items with different names
    { objectID: "ukus-crisps-chips", type: "synonym", synonyms: ["crisps", "chips", "potato chips"] },
    { objectID: "ukus-chips-fries", type: "synonym", synonyms: ["chips", "fries", "french fries"] },
    { objectID: "ukus-biscuit", type: "synonym", synonyms: ["biscuit", "cookie", "biscuits", "cookies"] },
    { objectID: "ukus-sweets", type: "synonym", synonyms: ["sweets", "candy", "candies"] },
    { objectID: "ukus-aubergine", type: "synonym", synonyms: ["aubergine", "eggplant"] },
    { objectID: "ukus-courgette", type: "synonym", synonyms: ["courgette", "zucchini"] },
    { objectID: "ukus-rocket", type: "synonym", synonyms: ["rocket", "arugula"] },
    { objectID: "ukus-coriander", type: "synonym", synonyms: ["coriander", "cilantro"] },
    { objectID: "ukus-spring-onion", type: "synonym", synonyms: ["spring onion", "scallion", "green onion"] },
    { objectID: "ukus-prawn", type: "synonym", synonyms: ["prawn", "shrimp", "prawns", "shrimps"] },
    { objectID: "ukus-mince", type: "synonym", synonyms: ["mince", "ground meat", "minced meat", "ground beef"] },
    { objectID: "ukus-jacket-potato", type: "synonym", synonyms: ["jacket potato", "baked potato"] },
    // Spelling differences
    { objectID: "ukus-yoghurt", type: "synonym", synonyms: ["yoghurt", "yogurt"] },
    { objectID: "ukus-fibre", type: "synonym", synonyms: ["fibre", "fiber"] },
    { objectID: "ukus-flavour", type: "synonym", synonyms: ["flavour", "flavor", "flavoured", "flavored"] },
    { objectID: "ukus-colour", type: "synonym", synonyms: ["colour", "color", "coloured", "colored"] },
    { objectID: "ukus-doughnut", type: "synonym", synonyms: ["doughnut", "donut", "doughnuts", "donuts"] },
    { objectID: "ukus-porridge", type: "synonym", synonyms: ["porridge", "oatmeal"] },
    { objectID: "ukus-treacle", type: "synonym", synonyms: ["treacle", "molasses"] },
    { objectID: "ukus-icing-sugar", type: "synonym", synonyms: ["icing sugar", "powdered sugar", "confectioners sugar"] },
    { objectID: "ukus-caster-sugar", type: "synonym", synonyms: ["caster sugar", "superfine sugar"] },
    { objectID: "ukus-lasagne", type: "synonym", synonyms: ["lasagne", "lasagna"] },
    { objectID: "ukus-mangetout", type: "synonym", synonyms: ["mangetout", "snow peas", "sugar snap peas"] },
    { objectID: "ukus-pepper", type: "synonym", synonyms: ["pepper", "bell pepper", "capsicum"] },
];
/**
 * D. Common Meal Names (Two-way synonyms)
 */
const COMMON_MEAL_SYNONYMS = [
    { objectID: "meal-spag-bol", type: "synonym", synonyms: ["spaghetti bolognese", "spag bol", "bolognese"] },
    { objectID: "meal-mac-cheese", type: "synonym", synonyms: ["macaroni cheese", "mac and cheese", "mac n cheese"] },
    { objectID: "meal-fish-chips", type: "synonym", synonyms: ["fish and chips", "fish & chips", "fish n chips"] },
    { objectID: "meal-bangers-mash", type: "synonym", synonyms: ["sausage and mash", "bangers and mash", "sausages and mash"] },
    { objectID: "meal-full-english", type: "synonym", synonyms: ["full english breakfast", "english breakfast", "full english"] },
    { objectID: "meal-sunday-roast", type: "synonym", synonyms: ["sunday roast", "roast dinner", "sunday dinner"] },
    { objectID: "meal-shepherds-pie", type: "synonym", synonyms: ["shepherd's pie", "shepherds pie", "cottage pie"] },
    { objectID: "meal-tikka-masala", type: "synonym", synonyms: ["chicken tikka masala", "tikka masala"] },
];
/**
 * E. Food Type Variations (Two-way synonyms)
 */
const FOOD_TYPE_SYNONYMS = [
    { objectID: "type-burger", type: "synonym", synonyms: ["hamburger", "burger", "beefburger"] },
    { objectID: "type-fries", type: "synonym", synonyms: ["french fries", "fries"] },
    { objectID: "type-soda", type: "synonym", synonyms: ["fizzy drink", "soft drink", "soda", "pop"] },
    { objectID: "type-takeaway", type: "synonym", synonyms: ["takeaway", "takeout", "take away", "take out"] },
];
/**
 * G. Generic Meat Cuts (One-way synonyms)
 * Common search terms that should find specific database entries
 */
const MEAT_CUT_SYNONYMS = [
    // Steak cuts - user searches simple name, finds full database name
    { objectID: "meat-fillet-steak", type: "onewaysynonym", input: "fillet steak", synonyms: ["beef steak fillet grilled", "beef fillet grilled", "beef fillet"] },
    { objectID: "meat-sirloin-steak", type: "onewaysynonym", input: "sirloin steak", synonyms: ["beef steak sirloin grilled", "beef sirloin grilled", "beef sirloin"] },
    { objectID: "meat-ribeye-steak", type: "onewaysynonym", input: "ribeye steak", synonyms: ["beef steak ribeye grilled", "beef ribeye grilled", "beef ribeye"] },
    { objectID: "meat-rump-steak", type: "onewaysynonym", input: "rump steak", synonyms: ["beef steak rump grilled", "beef rump grilled", "beef rump"] },
    { objectID: "meat-tbone-steak", type: "onewaysynonym", input: "t-bone steak", synonyms: ["beef t-bone steak", "t bone steak"] },
    // Reverse - database name finds simple search
    { objectID: "meat-beef-fillet", type: "onewaysynonym", input: "beef fillet", synonyms: ["fillet steak", "fillet steak grilled"] },
    // Chicken
    { objectID: "meat-chicken-breast", type: "onewaysynonym", input: "chicken breast", synonyms: ["chicken breast grilled", "chicken breast fried", "chicken breast roasted"] },
    { objectID: "meat-chicken-thigh", type: "onewaysynonym", input: "chicken thigh", synonyms: ["chicken thigh grilled", "chicken thigh roasted"] },
    // Pork
    { objectID: "meat-pork-chop", type: "onewaysynonym", input: "pork chop", synonyms: ["pork chop grilled", "pork chop fried", "pork loin chop grilled"] },
    { objectID: "meat-pork-loin", type: "onewaysynonym", input: "pork loin", synonyms: ["pork loin roasted", "pork loin grilled"] },
    // Lamb
    { objectID: "meat-lamb-chop", type: "onewaysynonym", input: "lamb chop", synonyms: ["lamb chop grilled", "lamb loin chop grilled"] },
    { objectID: "meat-leg-lamb", type: "onewaysynonym", input: "leg of lamb", synonyms: ["lamb leg roasted", "roast lamb leg"] },
    // Fish
    { objectID: "meat-salmon-fillet", type: "onewaysynonym", input: "salmon fillet", synonyms: ["salmon fillet grilled", "salmon fillet baked", "salmon fillet poached"] },
    { objectID: "meat-cod-fillet", type: "onewaysynonym", input: "cod fillet", synonyms: ["cod fillet baked", "cod fillet grilled", "cod fillet fried"] },
    { objectID: "meat-tuna-steak", type: "onewaysynonym", input: "tuna steak", synonyms: ["tuna steak grilled"] },
];
/**
 * F. Common Misspellings (as regular synonyms since alt corrections don't support multi-word)
 * Using regular synonyms means these are treated equally in results
 */
const MISSPELLING_SYNONYMS = [
    { objectID: "typo-macdonalds", type: "synonym", synonyms: ["macdonalds", "mcdonalds"] },
    { objectID: "typo-mcdonolds", type: "synonym", synonyms: ["mcdonolds", "mcdonalds"] },
    { objectID: "typo-spagetti", type: "synonym", synonyms: ["spagetti", "spaghetti"] },
    { objectID: "typo-spagheti", type: "synonym", synonyms: ["spagheti", "spaghetti"] },
    { objectID: "typo-brocolli", type: "synonym", synonyms: ["brocolli", "broccoli"] },
    { objectID: "typo-brocoli", type: "synonym", synonyms: ["brocoli", "broccoli"] },
    { objectID: "typo-cappucino", type: "synonym", synonyms: ["cappucino", "cappuccino"] },
    { objectID: "typo-capuccino", type: "synonym", synonyms: ["capuccino", "cappuccino"] },
    { objectID: "typo-parmasan", type: "synonym", synonyms: ["parmasan", "parmesan"] },
    { objectID: "typo-parmasean", type: "synonym", synonyms: ["parmasean", "parmesan"] },
    { objectID: "typo-ceasar", type: "synonym", synonyms: ["ceasar", "caesar"] },
    { objectID: "typo-cesear", type: "synonym", synonyms: ["cesear", "caesar"] },
    { objectID: "typo-lasanga", type: "synonym", synonyms: ["lasanga", "lasagne"] },
    { objectID: "typo-resturant", type: "synonym", synonyms: ["resturant", "restaurant"] },
    { objectID: "typo-sandwhich", type: "synonym", synonyms: ["sandwhich", "sandwich"] },
    { objectID: "typo-sandwitch", type: "synonym", synonyms: ["sandwitch", "sandwich"] },
    { objectID: "typo-protien", type: "synonym", synonyms: ["protien", "protein"] },
    { objectID: "typo-calroies", type: "synonym", synonyms: ["calroies", "calories"] },
    { objectID: "typo-nutrtion", type: "synonym", synonyms: ["nutrtion", "nutrition"] },
    { objectID: "typo-gregs", type: "synonym", synonyms: ["gregs", "greggs"] },
    { objectID: "typo-nandoes", type: "synonym", synonyms: ["nandoes", "nandos"] },
];
// =============================================================================
// COMBINE ALL SYNONYMS
// =============================================================================
const ALL_SYNONYMS = [
    ...FAST_FOOD_MENU_SYNONYMS,
    ...BRAND_SPELLING_SYNONYMS,
    ...UK_US_SPELLING_SYNONYMS,
    ...COMMON_MEAL_SYNONYMS,
    ...FOOD_TYPE_SYNONYMS,
    ...MEAT_CUT_SYNONYMS,
    ...MISSPELLING_SYNONYMS,
];
// =============================================================================
// FIREBASE FUNCTIONS
// =============================================================================
/**
 * Sync all synonyms to Algolia indices
 * Call this endpoint to push synonyms to all food indices
 */
exports.syncSynonymsToAlgolia = functions.https.onRequest({
    secrets: [algoliaAdminKey],
    cors: true,
    timeoutSeconds: 120,
}, async (request, response) => {
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const results = {};
    console.log(`📚 Syncing ${ALL_SYNONYMS.length} synonyms to ${ALL_INDICES.length} indices...`);
    for (const indexName of ALL_INDICES) {
        try {
            await client.saveSynonyms({
                indexName,
                synonymHit: ALL_SYNONYMS, // Cast to any for SDK compatibility
                forwardToReplicas: true,
                replaceExistingSynonyms: true,
            });
            results[indexName] = {
                status: "success",
                count: ALL_SYNONYMS.length,
            };
            console.log(`✅ Synced ${ALL_SYNONYMS.length} synonyms to ${indexName}`);
        }
        catch (error) {
            results[indexName] = {
                status: "failed",
                error: error.message,
            };
            console.error(`❌ Failed to sync synonyms to ${indexName}:`, error.message);
        }
    }
    response.json({
        success: true,
        message: "Synonym sync completed",
        totalSynonyms: ALL_SYNONYMS.length,
        categories: {
            fastFoodMenuItems: FAST_FOOD_MENU_SYNONYMS.length,
            brandSpellings: BRAND_SPELLING_SYNONYMS.length,
            ukUsSpellings: UK_US_SPELLING_SYNONYMS.length,
            commonMeals: COMMON_MEAL_SYNONYMS.length,
            foodTypes: FOOD_TYPE_SYNONYMS.length,
            meatCuts: MEAT_CUT_SYNONYMS.length,
            misspellings: MISSPELLING_SYNONYMS.length,
        },
        results,
    });
});
/**
 * Get synonym statistics from Algolia
 * Useful for verifying synonyms were applied
 */
exports.getSynonymStats = functions.https.onRequest({
    secrets: [algoliaAdminKey],
    cors: true,
}, async (request, response) => {
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const stats = {};
    for (const indexName of ALL_INDICES) {
        try {
            const result = await client.searchSynonyms({
                indexName,
                searchSynonymsParams: { query: "", hitsPerPage: 0 },
            });
            stats[indexName] = result.nbHits || 0;
        }
        catch (error) {
            stats[indexName] = -1; // Error indicator
            console.error(`Error getting synonyms for ${indexName}:`, error.message);
        }
    }
    response.json({
        success: true,
        synonymCounts: stats,
        expectedCount: ALL_SYNONYMS.length,
    });
});
/**
 * Clear all synonyms from Algolia indices
 * Use with caution - removes all synonyms
 */
exports.clearSynonymsFromAlgolia = functions.https.onRequest({
    secrets: [algoliaAdminKey],
    cors: true,
}, async (request, response) => {
    // Safety check - require confirmation parameter
    if (request.query.confirm !== "yes") {
        response.status(400).json({
            error: "Add ?confirm=yes to confirm clearing all synonyms",
        });
        return;
    }
    const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
    const results = {};
    for (const indexName of ALL_INDICES) {
        try {
            await client.clearSynonyms({
                indexName,
                forwardToReplicas: true,
            });
            results[indexName] = "cleared";
            console.log(`🗑️ Cleared synonyms from ${indexName}`);
        }
        catch (error) {
            results[indexName] = `failed: ${error.message}`;
        }
    }
    response.json({
        success: true,
        message: "Synonyms cleared",
        results,
    });
});
//# sourceMappingURL=food-synonyms.js.map