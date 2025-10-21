#!/usr/bin/env node

/**
 * Export Firebase Firestore food database to SQLite
 *
 * Usage:
 *   node firebase/scripts/exportToSQLite.js
 *
 * This will create nutrasafe_foods.db in the current directory
 */

// Run from project root, so we need to resolve paths correctly
const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
const sqlite3 = require(path.join(__dirname, '..', 'functions', 'node_modules', 'sqlite3')).verbose();

// Initialize Firebase Admin
const serviceAccount = require(path.join(__dirname, '..', 'service-account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// SQLite database path
const dbPath = path.join(__dirname, '..', '..', 'nutrasafe_foods.db');
const sqliteDb = new sqlite3.Database(dbPath);

console.log(`📂 Creating SQLite database at: ${dbPath}`);

// Create tables
function createTables() {
  return new Promise((resolve, reject) => {
    sqliteDb.serialize(() => {
      sqliteDb.run(`
        CREATE TABLE IF NOT EXISTS foods (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          brand TEXT,
          barcode TEXT,

          -- Macronutrients (per 100g)
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          fiber REAL NOT NULL,
          sugar REAL NOT NULL,
          sodium REAL NOT NULL,

          -- Serving info
          serving_description TEXT,
          serving_size_g REAL,

          -- Micronutrients (per 100g) - Vitamins
          vitamin_a REAL DEFAULT 0,
          vitamin_c REAL DEFAULT 0,
          vitamin_d REAL DEFAULT 0,
          vitamin_e REAL DEFAULT 0,
          vitamin_k REAL DEFAULT 0,
          thiamin_b1 REAL DEFAULT 0,
          riboflavin_b2 REAL DEFAULT 0,
          niacin_b3 REAL DEFAULT 0,
          pantothenic_b5 REAL DEFAULT 0,
          vitamin_b6 REAL DEFAULT 0,
          biotin_b7 REAL DEFAULT 0,
          folate_b9 REAL DEFAULT 0,
          vitamin_b12 REAL DEFAULT 0,
          choline REAL DEFAULT 0,

          -- Micronutrients (per 100g) - Minerals
          calcium REAL DEFAULT 0,
          iron REAL DEFAULT 0,
          magnesium REAL DEFAULT 0,
          phosphorus REAL DEFAULT 0,
          potassium REAL DEFAULT 0,
          zinc REAL DEFAULT 0,
          copper REAL DEFAULT 0,
          manganese REAL DEFAULT 0,
          selenium REAL DEFAULT 0,
          chromium REAL DEFAULT 0,
          molybdenum REAL DEFAULT 0,
          iodine REAL DEFAULT 0,

          -- Ingredients
          ingredients TEXT,

          -- Processing & Safety
          processing_score INTEGER,
          processing_grade TEXT,
          processing_label TEXT,

          -- Metadata
          is_verified BOOLEAN DEFAULT 0,
          verified_by TEXT,
          verified_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      `);

      sqliteDb.run(`CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode);`);
      sqliteDb.run(`CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name COLLATE NOCASE);`);
      sqliteDb.run(`CREATE INDEX IF NOT EXISTS idx_foods_brand ON foods(brand COLLATE NOCASE);`);

      sqliteDb.run(`
        CREATE TABLE IF NOT EXISTS food_ingredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          food_id TEXT NOT NULL,
          ingredient TEXT NOT NULL,
          position INTEGER NOT NULL,
          FOREIGN KEY(food_id) REFERENCES foods(id) ON DELETE CASCADE
        );
      `);

      sqliteDb.run(`CREATE INDEX IF NOT EXISTS idx_ingredients_food_id ON food_ingredients(food_id);`);
      sqliteDb.run(`CREATE INDEX IF NOT EXISTS idx_ingredients_text ON food_ingredients(ingredient COLLATE NOCASE);`, () => {
        console.log('✅ Tables created');
        resolve();
      });
    });
  });
}

// Helper to extract nested values
function getValue(obj, path, defaultValue = 0) {
  const keys = path.split('.');
  let value = obj;

  for (const key of keys) {
    if (value && typeof value === 'object' && key in value) {
      value = value[key];
    } else {
      return defaultValue;
    }
  }

  return typeof value === 'number' ? value : defaultValue;
}

// Parse serving size string to extract description and numeric value in grams
// Examples:
//   "100g" -> { description: "100g", grams: 100 }
//   "1 portion (327.5 g)" -> { description: "1 portion", grams: 327.5 }
//   "270g" -> { description: "270g", grams: 270 }
function parseServingSize(servingSizeStr) {
  if (!servingSizeStr || typeof servingSizeStr !== 'string') {
    return { description: null, grams: 0 };
  }

  const trimmed = servingSizeStr.trim();

  // Try to match "description (XXX g)" pattern
  const portionMatch = trimmed.match(/^(.+?)\s*\((\d+(?:\.\d+)?)\s*g\)$/i);
  if (portionMatch) {
    return {
      description: portionMatch[1].trim(),
      grams: parseFloat(portionMatch[2])
    };
  }

  // Try to match "XXXg" pattern
  const gramsMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*g$/i);
  if (gramsMatch) {
    return {
      description: trimmed,
      grams: parseFloat(gramsMatch[1])
    };
  }

  // If we can't parse it, return the whole string as description
  return {
    description: trimmed,
    grams: 0
  };
}

// Insert a food into SQLite
function insertFood(foodId, foodData) {
  return new Promise((resolve, reject) => {
    const now = Date.now();

    // Extract micronutrients
    const vitamins = foodData.vitamins || {};
    const minerals = foodData.minerals || {};

    // Parse serving size
    const servingInfo = parseServingSize(foodData.servingSize);

    // Prepare SQL statement
    const sql = `
      INSERT OR REPLACE INTO foods (
        id, name, brand, barcode,
        calories, protein, carbs, fat, fiber, sugar, sodium,
        serving_description, serving_size_g,
        vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
        thiamin_b1, riboflavin_b2, niacin_b3, pantothenic_b5,
        vitamin_b6, biotin_b7, folate_b9, vitamin_b12, choline,
        calcium, iron, magnesium, phosphorus, potassium,
        zinc, copper, manganese, selenium, chromium, molybdenum, iodine,
        ingredients,
        processing_score, processing_grade, processing_label,
        is_verified, verified_by, verified_at,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    `;

    const params = [
      foodId,
      foodData.foodName || foodData.name || 'Unknown',
      foodData.brandName || foodData.brand || null,
      foodData.barcode || null,

      // Macros - support both nested and flat structures
      getValue(foodData, 'nutrition.calories.kcal', getValue(foodData, 'calories.kcal', getValue(foodData, 'calories', 0))),
      getValue(foodData, 'nutrition.protein.per100g', getValue(foodData, 'protein.per100g', getValue(foodData, 'protein', 0))),
      getValue(foodData, 'nutrition.carbohydrates.per100g', getValue(foodData, 'carbs.per100g', getValue(foodData, 'carbohydrates', 0))),
      getValue(foodData, 'nutrition.fat.per100g', getValue(foodData, 'fat.per100g', getValue(foodData, 'fat', 0))),
      getValue(foodData, 'nutrition.fiber.per100g', getValue(foodData, 'fiber.per100g', getValue(foodData, 'fiber', 0))),
      getValue(foodData, 'nutrition.sugars.per100g', getValue(foodData, 'sugar.per100g', getValue(foodData, 'sugars', 0))),
      getValue(foodData, 'nutrition.salt.per100g', getValue(foodData, 'sodium.per100g', getValue(foodData, 'salt', 0))) * 0.4, // Convert salt to sodium

      // Serving info
      servingInfo.description,
      servingInfo.grams,

      // Vitamins
      getValue(vitamins, 'vitaminA', 0),
      getValue(vitamins, 'vitaminC', 0),
      getValue(vitamins, 'vitaminD', 0),
      getValue(vitamins, 'vitaminE', 0),
      getValue(vitamins, 'vitaminK', 0),
      getValue(vitamins, 'thiamine', getValue(vitamins, 'thiaminB1', 0)),
      getValue(vitamins, 'riboflavin', getValue(vitamins, 'riboflavinB2', 0)),
      getValue(vitamins, 'niacin', getValue(vitamins, 'niacinB3', 0)),
      getValue(vitamins, 'pantothenicAcid', getValue(vitamins, 'pantothenicB5', 0)),
      getValue(vitamins, 'vitaminB6', 0),
      getValue(vitamins, 'biotin', getValue(vitamins, 'biotinB7', 0)),
      getValue(vitamins, 'folate', getValue(vitamins, 'folateB9', 0)),
      getValue(vitamins, 'vitaminB12', 0),
      getValue(vitamins, 'choline', 0),

      // Minerals
      getValue(minerals, 'calcium', 0),
      getValue(minerals, 'iron', 0),
      getValue(minerals, 'magnesium', 0),
      getValue(minerals, 'phosphorus', 0),
      getValue(minerals, 'potassium', 0),
      getValue(minerals, 'zinc', 0),
      getValue(minerals, 'copper', 0),
      getValue(minerals, 'manganese', 0),
      getValue(minerals, 'selenium', 0),
      getValue(minerals, 'chromium', 0),
      getValue(minerals, 'molybdenum', 0),
      getValue(minerals, 'iodine', 0),

      // Ingredients (support both string and array formats)
      typeof foodData.ingredients === 'string' ? foodData.ingredients :
        (Array.isArray(foodData.ingredients) ? foodData.ingredients.join(', ') : null),

      // Processing
      foodData.processingScore || null,
      foodData.processingGrade || null,
      foodData.processingLabel || null,

      // Metadata
      foodData.verifiedBy ? 1 : 0,
      foodData.verifiedBy || null,
      foodData.verifiedAt ? foodData.verifiedAt.toMillis() : null,

      // Timestamps
      foodData.createdAt ? foodData.createdAt.toMillis() : now,
      foodData.updatedAt ? foodData.updatedAt.toMillis() : now
    ];

    sqliteDb.run(sql, params, function(err) {
      if (err) {
        console.error(`❌ Error inserting food ${foodId}:`, err.message);
        reject(err);
      } else {
        // Insert ingredients if present
        const ingredients = foodData.ingredients || [];
        if (Array.isArray(ingredients) && ingredients.length > 0) {
          insertIngredients(foodId, ingredients).then(resolve).catch(reject);
        } else {
          resolve();
        }
      }
    });
  });
}

// Insert ingredients for a food
function insertIngredients(foodId, ingredients) {
  const promises = ingredients.map((ingredient, index) => {
    return new Promise((resolve, reject) => {
      const sql = `INSERT INTO food_ingredients (food_id, ingredient, position) VALUES (?, ?, ?);`;
      sqliteDb.run(sql, [foodId, ingredient, index], (err) => {
        if (err) {
          console.error(`❌ Error inserting ingredient for ${foodId}:`, err.message);
          reject(err);
        } else {
          resolve();
        }
      });
    });
  });

  return Promise.all(promises);
}

// Export all foods from Firebase (both verified and main database)
async function exportAllFoods() {
  console.log('📥 Fetching ALL foods from Firebase...');

  try {
    // Try 'foods' collection first (this is likely your 30k food database)
    let snapshot = await db.collection('foods').get();

    // If 'foods' is empty, try 'verifiedFoods'
    if (snapshot.size === 0) {
      console.log('⚠️  "foods" collection is empty, trying "verifiedFoods"...');
      snapshot = await db.collection('verifiedFoods').get();
    }

    console.log(`Found ${snapshot.size} foods`);

    let imported = 0;
    const batchSize = 50;
    const batches = [];

    snapshot.forEach((doc) => {
      batches.push({ id: doc.id, data: doc.data() });
    });

    // Process in batches
    for (let i = 0; i < batches.length; i += batchSize) {
      const batch = batches.slice(i, i + batchSize);

      await Promise.all(batch.map(({ id, data }) => insertFood(id, data)));

      imported += batch.length;
      console.log(`✅ Imported ${imported}/${batches.length} foods`);
    }

    console.log(`🎉 Successfully imported ${imported} foods`);
    return imported;

  } catch (error) {
    console.error('❌ Error exporting foods:', error);
    throw error;
  }
}

// Main execution
async function main() {
  try {
    await createTables();
    const count = await exportAllFoods();

    console.log('\n📊 Export Summary:');
    console.log(`   ✅ ${count} foods exported`);
    console.log(`   📂 Database: ${dbPath}`);
    console.log('\n💡 Next steps:');
    console.log('   1. Copy nutrasafe_foods.db to your iOS project');
    console.log('   2. Add it to Xcode (drag into project navigator)');
    console.log('   3. Make sure "Copy items if needed" is checked');
    console.log('   4. Add to target membership');

    sqliteDb.close();
    process.exit(0);

  } catch (error) {
    console.error('❌ Export failed:', error);
    sqliteDb.close();
    process.exit(1);
  }
}

main();
