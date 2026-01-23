/**
 * Firebase Service
 * Handles Firestore operations for write-back
 */

import { initializeApp, FirebaseApp } from 'firebase/app';
import { getFirestore, Firestore } from 'firebase/firestore';
import { UnifiedFood, UnifiedFoodUpdate } from '../types';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyD6P4U8D1lOJ-h8-QgQ6GYTp4h9Qy7YQHM",
  authDomain: "nutrasafe-705c7.firebaseapp.com",
  projectId: "nutrasafe-705c7",
  storageBucket: "nutrasafe-705c7.appspot.com",
  messagingSenderId: "1043273165814",
  appId: "1:1043273165814:web:c3e98e4d8f5a6b7c8d9e0f",
};

// Initialize Firebase
let app: FirebaseApp;
let db: Firestore;

export function initializeFirebase() {
  if (!app) {
    app = initializeApp(firebaseConfig);
    db = getFirestore(app);
  }
  return { app, db };
}

// Cloud Function endpoints
const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

/**
 * Update a food item (Firestore or Algolia-only)
 */
export async function updateFood(
  food: UnifiedFood,
  updates: UnifiedFoodUpdate
): Promise<{ success: boolean; error?: string }> {
  const { objectID, _hasFirestoreBacking, _firestoreCollection, _sourceIndex } = food;

  // Prepare update payload
  const payload = {
    foodId: objectID,
    collection: _hasFirestoreBacking ? _firestoreCollection : _sourceIndex,
    foodName: updates.name,
    brandName: updates.brandName,
    barcode: updates.barcode,
    extractedIngredients: updates.ingredientsText,
    nutritionData: {
      calories: updates.calories,
      protein: updates.protein,
      carbs: updates.carbs,
      fat: updates.fat,
      saturatedFat: updates.saturatedFat,
      fiber: updates.fiber,
      sugar: updates.sugar,
      sodium: updates.sodium,
      salt: updates.salt,
    },
    servingSize: updates.servingDescription,
    servingSizeG: updates.servingSizeG,
    isPerUnit: updates.isPerUnit,
    source: updates.source,
  };

  try {
    const response = await fetch(`${FUNCTIONS_BASE}/updateVerifiedFood`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (result.success) {
      return { success: true };
    } else {
      return { success: false, error: result.error || 'Unknown error' };
    }
  } catch (error) {
    console.error('Error updating food:', error);
    return { success: false, error: String(error) };
  }
}

/**
 * Delete a food item
 */
export async function deleteFood(
  food: UnifiedFood
): Promise<{ success: boolean; error?: string }> {
  const { _sourceIndex, objectID } = food;

  try {
    const response = await fetch(`${FUNCTIONS_BASE}/deleteFoodFromAlgolia`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        foodId: objectID,
        indexName: _sourceIndex,
      }),
    });

    const result = await response.json();

    if (result.success) {
      return { success: true };
    } else {
      return { success: false, error: result.error || 'Unknown error' };
    }
  } catch (error) {
    console.error('Error deleting food:', error);
    return { success: false, error: String(error) };
  }
}

/**
 * Batch update multiple foods
 */
export async function batchUpdateFoods(
  foods: { food: UnifiedFood; updates: UnifiedFoodUpdate }[]
): Promise<{ success: number; failed: number; errors: string[] }> {
  let success = 0;
  let failed = 0;
  const errors: string[] = [];

  // Process in parallel with concurrency limit
  const CONCURRENCY = 5;
  for (let i = 0; i < foods.length; i += CONCURRENCY) {
    const batch = foods.slice(i, i + CONCURRENCY);
    const results = await Promise.all(
      batch.map(({ food, updates }) => updateFood(food, updates))
    );

    results.forEach((result, idx) => {
      if (result.success) {
        success++;
      } else {
        failed++;
        errors.push(`${batch[idx].food.name}: ${result.error}`);
      }
    });
  }

  return { success, failed, errors };
}

/**
 * Batch delete multiple foods
 */
export async function batchDeleteFoods(
  foods: UnifiedFood[]
): Promise<{ success: number; failed: number; errors: string[] }> {
  let success = 0;
  let failed = 0;
  const errors: string[] = [];

  // Process in parallel with concurrency limit
  const CONCURRENCY = 5;
  for (let i = 0; i < foods.length; i += CONCURRENCY) {
    const batch = foods.slice(i, i + CONCURRENCY);
    const results = await Promise.all(
      batch.map((food) => deleteFood(food))
    );

    results.forEach((result, idx) => {
      if (result.success) {
        success++;
      } else {
        failed++;
        errors.push(`${batch[idx].name}: ${result.error}`);
      }
    });
  }

  return { success, failed, errors };
}

/**
 * Add a new food item
 */
export async function addFood(
  food: Omit<UnifiedFood, '_id' | '_sourceIndex' | '_firestoreCollection' | '_hasFirestoreBacking' | '_confidenceScore' | '_reviewFlags' | '_duplicateCandidates' | '_isDirty' | '_isDeleted'>
): Promise<{ success: boolean; foodId?: string; error?: string }> {
  try {
    const response = await fetch(`${FUNCTIONS_BASE}/addVerifiedFood`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        foodName: food.name,
        brandName: food.brandName,
        barcode: food.barcode,
        extractedIngredients: food.ingredientsText,
        nutritionData: {
          calories: food.calories,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          saturatedFat: food.saturatedFat,
          fiber: food.fiber,
          sugar: food.sugar,
          sodium: food.sodium,
          salt: food.salt,
        },
        servingSize: food.servingDescription,
      }),
    });

    const result = await response.json();

    if (result.success) {
      return { success: true, foodId: result.foodId };
    } else {
      return { success: false, error: result.error || 'Unknown error' };
    }
  } catch (error) {
    console.error('Error adding food:', error);
    return { success: false, error: String(error) };
  }
}

export { db };
