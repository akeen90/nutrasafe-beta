import * as functions from 'firebase-functions';
import axios from 'axios';

interface IntelligentExtractionResult {
  success: boolean;
  extractedIngredients: string[];
  cleanIngredientsText: string;
  detectedAllergens: string[];
  error?: string;
}

interface AllergenInfo {
  name: string;
  keywords: string[];
}

// Comprehensive allergen detection database
const ALLERGEN_DATABASE: AllergenInfo[] = [
  {
    name: 'gluten',
    keywords: ['wheat', 'barley', 'rye', 'oats', 'spelt', 'kamut', 'gluten', 'flour', 'bran', 'semolina', 'durum']
  },
  {
    name: 'dairy',
    keywords: ['milk', 'cream', 'butter', 'cheese', 'yogurt', 'lactose', 'casein', 'whey', 'skimmed milk powder', 'milk powder']
  },
  {
    name: 'eggs',
    keywords: ['egg', 'eggs', 'albumin', 'lecithin', 'egg white', 'egg yolk', 'ovomucin']
  },
  {
    name: 'nuts',
    keywords: ['almond', 'hazelnut', 'walnut', 'cashew', 'pistachio', 'brazil nut', 'macadamia', 'pecan', 'pine nut']
  },
  {
    name: 'peanuts',
    keywords: ['peanut', 'groundnut', 'arachis oil', 'peanut oil']
  },
  {
    name: 'soy',
    keywords: ['soya', 'soy', 'soybean', 'tofu', 'tempeh', 'miso', 'soy lecithin', 'soy protein']
  },
  {
    name: 'fish',
    keywords: ['fish', 'anchovy', 'tuna', 'salmon', 'cod', 'haddock', 'fish oil', 'worcestershire sauce']
  },
  {
    name: 'shellfish',
    keywords: ['shellfish', 'crab', 'lobster', 'prawn', 'shrimp', 'crayfish', 'langoustine']
  },
  {
    name: 'sesame',
    keywords: ['sesame', 'tahini', 'sesame oil', 'sesame seed']
  },
  {
    name: 'sulphites',
    keywords: ['sulphite', 'sulfite', 'sulphur dioxide', 'sulfur dioxide', 'e220', 'e221', 'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228']
  },
  {
    name: 'celery',
    keywords: ['celery', 'celeriac', 'celery salt', 'celery extract']
  },
  {
    name: 'mustard',
    keywords: ['mustard', 'mustard seed', 'dijon', 'wholegrain mustard']
  },
  {
    name: 'lupin',
    keywords: ['lupin', 'lupine', 'lupin flour']
  },
  {
    name: 'molluscs',
    keywords: ['mollusc', 'mussel', 'oyster', 'clam', 'scallop', 'squid', 'octopus', 'snail']
  }
];

export const extractIngredientsWithAI = functions.https.onCall(async (data, context) => {
  try {
    const { imageBase64, foodName, brandName } = data;
    
    if (!imageBase64) {
      throw new functions.https.HttpsError('invalid-argument', 'Image data is required');
    }

    console.log(`🧠 Starting intelligent ingredient extraction for: ${foodName} ${brandName ? `by ${brandName}` : ''}`);

    // Get Gemini API key
    const geminiApiKey = functions.config().gemini?.api_key;
    if (!geminiApiKey) {
      throw new functions.https.HttpsError('failed-precondition', 'Gemini API key not configured');
    }

    // Create intelligent prompt for ingredient extraction
    const prompt = `Analyze this food product image and extract ONLY the ingredients list. Follow these rules strictly:

1. Extract ingredients as a clean, comma-separated list
2. Remove all quantities, percentages, and numbers (like "50%", "2g", etc.)
3. Remove allergen warnings and "contains" statements
4. Remove marketing text and brand names
5. Clean up formatting and make ingredients readable
6. Convert to lowercase and remove extra spaces
7. If you see multiple ingredient sections, extract from the main ingredients list only

For example:
- Input: "Wheat flour (50%), Sugar, Palm oil, Cocoa powder (5%), CONTAINS: Gluten, Made in a factory..."
- Output: "wheat flour, sugar, palm oil, cocoa powder"

Respond with ONLY the clean ingredients list, nothing else. If no clear ingredients are visible, respond with "NO_INGREDIENTS_FOUND".`;

    const geminiRequest = {
      contents: [{
        parts: [
          {
            text: prompt
          },
          {
            inline_data: {
              mime_type: "image/jpeg",
              data: imageBase64
            }
          }
        ]
      }]
    };

    console.log('🔍 Sending request to Gemini Vision API...');
    
    const geminiResponse = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
      geminiRequest,
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const extractedText = geminiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    
    if (!extractedText || extractedText === 'NO_INGREDIENTS_FOUND') {
      console.log('❌ No ingredients found in image');
      return {
        success: false,
        error: 'No ingredients could be extracted from the image',
        extractedIngredients: [],
        cleanIngredientsText: '',
        detectedAllergens: []
      } as IntelligentExtractionResult;
    }

    console.log(`✅ Raw Gemini extraction: ${extractedText}`);

    // Parse ingredients into array
    const ingredientsArray = extractedText
      .split(',')
      .map((ingredient: string) => ingredient.trim().toLowerCase())
      .filter((ingredient: string) => ingredient.length > 1 && !ingredient.includes('no ingredients')); // Remove empty and error strings

    // Detect allergens in the extracted ingredients
    const detectedAllergens: string[] = [];
    const combinedIngredients = ingredientsArray.join(' ').toLowerCase();
    
    for (const allergen of ALLERGEN_DATABASE) {
      for (const keyword of allergen.keywords) {
        if (combinedIngredients.includes(keyword.toLowerCase())) {
          if (!detectedAllergens.includes(allergen.name)) {
            detectedAllergens.push(allergen.name);
          }
          break; // Found this allergen, move to next
        }
      }
    }

    console.log(`🔍 Detected ${ingredientsArray.length} ingredients: ${ingredientsArray.join(', ')}`);
    console.log(`⚠️ Detected ${detectedAllergens.length} allergens: ${detectedAllergens.join(', ')}`);

    return {
      success: true,
      extractedIngredients: ingredientsArray,
      cleanIngredientsText: ingredientsArray.join(', '),
      detectedAllergens: detectedAllergens
    } as IntelligentExtractionResult;

  } catch (error) {
    console.error('❌ Error in intelligent ingredient extraction:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to extract ingredients intelligently', error);
  }
});