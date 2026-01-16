/**
 * Unified Product Scanner - AI Auto-Detection
 *
 * Uses Google Gemini Vision to automatically detect what each photo contains
 * (front label, ingredients list, nutrition table, barcode) and extract all
 * relevant data in a single pass.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import axios from 'axios';

// Define the Gemini API key as a secret
const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Request/Response interfaces
interface ScanProductRequest {
  images: Array<{
    base64: string;  // Base64 encoded image data
    mimeType?: string;  // e.g., 'image/jpeg', 'image/png'
  }>;
}

interface ScanProductResponse {
  // Product identification
  productName?: string;
  brand?: string;
  barcode?: string;

  // Ingredients
  ingredientsText?: string;
  allergens?: string[];
  containsStatement?: string;

  // Nutrition per 100g
  nutrition?: {
    calories?: number;
    protein?: number;
    carbohydrates?: number;
    fat?: number;
    fiber?: number;
    sugar?: number;
    salt?: number;
    saturatedFat?: number;
  };

  // Serving info
  servingSize?: number;
  servingUnit?: string;
  servingsPerContainer?: number;

  // Meta
  confidence: number;
  detectedContent: string[];  // What was found in images: 'front', 'ingredients', 'nutrition', 'barcode'
  warnings?: string[];
}

/**
 * Cloud Function: Scan product from multiple images with AI auto-detection
 */
export const scanProductComplete = onCall<ScanProductRequest>(
  {
    cors: true,
    timeoutSeconds: 60,  // Longer timeout for processing multiple images
    memory: '1GiB',
    secrets: [geminiApiKey],
  },
  async (request) => {
    const { images } = request.data;

    if (!images || images.length === 0) {
      throw new HttpsError('invalid-argument', 'At least one image must be provided');
    }

    if (images.length > 5) {
      throw new HttpsError('invalid-argument', 'Maximum 5 images allowed');
    }

    try {
      console.log(`📸 Processing ${images.length} image(s) for product scanning`);

      // Build the prompt and image parts for Gemini
      const prompt = buildProductScanPrompt();

      // Call Gemini Vision API with all images
      const result = await callGeminiVisionAPI(prompt, images, geminiApiKey.value());

      console.log(`✅ Product scan complete. Detected: ${result.detectedContent.join(', ')}`);
      console.log(`   Confidence: ${(result.confidence * 100).toFixed(0)}%`);
      if (result.barcode) {
        console.log(`   Barcode: ${result.barcode}`);
      }

      return result;
    } catch (error) {
      console.error('❌ Product scan failed:', error);
      throw new HttpsError('internal', 'Failed to scan product', { originalError: String(error) });
    }
  }
);

function buildProductScanPrompt(): string {
  return `You are a product scanning AI expert. Analyze these food product images and extract ALL available information.

TASK: Automatically detect what each image shows and extract the relevant data.

CONTENT TYPES TO DETECT:
1. FRONT LABEL - Product name, brand name, marketing text
2. INGREDIENTS LIST - Full ingredients text, allergen warnings, "contains" statements
3. NUTRITION TABLE - Nutrition facts per 100g (or convert from per serving)
4. BARCODE - EAN-13, UPC-A, or other product barcodes (13 or 12 digit numbers)

EXTRACTION RULES:

For PRODUCT NAME & BRAND:
- Extract the main product name (e.g., "Digestive Biscuits", "Greek Yogurt")
- Extract the brand name (e.g., "McVitie's", "Fage")
- Don't include size, flavor variants, or marketing text in the name

For BARCODE:
- Look for barcode numbers printed below barcodes
- UK/EU products typically use EAN-13 (13 digits starting with 5 for UK)
- US products typically use UPC-A (12 digits)
- Look for numbers like: 5000168001142, 012345678901
- ONLY return the numeric digits, no letters or symbols
- If barcode is partially visible or unclear, omit it

For INGREDIENTS (CRITICAL - always extract if visible):
- Extract the COMPLETE ingredients list text exactly as printed
- Start from "Ingredients:" and include EVERYTHING until the ingredients list ends
- Preserve commas and parentheses exactly as shown
- Include sub-ingredients in parentheses (e.g., "Chocolate (Cocoa Mass, Sugar, Cocoa Butter)")
- Include percentages if shown (e.g., "Chicken Breast (58%)")
- Identify allergens (typically in BOLD or CAPITALS): wheat, milk, eggs, nuts, soy, fish, shellfish, sesame, celery, mustard, lupin, molluscs, sulphites
- Extract "Contains:" or "May contain:" statements separately
- THIS FIELD IS VERY IMPORTANT - users rely on it for allergy safety

For NUTRITION (prefer per 100g, convert if needed):
- Energy: Return in kcal (convert from kJ: kJ ÷ 4.184)
- All values should be per 100g (convert from per serving if needed)
- Salt: return in grams (convert from sodium: mg × 2.5 ÷ 1000)

SERVING SIZE vs PACK SIZE - IMPORTANT:
- servingSize = recommended portion (usually 15-100g for snacks, 100-250g for meals)
- DO NOT use pack size (total product weight) as serving size
- Look for: "per serving", "1 portion", "per slice", "each (Xg)"

OUTPUT FORMAT (JSON only, no markdown):
{
  "productName": "Digestive Biscuits",
  "brand": "McVitie's",
  "barcode": "5000168001142",
  "ingredientsText": "Wheat Flour (with Calcium, Iron, Niacin, Thiamin), Sugar, Palm Oil...",
  "allergens": ["wheat", "milk"],
  "containsStatement": "Contains: Wheat, Milk. May contain: Nuts, Soya.",
  "nutrition": {
    "calories": 480,
    "protein": 7.5,
    "carbohydrates": 68,
    "fat": 20,
    "fiber": 3.5,
    "sugar": 20,
    "salt": 1.0,
    "saturatedFat": 9.5
  },
  "servingSize": 30,
  "servingUnit": "g",
  "servingsPerContainer": 10,
  "confidence": 0.92,
  "detectedContent": ["front", "ingredients", "nutrition", "barcode"],
  "warnings": ["Nutrition values converted from per serving to per 100g"]
}

CONFIDENCE GUIDELINES:
- 0.9+ : All text clear, all sections found
- 0.7-0.9 : Some OCR issues but data reliable
- 0.5-0.7 : Significant issues, some data may be wrong
- <0.5 : Poor quality, data unreliable

Only include fields where you have data. Omit fields where data wasn't found.
Return ONLY valid JSON, no explanations or markdown code blocks.`;
}

async function callGeminiVisionAPI(
  prompt: string,
  images: Array<{ base64: string; mimeType?: string }>,
  apiKey: string
): Promise<ScanProductResponse> {
  // Build the parts array with text prompt and all images
  const parts: Array<{ text?: string; inline_data?: { mime_type: string; data: string } }> = [
    { text: prompt }
  ];

  // Add each image
  for (const image of images) {
    parts.push({
      inline_data: {
        mime_type: image.mimeType || 'image/jpeg',
        data: image.base64
      }
    });
  }

  const response = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {
      contents: [{ parts }],
      generationConfig: {
        temperature: 0.1,  // Low temperature for accurate extraction
        topP: 0.8,
        maxOutputTokens: 2048,
      },
    },
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: 55000,
    }
  );

  const rawText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!rawText) {
    throw new Error('No response from Gemini Vision API');
  }

  // Parse JSON response (handle potential markdown code blocks)
  let jsonStr = rawText.trim();

  // Remove markdown code block if present
  if (jsonStr.startsWith('```json')) {
    jsonStr = jsonStr.slice(7);
  } else if (jsonStr.startsWith('```')) {
    jsonStr = jsonStr.slice(3);
  }
  if (jsonStr.endsWith('```')) {
    jsonStr = jsonStr.slice(0, -3);
  }
  jsonStr = jsonStr.trim();

  try {
    const parsed = JSON.parse(jsonStr);

    // Ensure required fields
    return {
      productName: parsed.productName,
      brand: parsed.brand,
      barcode: parsed.barcode,
      ingredientsText: parsed.ingredientsText,
      allergens: parsed.allergens,
      containsStatement: parsed.containsStatement,
      nutrition: parsed.nutrition,
      servingSize: parsed.servingSize,
      servingUnit: parsed.servingUnit || 'g',
      servingsPerContainer: parsed.servingsPerContainer,
      confidence: parsed.confidence || 0.7,
      detectedContent: parsed.detectedContent || [],
      warnings: parsed.warnings,
    };
  } catch (parseError) {
    console.error('Failed to parse Gemini response:', rawText);
    throw new Error(`Invalid JSON response from AI: ${parseError}`);
  }
}
