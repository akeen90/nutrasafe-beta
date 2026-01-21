/**
 * Consolidate consumer foods with size variants into single entries with portions
 *
 * Before: Banana (Small), Banana (Medium), Banana (Large) - 3 separate documents
 * After: Banana - 1 document with portions array
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Size patterns to detect and consolidate
const sizePatterns = [
  { pattern: /\s*\(Small\)$/i, size: 'Small', order: 1 },
  { pattern: /\s*\(Medium\)$/i, size: 'Medium', order: 2 },
  { pattern: /\s*\(Large\)$/i, size: 'Large', order: 3 },
  { pattern: /\s*\(Extra Large\)$/i, size: 'Extra Large', order: 4 },
  { pattern: /\s*\(Mini\)$/i, size: 'Mini', order: 0 },
  { pattern: /\s*Small$/i, size: 'Small', order: 1 },
  { pattern: /\s*Medium$/i, size: 'Medium', order: 2 },
  { pattern: /\s*Large$/i, size: 'Large', order: 3 },
];

function getBaseName(name) {
  let baseName = name;
  for (const { pattern } of sizePatterns) {
    baseName = baseName.replace(pattern, '');
  }
  return baseName.trim();
}

function getSizeInfo(name) {
  for (const { pattern, size, order } of sizePatterns) {
    if (pattern.test(name)) {
      return { size, order };
    }
  }
  return null;
}

async function consolidateFoods() {
  console.log('📦 Fetching consumer_foods collection...');

  const snapshot = await db.collection('consumer_foods').get();
  console.log(`Found ${snapshot.size} documents`);

  // Group foods by base name
  const foodGroups = new Map();

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const name = data.name;
    const baseName = getBaseName(name);
    const sizeInfo = getSizeInfo(name);

    if (!foodGroups.has(baseName)) {
      foodGroups.set(baseName, []);
    }

    foodGroups.get(baseName).push({
      docId: doc.id,
      data,
      sizeInfo,
      originalName: name
    });
  });

  console.log(`\nGrouped into ${foodGroups.size} unique foods\n`);

  // Process each group
  const consolidatedFoods = [];
  const toDelete = [];

  for (const [baseName, variants] of foodGroups) {
    // Check if this food has multiple size variants
    const hasMultipleSizes = variants.length > 1 && variants.some(v => v.sizeInfo);

    if (hasMultipleSizes) {
      // Sort by size order
      variants.sort((a, b) => {
        const orderA = a.sizeInfo?.order ?? 99;
        const orderB = b.sizeInfo?.order ?? 99;
        return orderA - orderB;
      });

      // Use the smallest (or first) as the base
      const baseVariant = variants[0];
      const baseData = baseVariant.data;

      // Build portions array
      const portions = variants
        .filter(v => v.sizeInfo)
        .map(v => ({
          name: `${v.sizeInfo.size} (${v.data.servingSizeG}g)`,
          calories: v.data.calories,
          serving_g: v.data.servingSizeG
        }));

      // Create consolidated food entry
      const consolidatedFood = {
        id: `consumer_${baseName.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`,
        name: baseName,
        category: baseData.category,
        servingSizeG: baseData.per100g ? 100 : baseData.servingSizeG,
        servingSize: 'per 100g',
        // Use per100g values as base nutrition
        calories: baseData.per100g?.calories ?? baseData.calories,
        protein: baseData.per100g?.protein ?? baseData.protein,
        carbs: baseData.per100g?.carbs ?? baseData.carbs,
        fat: baseData.per100g?.fat ?? baseData.fat,
        fiber: baseData.fiber,
        sugar: baseData.sugar,
        saturatedFat: baseData.saturatedFat,
        sodium: baseData.sodium,
        per100g: baseData.per100g,
        mwSource: baseData.mwSource,
        tags: baseData.tags || [],
        portions: portions,
        micronutrientProfile: baseData.micronutrientProfile,
        source: 'consumer_foods',
        dataSource: 'McCance and Widdowson 2021',
        searchableName: baseName.toLowerCase()
      };

      consolidatedFoods.push(consolidatedFood);

      // Mark all variants for deletion
      variants.forEach(v => toDelete.push(v.docId));

      console.log(`✓ ${baseName}: Consolidated ${variants.length} sizes into portions`);
      console.log(`  Portions: ${portions.map(p => p.name).join(', ')}`);
    } else {
      // Single entry or no size variants - keep as is but ensure proper structure
      const variant = variants[0];
      const data = variant.data;

      // If name has size suffix but no other variants, remove the suffix
      const cleanName = getBaseName(data.name);

      const food = {
        id: variant.docId,
        name: cleanName !== data.name ? cleanName : data.name,
        category: data.category,
        servingSizeG: data.servingSizeG || 100,
        servingSize: data.servingSize || 'per 100g',
        calories: data.per100g?.calories ?? data.calories,
        protein: data.per100g?.protein ?? data.protein,
        carbs: data.per100g?.carbs ?? data.carbs,
        fat: data.per100g?.fat ?? data.fat,
        fiber: data.fiber,
        sugar: data.sugar,
        saturatedFat: data.saturatedFat,
        sodium: data.sodium,
        per100g: data.per100g,
        mwSource: data.mwSource,
        tags: data.tags || [],
        micronutrientProfile: data.micronutrientProfile,
        source: 'consumer_foods',
        dataSource: 'McCance and Widdowson 2021',
        searchableName: (cleanName !== data.name ? cleanName : data.name).toLowerCase()
      };

      // Add default portion if we have serving info
      if (data.servingSizeG && data.servingSizeG !== 100) {
        food.portions = [{
          name: `1 serving (${data.servingSizeG}g)`,
          calories: data.calories,
          serving_g: data.servingSizeG
        }];
      }

      consolidatedFoods.push(food);
      toDelete.push(variant.docId);
    }
  }

  console.log(`\n📊 Summary:`);
  console.log(`  - Original documents: ${snapshot.size}`);
  console.log(`  - Consolidated to: ${consolidatedFoods.length} foods`);
  console.log(`  - Documents to delete: ${toDelete.length}`);

  // Write consolidated data to JSON for review
  const fs = require('fs');
  fs.writeFileSync(
    './consolidated-consumer-foods.json',
    JSON.stringify(consolidatedFoods, null, 2)
  );
  console.log('\n✅ Written to consolidated-consumer-foods.json for review');

  // Ask for confirmation before updating database
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('\nProceed with database update? (yes/no): ', async (answer) => {
    if (answer.toLowerCase() === 'yes') {
      console.log('\n🔄 Updating database...');

      // Delete old documents in batches
      const BATCH_SIZE = 500;
      for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchIds = toDelete.slice(i, i + BATCH_SIZE);
        batchIds.forEach(docId => {
          batch.delete(db.collection('consumer_foods').doc(docId));
        });
        await batch.commit();
        console.log(`  Deleted ${Math.min(i + BATCH_SIZE, toDelete.length)}/${toDelete.length}`);
      }

      // Add consolidated documents in batches
      for (let i = 0; i < consolidatedFoods.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchFoods = consolidatedFoods.slice(i, i + BATCH_SIZE);
        batchFoods.forEach(food => {
          const docRef = db.collection('consumer_foods').doc(food.id);
          batch.set(docRef, {
            ...food,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });
        await batch.commit();
        console.log(`  Added ${Math.min(i + BATCH_SIZE, consolidatedFoods.length)}/${consolidatedFoods.length}`);
      }

      console.log('\n✅ Database updated successfully!');
      console.log('📝 Remember to sync to Algolia: call syncConsumerFoodsToAlgolia');
    } else {
      console.log('Cancelled. Review consolidated-consumer-foods.json and run again.');
    }

    rl.close();
    process.exit(0);
  });
}

consolidateFoods().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
