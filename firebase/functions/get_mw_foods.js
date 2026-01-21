const admin = require("firebase-admin");
const fs = require("fs");

const serviceAccount = require("/tmp/firebase-sa-key.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "nutrasafe-705c7"
});

const db = admin.firestore();

async function getAllMWFoods() {
  console.log("Fetching all MW foods from generic_database...");
  const snapshot = await db.collection("generic_database").get();

  const foods = snapshot.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.foodName || data.name,
      category: data.category,
      calories: data.calories,
      protein: data.protein,
      carbs: data.carbs,
      fat: data.fat,
      fiber: data.fiber,
      sugar: data.sugar,
      saturatedFat: data.saturatedFat,
      sodium: data.sodium,
      micronutrients: data.micronutrientProfile
    };
  });

  console.log("Found", foods.length, "MW foods");

  // Save to file for processing
  fs.writeFileSync("/Users/aaronkeen/Downloads/mw_foods_full.json", JSON.stringify(foods, null, 2));
  console.log("Saved to /Users/aaronkeen/Downloads/mw_foods_full.json");

  // Print categories
  const categories = {};
  foods.forEach(f => {
    const cat = f.category || "Unknown";
    categories[cat] = (categories[cat] || 0) + 1;
  });

  console.log("\nCategories:");
  Object.entries(categories).sort((a,b) => b[1] - a[1]).forEach(([cat, count]) => {
    console.log("  ", cat + ":", count);
  });

  // Print sample names by category
  console.log("\nSample food names by category:");
  const byCategory = {};
  foods.forEach(f => {
    const cat = f.category || "Unknown";
    if (!byCategory[cat]) byCategory[cat] = [];
    byCategory[cat].push(f.name);
  });

  Object.keys(byCategory).sort().forEach(cat => {
    console.log("\n" + cat + ":");
    byCategory[cat].slice(0, 15).forEach(name => console.log("  -", name));
    if (byCategory[cat].length > 15) console.log("  ... and", byCategory[cat].length - 15, "more");
  });

  process.exit(0);
}

getAllMWFoods().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
