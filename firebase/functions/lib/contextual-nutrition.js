"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getContextualNutritionScore = void 0;
const functions = require("firebase-functions");
exports.getContextualNutritionScore = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { foodName, nutritionPer100g, servingSizeGrams } = req.body;
        if (!foodName || !nutritionPer100g || !servingSizeGrams) {
            res.status(400).json({
                error: 'Missing required fields: foodName, nutritionPer100g, servingSizeGrams'
            });
            return;
        }
        // Calculate nutrition per single serving
        const perServing = {
            calories: (nutritionPer100g.calories * servingSizeGrams) / 100,
            sugar: (nutritionPer100g.sugar * servingSizeGrams) / 100,
            saturatedFat: (nutritionPer100g.saturatedFat * servingSizeGrams) / 100,
            sodium: (nutritionPer100g.sodium * servingSizeGrams) / 100,
            protein: (nutritionPer100g.protein * servingSizeGrams) / 100,
            fiber: (nutritionPer100g.fiber * servingSizeGrams) / 100
        };
        // Define realistic consumption contexts based on food type
        const contexts = getConsumptionContexts(foodName, servingSizeGrams);
        // Calculate scores for each context
        const contextualScores = contexts.map(context => ({
            context: context.description,
            likelihood: context.likelihood,
            ...calculateContextualScore(perServing, context, foodName)
        }));
        res.json({
            success: true,
            foodName,
            perServing,
            contextualScores
        });
    }
    catch (error) {
        console.error('Error calculating contextual nutrition score:', error);
        res.status(500).json({ error: 'Failed to calculate contextual score' });
    }
});
function getConsumptionContexts(foodName, servingSizeGrams) {
    const lowerFood = foodName.toLowerCase();
    // Biscuits/cookies
    if (lowerFood.includes('biscuit') || lowerFood.includes('cookie')) {
        return [
            { size: 1, description: '1 biscuit', likelihood: 'medium' },
            { size: 3, description: '3 biscuits', likelihood: 'high' },
            { size: 6, description: 'small handful', likelihood: 'medium' }
        ];
    }
    // Chocolate/candy
    if (lowerFood.includes('chocolate') || lowerFood.includes('candy') || lowerFood.includes('sweet')) {
        return [
            { size: 1, description: '1 piece', likelihood: 'low' },
            { size: 3, description: 'few pieces', likelihood: 'high' },
            { size: 8, description: 'generous portion', likelihood: 'medium' }
        ];
    }
    // Nuts/snacks
    if (lowerFood.includes('nuts') || lowerFood.includes('chips') || lowerFood.includes('crisps')) {
        return [
            { size: 1, description: 'small handful', likelihood: 'low' },
            { size: 3, description: 'standard portion', likelihood: 'high' },
            { size: 6, description: 'large bowl', likelihood: 'medium' }
        ];
    }
    // Default contexts
    return [
        { size: 1, description: '1 serving', likelihood: 'medium' },
        { size: 2, description: '2 servings', likelihood: 'high' },
        { size: 4, description: 'large portion', likelihood: 'medium' }
    ];
}
function calculateContextualScore(perServing, context, foodName) {
    // Calculate total nutrition for this context
    const totalSugar = perServing.sugar * context.size;
    const totalCalories = perServing.calories * context.size;
    // WHO guidelines: <25g sugar per day, <200 calories per snack
    const sugarPercentOfDaily = (totalSugar / 25) * 100;
    const isHighCalorie = totalCalories > 200;
    let score;
    let message;
    let metabolicImpact;
    let balanceTip;
    // Determine score and messaging
    if (sugarPercentOfDaily < 10 && !isHighCalorie) {
        score = 'A';
        message = `${context.description} fits well in a balanced day`;
        metabolicImpact = 'Minimal metabolic impact';
    }
    else if (sugarPercentOfDaily < 25 && totalCalories < 300) {
        score = 'B';
        message = `${context.description} is moderate - fine occasionally`;
        metabolicImpact = 'Light metabolic load';
        balanceTip = 'Pair with protein or have after a meal';
    }
    else if (sugarPercentOfDaily < 50) {
        score = 'C';
        message = `${context.description} is a substantial treat`;
        metabolicImpact = 'Notable impact on blood sugar and energy';
        balanceTip = 'Consider splitting across the day or saving for active periods';
    }
    else {
        score = 'D';
        message = `${context.description} is a significant indulgence`;
        metabolicImpact = 'Major metabolic impact - expect energy fluctuations';
        balanceTip = 'Best enjoyed occasionally and when you can be active afterward';
    }
    return {
        score,
        message,
        metabolicImpact,
        balanceTip
    };
}
//# sourceMappingURL=contextual-nutrition.js.map