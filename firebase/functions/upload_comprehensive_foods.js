const admin = require("firebase-admin");
const { algoliasearch } = require("algoliasearch");
const fs = require("fs");

const serviceAccount = require("/tmp/firebase-sa-key.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "nutrasafe-705c7"
});

const db = admin.firestore();

const ALGOLIA_APP_ID = "WK0TIF84M2";
const ALGOLIA_ADMIN_KEY = "e54f75aae315af794ece385f3dc9c94b";

async function main() {
  // Load data
  const data = JSON.parse(fs.readFileSync("/Users/aaronkeen/Downloads/consumer_foods_comprehensive.json", "utf8"));
  console.log("Loaded", data.length, "foods");

  // Clear existing consumer_foods collection
  console.log("\n1. Clearing existing consumer_foods collection...");
  const existingDocs = await db.collection("consumer_foods").listDocuments();
  const deletePromises = existingDocs.map(doc => doc.delete());
  await Promise.all(deletePromises);
  console.log("   Deleted", existingDocs.length, "existing documents");

  // Upload to Firebase
  console.log("\n2. Uploading to Firebase...");
  const collectionRef = db.collection("consumer_foods");
  let count = 0;

  for (let i = 0; i < data.length; i += 500) {
    const batch = db.batch();
    const chunk = data.slice(i, i + 500);

    for (const food of chunk) {
      const docRef = collectionRef.doc(food.id);
      batch.set(docRef, {
        ...food,
        searchableName: food.name.toLowerCase(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "consumer_foods",
        dataSource: "McCance and Widdowson 2021"
      });
      count++;
    }

    await batch.commit();
    console.log("   Uploaded batch:", count, "/", data.length);
  }
  console.log("   Firebase upload complete:", count, "foods");

  // Sync to Algolia
  console.log("\n3. Syncing to Algolia...");
  const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
  const indexName = "consumer_foods";

  // Clear existing index
  console.log("   Clearing existing index...");
  await client.clearObjects({ indexName });

  // Prepare records
  const records = data.map(food => ({
    objectID: food.id,
    name: food.name,
    searchableName: food.name.toLowerCase(),
    category: food.category,
    servingSizeG: food.servingSizeG,
    servingSize: food.servingSize,
    per100g: food.per100g,
    mwSource: food.mwSource,
    tags: food.tags || [],
    calories: food.calories,
    protein: food.protein,
    carbs: food.carbs,
    fat: food.fat,
    fiber: food.fiber,
    sugar: food.sugar,
    saturatedFat: food.saturatedFat,
    sodium: food.sodium,
    micronutrientProfile: food.micronutrientProfile,
    source: "consumer_foods",
    dataSource: "McCance and Widdowson 2021"
  }));

  // Upload to Algolia
  console.log("   Uploading", records.length, "records to Algolia...");
  await client.saveObjects({ indexName, objects: records });

  // Configure index settings
  console.log("   Configuring index settings...");
  await client.setSettings({
    indexName,
    indexSettings: {
      searchableAttributes: ["name", "searchableName", "category", "tags", "mwSource"],
      attributesForFaceting: ["category", "tags", "filterOnly(source)"],
      customRanking: ["asc(name)"],
      highlightPreTag: "<mark>",
      highlightPostTag: "</mark>"
    }
  });

  console.log("   Algolia sync complete:", records.length, "records");
  console.log("\n✅ All done!");
  process.exit(0);
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
