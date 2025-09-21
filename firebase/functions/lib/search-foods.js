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
exports.searchFoods = functions.https.onRequest(async (req, res) => {
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
        // Enhanced search with better matching and ranking
        // Reduced for better performance
        const searchLimit = 100; // Reduced from 500 for better performance
        // Split query into words for multi-word search
        const queryWords = query.toLowerCase().split(/\s+/).filter((word) => word.length > 0);
        const firstWord = queryWords[0];
        // Simplified case-insensitive search strategy for better performance
        const searchVariations = [];
        if (firstWord) {
            // Try capitalized first (most common for food names)
            searchVariations.push(firstWord.charAt(0).toUpperCase() + firstWord.slice(1));
            // Try lowercase if different
            if (firstWord !== firstWord.charAt(0).toUpperCase() + firstWord.slice(1)) {
                searchVariations.push(firstWord);
            }
        }
        // Remove duplicates
        const uniqueVariations = [...new Set(searchVariations)];
        // Search with all variations and collect results
        let allDocs = new Map(); // Use Map to avoid duplicates by document ID
        for (const variation of uniqueVariations) {
            try {
                const snapshot = await admin.firestore()
                    .collection('verifiedFoods')
                    .where('foodName', '>=', variation)
                    .where('foodName', '<=', variation + '\uf8ff')
                    .limit(Math.max(1, Math.floor(searchLimit / uniqueVariations.length))) // Distribute limit across variations
                    .get();
                snapshot.docs.forEach(doc => {
                    allDocs.set(doc.id, doc); // Map prevents duplicates
                });
            }
            catch (error) {
                console.log(`Search variation "${variation}" failed:`, error);
            }
        }
        const verifiedSnapshot = { docs: Array.from(allDocs.values()) };
        // Convert to results and add relevance scoring
        let allResults = verifiedSnapshot.docs.map(doc => {
            const data = doc.data();
            const nutrition = data.nutritionData || {};
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
                // CRITICAL FIX: Map ingredients field for iOS app - convert array to string if needed
                ingredients: (() => {
                    const ingredientsData = data.extractedIngredients || data.ingredients || null;
                    if (Array.isArray(ingredientsData)) {
                        return ingredientsData.join(', ');
                    }
                    return ingredientsData;
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
        });
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
// Helper function to calculate relevance score
function calculateRelevance(foodName, brandName, originalQuery, queryWords) {
    const name = foodName.toLowerCase();
    const brand = brandName.toLowerCase();
    const query = originalQuery.toLowerCase();
    let score = 0;
    // Exact name match gets highest score
    if (name === query) {
        score += 1000;
    }
    // Exact brand match
    else if (brand === query) {
        score += 800;
    }
    // Name starts with full query
    else if (name.startsWith(query)) {
        score += 500;
    }
    // Brand starts with full query
    else if (brand.startsWith(query)) {
        score += 400;
    }
    // All query words found in name (for multi-word queries like "mars bar")
    else if (queryWords.every(word => name.includes(word))) {
        score += 300;
        // Bonus if words appear in order
        let lastIndex = -1;
        let inOrder = true;
        for (const word of queryWords) {
            const index = name.indexOf(word, lastIndex + 1);
            if (index <= lastIndex) {
                inOrder = false;
                break;
            }
            lastIndex = index;
        }
        if (inOrder)
            score += 100;
        // Bonus if query words appear at start of name
        if (name.startsWith(queryWords[0])) {
            score += 50;
        }
    }
    // Some query words found in name
    else {
        const foundWords = queryWords.filter(word => name.includes(word));
        score += foundWords.length * 50;
    }
    // Bonus for shorter names (more precise matches)
    score += Math.max(0, 100 - name.length);
    return score;
}
// Helper function to check if text matches query
function matchesQuery(text, originalQuery, queryWords) {
    if (!text)
        return false;
    const lowerText = text.toLowerCase();
    const query = originalQuery.toLowerCase();
    // Direct match
    if (lowerText.includes(query))
        return true;
    // Multi-word match - at least one word must match
    return queryWords.some(word => lowerText.includes(word));
}
//# sourceMappingURL=search-foods.js.map