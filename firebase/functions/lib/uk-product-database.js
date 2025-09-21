"use strict";
// UK Product Database with real product specifications
// This provides accurate serving sizes, barcodes, and nutrition data for common UK products
Object.defineProperty(exports, "__esModule", { value: true });
exports.UK_PRODUCT_DATABASE = void 0;
exports.findUKProduct = findUKProduct;
exports.calculateNutritionPerServing = calculateNutritionPerServing;
exports.UK_PRODUCT_DATABASE = [
    {
        names: ['Coca Cola Classic', 'Coca-Cola Classic', 'Coke Classic', 'Coca Cola', 'Coke'],
        brands: ['Coca-Cola', 'Coca Cola'],
        servingSize: {
            amount: 330,
            unit: 'ml',
            description: 'per 330ml can'
        },
        barcode: '5449000000996',
        ingredients: 'Carbonated Water, Sugar, Natural Flavourings including Caffeine, Phosphoric Acid, Caramel Colour (E150d)',
        nutritionPer100g: {
            calories: 42,
            protein: 0,
            carbs: 10.6,
            fat: 0,
            fiber: 0,
            sugar: 10.6,
            sodium: 4,
            saturatedFat: 0,
            salt: 0.01
        },
        allergens: {
            contains: [],
            mayContain: []
        }
    },
    {
        names: ['Mars Bar', 'Mars'],
        brands: ['Mars'],
        servingSize: {
            amount: 51,
            unit: 'g',
            description: 'per 51g bar'
        },
        barcode: '5000159407236',
        ingredients: 'Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey (from Milk), Palm Fat, Milk Fat, Barley Malt Extract, Salt, Emulsifier (Soya Lecithin), Vanilla Extract',
        nutritionPer100g: {
            calories: 449,
            protein: 4.2,
            carbs: 65,
            fat: 17.4,
            fiber: 0.9,
            sugar: 59.5,
            sodium: 96,
            saturatedFat: 6.8,
            salt: 0.24
        },
        allergens: {
            contains: ['Milk', 'Soya'],
            mayContain: ['Nuts', 'Peanuts']
        }
    },
    {
        names: ['Heinz Baked Beans', 'Baked Beans', 'Heinz Beans'],
        brands: ['Heinz'],
        servingSize: {
            amount: 415,
            unit: 'g',
            description: 'per 415g can'
        },
        barcode: '5000157005779',
        ingredients: 'Beans (51%), Tomatoes, Water, Sugar, Spirit Vinegar, Modified Corn Flour, Salt, Spice Extracts, Herb Extract',
        nutritionPer100g: {
            calories: 75,
            protein: 4.7,
            carbs: 13,
            fat: 0.6,
            fiber: 4.1,
            sugar: 5.2,
            sodium: 400,
            saturatedFat: 0.1,
            salt: 1.0
        },
        allergens: {
            contains: [],
            mayContain: []
        }
    },
    {
        names: ['Snickers', 'Snickers Bar'],
        brands: ['Snickers', 'Mars'],
        servingSize: {
            amount: 48,
            unit: 'g',
            description: 'per 48g bar'
        },
        barcode: '5000159461627',
        ingredients: 'Milk Chocolate (30%) (Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Lactose, Milkfat, Emulsifier (Soya Lecithin), Vanilla Extract), Peanuts (16%), Glucose Syrup, Sugar, Palm Fat, Skimmed Milk Powder, Salt, Emulsifier (Soya Lecithin), Egg White Powder',
        nutritionPer100g: {
            calories: 488,
            protein: 9.0,
            carbs: 56,
            fat: 23.9,
            fiber: 2.2,
            sugar: 47.8,
            sodium: 160,
            saturatedFat: 9.2,
            salt: 0.40
        },
        allergens: {
            contains: ['Milk', 'Peanuts', 'Soya', 'Egg'],
            mayContain: ['Nuts']
        }
    },
    {
        names: ['Walkers Ready Salted Crisps', 'Walkers Crisps', 'Ready Salted Crisps'],
        brands: ['Walkers'],
        servingSize: {
            amount: 25,
            unit: 'g',
            description: 'per 25g bag'
        },
        barcode: '5000328021035',
        ingredients: 'Potatoes, Sunflower Oil (24%), Salt',
        nutritionPer100g: {
            calories: 532,
            protein: 6.6,
            carbs: 50,
            fat: 33,
            fiber: 4.6,
            sugar: 0.6,
            sodium: 440,
            saturatedFat: 3.1,
            salt: 1.1
        },
        allergens: {
            contains: [],
            mayContain: ['Milk', 'Gluten']
        }
    },
    {
        names: ['Kit Kat', 'Kit Kat 4 Finger', 'KitKat'],
        brands: ['Kit Kat', 'KitKat', 'Nestlé'],
        servingSize: {
            amount: 45,
            unit: 'g',
            description: 'per 45g bar (4 fingers)'
        },
        barcode: '7613034626844',
        ingredients: 'Sugar, Wheat Flour, Cocoa Butter, Cocoa Mass, Whole Milk Powder, Lactose and Proteins from Whey (from Milk), Palm Fat, Emulsifier (Lecithins), Raising Agent (Sodium Bicarbonate), Salt, Natural Vanilla Flavouring',
        nutritionPer100g: {
            calories: 518,
            protein: 7.3,
            carbs: 59,
            fat: 27,
            fiber: 3.0,
            sugar: 47,
            sodium: 32,
            saturatedFat: 16,
            salt: 0.08
        },
        allergens: {
            contains: ['Gluten', 'Milk'],
            mayContain: ['Nuts', 'Peanuts']
        }
    },
    {
        names: ['Dairy Milk', 'Cadbury Dairy Milk', 'Dairy Milk Chocolate'],
        brands: ['Cadbury'],
        servingSize: {
            amount: 45,
            unit: 'g',
            description: 'per 45g bar'
        },
        barcode: '7622201159269',
        ingredients: 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Emulsifiers (E442, E476), Flavourings',
        nutritionPer100g: {
            calories: 534,
            protein: 7.3,
            carbs: 57,
            fat: 30,
            fiber: 2.5,
            sugar: 56,
            sodium: 24,
            saturatedFat: 18,
            salt: 0.06
        },
        allergens: {
            contains: ['Milk'],
            mayContain: ['Nuts', 'Wheat']
        }
    }
];
function findUKProduct(name, brand) {
    const normalizedName = name.toLowerCase().trim();
    const normalizedBrand = brand === null || brand === void 0 ? void 0 : brand.toLowerCase().trim();
    for (const product of exports.UK_PRODUCT_DATABASE) {
        // Check if name matches any of the product names
        const nameMatch = product.names.some(productName => normalizedName.includes(productName.toLowerCase()) ||
            productName.toLowerCase().includes(normalizedName));
        // Check if brand matches (if provided)
        const brandMatch = !normalizedBrand || product.brands.some(productBrand => normalizedBrand.includes(productBrand.toLowerCase()) ||
            productBrand.toLowerCase().includes(normalizedBrand));
        if (nameMatch && brandMatch) {
            return product;
        }
    }
    return null;
}
function calculateNutritionPerServing(product) {
    const { nutritionPer100g, servingSize } = product;
    const ratio = servingSize.amount / 100;
    return {
        calories: Math.round(nutritionPer100g.calories * ratio),
        protein: Math.round(nutritionPer100g.protein * ratio * 10) / 10,
        carbs: Math.round(nutritionPer100g.carbs * ratio * 10) / 10,
        fat: Math.round(nutritionPer100g.fat * ratio * 10) / 10,
        fiber: Math.round(nutritionPer100g.fiber * ratio * 10) / 10,
        sugar: Math.round(nutritionPer100g.sugar * ratio * 10) / 10,
        sodium: Math.round(nutritionPer100g.sodium * ratio),
        saturatedFat: Math.round(nutritionPer100g.saturatedFat * ratio * 10) / 10,
        salt: Math.round(nutritionPer100g.salt * ratio * 100) / 100
    };
}
//# sourceMappingURL=uk-product-database.js.map