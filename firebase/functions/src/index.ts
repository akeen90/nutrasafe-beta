import * as admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export the essential functions
export { addVerifiedFoodComplete } from './efficient-import';
export { searchFoods } from './search-foods';
export { searchCleansedFoods } from './search-cleansed-foods';
export { searchFoodByBarcode } from './search-food-by-barcode';
export { fastSearchFoods } from './fast-search';
export { searchFoodsWeb } from './search-foods-web';
export { getFoodDetails } from './food-details';
export { searchFoodsByCollection } from './search-foods-by-collection';
export { addVerifiedFood, updateVerifiedFood, deleteVerifiedFoods, deleteFoodFromAlgolia, moveFoodBetweenCollections, resetAdminManualFoods, resetAllFoodsToInitial, fixExistingFoodsVerification, updateServingSizes } from './food-management';
export { getOverviewStats, getAnalyticsData } from './analytics';
export { getUsers, addUser, updateUser, deleteUsers, getUserAnalytics, getAuthenticatedEmails, bulkAddToMailchimp } from './user-management';
export { getContextualNutritionScore } from './contextual-nutrition';
export { analyzeAdditivesEnhanced } from './additive-analyzer-enhanced';
export { extractIngredientsWithAI } from './intelligent-ingredient-extractor';
export { importGenericFoods, getNutrientSuggestions } from './import-generic-foods';
export { getAllFoods } from './get-all-foods';
export { analyzeAndCleanFoods, getCleansedFoods, exportCleansedFoods, deleteCleansedFood, updateCleansedFood, emergencyCleanCleansedFoods, updateCleansedFoodStatus } from './ai-food-cleaner';
export { testCors } from './test-cors';
export { detectLiveText } from './detect-live-text';
// export { processIngredientText } from './process-ingredient-text'; // Disabled - uses old SDK
export { replaceAllFoods } from './replace-foods-database';
export { standardizeIngredients } from './standardize-ingredients';
export { notifyIncompleteFood } from './notify-incomplete-food';
export { getUserReports, updateUserReport, deleteUserReport } from './user-reports';
export { saveFood, deleteFood, batchSaveFoods, getFood } from './save-food';
export { parseMicronutrientsWithAI, parseMicronutrientsWithAICached } from './parse-micronutrients-ai';
export { parseAdditivesWithAI, parseAdditivesWithAICached } from './parse-additives-ai';
export { parseNutritionOCR, parseNutritionOCRCached } from './parse-nutrition-ocr';
export { parseIngredientsOCR, parseIngredientsOCRCached } from './parse-ingredients-ocr';
export { findIngredients } from './find-ingredients';
export { auditMissingIngredients } from './audit-missing-ingredients';
export { recognizeFood } from './recognize-food';
export { scanProductComplete } from './scan-product-complete';

// Algolia integration
export { syncVerifiedFoodToAlgolia, syncFoodToAlgolia, syncManualFoodToAlgolia, syncUserAddedFoodToAlgolia, syncAIEnhancedFoodToAlgolia, syncAIManuallyAddedFoodToAlgolia, bulkImportFoodsToAlgolia, searchFoodsAlgolia, configureAlgoliaIndices, syncNewDatabasesToAlgolia } from './algolia-sync';

// Algolia synonyms and query rules
export { syncSynonymsToAlgolia, getSynonymStats, clearSynonymsFromAlgolia } from './food-synonyms';
export { configureQueryRules, getQueryRulesStats, clearQueryRules } from './algolia-query-rules';

// Mailchimp email marketing sync
export { syncEmailConsentToMailchimp, syncAllEmailConsentsToMailchimp } from './mailchimp-sync';

// Database scanning and batch operations
export { scanDatabaseIssues, batchUpdateFoods } from './scan-database';

// UK Data Cleansing - Google Discovery and Extraction
export { discoverUKProductPage, generateManualSearchLinks } from './uk-discovery';
export { extractUKProductData, extractWithPuppeteer, lookupTescoProduct } from './uk-extractor';

// Tesco Database Builder - builds comprehensive UK food database from Tesco API
export { getTescoBuildProgress, startTescoBuild, pauseTescoBuild, resetTescoDatabase, getTescoDatabaseStats } from './tesco-database-builder';