"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const additive_analyzer_enhanced_1 = require("./additive-analyzer-enhanced");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Fixed searchFoods function that properly maps ingredients field
exports.searchFoods = functions
    .runWith({
    timeoutSeconds: 30, // 30 second timeout - fast indexed search
    memory: '512MB' // Reduced memory for faster cold starts
})
    .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        // Load additive database for analysis
        (0, additive_analyzer_enhanced_1.loadAdditiveDatabase)();
        // Support both GET (?q=search) and POST ({"query": "search"}) for iOS app compatibility
        const query = req.query.q || (req.body && req.body.query) || '';
        if (!query || query.trim().length < 2) {
            res.status(400).json({ error: 'Query must be at least 2 characters' });
            return;
        }
        console.log(`Searching for: "${query}"`);
        // Split query into words for multi-strategy search
        const queryWords = query.toLowerCase().split(/\s+/).filter((word) => word.length > 0);
        const firstWord = queryWords[0];
        // FAST SEARCH: Use targeted queries instead of fetching everything
        let allDocs = new Map();
        // Helper function for fast targeted search
        async function fastSearch(collectionName, searchTerm) {
            const searches = [];
            // Strategy 1: Capitalize first letter (e.g., "Charlie")
            const capitalized = searchTerm.charAt(0).toUpperCase() + searchTerm.slice(1);
            // Strategy 2: All lowercase (e.g., "charlie")
            const lowercase = searchTerm.toLowerCase();
            // Strategy 3: All uppercase (e.g., "CHARLIE")
            const uppercase = searchTerm.toUpperCase();
            // Run searches in parallel for speed
            for (const term of [capitalized, lowercase, uppercase]) {
                // Search foodName
                searches.push(admin.firestore()
                    .collection(collectionName)
                    .where('foodName', '>=', term)
                    .where('foodName', '<=', term + '\uf8ff')
                    .limit(100)
                    .get());
                // Search brandName
                searches.push(admin.firestore()
                    .collection(collectionName)
                    .where('brandName', '>=', term)
                    .where('brandName', '<=', term + '\uf8ff')
                    .limit(100)
                    .get());
            }
            const results = await Promise.allSettled(searches);
            let count = 0;
            results.forEach((result) => {
                if (result.status === 'fulfilled') {
                    result.value.docs.forEach((doc) => {
                        if (!allDocs.has(doc.id)) {
                            allDocs.set(doc.id, doc);
                            count++;
                        }
                    });
                }
            });
            return count;
        }
        // Search both collections in parallel (much faster!)
        const startTime = Date.now();
        const [verifiedCount, foodsCount] = await Promise.all([
            fastSearch('verifiedFoods', firstWord),
            fastSearch('foods', firstWord)
        ]);
        const searchTime = Date.now() - startTime;
        console.log(`⚡ Fast search completed in ${searchTime}ms - found ${allDocs.size} candidates (${verifiedCount} verified, ${foodsCount} foods)`);
        const verifiedSnapshot = { docs: Array.from(allDocs.values()) };
        // Convert to results and add relevance scoring
        let allResults = verifiedSnapshot.docs.map(doc => {
            const data = doc.data();
            if (!data)
                return null; // Skip if no data
            const nutrition = data.nutritionData || data.nutrition || {};
            const foodName = data.foodName || '';
            const brandName = data.brandName || '';
            // Calculate relevance score for ranking
            const relevanceScore = calculateRelevance(foodName, brandName, query, queryWords);
            // Analyze ingredients for additives and processing score
            let additiveAnalysis = null;
            let processingInfo = null;
            const ingredientsData = data.extractedIngredients || data.ingredients || null;
            const ingredientsString = Array.isArray(ingredientsData) ? ingredientsData.join(', ') : ingredientsData;
            if (ingredientsString && typeof ingredientsString === 'string') {
                try {
                    const analysisResult = (0, additive_analyzer_enhanced_1.analyzeIngredientsForAdditives)(ingredientsString);
                    const processingScore = (0, additive_analyzer_enhanced_1.calculateProcessingScore)(analysisResult.detectedAdditives, ingredientsString);
                    const grade = (0, additive_analyzer_enhanced_1.determineGrade)(processingScore.totalScore, analysisResult.hasRedFlags);
                    // Transform additives to match iOS app expectations
                    additiveAnalysis = analysisResult.detectedAdditives.map(additive => (Object.assign(Object.assign({}, additive), { id: additive.code, consumerInfo: additive.consumer_guide })));
                    processingInfo = {
                        score: processingScore.totalScore,
                        grade: grade.grade,
                        label: grade.label,
                        breakdown: processingScore.breakdown
                    };
                }
                catch (error) {
                    console.log(`Additive analysis failed for ${foodName}:`, error);
                }
            }
            // Format data exactly as iOS app expects
            const calorieValue = nutrition.calories || nutrition.energy || 0;
            const proteinValue = nutrition.protein || 0;
            const carbsValue = nutrition.carbs || nutrition.carbohydrates || 0;
            const fatValue = nutrition.fat || 0;
            const fiberValue = nutrition.fiber || nutrition.fibre || 0;
            const sugarValue = nutrition.sugar || nutrition.sugars || 0;
            const sodiumValue = nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0);
            return {
                id: doc.id,
                name: foodName,
                brand: brandName || null,
                barcode: data.barcode || '',
                calories: typeof calorieValue === 'object' ? calorieValue : { kcal: calorieValue },
                protein: typeof proteinValue === 'object' ? proteinValue : { per100g: proteinValue },
                carbs: typeof carbsValue === 'object' ? carbsValue : { per100g: carbsValue },
                fat: typeof fatValue === 'object' ? fatValue : { per100g: fatValue },
                fiber: typeof fiberValue === 'object' ? fiberValue : { per100g: fiberValue },
                sugar: typeof sugarValue === 'object' ? sugarValue : { per100g: sugarValue },
                sodium: sodiumValue ? (typeof sodiumValue === 'object' ? sodiumValue : { per100g: sodiumValue }) : null,
                servingDescription: data.servingSize || '100g serving',
                // CRITICAL FIX: Map ingredients field for iOS app - keep as array
                ingredients: (() => {
                    const ingredientsData = data.extractedIngredients || data.ingredients || null;
                    if (Array.isArray(ingredientsData)) {
                        return ingredientsData; // Return array directly
                    }
                    // If it's a string, split it into array
                    if (typeof ingredientsData === 'string' && ingredientsData.trim()) {
                        return ingredientsData.split(',').map(i => i.trim()).filter(i => i.length > 0);
                    }
                    return null;
                })(),
                // CRITICAL FIX: Include verification status for dashboard filtering
                verifiedBy: data.verifiedBy || null,
                verificationMethod: data.verificationMethod || null,
                verifiedAt: data.verifiedAt || null,
                // Include micronutrient profile for vitamins/minerals display
                micronutrientProfile: data.micronutrientProfile || null,
                // Include additive analysis using comprehensive 400+ database
                additives: additiveAnalysis || [],
                processingScore: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.score) || 0,
                processingGrade: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.grade) || 'A',
                processingLabel: (processingInfo === null || processingInfo === void 0 ? void 0 : processingInfo.label) || 'Minimal processing',
                // Add relevance score for sorting
                _relevance: relevanceScore
            };
        })
            .filter(result => result !== null); // Remove null entries
        // Filter results that actually match the query and sort by relevance
        const filteredResults = allResults
            .filter(result => {
            const nameMatch = matchesQuery(result.name, query, queryWords);
            const brandMatch = result.brand ? matchesQuery(result.brand, query, queryWords) : false;
            return nameMatch || brandMatch;
        })
            .sort((a, b) => b._relevance - a._relevance) // Sort by relevance descending
            .slice(0, 20) // Limit to 20 results
            .map(result => {
            // Remove internal relevance score from final results
            const { _relevance } = result, cleanResult = __rest(result, ["_relevance"]);
            return cleanResult;
        });
        console.log(`Found ${filteredResults.length} relevant foods from ${allResults.length} total`);
        // Also check if any results have ingredients
        const withIngredients = filteredResults.filter(r => r.ingredients && r.ingredients.length > 0);
        console.log(`${withIngredients.length} foods have ingredients data`);
        // Return in the exact format iOS app expects
        res.json({
            foods: filteredResults
        });
    }
    catch (error) {
        console.error('Error searching foods:', error);
        res.status(500).json({ error: 'Failed to search foods' });
    }
});
// Google-like relevance scoring
function calculateRelevance(foodName, brandName, originalQuery, queryWords) {
    const name = foodName.toLowerCase();
    const brand = brandName.toLowerCase();
    const query = originalQuery.toLowerCase();
    let score = 0;
    // Count how many query words match in brand and name
    const brandMatches = queryWords.filter(word => brand.includes(word));
    const nameMatches = queryWords.filter(word => name.includes(word));
    const brandMatchRatio = brandMatches.length / queryWords.length;
    const nameMatchRatio = nameMatches.length / queryWords.length;
    // === TIER 1: EXACT MATCHES (1000-900 points) ===
    if (name === query) {
        return 1000; // Perfect name match
    }
    if (brand === query) {
        return 950; // Perfect brand match
    }
    // === TIER 2: FULL QUERY STRING MATCHES (800-600 points) ===
    if (brand.includes(query)) {
        score = 800;
        if (brand.startsWith(query))
            score += 50; // Bonus for prefix
        return score;
    }
    if (name.includes(query)) {
        score = 700;
        if (name.startsWith(query))
            score += 50; // Bonus for prefix
        return score;
    }
    // === TIER 3: ALL QUERY WORDS PRESENT (600-400 points) ===
    if (brandMatchRatio === 1.0) {
        score = 600;
        // Bonus for words in order
        if (wordsInOrder(brand, queryWords))
            score += 100;
        // Bonus for starting with first word
        if (brand.startsWith(queryWords[0]))
            score += 75;
        return score;
    }
    if (nameMatchRatio === 1.0) {
        score = 500;
        // Bonus for words in order
        if (wordsInOrder(name, queryWords))
            score += 100;
        // Bonus for starting with first word
        if (name.startsWith(queryWords[0]))
            score += 50;
        return score;
    }
    // === TIER 4: PARTIAL MATCHES (400-200 points) ===
    // Prioritize brand matches over name matches
    if (brandMatchRatio >= 0.5) {
        score = 400 * brandMatchRatio;
        if (brand.startsWith(queryWords[0]))
            score += 50;
    }
    else if (nameMatchRatio >= 0.5) {
        score = 300 * nameMatchRatio;
        if (name.startsWith(queryWords[0]))
            score += 30;
    }
    else {
        // Very weak match - just count any word matches
        score = (brandMatches.length * 40) + (nameMatches.length * 20);
    }
    // === TIER 5: QUALITY BONUSES (up to 100 points) ===
    // Bonus for shorter, more precise matches
    const lengthBonus = Math.max(0, 50 - Math.min(name.length, 50));
    score += lengthBonus;
    // Bonus for matches at word boundaries (e.g., "charlie" matches "Charlie Bigham's" better than "charliex")
    if (hasWordBoundaryMatch(brand, queryWords[0]) || hasWordBoundaryMatch(name, queryWords[0])) {
        score += 30;
    }
    return score;
}
// Helper: Check if words appear in order in text
function wordsInOrder(text, words) {
    let lastIndex = -1;
    for (const word of words) {
        const index = text.indexOf(word, lastIndex + 1);
        if (index <= lastIndex)
            return false;
        lastIndex = index;
    }
    return true;
}
// Helper: Check if word matches at word boundary
function hasWordBoundaryMatch(text, word) {
    // Check if word appears at start or after a space/punctuation
    const regex = new RegExp(`(^|\\s|-)${word}`, 'i');
    return regex.test(text);
}
// Helper function to check if text matches query (Google-like flexible matching)
function matchesQuery(text, originalQuery, queryWords) {
    if (!text)
        return false;
    const lowerText = text.toLowerCase();
    const query = originalQuery.toLowerCase();
    // Direct match of full query string (best match)
    if (lowerText.includes(query))
        return true;
    // For single word queries, just check if word is present
    if (queryWords.length === 1) {
        return lowerText.includes(queryWords[0]);
    }
    // For multi-word queries: require at least 50% of words to match
    const matchedWords = queryWords.filter(word => lowerText.includes(word));
    return matchedWords.length >= Math.ceil(queryWords.length / 2);
}
//# sourceMappingURL=search-foods.js.map