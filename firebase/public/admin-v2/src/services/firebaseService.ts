/**
 * Firebase Service
 * Handles Firestore operations for write-back
 */

import { initializeApp, FirebaseApp } from 'firebase/app';
import { getFirestore, Firestore } from 'firebase/firestore';
import {
  getAuth,
  Auth,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User
} from 'firebase/auth';
import { getFunctions, Functions } from 'firebase/functions';
import { UnifiedFood, UnifiedFoodUpdate } from '../types';

// HIGH-12 FIX: Firebase configuration from environment variables
// These should be set in .env file (not committed) or deployment environment
// Vite exposes env vars prefixed with VITE_ to the client
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyAW1cyvgMe7jU38P6b1RgAOd7w6lCGK5lE",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "nutrasafe-705c7.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "nutrasafe-705c7",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "nutrasafe-705c7.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1043273165814",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:1043273165814:web:c3e98e4d8f5a6b7c8d9e0f",
};

// Security note: These are public Firebase Web API keys which are safe to expose
// (they identify the project but don't grant write access - that's controlled by Firestore rules)
// However, using env vars allows different configs for dev/staging/prod

// Initialize Firebase
let app: FirebaseApp;
let db: Firestore;
let auth: Auth;
let functions: Functions;

export function initializeFirebase() {
  if (!app) {
    app = initializeApp(firebaseConfig);
    db = getFirestore(app);
    auth = getAuth(app);
    functions = getFunctions(app);
  }
  return { app, db, auth, functions };
}

// Auth helpers
export function getFirebaseAuth(): Auth {
  if (!auth) {
    initializeFirebase();
  }
  return auth;
}

export function getFirebaseFunctions(): Functions {
  if (!functions) {
    initializeFirebase();
  }
  return functions;
}

export async function signIn(email: string, password: string): Promise<User> {
  const auth = getFirebaseAuth();
  const result = await signInWithEmailAndPassword(auth, email, password);
  return result.user;
}

export async function signOut(): Promise<void> {
  const auth = getFirebaseAuth();
  await firebaseSignOut(auth);
}

export function onAuthChange(callback: (user: User | null) => void): () => void {
  const auth = getFirebaseAuth();
  return onAuthStateChanged(auth, callback);
}

export function getCurrentUser(): User | null {
  const auth = getFirebaseAuth();
  return auth.currentUser;
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
 * Delete a food item - Uses comprehensive delete to remove from ALL indices
 * This prevents foods from "coming back" when they exist in multiple indices
 * Falls back to single-index delete if comprehensive endpoint fails
 */
export async function deleteFood(
  food: UnifiedFood
): Promise<{ success: boolean; error?: string; deletedFrom?: number }> {
  const { _sourceIndex, objectID, barcode } = food;

  try {
    // Try comprehensive delete first (removes from ALL indices with same barcode)
    let response = await fetch(`${FUNCTIONS_BASE}/deleteFoodComprehensive`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        foodId: objectID,
        indexName: _sourceIndex,
        barcode: barcode,
        deleteFromAllIndices: true,
      }),
    });

    // If comprehensive delete fails, fall back to single-index delete
    if (!response.ok) {
      console.log('Comprehensive delete unavailable, using single-index delete');
      response = await fetch(`${FUNCTIONS_BASE}/deleteFoodFromAlgolia`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          foodId: objectID,
          indexName: _sourceIndex,
        }),
      });
    }

    const result = await response.json();

    if (result.success) {
      console.log(`✅ Deleted food from ${result.deletedFrom?.length || 1} location(s)`);
      return {
        success: true,
        deletedFrom: result.deletedFrom?.length || 1
      };
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

/**
 * Move foods between Algolia indices
 */
export async function moveFoodsBetweenIndices(
  foods: UnifiedFood[],
  toIndex: string
): Promise<{ success: number; failed: number; errors: string[] }> {
  const foodsBySourceIndex = new Map<string, string[]>();

  // Group foods by source index
  foods.forEach(food => {
    const sourceIndex = food._sourceIndex;
    if (!foodsBySourceIndex.has(sourceIndex)) {
      foodsBySourceIndex.set(sourceIndex, []);
    }
    foodsBySourceIndex.get(sourceIndex)!.push(food.objectID);
  });

  let totalSuccess = 0;
  let totalFailed = 0;
  const allErrors: string[] = [];

  // Move each group
  for (const [fromIndex, foodIds] of foodsBySourceIndex.entries()) {
    if (fromIndex === toIndex) {
      // Skip foods already in destination index
      console.log(`Skipping ${foodIds.length} foods already in ${toIndex}`);
      totalSuccess += foodIds.length;
      continue;
    }

    try {
      const response = await fetch(`${FUNCTIONS_BASE}/moveFoodsBetweenIndices`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          foodIds,
          fromIndex,
          toIndex,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`❌ Move failed (HTTP ${response.status}):`, errorText);
        totalFailed += foodIds.length;
        allErrors.push(`${fromIndex} → ${toIndex}: HTTP ${response.status} - ${errorText}`);
        continue;
      }

      const result = await response.json();
      console.log('Move result:', result);

      if (result.success) {
        totalSuccess += result.moved || 0;
        totalFailed += result.failed || 0;
        if (result.errors && result.errors.length > 0) {
          allErrors.push(...result.errors);
        }
        console.log(`✅ Moved ${result.moved} foods from ${fromIndex} to ${toIndex}`);
      } else {
        totalFailed += foodIds.length;
        const errorDetail = result.details || result.error || 'Unknown error';
        console.error(`❌ Move failed:`, errorDetail);
        allErrors.push(`${fromIndex} → ${toIndex}: ${errorDetail}`);
      }
    } catch (error) {
      console.error(`❌ Error moving foods from ${fromIndex}:`, error);
      totalFailed += foodIds.length;
      allErrors.push(`${fromIndex} → ${toIndex}: ${String(error)}`);
    }
  }

  return { success: totalSuccess, failed: totalFailed, errors: allErrors };
}

export { db };
