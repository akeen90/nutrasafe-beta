/**
 * Google Image Search Service
 * Find official white background product images from manufacturer sites
 */

// Google Custom Search API Configuration
// IMPORTANT: DO NOT commit API keys to git!
// These should be loaded from environment variables or a secure config
// Get your API key from: https://console.cloud.google.com/apis/credentials
// Get your Search Engine ID from: https://programmablesearchengine.google.com/

// For Vite, use import.meta.env
// Create a .env.local file (git-ignored) with:
// VITE_GOOGLE_API_KEY=your_api_key_here
// VITE_GOOGLE_CX=your_search_engine_id_here

const GOOGLE_API_KEY = import.meta.env.VITE_GOOGLE_API_KEY || '';
const GOOGLE_CX = import.meta.env.VITE_GOOGLE_CX || '';

// Manufacturer domains to prioritize
const MANUFACTURER_DOMAINS = [
  'nestle.com', 'unilever.com', 'pepsico.com', 'cocacola.com', 'kellogs.com',
  'kraftheinz.com', 'danone.com', 'generalmills.com', 'mondelez.com',
  'mars.com', 'ferrero.com', 'heinz.com', 'campbells.com', 'kelloggs.co.uk',
  'walkers.co.uk', 'cadbury.co.uk', 'mcvities.co.uk', 'weetabix.co.uk',
  'muller.co.uk', 'warburtons.co.uk', 'hovis.co.uk', 'primula.co.uk',
];

// Retail domains to EXCLUDE (often have overlays)
const EXCLUDED_DOMAINS = [
  'tesco.com', 'sainsburys.co.uk', 'asda.com', 'morrisons.com',
  'waitrose.com', 'ocado.com', 'amazon.co.uk', 'ebay.co.uk',
];

export interface GoogleImageResult {
  url: string;
  thumbnail: string;
  title: string;
  domain: string;
  width: number;
  height: number;
  fileSize?: number;
  isManufacturerSite: boolean;
  qualityScore: number; // 0-100
  disqualified: boolean;
  disqualifyReason?: string;
}

export interface ImageAnalysisResult {
  hasWhiteBackground: boolean;
  backgroundConfidence: number; // 0-100
  hasOverlay: boolean;
  overlayTypes: string[];
  isCleanProductShot: boolean;
  qualityScore: number;
}

/**
 * Search Google Images for a product
 */
export async function searchGoogleImages(
  productName: string,
  brandName?: string | null,
  maxResults: number = 10
): Promise<GoogleImageResult[]> {
  // Build a more specific query
  let query = '';

  // Always start with brand name if available (most important)
  if (brandName && brandName.trim()) {
    query = `${brandName} ${productName}`;
  } else {
    query = productName;
  }

  // Add VERY specific keywords to find actual food/drink product packaging
  // Include terms that only real food products would have
  // Exclude bulk/wholesale and non-food items
  const searchQuery = `${query} product "nutrition facts" OR "ingredients" OR "barcode" OR "500ml" OR "330ml" OR "100g" white background -bulk -pallet -wholesale -case -toy -merchandise -costume -clothing -game -collectible -sketch -drawing`;

  const params = new URLSearchParams({
    key: GOOGLE_API_KEY,
    cx: GOOGLE_CX,
    q: searchQuery,
    searchType: 'image',
    num: String(Math.min(maxResults, 10)), // Max 10 per request
    imgSize: 'large', // Prefer large images
    imgType: 'photo', // Photos only, not clipart
    safe: 'active',
    // Image color filters for white background
    imgDominantColor: 'white',
    imgColorType: 'color',
  });

  try {
    const response = await fetch(
      `https://www.googleapis.com/customsearch/v1?${params}`
    );

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'Google API request failed');
    }

    const data = await response.json();
    const items = data.items || [];

    const results: GoogleImageResult[] = items.map((item: any) => {
      const url = item.link;
      const domain = new URL(url).hostname.replace('www.', '');
      const isManufacturer = MANUFACTURER_DOMAINS.some(d => domain.includes(d));
      const isExcluded = EXCLUDED_DOMAINS.some(d => domain.includes(d));

      let qualityScore = 50; // Base score
      if (isManufacturer) qualityScore += 30;
      if (item.image?.width > 800) qualityScore += 10;
      if (item.image?.height > 800) qualityScore += 10;

      return {
        url,
        thumbnail: item.image?.thumbnailLink || url,
        title: item.title || '',
        domain,
        width: item.image?.width || 0,
        height: item.image?.height || 0,
        fileSize: item.image?.byteSize,
        isManufacturerSite: isManufacturer,
        qualityScore,
        disqualified: isExcluded,
        disqualifyReason: isExcluded ? `Retailer site (${domain})` : undefined,
      };
    });

    // Sort by quality score (manufacturer sites first, then by dimensions)
    return results.sort((a, b) => b.qualityScore - a.qualityScore);
  } catch (error) {
    console.error('Google Image Search error:', error);
    throw error;
  }
}

/**
 * Analyze image for white background and overlays
 * Uses browser canvas to analyze the image
 */
export async function analyzeImageQuality(
  imageUrl: string,
  onProgress?: (percent: number) => void
): Promise<ImageAnalysisResult> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';

    img.onload = () => {
      try {
        onProgress?.(20);

        // Create canvas and draw image
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d', { willReadFrequently: true });
        if (!ctx) {
          throw new Error('Could not get canvas context');
        }

        // Scale down for faster analysis (max 400px)
        const scale = Math.min(1, 400 / Math.max(img.width, img.height));
        canvas.width = img.width * scale;
        canvas.height = img.height * scale;
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

        onProgress?.(40);

        // Get image data
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const pixels = imageData.data;

        // Analyze edges for background detection
        const edgePixels: number[] = [];
        const edgeThickness = Math.floor(Math.min(canvas.width, canvas.height) * 0.1);

        // Sample edges
        for (let x = 0; x < canvas.width; x++) {
          for (let y = 0; y < edgeThickness; y++) {
            const idx = (y * canvas.width + x) * 4;
            edgePixels.push(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
          }
          for (let y = canvas.height - edgeThickness; y < canvas.height; y++) {
            const idx = (y * canvas.width + x) * 4;
            edgePixels.push(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
          }
        }

        for (let y = edgeThickness; y < canvas.height - edgeThickness; y++) {
          for (let x = 0; x < edgeThickness; x++) {
            const idx = (y * canvas.width + x) * 4;
            edgePixels.push(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
          }
          for (let x = canvas.width - edgeThickness; x < canvas.width; x++) {
            const idx = (y * canvas.width + x) * 4;
            edgePixels.push(pixels[idx], pixels[idx + 1], pixels[idx + 2]);
          }
        }

        onProgress?.(60);

        // Calculate average edge color
        const avgR = edgePixels.filter((_, i) => i % 3 === 0).reduce((a, b) => a + b, 0) / (edgePixels.length / 3);
        const avgG = edgePixels.filter((_, i) => i % 3 === 1).reduce((a, b) => a + b, 0) / (edgePixels.length / 3);
        const avgB = edgePixels.filter((_, i) => i % 3 === 2).reduce((a, b) => a + b, 0) / (edgePixels.length / 3);

        // Check if background is white (all RGB > 240)
        const isWhite = avgR > 240 && avgG > 240 && avgB > 240;
        const whiteness = (avgR + avgG + avgB) / (3 * 255) * 100;

        onProgress?.(80);

        // Detect overlays by looking for text-like patterns
        // Check for high contrast regions that might be text
        const overlayTypes: string[] = [];
        let hasOverlay = false;

        // Simple overlay detection: look for dark text on white background
        let darkPixelCount = 0;
        for (let i = 0; i < pixels.length; i += 4) {
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];
          const brightness = (r + g + b) / 3;

          if (brightness < 100) darkPixelCount++;
        }

        const darkPixelRatio = darkPixelCount / (pixels.length / 4);

        // If more than 5% dark pixels, likely has overlay text
        if (darkPixelRatio > 0.05 && darkPixelRatio < 0.3) {
          hasOverlay = true;
          overlayTypes.push('Possible text overlay');
        }

        // Check for colorful overlays (promotional graphics)
        let colorfulPixelCount = 0;
        for (let i = 0; i < pixels.length; i += 4) {
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];

          // Check if color is saturated (not grayscale)
          const maxChannel = Math.max(r, g, b);
          const minChannel = Math.min(r, g, b);
          const saturation = maxChannel - minChannel;

          if (saturation > 50 && maxChannel > 100 && maxChannel < 220) {
            colorfulPixelCount++;
          }
        }

        const colorfulRatio = colorfulPixelCount / (pixels.length / 4);
        if (colorfulRatio > 0.15) {
          hasOverlay = true;
          overlayTypes.push('Colorful graphics/banner');
        }

        onProgress?.(100);

        // Calculate quality score
        let qualityScore = 0;
        if (isWhite) qualityScore += 40;
        qualityScore += whiteness * 0.3; // Up to 30 points for whiteness
        if (!hasOverlay) qualityScore += 30;

        const isCleanProductShot = isWhite && !hasOverlay && whiteness > 90;

        resolve({
          hasWhiteBackground: isWhite,
          backgroundConfidence: Math.round(whiteness),
          hasOverlay,
          overlayTypes,
          isCleanProductShot,
          qualityScore: Math.round(qualityScore),
        });
      } catch (error) {
        reject(error);
      }
    };

    img.onerror = () => {
      reject(new Error('Failed to load image for analysis'));
    };

    // Use proxy to avoid CORS issues
    img.src = imageUrl.startsWith('data:') ? imageUrl : `${imageUrl}`;
  });
}

/**
 * Check if Google API is configured
 */
export function isGoogleAPIConfigured(): boolean {
  return (
    GOOGLE_API_KEY !== 'YOUR_GOOGLE_API_KEY' &&
    GOOGLE_CX !== 'YOUR_CUSTOM_SEARCH_ENGINE_ID' &&
    GOOGLE_API_KEY.length > 0 &&
    GOOGLE_CX.length > 0
  );
}

/**
 * Get configuration help message
 */
export function getConfigurationHelp(): string {
  return `To use Google Image Search, you need to:

1. Get a Google API Key:
   - Go to https://console.cloud.google.com/apis/credentials
   - Create a new API key
   - Enable "Custom Search API" for your project

2. Create a Custom Search Engine:
   - Go to https://programmablesearchengine.google.com/
   - Create a new search engine
   - Enable "Image Search"
   - Set "Search the entire web" or add specific manufacturer sites
   - Copy your Search Engine ID (CX)

3. Update googleImageService.ts:
   - Replace GOOGLE_API_KEY with your API key
   - Replace GOOGLE_CX with your Search Engine ID

Note: Google Custom Search API has a free tier of 100 searches/day.`;
}
