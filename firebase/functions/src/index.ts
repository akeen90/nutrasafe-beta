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
export { addVerifiedFood, updateVerifiedFood, deleteVerifiedFoods, moveFoodBetweenCollections, resetAdminManualFoods, resetAllFoodsToInitial, fixExistingFoodsVerification, updateServingSizes } from './food-management';
export { getOverviewStats, getAnalyticsData } from './analytics';
export { getUsers, addUser, updateUser, deleteUsers, getUserAnalytics } from './user-management';
export { getContextualNutritionScore } from './contextual-nutrition';
export { analyzeAdditivesEnhanced } from './additive-analyzer-enhanced';
export { extractIngredientsWithAI } from './intelligent-ingredient-extractor';
export { searchFoodsWithMicronutrients } from './enhanced-micronutrient-search';
export { importGenericFoods, getNutrientSuggestions } from './import-generic-foods';
export { getAllFoods } from './get-all-foods';
export { analyzeAndCleanFoods, getCleansedFoods, exportCleansedFoods, deleteCleansedFood, updateCleansedFood, emergencyCleanCleansedFoods, updateCleansedFoodStatus } from './ai-food-cleaner';
export { testCors } from './test-cors';
export { detectLiveText } from './detect-live-text';
export { processIngredientText } from './process-ingredient-text';
export { replaceAllFoods } from './replace-foods-database';
export { standardizeIngredients } from './standardize-ingredients';
export { notifyIncompleteFood } from './notify-incomplete-food';