"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchCleansedFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Search function that uses cleansed foods as the primary database
exports.searchCleansedFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        // Support both GET (?q=search) and POST ({"query": "search"}) for iOS app compatibility
        const query = req.query.q || (req.body && req.body.query) || '';
        if (!query || query.trim().length < 2) {
            res.status(400).json({ error: 'Query must be at least 2 characters' });
            return;
        }
        console.log(`🔎 searchCleansedFoods: Searching for: "${query}"`);
        // Enhanced search with better matching and ranking
        const searchLimit = 100;
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
        // Search cleansedFoods collection with all variations and collect results
        let allDocs = new Map(); // Use Map to avoid duplicates by document ID
        for (const variation of uniqueVariations) {
            try {
                // Search by foodName (from cleanedData)
                const snapshot = await admin.firestore()
                    .collection('cleansedFoods')
                    .where('cleanedData.foodName', '>=', variation)
                    .where('cleanedData.foodName', '<=', variation + '\uf8ff')
                    .limit(Math.max(1, Math.floor(searchLimit / uniqueVariations.length)))
                    .get();
                snapshot.docs.forEach(doc => {
                    allDocs.set(doc.id, doc); // Map prevents duplicates
                });
            }
            catch (error) {
                console.log(`Search variation "${variation}" failed:`, error);
            }
        }
        const cleanedSnapshot = { docs: Array.from(allDocs.values()) };
        // Convert to results and add relevance scoring
        let allResults = cleanedSnapshot.docs
            .filter(doc => {
            const data = doc.data();
            // Filter out foods recommended for deletion
            return !data.cleanedData?.recommendedForDeletion && !data.aiAnalysis?.recommendedForDeletion;
        })
            .map(doc => {
            const data = doc.data();
            const cleanedData = data.cleanedData || {};
            const foodName = cleanedData.foodName || cleanedData.name || '';
            const brandName = cleanedData.brandName || cleanedData.brand || '';
            // Calculate relevance score for ranking
            const relevanceScore = calculateRelevance(foodName, brandName, query, queryWords);
            // Transform cleansed data to match app's expected format
            const calorieValue = cleanedData.calories?.kcal || cleanedData.nutritionData?.calories || 0;
            const proteinValue = cleanedData.protein?.per100g || cleanedData.nutritionData?.protein || 0;
            const carbsValue = cleanedData.carbs?.per100g || cleanedData.nutritionData?.carbs || 0;
            const fatValue = cleanedData.fat?.per100g || cleanedData.nutritionData?.fat || 0;
            const fiberValue = cleanedData.fiber?.per100g || cleanedData.nutritionData?.fiber || 0;
            const sugarValue = cleanedData.sugar?.per100g || cleanedData.nutritionData?.sugar || 0;
            const sodiumValue = cleanedData.sodium?.per100g || cleanedData.nutritionData?.sodium || 0;
            return {
                id: doc.id,
                name: foodName,
                brand: brandName || null,
                barcode: cleanedData.barcode || '',
                calories: typeof calorieValue === 'object' ? calorieValue : { kcal: calorieValue },
                protein: typeof proteinValue === 'object' ? proteinValue : { per100g: proteinValue },
                carbs: typeof carbsValue === 'object' ? carbsValue : { per100g: carbsValue },
                fat: typeof fatValue === 'object' ? fatValue : { per100g: fatValue },
                fiber: typeof fiberValue === 'object' ? fiberValue : { per100g: fiberValue },
                sugar: typeof sugarValue === 'object' ? sugarValue : { per100g: sugarValue },
                sodium: sodiumValue ? (typeof sodiumValue === 'object' ? sodiumValue : { per100g: sodiumValue }) : null,
                servingDescription: cleanedData.servingDescription || cleanedData.servingSize || '100g serving',
                // Use the cleaned ingredients (already processed by AI)
                ingredients: cleanedData.extractedIngredients || cleanedData.ingredients || null,
                // Include verification status
                verifiedBy: cleanedData.verifiedBy || 'ai_cleansed',
                verificationMethod: cleanedData.verificationMethod || 'ai_analysis',
                verifiedAt: cleanedData.verifiedAt || null,
                // Include micronutrient profile if available
                micronutrientProfile: cleanedData.micronutrientProfile || null,
                // Include additive analysis (already processed by AI)
                additives: cleanedData.additives || [],
                processingScore: cleanedData.processingScore || 0,
                processingGrade: cleanedData.processingGrade || 'A',
                processingLabel: cleanedData.processingLabel || 'Minimal processing',
                // Add relevance score for sorting
                _relevance: relevanceScore,
                // Mark as cleansed data source
                _source: 'cleansed'
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
            // Remove internal relevance score and source from final results
            const { _relevance, _source, ...cleanResult } = result;
            return cleanResult;
        });
        console.log(`🔎 searchCleansedFoods: Found ${filteredResults.length} relevant foods from cleansed database`);
        // Also check if any results have ingredients
        const withIngredients = filteredResults.filter(r => r.ingredients && r.ingredients.length > 0);
        console.log(`🔎 searchCleansedFoods: ${withIngredients.length} foods have ingredients data`);
        // Return in the exact format iOS app expects
        res.json({
            foods: filteredResults
        });
    }
    catch (error) {
        console.error('❌ Error searching cleansed foods:', error);
        res.status(500).json({ error: 'Failed to search cleansed foods' });
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
//# sourceMappingURL=search-cleansed-foods.js.map