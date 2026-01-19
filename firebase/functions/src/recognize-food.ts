/**
 * AI-Powered Food Recognition with Database Lookup
 *
 * Hybrid approach:
 * 1. Gemini 1.5 Pro identifies foods + estimates portion sizes
 * 2. Algolia searches for verified nutrition data
 * 3. Falls back to AI estimates only when no database match
 */

import * as functions from 'firebase-functions';
import axios from 'axios';
import { algoliasearch } from 'algoliasearch';

// Access secrets from functions.config() - set via: firebase functions:config:set gemini.api_key="xxx" algolia.admin_key="xxx"
// Or use environment variables from .env file

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
// Database indices - UK sources first (tesco_products, uk_foods_cleaned), then others
const SEARCH_INDICES = ['tesco_products', 'uk_foods_cleaned', 'fast_foods_database', 'generic_database'];
// UK source indices (for prioritization)
const UK_SOURCE_INDICES = new Set(['tesco_products', 'uk_foods_cleaned']);

// Interfaces
interface GeminiIdentifiedFood {
  name: string;
  brand: string | null;
  portionGrams: number;
  searchTerms: string[];  // Alternative names for better matching
  confidence: number;
  isPackaging: boolean;  // true = photo of product packaging, false = plated/prepared food
  // Fallback estimates (used only if no database match)
  estimatedCaloriesPer100g: number;
  estimatedProteinPer100g: number;
  estimatedCarbsPer100g: number;
  estimatedFatPer100g: number;
}

interface AlgoliaFoodHit {
  objectID: string;
  name: string;
  brandName?: string;
  brand?: string;  // Some indices use 'brand' instead of 'brandName'
  // Algolia stores nutrition - handle different field name conventions
  calories?: number;
  Calories?: number;  // Some CSV imports may use title case
  energy?: number;    // Alternative field name
  protein?: number;
  Protein?: number;
  carbs?: number;
  Carbs?: number;
  carbohydrates?: number;
  fat?: number;
  Fat?: number;
  fiber?: number;
  Fiber?: number;
  fibre?: number;     // British spelling
  sugar?: number;
  Sugar?: number;
  sodium?: number;
  Sodium?: number;
  // Serving size (use for packaged products instead of AI estimate)
  servingSize?: number;
  ServingSize?: number;
  serving_size?: number;  // Alternative field naming
  ingredients?: string | string[];  // May be string or array depending on record
  verified?: boolean;
  isGeneric?: boolean;
}

interface FoodRecognitionItem {
  name: string;
  brand: string | null;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
  sodium: number;
  portionGrams: number;
  confidence: number;
  isFromDatabase: boolean;  // true = verified data, false = AI estimate
  databaseId: string | null;  // Algolia objectID if from database
  ingredients: string | null;
}

/**
 * Cloud Function: Recognize food items using Gemini + Algolia hybrid approach
 * Using v1 functions style
 */
export const recognizeFood = functions
  .runWith({ timeoutSeconds: 90, memory: '1GB' })
  .https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const { image } = req.body;

    if (!image || typeof image !== 'string') {
      res.status(400).json({ error: 'Base64 encoded image is required' });
      return;
    }

    // Get API keys from secrets (v1 style)
    const geminiApiKey = process.env.GEMINI_API_KEY || '';
    const algoliaAdminKey = process.env.ALGOLIA_ADMIN_API_KEY || '';

    if (!geminiApiKey || !algoliaAdminKey) {
      console.error('Missing required API keys');
      res.status(500).json({ error: 'Server configuration error' });
      return;
    }

    try {
      // Step 1: Identify foods with Gemini
      console.log('🔍 Step 1: Identifying foods with Gemini...');
      const identifiedFoods = await identifyFoodsWithGemini(image, geminiApiKey);
      console.log(`✅ Gemini identified ${identifiedFoods.length} foods`);

      if (identifiedFoods.length === 0) {
        res.set('Access-Control-Allow-Origin', '*');
        res.status(200).json({ foods: [] });
        return;
      }

      // Step 2: Look up packaged foods in database, use AI estimates for plated food
      console.log('📚 Step 2: Processing foods (DB lookup for packaging, AI for plated)...');
      const algoliaClient = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey);
      const finalFoods: FoodRecognitionItem[] = [];

      for (const identified of identifiedFoods) {
        // FILTER OUT NON-FOOD PRODUCTS
        if (isNonFoodProduct(identified.name, identified.brand)) {
          console.log(`  🚫 [Non-food] Skipping "${identified.name}" (${identified.brand || 'no brand'}) - not a food product`);
          continue;
        }

        // For PACKAGED products, cap portion size to prevent logging whole pack
        // AI often estimates total pack weight (e.g., 700g for 4 chicken breasts)
        // but users typically want to log a single serving
        let adjustedPortionGrams = identified.portionGrams;

        if (identified.isPackaging) {
          // Maximum reasonable single serving for packaged products
          const MAX_PACKAGED_PORTION = 250; // Most single servings are under 250g

          if (identified.portionGrams > MAX_PACKAGED_PORTION) {
            console.log(`  ⚠️ [Portion cap] "${identified.name}": ${identified.portionGrams}g → ${MAX_PACKAGED_PORTION}g (likely whole pack detected)`);
            adjustedPortionGrams = MAX_PACKAGED_PORTION;
          }
        }

        const portionMultiplier = adjustedPortionGrams / 100;

        // Only search database for packaged products with branding visible
        // Plated/prepared food uses AI estimates directly (more accurate for generic items)
        if (identified.isPackaging && identified.brand) {
          const dbMatch = await searchDatabaseForFood(algoliaClient, identified);

          if (dbMatch) {
            // Extract nutrition with fallbacks for different field naming conventions
            const caloriesVal = dbMatch.calories ?? dbMatch.Calories ?? dbMatch.energy ?? 0;
            const proteinVal = dbMatch.protein ?? dbMatch.Protein ?? 0;
            const carbsVal = dbMatch.carbs ?? dbMatch.Carbs ?? dbMatch.carbohydrates ?? 0;
            const fatVal = dbMatch.fat ?? dbMatch.Fat ?? 0;
            const fiberVal = dbMatch.fiber ?? dbMatch.Fiber ?? dbMatch.fibre ?? 0;
            const sugarVal = dbMatch.sugar ?? dbMatch.Sugar ?? 0;
            const sodiumVal = dbMatch.sodium ?? dbMatch.Sodium ?? 0;
            const brandVal = dbMatch.brandName ?? dbMatch.brand ?? identified.brand;

            // Log the raw database record for debugging
            console.log(`  📦 DB record fields: ${Object.keys(dbMatch).join(', ')}`);
            console.log(`  📊 Nutrition values (per 100g) - cal: ${caloriesVal}, prot: ${proteinVal}, carbs: ${carbsVal}, fat: ${fatVal}`);

            // VALIDATE nutrition data before using it
            const validation = validateNutritionData(caloriesVal, proteinVal, carbsVal, fatVal, dbMatch.name);

            if (!validation.isValid) {
              // Bad database data - fall through to AI estimates
              console.log(`  ❌ [Packaging] "${identified.name}" → DB match "${dbMatch.name}" has invalid nutrition, using AI estimate instead`);
              // Don't continue - fall through to AI estimate
            } else {
              // For PACKAGED products with database match, prefer the database serving size
              // over AI-estimated portion (AI should only estimate portions for generic plated food)
              const dbServingSize = dbMatch.servingSize ?? dbMatch.ServingSize ?? dbMatch.serving_size;
              let finalPortionGrams: number;

              if (dbServingSize && dbServingSize > 0) {
                // Use database serving size for packaged products
                finalPortionGrams = dbServingSize;
                console.log(`  📐 Using DB serving size: ${finalPortionGrams}g (AI estimated: ${adjustedPortionGrams}g)`);
              } else {
                // Fallback to AI estimate if no database serving size
                finalPortionGrams = adjustedPortionGrams;
                console.log(`  📐 No DB serving size, using AI estimate: ${finalPortionGrams}g`);
              }

              const finalPortionMultiplier = finalPortionGrams / 100;

              // Database match found with valid nutrition - use verified data scaled to portion
              finalFoods.push({
                name: dbMatch.name,
                brand: brandVal,
                calories: Math.round(caloriesVal * finalPortionMultiplier),
                protein: Math.round(proteinVal * finalPortionMultiplier * 10) / 10,
                carbs: Math.round(carbsVal * finalPortionMultiplier * 10) / 10,
                fat: Math.round(fatVal * finalPortionMultiplier * 10) / 10,
                fiber: Math.round(fiberVal * finalPortionMultiplier * 10) / 10,
                sugar: Math.round(sugarVal * finalPortionMultiplier * 10) / 10,
                sodium: Math.round(sodiumVal * finalPortionMultiplier * 10) / 10,
                portionGrams: finalPortionGrams,
                confidence: identified.confidence,
                isFromDatabase: true,
                databaseId: dbMatch.objectID,
                ingredients: Array.isArray(dbMatch.ingredients)
                  ? dbMatch.ingredients.join(', ')
                  : (dbMatch.ingredients || null),
              });
              console.log(`  ✅ [Packaging] "${identified.name}" → DB match: "${dbMatch.name}" (${caloriesVal} kcal/100g × ${finalPortionMultiplier.toFixed(2)} = ${Math.round(caloriesVal * finalPortionMultiplier)} kcal)`);
              continue;
            }
          }
          // If no DB match for packaging, fall through to AI estimate
          console.log(`  ⚠️ [Packaging] "${identified.name}" → No DB match, using AI estimate`);
        } else {
          console.log(`  🍽️ [Plated] "${identified.name}" → Using AI estimate (generic food)`);
        }

        // Use AI estimates for plated food or when no DB match found
        // Validate AI estimates before using them
        const aiValidation = validateNutritionData(
          identified.estimatedCaloriesPer100g,
          identified.estimatedProteinPer100g,
          identified.estimatedCarbsPer100g,
          identified.estimatedFatPer100g,
          `AI estimate: ${identified.name}`
        );

        if (aiValidation.issues.length > 0 && !aiValidation.isValid) {
          // AI gave unrealistic values - use reasonable defaults
          console.log(`  ⚠️ [AI] "${identified.name}" has invalid estimates, using conservative defaults`);
          finalFoods.push({
            name: identified.name,
            brand: identified.brand,
            calories: Math.round(150 * portionMultiplier), // Conservative default: 150 kcal/100g
            protein: Math.round(5 * portionMultiplier * 10) / 10,
            carbs: Math.round(20 * portionMultiplier * 10) / 10,
            fat: Math.round(5 * portionMultiplier * 10) / 10,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            portionGrams: adjustedPortionGrams,
            confidence: 0.3,  // Low confidence for defaulted values
            isFromDatabase: false,
            databaseId: null,
            ingredients: null,
          });
        } else {
          finalFoods.push({
            name: identified.name,
            brand: identified.brand,
            calories: Math.round(identified.estimatedCaloriesPer100g * portionMultiplier),
            protein: Math.round(identified.estimatedProteinPer100g * portionMultiplier * 10) / 10,
            carbs: Math.round(identified.estimatedCarbsPer100g * portionMultiplier * 10) / 10,
            fat: Math.round(identified.estimatedFatPer100g * portionMultiplier * 10) / 10,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            portionGrams: adjustedPortionGrams,
            confidence: identified.isPackaging ? identified.confidence * 0.8 : identified.confidence,  // Lower confidence only for failed DB lookups
            isFromDatabase: false,
            databaseId: null,
            ingredients: null,
          });
        }
      }

      const dbMatches = finalFoods.filter(f => f.isFromDatabase).length;
      const platedCount = identifiedFoods.filter(f => !f.isPackaging).length;
      console.log(`✅ Complete: ${dbMatches} from database, ${platedCount} plated (AI estimates)`);

      res.set('Access-Control-Allow-Origin', '*');
      res.status(200).json({ foods: finalFoods });
    } catch (error) {
      console.error('❌ Food recognition failed:', error);
      res.status(500).json({
        error: 'Failed to recognize food',
        details: String(error)
      });
    }
  }
);

/**
 * Non-food products that should be filtered out
 * These are common household items that might appear in photos
 */
const NON_FOOD_KEYWORDS = [
  // Oral care
  'toothpaste', 'mouthwash', 'dental', 'toothbrush', 'oral-b', 'oral b', 'colgate',
  'sensodyne', 'listerine', 'floss', 'denture',
  // Personal care
  'shampoo', 'conditioner', 'soap', 'body wash', 'lotion', 'deodorant', 'antiperspirant',
  'moisturizer', 'moisturiser', 'sunscreen', 'perfume', 'cologne', 'hair gel', 'hairspray',
  // Cleaning products
  'detergent', 'bleach', 'dishwasher', 'fabric softener', 'cleaner', 'disinfectant',
  'polish', 'wax', 'air freshener',
  // Medicine / Health
  'medicine', 'tablet', 'capsule', 'pill', 'paracetamol', 'ibuprofen', 'aspirin',
  'vitamins supplement', 'multivitamin', 'bandage', 'plaster', 'first aid',
  // Pet care
  'cat food', 'dog food', 'pet food', 'fish food', 'bird food', 'pet treats',
  // Baby care (non-food)
  'diaper', 'nappy', 'baby wipes', 'baby lotion', 'baby powder',
  // Other household
  'battery', 'light bulb', 'paper towel', 'toilet paper', 'tissue',
];

/**
 * Check if an identified item is a non-food product
 */
function isNonFoodProduct(name: string, brand: string | null): boolean {
  const searchText = `${name} ${brand || ''}`.toLowerCase();

  for (const keyword of NON_FOOD_KEYWORDS) {
    if (searchText.includes(keyword)) {
      return true;
    }
  }

  return false;
}

/**
 * Validate nutrition data for reasonable values
 * Returns true if data seems valid, false if clearly wrong
 */
function validateNutritionData(
  caloriesPer100g: number,
  proteinPer100g: number,
  carbsPer100g: number,
  fatPer100g: number,
  foodName: string
): { isValid: boolean; issues: string[] } {
  const issues: string[] = [];

  // Check for negative values
  if (caloriesPer100g < 0) issues.push(`Negative calories: ${caloriesPer100g}`);
  if (proteinPer100g < 0) issues.push(`Negative protein: ${proteinPer100g}`);
  if (carbsPer100g < 0) issues.push(`Negative carbs: ${carbsPer100g}`);
  if (fatPer100g < 0) issues.push(`Negative fat: ${fatPer100g}`);

  // Check calorie range (pure water = 0, pure fat = ~900 kcal/100g)
  // Allow up to 950 for oils/fats
  if (caloriesPer100g > 950) {
    issues.push(`Calories too high: ${caloriesPer100g} kcal/100g (max expected ~900)`);
  }

  // Check for all-zeros (likely missing data)
  if (caloriesPer100g === 0 && proteinPer100g === 0 && carbsPer100g === 0 && fatPer100g === 0) {
    issues.push('All nutrition values are 0 (missing data)');
  }

  // Macro consistency check: calories should roughly match calculated from macros
  // Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
  const calculatedCalories = (proteinPer100g * 4) + (carbsPer100g * 4) + (fatPer100g * 9);

  // Allow variance for fiber, alcohol, rounding (±40% or ±50 kcal, whichever is larger)
  const tolerance = Math.max(50, calculatedCalories * 0.4);

  if (caloriesPer100g > 0 && calculatedCalories > 0) {
    const diff = Math.abs(caloriesPer100g - calculatedCalories);
    if (diff > tolerance) {
      issues.push(`Macro mismatch: stated ${caloriesPer100g} kcal, calculated ${Math.round(calculatedCalories)} kcal (diff: ${Math.round(diff)})`);
    }
  }

  // Check for suspiciously high individual macros
  if (proteinPer100g > 100) issues.push(`Protein too high: ${proteinPer100g}g/100g (max ~90g for pure protein)`);
  if (carbsPer100g > 100) issues.push(`Carbs too high: ${carbsPer100g}g/100g`);
  if (fatPer100g > 100) issues.push(`Fat too high: ${fatPer100g}g/100g`);

  // Log validation results
  if (issues.length > 0) {
    console.log(`  ⚠️ [Nutrition validation] "${foodName}" has ${issues.length} issue(s):`);
    issues.forEach(issue => console.log(`      - ${issue}`));
  }

  // Consider valid if no critical issues (negative values, extreme values)
  const hasCriticalIssue = issues.some(issue =>
    issue.includes('Negative') ||
    issue.includes('too high') ||
    issue.includes('All nutrition values are 0')
  );

  return { isValid: !hasCriticalIssue, issues };
}

/**
 * Build the prompt for food identification with enhanced image analysis
 */
function buildIdentificationPrompt(): string {
  return `You are an expert food identification AI with advanced visual analysis. Analyse this photo comprehensively.

## STEP 1: IMAGE QUALITY ASSESSMENT
First, mentally assess the image quality to adjust your confidence:
- Lighting: Well-lit, dark, overexposed, or colour-cast (warm restaurant lighting, flash)?
- Focus: Sharp, slightly blurry, or very blurry?
- Angle: Top-down (best for portions), angled, or side view?
- Obstructions: Any food partially hidden or cut off?
Reduce confidence for poor quality images. Account for colour casts when identifying foods.

## STEP 2: REFERENCE OBJECT DETECTION FOR PORTION SIZING
CRITICAL: Look for reference objects to calibrate portion sizes accurately:

COMMON REFERENCE OBJECTS:
- Standard dinner plate: 26-28cm diameter → food covering half = ~150-200g meat or ~200g carbs
- Side plate: 18-20cm diameter
- Bowl (standard): 15-18cm diameter
- Adult hand/fingers visible: palm ≈ 100g meat, fist ≈ 150g carbs
- Fork length: ~19-20cm (use to gauge food size)
- Knife length: ~22-24cm
- Standard mug: 250-300ml
- iPhone/smartphone: ~15cm tall
- £1/£2 coin: 2.3cm/2.8cm diameter
- Takeaway container: small ~300ml, medium ~500ml, large ~750ml

PORTION CALIBRATION METHOD:
1. Identify any reference objects in the image
2. Estimate plate/container size from reference
3. Estimate food coverage area on plate (quarter, half, full)
4. Calculate portion weight from coverage + food density

## STEP 3: FOOD IDENTIFICATION
For EACH food item, provide:
1. name: Specific name WITH cooking method (e.g., "pan-fried salmon fillet" not just "fish")
2. brand: Brand name if visible on packaging, otherwise null
3. portionGrams: Weight calibrated using detected reference objects
4. searchTerms: 2-3 alternative database search terms
5. confidence: 0.0-1.0 (reduce for blurry/obscured/poor lighting)
6. isPackaging: true if product packaging visible, false if plated food
7. estimatedCaloriesPer100g, estimatedProteinPer100g, estimatedCarbsPer100g, estimatedFatPer100g

## FOOD RECOGNITION - BE SPECIFIC

IDENTIFY COOKING METHODS (affects calories significantly):
- "grilled chicken breast" (165 kcal) vs "fried chicken breast" (220 kcal)
- "steamed vegetables" vs "roasted vegetables with oil"
- "boiled rice" vs "egg fried rice" vs "pilau rice"
- "oven chips" (200 kcal) vs "deep-fried chips" (280 kcal)
- "poached egg" vs "fried egg"

IDENTIFY SPECIFIC FOOD TYPES:
- Proteins: Cut (breast/thigh/fillet), cooking method, skin on/off, breaded/plain
- Carbs: White/brown rice, regular/sweet potato, bread type, pasta shape
- Vegetables: Raw/cooked, fresh/frozen, with oil or plain
- Sauces: Cream-based/tomato-based, amount visible

RECOGNISE CUISINES:
- British: Fish and chips, full English, roast dinner, pie and mash, Sunday roast
- Italian: Pasta (penne/spaghetti/lasagne), risotto, pizza
- Asian: Stir-fry, curry (Thai/Chinese/Japanese), sushi, noodles (rice/egg)
- Indian: Curry type (tikka/korma/madras), rice type, naan/chapati/roti
- Mexican: Tacos, burritos, nachos, fajitas
- Fast food: Recognise chains (McDonald's, KFC, Nando's, Greggs, etc.)

RECOGNISE SNACKS AND DRINKS:
- Crisps, chocolate bars, biscuits, cakes, pastries
- Coffee drinks (latte/cappuccino/americano), smoothies, soft drinks
- Alcoholic drinks: beer, wine, spirits with mixers

## PACKAGING vs PLATED FOOD
- isPackaging = true: Product in original packaging with labels/branding visible
- isPackaging = false: Food on plate, in bowl, takeaway container, or being eaten

## CRITICAL FOR PACKAGED PRODUCTS
When isPackaging = true, estimate the SINGLE SERVING portion, NOT the whole pack:
- Pack of 4 chicken breasts (700g total) → portionGrams = 175g (one breast)
- Pack of sausages (400g for 8 sausages) → portionGrams = 50g (one sausage)
- Sliced bread loaf → portionGrams = 35g (one slice)
- Yogurt multipack → portionGrams = 125g (one pot)
- Ready meal → portionGrams = stated serving size on pack
Users scan packaged products to LOG A SINGLE SERVING, not the entire pack.

## CRITICAL - BREAK DOWN MEALS INTO COMPONENTS
For plated food, list EACH component SEPARATELY:
- "Sausage and mash" → "pork sausages", "mashed potato", "onion gravy"
- "Full English" → "bacon rashers", "fried eggs", "pork sausages", "baked beans", "toast", "grilled tomato", "mushrooms"
- "Roast dinner" → "roast chicken", "roast potatoes", "carrots", "peas", "gravy", "Yorkshire pudding"
- "Curry and rice" → "chicken tikka masala", "pilau rice", "naan bread"
- "Fish and chips" → "battered cod", "chips", "mushy peas" (if visible)

## PORTION SIZE GUIDELINES

PROTEINS (calibrated to palm/plate coverage):
- Chicken breast: small 120g, medium 165g, large 200g
- Chicken thigh (boneless): 80-100g each
- Steak: small 150g, medium 200g, large 280g
- Salmon fillet: 120-150g typical
- Pork sausage: 50-60g each
- Bacon rasher: 20-25g each
- Burger patty: 100g (fast food) to 150g (restaurant)
- Fried egg: 50g each

CARBOHYDRATES:
- Rice (cooked): small 120g, medium 180g, large 250g
- Chips: small 100g, medium 150g, large 200g
- Mashed potato: 150-200g serving
- Baked potato: medium 200g, large 300g
- Pasta (cooked): 180-250g restaurant portion
- Bread slice: 30-40g, burger bun: 50-60g
- Naan bread: 150-180g, chapati: 40g

VEGETABLES:
- Side portion: 80-100g
- Half plate of veg: 150g
- Side salad: 80-100g, large salad: 150-200g

SAUCES:
- Gravy: 50-80ml
- Curry sauce: 150-200g
- Pasta sauce: 100-150g

## NUTRITIONAL VALUES (per 100g UK)

PROTEINS:
- Grilled chicken breast: 165 kcal, 31g protein, 0g carbs, 4g fat
- Fried chicken breast: 220 kcal, 28g protein, 2g carbs, 11g fat
- Roast chicken with skin: 190 kcal, 25g protein, 0g carbs, 10g fat
- Sirloin steak: 160 kcal, 25g protein, 0g carbs, 7g fat
- Ribeye steak: 200 kcal, 23g protein, 0g carbs, 12g fat
- Grilled salmon: 200 kcal, 22g protein, 0g carbs, 12g fat
- Battered fish: 230 kcal, 15g protein, 12g carbs, 13g fat
- Pork sausage: 250 kcal, 12g protein, 3g carbs, 20g fat
- Bacon: 270 kcal, 25g protein, 0g carbs, 19g fat
- Beef mince (cooked): 210 kcal, 21g protein, 0g carbs, 14g fat

CARBOHYDRATES:
- White rice (boiled): 130 kcal, 3g protein, 28g carbs, 0.5g fat
- Egg fried rice: 180 kcal, 4g protein, 25g carbs, 7g fat
- Pilau rice: 145 kcal, 3g protein, 27g carbs, 3g fat
- Oven chips: 200 kcal, 3g protein, 30g carbs, 8g fat
- Deep-fried chips: 280 kcal, 3g protein, 35g carbs, 14g fat
- Mashed potato: 100 kcal, 2g protein, 15g carbs, 4g fat
- Roast potatoes: 150 kcal, 2g protein, 22g carbs, 6g fat
- Pasta (cooked): 130 kcal, 5g protein, 25g carbs, 1g fat
- Naan bread: 290 kcal, 9g protein, 50g carbs, 6g fat
- White bread: 245 kcal, 9g protein, 47g carbs, 3g fat

SAUCES:
- Gravy: 35 kcal, 1g protein, 4g carbs, 2g fat
- Tikka masala sauce: 120 kcal, 3g protein, 6g carbs, 9g fat
- Korma sauce: 150 kcal, 2g protein, 8g carbs, 12g fat
- Tomato pasta sauce: 45 kcal, 1g protein, 7g carbs, 1g fat
- Creamy pasta sauce: 120 kcal, 2g protein, 5g carbs, 10g fat

VEGETABLES:
- Mixed vegetables: 50 kcal, 2g protein, 8g carbs, 1g fat
- Roasted vegetables: 80 kcal, 2g protein, 10g carbs, 4g fat

## REALISTIC MEAL TOTALS
- Steak (200g) + chips (150g): 320 + 420 = 740 kcal
- Chicken breast + rice + veg: 270 + 260 + 50 = 580 kcal
- Fish and chips: 350 + 400 = 750 kcal
- Full English breakfast: 800-1000 kcal
- Curry + rice + naan: 350 + 320 + 480 = 1150 kcal
- Burger + bun + chips: 300 + 150 + 350 = 800 kcal

DO NOT estimate over 1000 kcal unless clearly large portions or high-calorie items.

## CRITICAL: ONLY IDENTIFY EDIBLE FOOD ITEMS
DO NOT identify non-food products. SKIP and IGNORE:
- Oral care: toothpaste, mouthwash, dental products, toothbrushes (Oral-B, Colgate, Sensodyne, etc.)
- Personal care: shampoo, conditioner, soap, lotion, deodorant, sunscreen, makeup
- Cleaning products: detergent, bleach, cleaners, dishwasher products
- Medicine: tablets, pills, supplements, vitamins (unless clearly food/drink vitamins)
- Pet food: cat food, dog food, pet treats
- Baby products: diapers, wipes, baby lotion (baby food IS acceptable)
- Household items: batteries, tissues, paper towels

Only return items that are HUMAN FOOD OR DRINK. If a non-food product is visible, simply ignore it.

## RESPONSE FORMAT
Respond with ONLY valid JSON (no markdown):
{
  "foods": [
    {
      "name": "specific food name with cooking method",
      "brand": "brand or null",
      "portionGrams": number,
      "searchTerms": ["term1", "term2", "term3"],
      "confidence": 0.0-1.0,
      "isPackaging": true/false,
      "estimatedCaloriesPer100g": number,
      "estimatedProteinPer100g": number,
      "estimatedCarbsPer100g": number,
      "estimatedFatPer100g": number
    }
  ]
}

If no food is visible, return: {"foods": []}`;
}

/**
 * Identify foods using Gemini 2.0 Flash (best balance of speed and accuracy)
 */
async function identifyFoodsWithGemini(base64Image: string, apiKey: string): Promise<GeminiIdentifiedFood[]> {
  // Using gemini-2.0-flash for best multimodal performance
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

  const response = await axios.post(url, {
    contents: [{
      parts: [
        { text: buildIdentificationPrompt() },
        {
          inline_data: {
            mime_type: 'image/jpeg',
            data: base64Image
          }
        }
      ]
    }],
    generationConfig: {
      temperature: 0.1,  // Very low for consistent, accurate identification
      topP: 0.8,
      topK: 20,
      maxOutputTokens: 4096,
    }
  });

  const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text || '{"foods": []}';
  return parseGeminiResponse(text);
}

/**
 * Parse Gemini's identification response
 */
function parseGeminiResponse(responseText: string): GeminiIdentifiedFood[] {
  try {
    let cleanedText = responseText.trim();
    cleanedText = cleanedText.replace(/^```json\s*/i, '');
    cleanedText = cleanedText.replace(/^```\s*/i, '');
    cleanedText = cleanedText.replace(/\s*```$/i, '');
    cleanedText = cleanedText.trim();

    const parsed = JSON.parse(cleanedText);
    const foods: GeminiIdentifiedFood[] = [];

    if (Array.isArray(parsed.foods)) {
      for (const item of parsed.foods) {
        if (typeof item.name === 'string' && item.name.length > 0) {
          foods.push({
            name: item.name,
            brand: typeof item.brand === 'string' ? item.brand : null,
            portionGrams: typeof item.portionGrams === 'number' && item.portionGrams > 0
              ? Math.round(item.portionGrams)
              : 100,
            searchTerms: Array.isArray(item.searchTerms)
              ? item.searchTerms.filter((t: unknown) => typeof t === 'string')
              : [item.name],
            confidence: typeof item.confidence === 'number'
              ? Math.min(1, Math.max(0, item.confidence))
              : 0.5,
            isPackaging: item.isPackaging === true,  // Default to false (plated food) if not specified
            estimatedCaloriesPer100g: typeof item.estimatedCaloriesPer100g === 'number'
              ? Math.max(0, item.estimatedCaloriesPer100g)
              : 100,
            estimatedProteinPer100g: typeof item.estimatedProteinPer100g === 'number'
              ? Math.max(0, item.estimatedProteinPer100g)
              : 5,
            estimatedCarbsPer100g: typeof item.estimatedCarbsPer100g === 'number'
              ? Math.max(0, item.estimatedCarbsPer100g)
              : 10,
            estimatedFatPer100g: typeof item.estimatedFatPer100g === 'number'
              ? Math.max(0, item.estimatedFatPer100g)
              : 5,
          });
        }
      }
    }

    return foods;
  } catch (error) {
    console.error('Failed to parse Gemini response:', responseText, error);
    return [];
  }
}

/**
 * Search Algolia database for a food match
 * PRIORITIZES UK results over generic/US versions
 */
async function searchDatabaseForFood(
  client: ReturnType<typeof algoliasearch>,
  food: GeminiIdentifiedFood
): Promise<AlgoliaFoodHit | null> {
  // Build search queries from the identified food
  const searchQueries = [
    food.name,  // Primary name
    ...(food.searchTerms || []),  // Alternative terms
  ];

  // If brand is specified, try brand + name first
  if (food.brand) {
    searchQueries.unshift(`${food.brand} ${food.name}`);
  }

  // Collect ALL potential matches across all indices, then prioritize
  interface CandidateMatch {
    hit: AlgoliaFoodHit;
    matchScore: number;
    indexName: string;
    isUkSource: boolean;
  }
  const candidates: CandidateMatch[] = [];

  // Search all indices for all queries
  for (const query of searchQueries) {
    for (const indexName of SEARCH_INDICES) {
      try {
        const result = await client.searchSingleIndex({
          indexName,
          searchParams: {
            query,
            hitsPerPage: 3,
            // Retrieve all attributes to handle different field naming conventions
            // CSV imports may use different cases or spellings
            attributesToRetrieve: ['*'],
          },
        });

        if (result.hits && result.hits.length > 0) {
          for (const rawHit of result.hits) {
            const hit = rawHit as unknown as AlgoliaFoodHit;

            // Calculate match score
            const queryWords = query.toLowerCase().split(' ');
            const hitName = hit.name.toLowerCase();
            const matchScore = queryWords.filter(word => hitName.includes(word)).length / queryWords.length;

            // Only consider if at least 50% of query words match
            if (matchScore >= 0.5) {
              candidates.push({
                hit,
                matchScore,
                indexName,
                isUkSource: UK_SOURCE_INDICES.has(indexName),
              });
            }
          }
        }
      } catch (error) {
        // Continue to next index if this one fails
        console.warn(`Search failed for "${query}" in ${indexName}:`, error);
      }
    }
  }

  // No matches found
  if (candidates.length === 0) {
    return null;
  }

  // PRIORITIZE: Tesco (tier 1) > UK Foods (tier 2) > Others (tier 3)
  // Sort by: 1) Source tier, 2) Match score descending
  const getSourceTier = (indexName: string): number => {
    if (indexName === 'tesco_products') return 0;  // Tier 1: Official supermarket data
    if (indexName === 'uk_foods_cleaned') return 1;  // Tier 2: UK verified data
    return 2;  // Tier 3: Other sources
  };

  candidates.sort((a, b) => {
    const tierA = getSourceTier(a.indexName);
    const tierB = getSourceTier(b.indexName);
    // Lower tier number = higher priority
    if (tierA !== tierB) return tierA - tierB;
    // Within same tier, prefer higher match score
    return b.matchScore - a.matchScore;
  });

  const bestMatch = candidates[0];
  const tierLabel = getSourceTier(bestMatch.indexName) === 0 ? 'TIER 1' : getSourceTier(bestMatch.indexName) === 1 ? 'TIER 2' : 'TIER 3';
  console.log(`  🎯 Best match: "${bestMatch.hit.name}" from ${bestMatch.indexName} [${tierLabel}] (score: ${(bestMatch.matchScore * 100).toFixed(0)}%)`);

  // If best match is non-UK but UK matches exist, log warning
  if (!bestMatch.isUkSource) {
    const ukMatches = candidates.filter(c => c.isUkSource);
    if (ukMatches.length > 0) {
      console.log(`  ⚠️ Note: UK match exists but non-UK was selected: "${ukMatches[0].hit.name}"`);
    }
  }

  return bestMatch.hit;
}
