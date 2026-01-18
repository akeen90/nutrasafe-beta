import * as functionsV2 from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import { algoliasearch } from 'algoliasearch';

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const algoliaAdminKey = defineSecret('ALGOLIA_ADMIN_API_KEY');

// Issue types
interface Issue {
  type: 'missing-nutrition' | 'impossible-nutrition' | 'misspelling' | 'non-word' | 'weird-spacing' | 'missing-barcode' | 'missing-ingredients';
  field?: string;
  value?: string;
  suggestion?: string;
}

interface FoodWithIssues {
  objectID: string;
  foodName?: string;
  name?: string;
  brandName?: string;
  brand?: string;
  barcode?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
  sodium?: number;
  extractedIngredients?: string[];
  ingredients?: string[];
  issues: Issue[];
  [key: string]: unknown;
}

// Legitimate foreign food terms that should NOT be flagged as misspellings
const FOREIGN_FOOD_TERMS = new Set([
  // French terms
  'chocolat', 'pain', 'pains', 'croissant', 'croissants', 'brioche', 'brioches',
  'baguette', 'baguettes', 'crepe', 'crepes', 'gateau', 'gateaux', 'patisserie',
  'quiche', 'ratatouille', 'bechamel', 'beurre', 'fromage', 'jambon', 'poulet',
  'boeuf', 'poisson', 'legumes', 'salade', 'soupe', 'creme', 'fraiche', 'au',
  'aux', 'avec', 'sans', 'du', 'de', 'la', 'le', 'les', 'noir', 'blanc', 'rouge',
  'vert', 'gratin', 'gratiné', 'flambé', 'sauté', 'julienne', 'puree', 'compote',
  'mousse', 'souffle', 'parfait', 'tarte', 'tartes', 'galette', 'galettes',
  'macaron', 'macarons', 'eclair', 'eclairs', 'profiterole', 'profiteroles',
  'madeleine', 'madeleines', 'financier', 'financiers', 'canelé', 'canelés',

  // Italian terms
  'pasta', 'spaghetti', 'penne', 'rigatoni', 'fusilli', 'farfalle', 'linguine',
  'tagliatelle', 'fettuccine', 'lasagna', 'lasagne', 'ravioli', 'tortellini',
  'gnocchi', 'risotto', 'pizza', 'pizze', 'focaccia', 'ciabatta', 'panini',
  'bruschetta', 'antipasto', 'antipasti', 'prosciutto', 'pancetta', 'salami',
  'mortadella', 'bresaola', 'mozzarella', 'ricotta', 'mascarpone', 'parmigiano',
  'parmesan', 'pecorino', 'gorgonzola', 'burrata', 'stracciatella', 'gelato',
  'tiramisu', 'panna', 'cotta', 'biscotti', 'amaretti', 'panettone', 'pandoro',
  'cannoli', 'espresso', 'cappuccino', 'latte', 'macchiato', 'affogato',
  'arrabbiata', 'carbonara', 'bolognese', 'pesto', 'pomodoro', 'marinara',
  'alfredo', 'primavera', 'aglio', 'olio', 'peperoncino', 'alla', 'al', 'con',
  'fra', 'diavolo', 'piccante', 'dolce', 'amaro', 'secco',

  // Spanish terms
  'tapas', 'paella', 'gazpacho', 'tortilla', 'empanada', 'empanadas', 'churro',
  'churros', 'chorizo', 'jamon', 'serrano', 'iberico', 'manchego', 'queso',
  'salsa', 'guacamole', 'enchilada', 'enchiladas', 'burrito', 'burritos',
  'taco', 'tacos', 'quesadilla', 'quesadillas', 'fajita', 'fajitas', 'nacho',
  'nachos', 'jalapeno', 'chipotle', 'mole', 'ceviche', 'arroz', 'frijoles',
  'pollo', 'carne', 'asada', 'carnitas', 'barbacoa', 'picante', 'verde', 'rojo',

  // German terms
  'bratwurst', 'wurst', 'schnitzel', 'pretzel', 'strudel', 'sauerkraut',
  'pumpernickel', 'lebkuchen', 'muesli', 'müsli', 'spätzle', 'spatzle',
  'knödel', 'knodel', 'käse', 'kase', 'brot', 'brötchen', 'kuchen',

  // Greek terms
  'gyro', 'gyros', 'souvlaki', 'tzatziki', 'hummus', 'falafel', 'pita', 'pitta',
  'moussaka', 'spanakopita', 'baklava', 'dolma', 'dolmades', 'feta', 'halloumi',

  // Japanese terms
  'sushi', 'sashimi', 'maki', 'nigiri', 'tempura', 'teriyaki', 'yakitori',
  'ramen', 'udon', 'soba', 'miso', 'tofu', 'edamame', 'wasabi', 'nori',
  'sake', 'matcha', 'mochi', 'dashi', 'katsu', 'tonkatsu', 'gyoza', 'onigiri',

  // Chinese terms
  'dim', 'sum', 'wonton', 'chow', 'mein', 'lo', 'kung', 'pao', 'szechuan',
  'sichuan', 'cantonese', 'hoisin', 'bok', 'choy', 'tofu', 'congee',

  // Indian terms
  'curry', 'tikka', 'masala', 'tandoori', 'naan', 'roti', 'chapati', 'paratha',
  'samosa', 'pakora', 'bhaji', 'korma', 'vindaloo', 'biryani', 'pilau', 'pilaf',
  'dal', 'dahl', 'paneer', 'ghee', 'chutney', 'raita', 'lassi', 'chai',

  // Thai terms
  'pad', 'thai', 'satay', 'tom', 'yum', 'som', 'tam', 'larb', 'nam', 'pla',
  'gaeng', 'kaeng', 'massaman', 'panang', 'basil', 'galangal', 'lemongrass',

  // Middle Eastern terms
  'shawarma', 'kebab', 'kebabs', 'kibbeh', 'tabbouleh', 'fattoush', 'labneh',
  'tahini', 'baba', 'ganoush', 'halal', 'kosher', 'za\'atar', 'zaatar', 'sumac',

  // Other international terms
  'kimchi', 'bulgogi', 'bibimbap', 'pho', 'banh', 'mi', 'borscht', 'pierogi',
  'goulash', 'paprikash', 'tagine', 'couscous', 'harissa', 'ras', 'hanout',
]);

// Foreign food phrases - if text contains these, skip misspelling check for contained words
const FOREIGN_FOOD_PHRASES = [
  'pain au chocolat', 'pains au chocolat', 'au chocolat', 'chocolat noir',
  'chocolat blanc', 'chocolat chaud', 'mousse au chocolat', 'gateau au chocolat',
  'tarte au chocolat', 'creme au chocolat', 'fondant au chocolat',
  'croissant au beurre', 'pain aux raisins', 'pain aux noix',
  'coq au vin', 'boeuf bourguignon', 'crème brûlée', 'creme brulee',
  'pot au feu', 'gratin dauphinois', 'tarte tatin', 'île flottante',
  'croque monsieur', 'croque madame', 'salade niçoise', 'salade nicoise',
  'carte d\'or', 'carte dor', 'haagen dazs', 'häagen-dazs',
];

// Misspellings dictionary with corrections
const MISSPELLINGS: Record<string, string> = {
  // Nutrition terms
  'protien': 'protein',
  'caloires': 'calories',
  'carbohidrates': 'carbohydrates',
  'suger': 'sugar',
  'sodiem': 'sodium',
  'soduim': 'sodium',

  // Chocolate variations (NOT 'chocolat' - that's French!)
  'choclate': 'chocolate',
  'cholocate': 'chocolate',
  'chocloate': 'chocolate',
  'chocalate': 'chocolate',

  // Vanilla
  'vanila': 'vanilla',
  'vanilia': 'vanilla',

  // Fruits
  'strawbery': 'strawberry',
  'bluberry': 'blueberry',
  'blueberrry': 'blueberry',
  'oragne': 'orange',
  'oraneg': 'orange',
  'bananana': 'banana',
  'bannana': 'banana',
  'appel': 'apple',
  'lemmon': 'lemon',
  'cheery': 'cherry',
  'cherrie': 'cherry',

  // Meats
  'chiken': 'chicken',
  'chickin': 'chicken',
  'chickn': 'chicken',
  'beaf': 'beef',
  'prok': 'pork',
  'salman': 'salmon',
  'samon': 'salmon',
  'tunna': 'tuna',

  // Vegetables
  'vegatable': 'vegetable',
  'vegetabel': 'vegetable',
  'vegitables': 'vegetables',
  'tomatoe': 'tomato',
  'tomatos': 'tomatoes',
  'potatos': 'potatoes',
  'letuce': 'lettuce',
  'lettuse': 'lettuce',

  // Dairy
  'cheeze': 'cheese',
  'chese': 'cheese',
  'cheesse': 'cheese',
  'yougurt': 'yogurt',
  'yoghert': 'yogurt',
  'yougrt': 'yogurt',
  'buuter': 'butter',
  'buttr': 'butter',

  // Meals
  'breackfast': 'breakfast',
  'breakfest': 'breakfast',
  'luch': 'lunch',
  'diner': 'dinner',
  'dinr': 'dinner',
  'snaks': 'snacks',
  'deserts': 'desserts',

  // Foods
  'ceral': 'cereal',
  'cerael': 'cereal',
  'cerial': 'cereal',
  'biscits': 'biscuits',
  'biscuts': 'biscuits',
  'chrisps': 'crisps',
  'crissp': 'crisps',

  // Labels
  'oragnic': 'organic',
  'orgainc': 'organic',
  'natual': 'natural',
  'natrual': 'natural',
  'artifical': 'artificial',
  'artifcial': 'artificial',
  'preservitive': 'preservative',
  'containts': 'contains',
  'ingredeints': 'ingredients',
  'ingrdients': 'ingredients',
  'nutritoin': 'nutrition',
  'nutrtion': 'nutrition',
  'servng': 'serving',
  'seving': 'serving',

  // US misspellings (wrong in UK context)
  'flavord': 'flavoured',
  'colord': 'coloured',
  'favourate': 'favourite',

  // Minerals/vitamins
  'calcuim': 'calcium',
  'magneisum': 'magnesium',
  'potasium': 'potassium',
  'pottasium': 'potassium',
  'vitmin': 'vitamin',
  'vitamn': 'vitamin',
};

/**
 * Check if a potential misspelling is actually a legitimate foreign food term
 */
function isLegitForeignTerm(word: string, fullText: string): boolean {
  const lowerWord = word.toLowerCase();
  const lowerText = fullText.toLowerCase();

  // Check if it's a known foreign food term
  if (FOREIGN_FOOD_TERMS.has(lowerWord)) {
    return true;
  }

  // Check if it appears in a known foreign food phrase
  for (const phrase of FOREIGN_FOOD_PHRASES) {
    if (lowerText.includes(phrase)) {
      return true;
    }
  }

  return false;
}

/**
 * Detect issues in a food record
 */
function detectIssues(food: Record<string, unknown>): Issue[] {
  const issues: Issue[] = [];

  // Get food name and brand
  const name = ((food.foodName || food.name || '') as string).toLowerCase();
  const brand = ((food.brandName || food.brand || '') as string).toLowerCase();
  const text = `${name} ${brand}`;

  // 1. Missing Nutrition (all zeros indicates missing data)
  const calories = (food.calories as number) || 0;
  const protein = (food.protein as number) || 0;
  const carbs = (food.carbs as number) || (food.carbohydrates as number) || 0;
  const fat = (food.fat as number) || 0;
  const fiber = (food.fiber as number) || 0;
  const sugar = (food.sugar as number) || 0;
  const sodium = (food.sodium as number) || 0;

  if (calories === 0 && protein === 0 && carbs === 0 && fat === 0) {
    issues.push({ type: 'missing-nutrition', field: 'nutrition' });
  }

  // 1b. Impossible/Highly Unlikely Nutrition (per 100g basis)
  // These are scientifically impossible or highly unlikely values
  const impossibleIssues: string[] = [];

  // Calories: Pure fat is ~900 kcal/100g, anything higher is impossible
  if (calories > 900) {
    impossibleIssues.push(`calories: ${calories} (max possible ~900)`);
  }

  // Macronutrients can't exceed 100g per 100g serving
  if (protein > 100) {
    impossibleIssues.push(`protein: ${protein}g (max 100g)`);
  }
  if (carbs > 100) {
    impossibleIssues.push(`carbs: ${carbs}g (max 100g)`);
  }
  if (fat > 100) {
    impossibleIssues.push(`fat: ${fat}g (max 100g)`);
  }
  if (fiber > 100) {
    impossibleIssues.push(`fiber: ${fiber}g (max 100g)`);
  }
  if (sugar > 100) {
    impossibleIssues.push(`sugar: ${sugar}g (max 100g)`);
  }

  // Sugar can't exceed carbs
  if (sugar > carbs && carbs > 0) {
    impossibleIssues.push(`sugar (${sugar}g) > carbs (${carbs}g)`);
  }

  // Fiber can't exceed carbs
  if (fiber > carbs && carbs > 0) {
    impossibleIssues.push(`fiber (${fiber}g) > carbs (${carbs}g)`);
  }

  // Total macros can't exceed 100g (with small tolerance for rounding)
  const totalMacros = protein + carbs + fat;
  if (totalMacros > 105) {
    impossibleIssues.push(`total macros: ${totalMacros.toFixed(1)}g (max ~100g)`);
  }

  // Calorie math check: calculated vs stated (with 15% tolerance)
  // 4 cal/g protein, 4 cal/g carbs, 9 cal/g fat
  if (calories > 0 && (protein > 0 || carbs > 0 || fat > 0)) {
    const calculatedCals = (protein * 4) + (carbs * 4) + (fat * 9);
    const difference = Math.abs(calories - calculatedCals);
    const percentDiff = (difference / calories) * 100;
    // Flag if more than 30% off and difference is significant
    if (percentDiff > 30 && difference > 50) {
      impossibleIssues.push(`calories mismatch: stated ${calories} vs calculated ${calculatedCals.toFixed(0)}`);
    }
  }

  // Sodium: typically measured in mg, > 10000mg (10g) is extreme
  if (sodium > 10000) {
    impossibleIssues.push(`sodium: ${sodium}mg (extremely high)`);
  }

  if (impossibleIssues.length > 0) {
    issues.push({
      type: 'impossible-nutrition',
      field: 'nutrition',
      value: impossibleIssues.join('; ')
    });
  }

  // 2. Misspellings (with field and suggestion)
  // Skip if the word is actually a legitimate foreign food term
  for (const [wrong, correct] of Object.entries(MISSPELLINGS)) {
    if (text.includes(wrong)) {
      // Check if this is actually a foreign food term (e.g., "chocolat" in "pain au chocolat")
      if (isLegitForeignTerm(wrong, text)) {
        continue; // Skip - it's a legitimate term
      }
      const field = name.includes(wrong) ? 'name' : 'brand';
      issues.push({ type: 'misspelling', field, value: wrong, suggestion: correct });
    }
  }

  // Also check ingredients for misspellings
  const ingredients = (food.extractedIngredients || food.ingredients || []) as string[];
  if (Array.isArray(ingredients)) {
    const ingredientText = ingredients.join(' ').toLowerCase();
    for (const [wrong, correct] of Object.entries(MISSPELLINGS)) {
      if (ingredientText.includes(wrong) && !issues.some(i => i.value === wrong)) {
        // Check if this is actually a foreign food term
        if (isLegitForeignTerm(wrong, ingredientText)) {
          continue; // Skip - it's a legitimate term
        }
        issues.push({ type: 'misspelling', field: 'ingredients', value: wrong, suggestion: correct });
      }
    }
  }

  // 3. Non-words detection (gibberish)
  // Check for words with no vowels that are too long (likely data corruption)
  const words = text.split(/\s+/).filter(w => w.length > 0);
  for (const word of words) {
    // Skip short words and common abbreviations
    if (word.length < 4) continue;

    // Skip if it's a legitimate foreign food term
    if (isLegitForeignTerm(word, text)) continue;

    // Check for words with no vowels longer than 6 chars (likely gibberish)
    if (word.length > 6 && !/[aeiou]/i.test(word)) {
      issues.push({ type: 'non-word', field: 'name', value: word });
    }

    // Check for excessive repeated characters (e.g., "aaaaa")
    if (/(.)\1{3,}/.test(word)) {
      issues.push({ type: 'non-word', field: 'name', value: word });
    }

    // Check for unusual character sequences (numbers mixed with letters in odd patterns)
    if (/^[a-z]+\d{3,}[a-z]+$/i.test(word) || /^\d+[a-z]+\d+$/i.test(word)) {
      issues.push({ type: 'non-word', field: 'name', value: word });
    }
  }

  // 3b. Weird Spacing Detection
  // Look for single letters surrounded by spaces (like "Chocolat e" or "B iscuits")
  const originalName = (food.foodName || food.name || '') as string;
  const originalBrand = (food.brandName || food.brand || '') as string;
  const originalText = `${originalName} ${originalBrand}`;

  // Pattern: space + single letter + space (or end of string)
  // e.g., "Chocolat e" -> captures " e" at end or " e " in middle
  const weirdSpacingMatches = originalText.match(/\s+[a-zA-Z]\s+|\s+[a-zA-Z]$/g);
  if (weirdSpacingMatches) {
    for (const match of weirdSpacingMatches) {
      const trimmed = match.trim();
      // Skip common single letters that are legitimate (e.g., "Vitamin E", "Type A")
      const legitSingleLetters = ['a', 'e', 'i', 'o', 'u', 'b', 'c', 'd', 'k'];
      const lowerTrimmed = trimmed.toLowerCase();

      // Check context - is it preceded by words like "vitamin", "type", "grade", "class"?
      const legitContexts = ['vitamin', 'type', 'grade', 'class', 'size', 'group', 'category'];
      const beforeMatch = originalText.substring(0, originalText.indexOf(match)).toLowerCase();
      const hasLegitContext = legitContexts.some(ctx => beforeMatch.endsWith(ctx));

      if (!hasLegitContext && legitSingleLetters.includes(lowerTrimmed)) {
        // Likely a weird spacing issue (e.g., "Chocolat e" should be "Chocolate")
        issues.push({
          type: 'weird-spacing',
          field: originalName.includes(match) ? 'name' : 'brand',
          value: `"${match.trim()}" (stray letter)`,
          suggestion: 'Check for OCR/data entry error'
        });
      }
    }
  }

  // Also check for multiple consecutive spaces
  if (/\s{2,}/.test(originalText)) {
    const multiSpaceMatch = originalText.match(/\S+\s{2,}\S+/);
    if (multiSpaceMatch) {
      issues.push({
        type: 'weird-spacing',
        field: 'name',
        value: `Multiple spaces: "${multiSpaceMatch[0]}"`,
        suggestion: 'Remove extra spaces'
      });
    }
  }

  // 4. Missing Barcode
  if (!food.barcode) {
    issues.push({ type: 'missing-barcode' });
  }

  // 5. Missing Ingredients
  if (!ingredients || ingredients.length === 0) {
    issues.push({ type: 'missing-ingredients' });
  }

  return issues;
}

/**
 * Scan entire Algolia index for issues
 * Uses browseObjects to iterate through all records
 */
export const scanDatabaseIssues = functionsV2.https.onRequest({
  secrets: [algoliaAdminKey],
  cors: true,
  timeoutSeconds: 540,  // 9 minutes for full scan
  memory: '1GiB',       // Extra memory for processing
}, async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { indexName, checkTypes } = req.body;

    if (!indexName) {
      res.status(400).json({ success: false, error: 'Index name is required' });
      return;
    }

    console.log(`🔍 Starting database scan for index: ${indexName}`);

    // Initialize Algolia client
    const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

    // Collect all foods with issues
    const foodsWithIssues: FoodWithIssues[] = [];
    let totalScanned = 0;

    // Browse ALL objects in the index using cursor-based pagination (no 1000 limit)
    // This uses Algolia's browse API which can iterate through the entire index
    let cursor: string | undefined;
    let batchNumber = 0;

    do {
      batchNumber++;
      const browseParams: Record<string, unknown> = {
        attributesToRetrieve: [
          'objectID', 'foodName', 'name', 'brandName', 'brand', 'barcode',
          'calories', 'protein', 'carbs', 'carbohydrates', 'fat', 'fiber',
          'sugar', 'sodium', 'extractedIngredients', 'ingredients',
          'servingSize', 'category'
        ],
        hitsPerPage: 1000,  // Max batch size for browse
      };

      // Add cursor for subsequent requests
      if (cursor) {
        browseParams.cursor = cursor;
      }

      const result = await client.browse({
        indexName,
        browseParams,
      });

      const hits = (result.hits || []) as Record<string, unknown>[];
      totalScanned += hits.length;

      console.log(`📊 Scanned batch ${batchNumber}: ${hits.length} records (total: ${totalScanned})`);

      // Check each food for issues
      for (const food of hits) {
        const issues = detectIssues(food);

        // Filter by checkTypes if specified
        let filteredIssues = issues;
        if (checkTypes && Array.isArray(checkTypes) && checkTypes.length > 0) {
          filteredIssues = issues.filter(issue => {
            if (checkTypes.includes('misspellings') && issue.type === 'misspelling') return true;
            if (checkTypes.includes('missing-nutrition') && issue.type === 'missing-nutrition') return true;
            if (checkTypes.includes('impossible-nutrition') && issue.type === 'impossible-nutrition') return true;
            if (checkTypes.includes('non-words') && issue.type === 'non-word') return true;
            if (checkTypes.includes('weird-spacing') && issue.type === 'weird-spacing') return true;
            if (checkTypes.includes('missing-barcode') && issue.type === 'missing-barcode') return true;
            if (checkTypes.includes('missing-ingredients') && issue.type === 'missing-ingredients') return true;
            return false;
          });
        }

        if (filteredIssues.length > 0) {
          foodsWithIssues.push({
            ...(food as FoodWithIssues),
            objectID: food.objectID as string,
            issues: filteredIssues,
          });
        }
      }

      // Get cursor for next batch (undefined when done)
      cursor = result.cursor;

      // Safety check to prevent infinite loops (60k records / 1000 per batch = 60 batches max expected)
      if (batchNumber > 200) {
        console.log('⚠️ Reached batch limit (200), stopping scan');
        break;
      }
    } while (cursor);

    console.log(`✅ Scan complete: ${totalScanned} records scanned, ${foodsWithIssues.length} issues found`);

    res.json({
      success: true,
      totalScanned,
      issuesFound: foodsWithIssues.length,
      foods: foodsWithIssues,
    });

  } catch (error: unknown) {
    console.error('❌ Error scanning database:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to scan database',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

/**
 * Batch update and delete foods in Algolia
 */
export const batchUpdateFoods = functionsV2.https.onRequest({
  secrets: [algoliaAdminKey],
  cors: true,
}, async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { indexName, updates, deletes } = req.body;

    if (!indexName) {
      res.status(400).json({ success: false, error: 'Index name is required' });
      return;
    }

    console.log(`📝 Batch update for index: ${indexName}`);
    console.log(`   Updates: ${updates?.length || 0}, Deletes: ${deletes?.length || 0}`);

    // Initialize Algolia client
    const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

    let updatedCount = 0;
    let deletedCount = 0;

    // Apply updates (partial updates)
    if (updates && Array.isArray(updates) && updates.length > 0) {
      const objects = updates.map((u: { objectID: string; changes: Record<string, unknown> }) => ({
        objectID: u.objectID,
        ...u.changes,
      }));

      // DEBUG: Log the first few objects being updated
      console.log(`📝 Objects to update (first 3):`, JSON.stringify(objects.slice(0, 3), null, 2));

      // Process in batches of 1000
      const batchSize = 1000;
      for (let i = 0; i < objects.length; i += batchSize) {
        const batch = objects.slice(i, i + batchSize);
        console.log(`   Processing batch starting at index ${i}, batch size: ${batch.length}`);

        const updateResponse = await client.partialUpdateObjects({
          indexName,
          objects: batch,
          createIfNotExists: false,
        });
        console.log(`   Algolia response:`, JSON.stringify(updateResponse, null, 2));

        updatedCount += batch.length;
        console.log(`   Updated batch: ${batch.length} records`);
      }
    }

    // Apply deletes
    if (deletes && Array.isArray(deletes) && deletes.length > 0) {
      // Process in batches of 1000
      const batchSize = 1000;
      for (let i = 0; i < deletes.length; i += batchSize) {
        const batch = deletes.slice(i, i + batchSize);
        await client.deleteObjects({
          indexName,
          objectIDs: batch,
        });
        deletedCount += batch.length;
        console.log(`   Deleted batch: ${batch.length} records`);
      }
    }

    console.log(`✅ Batch update complete: ${updatedCount} updated, ${deletedCount} deleted`);

    res.json({
      success: true,
      updated: updatedCount,
      deleted: deletedCount,
    });

  } catch (error: unknown) {
    console.error('❌ Error in batch update:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to batch update',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});
