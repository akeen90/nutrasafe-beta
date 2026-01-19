"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fixHtmlCode = exports.fixSimpleIngredients = exports.fixKjKcalCombinedCalories = exports.batchUpdateFoods = exports.scanDatabaseIssues = void 0;
const functions = require("firebase-functions");
const algoliasearch_1 = require("algoliasearch");
// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
// Use functions.config() for v1 triggers (more reliable than v2 secrets)
const getAlgoliaAdminKey = () => functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || '';
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
const MISSPELLINGS = {
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
function isLegitForeignTerm(word, fullText) {
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
 * Detect if a calorie value is likely kJ + kcal combined (common Tesco data entry error)
 *
 * Pattern: When data is scraped, sometimes the energy value appears as kJ and kcal
 * concatenated together. For example:
 * - Actual: 583 kcal / 2431 kJ
 * - Error: 2431583 (kJ concatenated with kcal)
 *
 * Detection method:
 * 1. Try splitting the number at different positions
 * 2. Check if one part × 4.184 ≈ the other part (with 10 kcal tolerance)
 * 3. If so, the smaller number is the kcal
 *
 * Conversion: 1 kcal = 4.184 kJ
 */
function detectKjKcalCombined(calories, protein, carbs, fat, tolerancePercent = 10 // 10% tolerance for the kJ/kcal conversion check
) {
    const calStr = calories.toString();
    // Need at least 4 digits to have two meaningful parts (e.g., "1234" -> "12" and "34")
    if (calStr.length < 4) {
        return { isLikelyCombined: false, suggestedKcal: 0, pattern: 'too-short' };
    }
    // Try splitting at different positions
    for (let splitPos = 1; splitPos < calStr.length; splitPos++) {
        const firstPart = parseInt(calStr.substring(0, splitPos), 10);
        const secondPart = parseInt(calStr.substring(splitPos), 10);
        // Skip if either part is 0 or has leading zeros that got trimmed
        if (firstPart === 0 || secondPart === 0)
            continue;
        // Check if firstPart is kJ and secondPart is kcal
        // kJ / 4.184 should ≈ kcal
        const firstAsKcal = firstPart / 4.184;
        const toleranceKcal1 = secondPart * (tolerancePercent / 100); // 10% of the kcal value
        if (Math.abs(secondPart - firstAsKcal) <= toleranceKcal1) {
            // Smaller value is kcal
            const suggestedKcal = Math.min(firstPart, secondPart);
            // Sanity check: kcal should be reasonable (1-900 per 100g)
            if (suggestedKcal >= 1 && suggestedKcal <= 900) {
                return {
                    isLikelyCombined: true,
                    suggestedKcal: secondPart, // The kcal is the second part (after kJ)
                    pattern: `kJ|kcal concatenated (${firstPart}|${secondPart})`
                };
            }
        }
        // Check if firstPart is kcal and secondPart is kJ
        // kcal * 4.184 should ≈ kJ
        const secondAsKcal = secondPart / 4.184;
        const toleranceKcal2 = firstPart * (tolerancePercent / 100); // 10% of the kcal value
        if (Math.abs(firstPart - secondAsKcal) <= toleranceKcal2) {
            // Smaller value is kcal
            const suggestedKcal = Math.min(firstPart, secondPart);
            // Sanity check: kcal should be reasonable (1-900 per 100g)
            if (suggestedKcal >= 1 && suggestedKcal <= 900) {
                return {
                    isLikelyCombined: true,
                    suggestedKcal: firstPart, // The kcal is the first part (before kJ)
                    pattern: `kcal|kJ concatenated (${firstPart}|${secondPart})`
                };
            }
        }
    }
    return { isLikelyCombined: false, suggestedKcal: 0, pattern: 'no-match' };
}
/**
 * Detect issues in a food record
 */
function detectIssues(food) {
    const issues = [];
    // Get food name and brand
    const name = (food.foodName || food.name || '').toLowerCase();
    const brand = (food.brandName || food.brand || '').toLowerCase();
    const text = `${name} ${brand}`;
    // 1. Missing Nutrition (all zeros indicates missing data)
    const calories = food.calories || 0;
    const protein = food.protein || 0;
    const carbs = food.carbs || food.carbohydrates || 0;
    const fat = food.fat || 0;
    const fiber = food.fiber || 0;
    const sugar = food.sugar || 0;
    const sodium = food.sodium || 0;
    if (calories === 0 && protein === 0 && carbs === 0 && fat === 0) {
        issues.push({ type: 'missing-nutrition', field: 'nutrition' });
    }
    // 1b. Impossible/Highly Unlikely Nutrition (per 100g basis)
    // These are scientifically impossible or highly unlikely values
    const impossibleIssues = [];
    // Calories: Pure fat is ~900 kcal/100g, anything higher is impossible
    // But first check if it might be kJ + kcal combined (common data entry error)
    if (calories > 900) {
        const kjKcalCombinedCheck = detectKjKcalCombined(calories, protein, carbs, fat);
        if (kjKcalCombinedCheck.isLikelyCombined) {
            impossibleIssues.push(`calories: ${calories} appears to be kJ+kcal combined (likely correct kcal: ~${kjKcalCombinedCheck.suggestedKcal})`);
        }
        else {
            impossibleIssues.push(`calories: ${calories} (max possible ~900)`);
        }
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
    // Handle ingredients as array or string (some records have string instead of array)
    let ingredients = [];
    const rawIngredients = food.extractedIngredients || food.ingredients;
    if (Array.isArray(rawIngredients)) {
        ingredients = rawIngredients;
    }
    else if (typeof rawIngredients === 'string' && rawIngredients.length > 0) {
        ingredients = [rawIngredients];
    }
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
        if (word.length < 4)
            continue;
        // Skip if it's a legitimate foreign food term
        if (isLegitForeignTerm(word, text))
            continue;
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
    const originalName = (food.foodName || food.name || '');
    const originalBrand = (food.brandName || food.brand || '');
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
    // 4. HTML Code Detection
    // Check for HTML tags in name, brand, and ingredients
    const htmlTagPattern = /<[^>]+>|&[a-z]+;|&[#]\d+;|&#x[a-f0-9]+;/gi;
    const fieldsToCheckForHtml = [
        { field: 'name', value: originalName },
        { field: 'brand', value: originalBrand },
        { field: 'ingredients', value: ingredients.join(' ') },
    ];
    for (const { field, value } of fieldsToCheckForHtml) {
        if (value && htmlTagPattern.test(value)) {
            const htmlMatches = value.match(htmlTagPattern);
            issues.push({
                type: 'html-code',
                field,
                value: htmlMatches ? htmlMatches.slice(0, 3).join(', ') : 'HTML detected',
                suggestion: 'Remove HTML tags and entities'
            });
        }
    }
    // 5. Missing Barcode
    if (!food.barcode) {
        issues.push({ type: 'missing-barcode' });
    }
    // 6. Missing Ingredients
    if (!ingredients || ingredients.length === 0) {
        issues.push({ type: 'missing-ingredients' });
    }
    return issues;
}
/**
 * Scan entire Algolia index for issues
 * Uses browseObjects to iterate through all records
 */
exports.scanDatabaseIssues = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onRequest(async (req, res) => {
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
        const adminKey = getAlgoliaAdminKey();
        if (!adminKey) {
            res.status(500).json({ success: false, error: 'Algolia admin key not configured' });
            return;
        }
        console.log(`🔍 Starting database scan for index: ${indexName}`);
        // Initialize Algolia client
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
        // Collect all foods with issues
        const foodsWithIssues = [];
        let totalScanned = 0;
        // Browse ALL objects in the index using cursor-based pagination (no 1000 limit)
        // This uses Algolia's browse API which can iterate through the entire index
        let cursor;
        let batchNumber = 0;
        do {
            batchNumber++;
            // Build browse parameters
            const browseParams = {
                attributesToRetrieve: [
                    'objectID', 'foodName', 'name', 'brandName', 'brand', 'barcode',
                    'calories', 'protein', 'carbs', 'carbohydrates', 'fat', 'fiber',
                    'sugar', 'sodium', 'extractedIngredients', 'ingredients',
                    'servingSize', 'category'
                ],
                hitsPerPage: 1000, // Max batch size for browse
            };
            // Add cursor for subsequent requests
            if (cursor) {
                browseParams.cursor = cursor;
            }
            console.log(`📊 Browsing batch ${batchNumber}${cursor ? ' with cursor' : ''}...`);
            const result = await client.browse({
                indexName,
                browseParams,
            });
            const hits = (result.hits || []);
            totalScanned += hits.length;
            console.log(`📊 Scanned batch ${batchNumber}: ${hits.length} records (total: ${totalScanned})`);
            // Check each food for issues
            for (const food of hits) {
                const issues = detectIssues(food);
                // Filter by checkTypes if specified
                let filteredIssues = issues;
                if (checkTypes && Array.isArray(checkTypes) && checkTypes.length > 0) {
                    filteredIssues = issues.filter(issue => {
                        if (checkTypes.includes('misspellings') && issue.type === 'misspelling')
                            return true;
                        if (checkTypes.includes('missing-nutrition') && issue.type === 'missing-nutrition')
                            return true;
                        if (checkTypes.includes('impossible-nutrition') && issue.type === 'impossible-nutrition')
                            return true;
                        if (checkTypes.includes('non-words') && issue.type === 'non-word')
                            return true;
                        if (checkTypes.includes('weird-spacing') && issue.type === 'weird-spacing')
                            return true;
                        if (checkTypes.includes('missing-barcode') && issue.type === 'missing-barcode')
                            return true;
                        if (checkTypes.includes('missing-ingredients') && issue.type === 'missing-ingredients')
                            return true;
                        if (checkTypes.includes('html-code') && issue.type === 'html-code')
                            return true;
                        return false;
                    });
                }
                if (filteredIssues.length > 0) {
                    foodsWithIssues.push({
                        ...food,
                        objectID: food.objectID,
                        issues: filteredIssues,
                    });
                }
            }
            // Get cursor for next batch (undefined when done)
            cursor = result.cursor;
            // Safety check to prevent infinite loops (200k records / 1000 per batch = 200 batches max expected)
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
    }
    catch (error) {
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
exports.batchUpdateFoods = functions
    .runWith({ timeoutSeconds: 300, memory: '512MB' })
    .https.onRequest(async (req, res) => {
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
        const adminKey = getAlgoliaAdminKey();
        if (!adminKey) {
            res.status(500).json({ success: false, error: 'Algolia admin key not configured' });
            return;
        }
        console.log(`📝 Batch update for index: ${indexName}`);
        console.log(`   Updates: ${updates?.length || 0}, Deletes: ${deletes?.length || 0}`);
        // Initialize Algolia client
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
        let updatedCount = 0;
        let deletedCount = 0;
        // Apply updates (partial updates)
        if (updates && Array.isArray(updates) && updates.length > 0) {
            const objects = updates.map((u) => ({
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
    }
    catch (error) {
        console.error('❌ Error in batch update:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to batch update',
            details: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
/**
 * Fix kJ+kcal combined calories in an Algolia index
 * Scans for impossibly high calorie values that are actually kJ and kcal concatenated,
 * then fixes them by extracting the correct kcal value.
 */
exports.fixKjKcalCombinedCalories = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onRequest(async (req, res) => {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { indexName, dryRun = true } = req.body;
        if (!indexName) {
            res.status(400).json({ success: false, error: 'Index name is required' });
            return;
        }
        const adminKey = getAlgoliaAdminKey();
        if (!adminKey) {
            res.status(500).json({ success: false, error: 'Algolia admin key not configured' });
            return;
        }
        console.log(`🔧 ${dryRun ? '[DRY RUN] ' : ''}Fixing kJ+kcal combined calories in index: ${indexName}`);
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
        // Find all records with impossibly high calories (> 900)
        const itemsToFix = [];
        let totalScanned = 0;
        let cursor;
        let batchNumber = 0;
        do {
            batchNumber++;
            const browseParams = {
                filters: 'calories > 900',
                attributesToRetrieve: ['objectID', 'calories', 'protein', 'carbs', 'carbohydrates', 'fat', 'foodName', 'name'],
                hitsPerPage: 1000,
            };
            if (cursor) {
                browseParams.cursor = cursor;
            }
            const result = await client.browse({ indexName, browseParams });
            const hits = (result.hits || []);
            totalScanned += hits.length;
            console.log(`📊 Scanned batch ${batchNumber}: ${hits.length} records with calories > 900`);
            for (const food of hits) {
                const calories = food.calories || 0;
                const protein = food.protein || 0;
                const carbs = food.carbs || food.carbohydrates || 0;
                const fat = food.fat || 0;
                const detection = detectKjKcalCombined(calories, protein, carbs, fat);
                if (detection.isLikelyCombined && detection.suggestedKcal > 0) {
                    itemsToFix.push({
                        objectID: food.objectID,
                        oldCalories: calories,
                        newCalories: detection.suggestedKcal,
                        pattern: detection.pattern,
                    });
                }
            }
            cursor = result.cursor;
            if (batchNumber > 100) {
                console.log('⚠️ Reached batch limit, stopping scan');
                break;
            }
        } while (cursor);
        console.log(`📊 Found ${itemsToFix.length} items to fix out of ${totalScanned} with high calories`);
        // Apply fixes if not dry run
        let fixedCount = 0;
        if (!dryRun && itemsToFix.length > 0) {
            const updates = itemsToFix.map(item => ({
                objectID: item.objectID,
                calories: item.newCalories,
            }));
            // Process in batches of 1000
            const batchSize = 1000;
            for (let i = 0; i < updates.length; i += batchSize) {
                const batch = updates.slice(i, i + batchSize);
                await client.partialUpdateObjects({
                    indexName,
                    objects: batch,
                    createIfNotExists: false,
                });
                fixedCount += batch.length;
                console.log(`✅ Fixed batch: ${batch.length} records (total: ${fixedCount})`);
            }
        }
        res.json({
            success: true,
            dryRun,
            totalScanned,
            itemsFound: itemsToFix.length,
            itemsFixed: fixedCount,
            items: itemsToFix.slice(0, 100), // Return first 100 for preview
            message: dryRun
                ? `Found ${itemsToFix.length} items to fix. Run with dryRun=false to apply fixes.`
                : `Fixed ${fixedCount} items.`,
        });
    }
    catch (error) {
        console.error('❌ Error fixing calories:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fix calories',
            details: error instanceof Error ? error.message : 'Unknown error',
        });
    }
});
/**
 * Simple/single ingredient foods mapping
 * Maps food name patterns to their obvious ingredients
 */
const SIMPLE_INGREDIENT_FOODS = [
    // Oils
    {
        patterns: [/\bolive\s*oil\b/i, /\bextra\s*virgin\s*olive\b/i],
        ingredients: ['Olive Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bvegetable\s*oil\b/i],
        ingredients: ['Vegetable Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bsunflower\s*oil\b/i],
        ingredients: ['Sunflower Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bcoconut\s*oil\b/i],
        ingredients: ['Coconut Oil'],
        category: 'oils'
    },
    {
        patterns: [/\brapeseed\s*oil\b/i, /\bcanola\s*oil\b/i],
        ingredients: ['Rapeseed Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bsesame\s*oil\b/i],
        ingredients: ['Sesame Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bavocado\s*oil\b/i],
        ingredients: ['Avocado Oil'],
        category: 'oils'
    },
    {
        patterns: [/\bgroundnut\s*oil\b/i, /\bpeanut\s*oil\b/i],
        ingredients: ['Groundnut Oil (Peanut)'],
        category: 'oils'
    },
    // Vinegars
    {
        patterns: [/\bbalsamic\s*vinegar\b/i],
        ingredients: ['Balsamic Vinegar (Grape Must, Wine Vinegar)'],
        category: 'vinegars'
    },
    {
        patterns: [/\bwhite\s*wine\s*vinegar\b/i],
        ingredients: ['White Wine Vinegar'],
        category: 'vinegars'
    },
    {
        patterns: [/\bred\s*wine\s*vinegar\b/i],
        ingredients: ['Red Wine Vinegar'],
        category: 'vinegars'
    },
    {
        patterns: [/\bapple\s*cider\s*vinegar\b/i],
        ingredients: ['Apple Cider Vinegar'],
        category: 'vinegars'
    },
    {
        patterns: [/\bmalt\s*vinegar\b/i],
        ingredients: ['Malt Vinegar (Barley)'],
        category: 'vinegars'
    },
    // Sweeteners
    {
        patterns: [/\bhoney\b/i],
        ingredients: ['Honey'],
        category: 'sweeteners'
    },
    {
        patterns: [/\bmaple\s*syrup\b/i],
        ingredients: ['Maple Syrup'],
        category: 'sweeteners'
    },
    {
        patterns: [/\bgolden\s*syrup\b/i],
        ingredients: ['Golden Syrup (Sugar, Water)'],
        category: 'sweeteners'
    },
    {
        patterns: [/\bagave\s*(syrup|nectar)\b/i],
        ingredients: ['Agave Syrup'],
        category: 'sweeteners'
    },
    {
        patterns: [/\bmolasses\b/i, /\btreacle\b/i],
        ingredients: ['Molasses'],
        category: 'sweeteners'
    },
    // Butters & Spreads
    {
        patterns: [/\bpeanut\s*butter\b/i],
        ingredients: ['Peanuts'],
        category: 'spreads'
    },
    {
        patterns: [/\balmond\s*butter\b/i],
        ingredients: ['Almonds'],
        category: 'spreads'
    },
    {
        patterns: [/\bcashew\s*butter\b/i],
        ingredients: ['Cashew Nuts'],
        category: 'spreads'
    },
    {
        patterns: [/\btahini\b/i, /\bsesame\s*(seed\s*)?paste\b/i],
        ingredients: ['Sesame Seeds'],
        category: 'spreads'
    },
    // Dairy basics
    {
        patterns: [/\bwhole\s*milk\b/i, /\bfull\s*fat\s*milk\b/i],
        ingredients: ['Whole Milk'],
        category: 'dairy'
    },
    {
        patterns: [/\bsemi[\s-]?skimmed\s*milk\b/i],
        ingredients: ['Semi-Skimmed Milk'],
        category: 'dairy'
    },
    {
        patterns: [/\bskimmed\s*milk\b/i],
        ingredients: ['Skimmed Milk'],
        category: 'dairy'
    },
    {
        patterns: [/\bdouble\s*cream\b/i],
        ingredients: ['Double Cream'],
        category: 'dairy'
    },
    {
        patterns: [/\bsingle\s*cream\b/i],
        ingredients: ['Single Cream'],
        category: 'dairy'
    },
    {
        patterns: [/\bwhipping\s*cream\b/i],
        ingredients: ['Whipping Cream'],
        category: 'dairy'
    },
    {
        patterns: [/\bclotted\s*cream\b/i],
        ingredients: ['Clotted Cream'],
        category: 'dairy'
    },
    {
        patterns: [/\bsoured?\s*cream\b/i],
        ingredients: ['Soured Cream'],
        category: 'dairy'
    },
    {
        patterns: [/\bcreme\s*fraiche\b/i],
        ingredients: ['Crème Fraîche'],
        category: 'dairy'
    },
    {
        patterns: [/\bbutter\b/i],
        ingredients: ['Butter (Milk)'],
        category: 'dairy'
    },
    // Eggs
    {
        patterns: [/\b(free\s*range\s*)?eggs?\b/i, /\blarge\s*eggs?\b/i, /\bmedium\s*eggs?\b/i],
        ingredients: ['Eggs'],
        category: 'eggs'
    },
    // Plain flours & grains
    {
        patterns: [/\bplain\s*flour\b/i, /\ball[\s-]?purpose\s*flour\b/i],
        ingredients: ['Wheat Flour'],
        category: 'grains'
    },
    {
        patterns: [/\bself[\s-]?raising\s*flour\b/i],
        ingredients: ['Wheat Flour, Raising Agents'],
        category: 'grains'
    },
    {
        patterns: [/\bstrong\s*(bread\s*)?flour\b/i],
        ingredients: ['Strong Wheat Flour'],
        category: 'grains'
    },
    {
        patterns: [/\bwholemeal\s*flour\b/i],
        ingredients: ['Wholemeal Wheat Flour'],
        category: 'grains'
    },
    {
        patterns: [/\brice\b/i, /\bbasmati\b/i, /\bjasmine\s*rice\b/i, /\blong\s*grain\s*rice\b/i],
        ingredients: ['Rice'],
        category: 'grains'
    },
    {
        patterns: [/\bporridge\s*oats\b/i, /\brolled\s*oats\b/i, /\boats\b/i],
        ingredients: ['Oats'],
        category: 'grains'
    },
    {
        patterns: [/\bquinoa\b/i],
        ingredients: ['Quinoa'],
        category: 'grains'
    },
    {
        patterns: [/\bcouscous\b/i],
        ingredients: ['Couscous (Wheat)'],
        category: 'grains'
    },
    // Sugars
    {
        patterns: [/\bcaster\s*sugar\b/i],
        ingredients: ['Caster Sugar'],
        category: 'sugars'
    },
    {
        patterns: [/\bgranulated\s*sugar\b/i],
        ingredients: ['Granulated Sugar'],
        category: 'sugars'
    },
    {
        patterns: [/\bicing\s*sugar\b/i, /\bpowdered\s*sugar\b/i],
        ingredients: ['Icing Sugar'],
        category: 'sugars'
    },
    {
        patterns: [/\b(light\s*)?brown\s*sugar\b/i, /\bdemerara\s*sugar\b/i],
        ingredients: ['Brown Sugar'],
        category: 'sugars'
    },
    {
        patterns: [/\bmuscovado\s*sugar\b/i],
        ingredients: ['Muscovado Sugar'],
        category: 'sugars'
    },
    // Nuts (plain)
    {
        patterns: [/\balmonds?\b/i, /\bwhole\s*almonds?\b/i, /\bflaked\s*almonds?\b/i],
        ingredients: ['Almonds'],
        category: 'nuts'
    },
    {
        patterns: [/\bwalnuts?\b/i],
        ingredients: ['Walnuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bcashews?\b/i, /\bcashew\s*nuts?\b/i],
        ingredients: ['Cashew Nuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bpistachios?\b/i],
        ingredients: ['Pistachios'],
        category: 'nuts'
    },
    {
        patterns: [/\bhazelnuts?\b/i],
        ingredients: ['Hazelnuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bpecans?\b/i],
        ingredients: ['Pecans'],
        category: 'nuts'
    },
    {
        patterns: [/\bmacadamia\b/i],
        ingredients: ['Macadamia Nuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bbrazil\s*nuts?\b/i],
        ingredients: ['Brazil Nuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bpeanuts?\b/i, /\bmonkey\s*nuts?\b/i],
        ingredients: ['Peanuts'],
        category: 'nuts'
    },
    {
        patterns: [/\bmixed\s*nuts\b/i],
        ingredients: ['Mixed Nuts (may contain various tree nuts and peanuts)'],
        category: 'nuts'
    },
    // Seeds
    {
        patterns: [/\bchia\s*seeds?\b/i],
        ingredients: ['Chia Seeds'],
        category: 'seeds'
    },
    {
        patterns: [/\bflax\s*seeds?\b/i, /\blinseed\b/i],
        ingredients: ['Flaxseeds'],
        category: 'seeds'
    },
    {
        patterns: [/\bsunflower\s*seeds?\b/i],
        ingredients: ['Sunflower Seeds'],
        category: 'seeds'
    },
    {
        patterns: [/\bpumpkin\s*seeds?\b/i],
        ingredients: ['Pumpkin Seeds'],
        category: 'seeds'
    },
    {
        patterns: [/\bsesame\s*seeds?\b/i],
        ingredients: ['Sesame Seeds'],
        category: 'seeds'
    },
    {
        patterns: [/\bpoppy\s*seeds?\b/i],
        ingredients: ['Poppy Seeds'],
        category: 'seeds'
    },
    // Dried fruits
    {
        patterns: [/\braisins?\b/i],
        ingredients: ['Raisins (Dried Grapes)'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bsultanas?\b/i],
        ingredients: ['Sultanas (Dried Grapes)'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bcurrants?\b/i],
        ingredients: ['Currants (Dried Grapes)'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bdried?\s*apricots?\b/i],
        ingredients: ['Dried Apricots'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bdates?\b/i, /\bmedjool\s*dates?\b/i],
        ingredients: ['Dates'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bdried?\s*figs?\b/i],
        ingredients: ['Dried Figs'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bprunes?\b/i],
        ingredients: ['Prunes (Dried Plums)'],
        category: 'dried_fruit'
    },
    {
        patterns: [/\bdried?\s*cranberries?\b/i],
        ingredients: ['Dried Cranberries'],
        category: 'dried_fruit'
    },
    // Salt & basic seasonings
    {
        patterns: [/\bsea\s*salt\b/i, /\btable\s*salt\b/i, /\brock\s*salt\b/i],
        ingredients: ['Salt'],
        category: 'seasonings'
    },
    {
        patterns: [/\bblack\s*pepper\b/i, /\bpeppercorns?\b/i],
        ingredients: ['Black Pepper'],
        category: 'seasonings'
    },
    // Fresh produce (single items)
    {
        patterns: [/\bbananas?\b/i],
        ingredients: ['Banana'],
        category: 'fruit'
    },
    {
        patterns: [/\bapples?\b/i],
        ingredients: ['Apple'],
        category: 'fruit'
    },
    {
        patterns: [/\boranges?\b/i],
        ingredients: ['Orange'],
        category: 'fruit'
    },
    {
        patterns: [/\blemons?\b/i],
        ingredients: ['Lemon'],
        category: 'fruit'
    },
    {
        patterns: [/\blimes?\b/i],
        ingredients: ['Lime'],
        category: 'fruit'
    },
    {
        patterns: [/\bavocados?\b/i],
        ingredients: ['Avocado'],
        category: 'fruit'
    },
    {
        patterns: [/\btomato(es)?\b/i],
        ingredients: ['Tomatoes'],
        category: 'vegetables'
    },
    {
        patterns: [/\bonions?\b/i],
        ingredients: ['Onion'],
        category: 'vegetables'
    },
    {
        patterns: [/\bgarlic\b/i],
        ingredients: ['Garlic'],
        category: 'vegetables'
    },
    {
        patterns: [/\bpotato(es)?\b/i],
        ingredients: ['Potatoes'],
        category: 'vegetables'
    },
    {
        patterns: [/\bcarrots?\b/i],
        ingredients: ['Carrots'],
        category: 'vegetables'
    },
    {
        patterns: [/\bcucumber\b/i],
        ingredients: ['Cucumber'],
        category: 'vegetables'
    },
    {
        patterns: [/\bbroccoli\b/i],
        ingredients: ['Broccoli'],
        category: 'vegetables'
    },
    {
        patterns: [/\bspinach\b/i],
        ingredients: ['Spinach'],
        category: 'vegetables'
    },
    {
        patterns: [/\bkale\b/i],
        ingredients: ['Kale'],
        category: 'vegetables'
    },
    {
        patterns: [/\bmushrooms?\b/i],
        ingredients: ['Mushrooms'],
        category: 'vegetables'
    },
    {
        patterns: [/\bpeppers?\b/i, /\bbell\s*peppers?\b/i],
        ingredients: ['Peppers'],
        category: 'vegetables'
    },
    {
        patterns: [/\bcourgettes?\b/i, /\bzucchini\b/i],
        ingredients: ['Courgette'],
        category: 'vegetables'
    },
    {
        patterns: [/\baubergine\b/i, /\beggplant\b/i],
        ingredients: ['Aubergine'],
        category: 'vegetables'
    },
    // Canned basics
    {
        patterns: [/\bchopped\s*tomato(es)?\b/i, /\btinned\s*tomato(es)?\b/i, /\bcanned\s*tomato(es)?\b/i],
        ingredients: ['Tomatoes'],
        category: 'canned'
    },
    {
        patterns: [/\btomato\s*passata\b/i, /\bpassata\b/i],
        ingredients: ['Tomatoes'],
        category: 'canned'
    },
    {
        patterns: [/\btomato\s*puree\b/i, /\btomato\s*paste\b/i],
        ingredients: ['Tomatoes'],
        category: 'canned'
    },
    {
        patterns: [/\bcoconut\s*milk\b/i, /\bcoconut\s*cream\b/i],
        ingredients: ['Coconut Extract, Water'],
        category: 'canned'
    },
    {
        patterns: [/\bchickpeas?\b/i, /\bgarbanzo\b/i],
        ingredients: ['Chickpeas'],
        category: 'canned'
    },
    {
        patterns: [/\blentils?\b/i],
        ingredients: ['Lentils'],
        category: 'canned'
    },
    {
        patterns: [/\bkidney\s*beans?\b/i],
        ingredients: ['Kidney Beans'],
        category: 'canned'
    },
    {
        patterns: [/\bbaked\s*beans?\b/i],
        ingredients: ['Beans, Tomato Sauce, Sugar, Salt'],
        category: 'canned'
    },
    {
        patterns: [/\bbutter\s*beans?\b/i, /\blima\s*beans?\b/i],
        ingredients: ['Butter Beans'],
        category: 'canned'
    },
    {
        patterns: [/\bcannellini\s*beans?\b/i],
        ingredients: ['Cannellini Beans'],
        category: 'canned'
    },
    {
        patterns: [/\bblack\s*beans?\b/i],
        ingredients: ['Black Beans'],
        category: 'canned'
    },
    // Sauces basics
    {
        patterns: [/\bsoy\s*sauce\b/i, /\bsoya\s*sauce\b/i],
        ingredients: ['Water, Soya Beans, Wheat, Salt'],
        category: 'sauces'
    },
    {
        patterns: [/\bworcestershire\s*sauce\b/i],
        ingredients: ['Vinegar, Molasses, Sugar, Salt, Anchovies, Tamarind, Onion, Garlic, Spices'],
        category: 'sauces'
    },
    {
        patterns: [/\btabasco\b/i, /\bhot\s*sauce\b/i],
        ingredients: ['Peppers, Vinegar, Salt'],
        category: 'sauces'
    },
    // Water & basic drinks
    {
        patterns: [/\bwater\b/i, /\bmineral\s*water\b/i, /\bspring\s*water\b/i, /\bsparkling\s*water\b/i],
        ingredients: ['Water'],
        category: 'drinks'
    },
    {
        patterns: [/\bblack\s*coffee\b/i, /\binstant\s*coffee\b/i, /\bground\s*coffee\b/i],
        ingredients: ['Coffee'],
        category: 'drinks'
    },
    {
        patterns: [/\bgreen\s*tea\b/i, /\bblack\s*tea\b/i, /\btea\s*bags?\b/i],
        ingredients: ['Tea'],
        category: 'drinks'
    },
];
/**
 * Detect if a food name matches a simple ingredient pattern
 */
function detectSimpleIngredient(foodName) {
    const name = foodName.toLowerCase().trim();
    for (const entry of SIMPLE_INGREDIENT_FOODS) {
        for (const pattern of entry.patterns) {
            if (pattern.test(name)) {
                return {
                    match: true,
                    ingredients: entry.ingredients,
                    category: entry.category
                };
            }
        }
    }
    return null;
}
/**
 * Fix missing ingredients for simple/single ingredient foods
 * When objectIDs are provided, only fixes those specific items (fast mode from scan results)
 * When objectIDs are not provided, scans the entire index (slow mode)
 */
exports.fixSimpleIngredients = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (data, context) => {
    try {
        const { indexName, dryRun = false, objectIDs } = data || {};
        if (!indexName) {
            throw new functions.https.HttpsError('invalid-argument', 'Index name is required');
        }
        const adminKey = getAlgoliaAdminKey();
        if (!adminKey) {
            throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
        }
        const useQuickMode = objectIDs && Array.isArray(objectIDs) && objectIDs.length > 0;
        console.log(`🥗 ${dryRun ? '[DRY RUN] ' : ''}${useQuickMode ? '[QUICK MODE] ' : ''}Fixing simple ingredients in index: ${indexName}`);
        if (useQuickMode) {
            console.log(`   Processing ${objectIDs.length} specific items from scan results`);
        }
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
        // Find all records with missing ingredients
        const itemsToFix = [];
        let totalScanned = 0;
        let totalMissingIngredients = 0;
        if (useQuickMode) {
            // QUICK MODE: Fetch only the specific objectIDs provided
            console.log(`📊 Quick mode: Fetching ${objectIDs.length} specific objects`);
            // Fetch objects in batches of 1000
            const batchSize = 1000;
            for (let i = 0; i < objectIDs.length; i += batchSize) {
                const batchIds = objectIDs.slice(i, i + batchSize);
                const objects = await client.getObjects({
                    requests: batchIds.map((id) => ({
                        indexName,
                        objectID: id,
                        attributesToRetrieve: ['objectID', 'foodName', 'name', 'ingredients', 'extractedIngredients'],
                    })),
                });
                for (const food of objects.results) {
                    if (!food)
                        continue;
                    totalScanned++;
                    const ingredients = food.ingredients || food.extractedIngredients || [];
                    // Only process items with missing ingredients
                    if (ingredients.length > 0)
                        continue;
                    totalMissingIngredients++;
                    const foodName = food.foodName || food.name || '';
                    if (!foodName)
                        continue;
                    const detection = detectSimpleIngredient(foodName);
                    if (detection && detection.match) {
                        itemsToFix.push({
                            objectID: food.objectID,
                            foodName,
                            ingredients: detection.ingredients,
                            category: detection.category,
                        });
                    }
                }
            }
            console.log(`📊 Quick mode: Processed ${totalScanned} objects, found ${itemsToFix.length} simple ingredient items`);
        }
        else {
            // FULL SCAN MODE: Browse entire index
            let cursor;
            let batchNumber = 0;
            do {
                batchNumber++;
                const browseParams = {
                    attributesToRetrieve: ['objectID', 'foodName', 'name', 'ingredients', 'extractedIngredients'],
                    hitsPerPage: 1000,
                };
                if (cursor) {
                    browseParams.cursor = cursor;
                }
                const result = await client.browse({ indexName, browseParams });
                const hits = (result.hits || []);
                totalScanned += hits.length;
                console.log(`📊 Scanned batch ${batchNumber}: ${hits.length} records`);
                for (const food of hits) {
                    const ingredients = food.ingredients || food.extractedIngredients || [];
                    // Only process items with missing ingredients
                    if (ingredients.length > 0)
                        continue;
                    totalMissingIngredients++;
                    const foodName = food.foodName || food.name || '';
                    if (!foodName)
                        continue;
                    const detection = detectSimpleIngredient(foodName);
                    if (detection && detection.match) {
                        itemsToFix.push({
                            objectID: food.objectID,
                            foodName,
                            ingredients: detection.ingredients,
                            category: detection.category,
                        });
                    }
                }
                cursor = result.cursor;
                if (batchNumber > 100) {
                    console.log('⚠️ Reached batch limit, stopping scan');
                    break;
                }
            } while (cursor);
        }
        console.log(`📊 Found ${itemsToFix.length} simple ingredient items to fix out of ${totalMissingIngredients} with missing ingredients`);
        // Apply fixes if not dry run
        let fixedCount = 0;
        if (!dryRun && itemsToFix.length > 0) {
            const updates = itemsToFix.map(item => ({
                objectID: item.objectID,
                ingredients: item.ingredients,
                extractedIngredients: item.ingredients,
            }));
            // Process in batches of 1000
            const batchSize = 1000;
            for (let i = 0; i < updates.length; i += batchSize) {
                const batch = updates.slice(i, i + batchSize);
                await client.partialUpdateObjects({
                    indexName,
                    objects: batch,
                    createIfNotExists: false,
                });
                fixedCount += batch.length;
                console.log(`✅ Fixed batch: ${batch.length} records (total: ${fixedCount})`);
            }
        }
        // Group items by category for the response
        const byCategory = {};
        for (const item of itemsToFix) {
            byCategory[item.category] = (byCategory[item.category] || 0) + 1;
        }
        return {
            success: true,
            dryRun,
            itemsScanned: totalScanned,
            itemsDetected: itemsToFix.length,
            itemsFixed: fixedCount,
            byCategory,
            items: itemsToFix.slice(0, 100), // Return first 100 for preview
            message: dryRun
                ? `Found ${itemsToFix.length} simple ingredient items to fix. Run with dryRun=false to apply fixes.`
                : `Fixed ${fixedCount} items with simple ingredients.`,
        };
    }
    catch (error) {
        console.error('❌ Error fixing simple ingredients:', error);
        throw new functions.https.HttpsError('internal', 'Failed to fix simple ingredients', error instanceof Error ? error.message : 'Unknown error');
    }
});
/**
 * Helper function to strip HTML tags and decode HTML entities
 */
function stripHtml(text) {
    if (!text)
        return text;
    // Remove HTML tags
    let cleaned = text.replace(/<[^>]+>/g, '');
    // Decode common HTML entities
    const htmlEntities = {
        '&nbsp;': ' ',
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&quot;': '"',
        '&apos;': "'",
        '&#39;': "'",
        '&ndash;': '–',
        '&mdash;': '—',
        '&copy;': '©',
        '&reg;': '®',
        '&trade;': '™',
        '&euro;': '€',
        '&pound;': '£',
        '&yen;': '¥',
        '&cent;': '¢',
        '&deg;': '°',
        '&plusmn;': '±',
        '&times;': '×',
        '&divide;': '÷',
        '&frac12;': '½',
        '&frac14;': '¼',
        '&frac34;': '¾',
    };
    for (const [entity, char] of Object.entries(htmlEntities)) {
        cleaned = cleaned.replace(new RegExp(entity, 'gi'), char);
    }
    // Decode numeric HTML entities (&#123; or &#x7B;)
    cleaned = cleaned.replace(/&#(\d+);/g, (_, num) => String.fromCharCode(parseInt(num, 10)));
    cleaned = cleaned.replace(/&#x([a-fA-F0-9]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
    // Clean up multiple spaces left behind
    cleaned = cleaned.replace(/\s+/g, ' ').trim();
    return cleaned;
}
/**
 * Detect if a string contains HTML
 */
function containsHtml(text) {
    if (!text)
        return false;
    const htmlPattern = /<[^>]+>|&[a-z]+;|&#\d+;|&#x[a-f0-9]+;/gi;
    return htmlPattern.test(text);
}
/**
 * Fix HTML code in food records
 * When objectIDs are provided, only fixes those specific items (fast mode from scan results)
 * When objectIDs are not provided, scans the entire index for HTML issues (slow mode)
 */
exports.fixHtmlCode = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (data, context) => {
    try {
        const { indexName, dryRun = false, objectIDs } = data || {};
        if (!indexName) {
            throw new functions.https.HttpsError('invalid-argument', 'Index name is required');
        }
        const adminKey = getAlgoliaAdminKey();
        if (!adminKey) {
            throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
        }
        const useQuickMode = objectIDs && Array.isArray(objectIDs) && objectIDs.length > 0;
        console.log(`🧹 ${dryRun ? '[DRY RUN] ' : ''}${useQuickMode ? '[QUICK MODE] ' : ''}Fixing HTML code in index: ${indexName}`);
        if (useQuickMode) {
            console.log(`   Processing ${objectIDs.length} specific items from scan results`);
        }
        const client = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, adminKey);
        // Find all records with HTML in text fields
        const itemsToFix = [];
        let totalScanned = 0;
        if (useQuickMode) {
            // QUICK MODE: Fetch only the specific objectIDs provided
            console.log(`📊 Quick mode: Fetching ${objectIDs.length} specific objects`);
            // Fetch objects in batches of 1000
            const batchSize = 1000;
            for (let i = 0; i < objectIDs.length; i += batchSize) {
                const batchIds = objectIDs.slice(i, i + batchSize);
                const objects = await client.getObjects({
                    requests: batchIds.map((id) => ({
                        indexName,
                        objectID: id,
                        attributesToRetrieve: ['objectID', 'foodName', 'name', 'brandName', 'brand', 'ingredients', 'extractedIngredients'],
                    })),
                });
                for (const food of objects.results) {
                    if (!food)
                        continue;
                    totalScanned++;
                    const foodName = food.foodName || food.name || '';
                    const brandName = food.brandName || food.brand || '';
                    const ingredients = food.ingredients || food.extractedIngredients || [];
                    const ingredientText = ingredients.join(' ');
                    const hasHtmlInName = containsHtml(foodName);
                    const hasHtmlInBrand = containsHtml(brandName);
                    const hasHtmlInIngredients = containsHtml(ingredientText);
                    if (hasHtmlInName || hasHtmlInBrand || hasHtmlInIngredients) {
                        const htmlFound = [];
                        if (hasHtmlInName)
                            htmlFound.push('name');
                        if (hasHtmlInBrand)
                            htmlFound.push('brand');
                        if (hasHtmlInIngredients)
                            htmlFound.push('ingredients');
                        const item = {
                            objectID: food.objectID,
                            foodName,
                            htmlFound,
                        };
                        if (hasHtmlInName) {
                            item.cleanedName = stripHtml(foodName);
                        }
                        if (hasHtmlInBrand) {
                            item.cleanedBrand = stripHtml(brandName);
                        }
                        if (hasHtmlInIngredients) {
                            item.cleanedIngredients = ingredients.map(ing => stripHtml(ing));
                        }
                        itemsToFix.push(item);
                    }
                }
            }
            console.log(`📊 Quick mode: Processed ${totalScanned} objects, found ${itemsToFix.length} with HTML`);
        }
        else {
            // FULL SCAN MODE: Browse entire index
            let cursor;
            let batchNumber = 0;
            do {
                batchNumber++;
                const browseParams = {
                    attributesToRetrieve: ['objectID', 'foodName', 'name', 'brandName', 'brand', 'ingredients', 'extractedIngredients'],
                    hitsPerPage: 1000,
                };
                if (cursor) {
                    browseParams.cursor = cursor;
                }
                const result = await client.browse({ indexName, browseParams });
                const hits = (result.hits || []);
                totalScanned += hits.length;
                console.log(`📊 Scanned batch ${batchNumber}: ${hits.length} records`);
                for (const food of hits) {
                    const foodName = food.foodName || food.name || '';
                    const brandName = food.brandName || food.brand || '';
                    const ingredients = food.ingredients || food.extractedIngredients || [];
                    const ingredientText = ingredients.join(' ');
                    const hasHtmlInName = containsHtml(foodName);
                    const hasHtmlInBrand = containsHtml(brandName);
                    const hasHtmlInIngredients = containsHtml(ingredientText);
                    if (hasHtmlInName || hasHtmlInBrand || hasHtmlInIngredients) {
                        const htmlFound = [];
                        if (hasHtmlInName)
                            htmlFound.push('name');
                        if (hasHtmlInBrand)
                            htmlFound.push('brand');
                        if (hasHtmlInIngredients)
                            htmlFound.push('ingredients');
                        const item = {
                            objectID: food.objectID,
                            foodName,
                            htmlFound,
                        };
                        if (hasHtmlInName) {
                            item.cleanedName = stripHtml(foodName);
                        }
                        if (hasHtmlInBrand) {
                            item.cleanedBrand = stripHtml(brandName);
                        }
                        if (hasHtmlInIngredients) {
                            item.cleanedIngredients = ingredients.map(ing => stripHtml(ing));
                        }
                        itemsToFix.push(item);
                    }
                }
                cursor = result.cursor;
                if (batchNumber > 100) {
                    console.log('⚠️ Reached batch limit, stopping scan');
                    break;
                }
            } while (cursor);
        }
        console.log(`📊 Found ${itemsToFix.length} items with HTML code out of ${totalScanned} scanned`);
        // Apply fixes if not dry run
        let fixedCount = 0;
        if (!dryRun && itemsToFix.length > 0) {
            const updates = itemsToFix.map(item => {
                const update = { objectID: item.objectID };
                if (item.cleanedName) {
                    update.foodName = item.cleanedName;
                    update.name = item.cleanedName;
                }
                if (item.cleanedBrand) {
                    update.brandName = item.cleanedBrand;
                    update.brand = item.cleanedBrand;
                }
                if (item.cleanedIngredients) {
                    update.ingredients = item.cleanedIngredients;
                    update.extractedIngredients = item.cleanedIngredients;
                }
                return update;
            });
            // Process in batches of 1000
            const batchSize = 1000;
            for (let i = 0; i < updates.length; i += batchSize) {
                const batch = updates.slice(i, i + batchSize);
                await client.partialUpdateObjects({
                    indexName,
                    objects: batch,
                    createIfNotExists: false,
                });
                fixedCount += batch.length;
                console.log(`✅ Fixed batch: ${batch.length} records (total: ${fixedCount})`);
            }
        }
        // Group by field for response
        const byField = { name: 0, brand: 0, ingredients: 0 };
        for (const item of itemsToFix) {
            for (const field of item.htmlFound) {
                byField[field] = (byField[field] || 0) + 1;
            }
        }
        return {
            success: true,
            dryRun,
            itemsScanned: totalScanned,
            itemsDetected: itemsToFix.length,
            itemsFixed: fixedCount,
            byField,
            items: itemsToFix.slice(0, 100), // Return first 100 for preview
            message: dryRun
                ? `Found ${itemsToFix.length} items with HTML code. Run with dryRun=false to apply fixes.`
                : `Fixed ${fixedCount} items by removing HTML code.`,
        };
    }
    catch (error) {
        console.error('❌ Error fixing HTML code:', error);
        throw new functions.https.HttpsError('internal', 'Failed to fix HTML code', error instanceof Error ? error.message : 'Unknown error');
    }
});
//# sourceMappingURL=scan-database.js.map