/**
 * SearchAPI Image Search Service
 * Uses SearchAPI.io's Google Images API to find product images
 * Better browser support than SerpApi - designed for client-side use
 */

const SEARCHAPI_KEY = import.meta.env.VITE_SEARCHAPI_KEY || '';

// Manufacturer domains to prioritize
const MANUFACTURER_DOMAINS = [
  'nestle.com', 'unilever.com', 'pepsico.com', 'cocacola.com', 'kellogs.com',
  'kraftheinz.com', 'danone.com', 'generalmills.com', 'mondelez.com',
  'mars.com', 'ferrero.com', 'heinz.com', 'campbells.com', 'kelloggs.co.uk',
  'walkers.co.uk', 'cadbury.co.uk', 'mcvities.co.uk', 'weetabix.co.uk',
  'muller.co.uk', 'warburtons.co.uk', 'hovis.co.uk', 'primula.co.uk',
];

// Retail domains to EXCLUDE
const EXCLUDED_DOMAINS = [
  'tesco.com', 'sainsburys.co.uk', 'asda.com', 'morrisons.com',
  'waitrose.com', 'ocado.com', 'amazon.co.uk', 'ebay.co.uk',
];

export interface SerpApiImageResult {
  url: string;
  thumbnail: string;
  title: string;
  domain: string;
  width?: number;
  height?: number;
  isManufacturerSite: boolean;
  qualityScore: number;
  disqualified: boolean;
  disqualifyReason?: string;
  source?: string;
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
 * Search for product images using SerpApi Google Lens API
 */
export async function searchSerpApiImages(
  productName: string,
  brandName?: string | null,
  maxResults: number = 10,
  sourceIndex?: string
): Promise<SerpApiImageResult[]> {
  // Build search query - keep it simple to maximize results
  let query = '';

  // Special handling for fast food database - search for restaurant outlet, not product
  if (sourceIndex === 'fast_foods_database') {
    // Extract restaurant name from product name
    // Examples: "KFC Original Recipe Chicken", "McDonald's Big Mac", "Subway 6 inch Turkey Sub"
    // We want to search for "KFC restaurant" or "McDonald's restaurant"

    if (brandName && brandName.trim()) {
      // Use brand name as the restaurant (e.g., "KFC", "McDonald's")
      query = `${brandName} restaurant outlet storefront`;
    } else {
      // Try to extract restaurant name from product name (first few words usually)
      const words = productName.split(' ');
      const restaurantName = words.slice(0, Math.min(2, words.length)).join(' ');
      query = `${restaurantName} restaurant outlet storefront`;
    }

    console.log(`🍔 Fast food mode: Original "${brandName} ${productName}" → Restaurant search "${query}"`);
  } else {
    // Normal product search
    if (brandName && brandName.trim()) {
      query = `${brandName} ${productName}`;
    } else {
      query = productName;
    }

    // Clean up the query to remove common noise words that hurt search results
    query = query
      .replace(/\b(zero sugar|sugar free|no sugar|caffeine free)\b/gi, '') // Remove sugar/caffeine descriptors
      .replace(/\b\d+ml\b/gi, '') // Remove size (500ml, 330ml, etc.)
      .replace(/\b\d+g\b/gi, '') // Remove weight (100g, etc.)
      .replace(/\bpack of \d+\b/gi, '') // Remove pack sizes
      .replace(/\bmultipack\b/gi, '') // Remove multipack
      .replace(/\s+/g, ' ') // Clean up extra spaces
      .trim();

    console.log(`Original: "${brandName} ${productName}" → Cleaned: "${query}"`);
  }

  try {
    // Use SearchAPI.io Google Images
    console.log('[searchSerpApiImages] About to call searchGoogleImagesViaSearchAPI with query:', query);
    const results = await searchGoogleImagesViaSearchAPI(query, maxResults);
    console.log('[searchSerpApiImages] Got results back:', results.length);
    return results;
  } catch (error) {
    console.error('[searchSerpApiImages] SearchAPI search error:', error);
    throw error;
  }
}

/**
 * Use SearchAPI.io's Google Images API
 */
async function searchGoogleImagesViaSearchAPI(
  query: string,
  maxResults: number
): Promise<SerpApiImageResult[]> {
  console.log('[searchGoogleImagesViaSearchAPI] ENTRY - query:', query, 'maxResults:', maxResults);
  console.log('[searchGoogleImagesViaSearchAPI] API KEY exists:', SEARCHAPI_KEY.length > 0);

  const params = new URLSearchParams({
    api_key: SEARCHAPI_KEY,
    engine: 'google_images',
    q: query,
    hl: 'en',
    gl: 'uk',
    num: String(Math.min(maxResults, 20)), // SearchAPI supports up to 20
  });

  console.log('[searchGoogleImagesViaSearchAPI] URL:', `https://www.searchapi.io/api/v1/search?${params}`);

  const response = await fetch(
    `https://www.searchapi.io/api/v1/search?${params}`,
    {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    }
  );

  if (!response.ok) {
    let errorMsg = 'SearchAPI request failed';
    try {
      const error = await response.json();
      console.error('SearchAPI error response:', error);
      errorMsg = error.error || error.message || errorMsg;
    } catch (e) {
      errorMsg = `HTTP ${response.status}: ${response.statusText}`;
    }
    throw new Error(errorMsg);
  }

  const data = await response.json();

  console.log('SearchAPI response for query:', query);
  console.log('Response keys:', Object.keys(data));
  console.log('Number of results:', data.images?.length || 0);

  // SearchAPI returns "images" array for Google Images engine
  const imagesResults = data.images || [];

  if (imagesResults.length === 0) {
    console.warn('No images found in SearchAPI response:', data);
  }

  // Convert SearchAPI format to our format
  const images = imagesResults.map((item: any, index: number) => ({
    ...item,
    position: index + 1,
  }));

  const results: SerpApiImageResult[] = images.map((item: any) => {
    // SearchAPI Google Images format (verified from API response):
    // {
    //   position: number,
    //   title: string,
    //   source: { name: string, link: string },
    //   original: { link: string, width: number, height: number },
    //   thumbnail: string
    // }
    const url = item.original?.link || item.thumbnail || '';
    let domain = '';

    try {
      // Extract domain from source.name or source.link
      domain = item.source?.name || new URL(item.source?.link || url).hostname.replace('www.', '');
    } catch (e) {
      domain = '';
    }

    const isManufacturer = MANUFACTURER_DOMAINS.some(d => domain.includes(d));
    const isExcluded = EXCLUDED_DOMAINS.some(d => domain.includes(d));

    let qualityScore = 50;
    if (isManufacturer) qualityScore += 30;
    if (item.position <= 3) qualityScore += 10;
    if (item.original?.width > 800) qualityScore += 10;
    if (item.original?.height > 800) qualityScore += 10;

    return {
      url,
      thumbnail: item.thumbnail || url,
      title: item.title || '',
      domain,
      width: item.original?.width,
      height: item.original?.height,
      isManufacturerSite: isManufacturer,
      qualityScore,
      disqualified: isExcluded,
      disqualifyReason: isExcluded ? `Retailer site (${domain})` : undefined,
      source: item.source?.name,
    };
  });

  return results.sort((a, b) => b.qualityScore - a.qualityScore);
}

/**
 * Analyze image for white/transparent background and detect unwanted elements
 * Uses browser canvas to analyze the image
 * STRICT FILTERING: Only accepts clean product shots on white/transparent backgrounds
 * Rejects: colored backgrounds, text overlays, people, promotional graphics
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

        onProgress?.(30);

        // Get image data
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const pixels = imageData.data;
        const totalPixels = pixels.length / 4;

        // ========== EDGE ANALYSIS (Background Detection) ==========
        // Sample edges where background should be visible (top, bottom, left, right strips)
        const edgeWidth = Math.floor(canvas.width * 0.1); // 10% from each edge
        const edgeHeight = Math.floor(canvas.height * 0.1);

        let edgeWhiteCount = 0;
        let edgeTransparentCount = 0;
        let edgeColoredCount = 0;
        let edgeSkinToneCount = 0;
        let edgeSampleCount = 0;

        // Sample top and bottom strips
        for (let y = 0; y < edgeHeight; y++) {
          for (let x = 0; x < canvas.width; x += 2) {
            const idx = (y * canvas.width + x) * 4;
            analyzePixelForBackground(pixels, idx);
          }
        }
        for (let y = canvas.height - edgeHeight; y < canvas.height; y++) {
          for (let x = 0; x < canvas.width; x += 2) {
            const idx = (y * canvas.width + x) * 4;
            analyzePixelForBackground(pixels, idx);
          }
        }
        // Sample left and right strips
        for (let y = edgeHeight; y < canvas.height - edgeHeight; y += 2) {
          for (let x = 0; x < edgeWidth; x++) {
            const idx = (y * canvas.width + x) * 4;
            analyzePixelForBackground(pixels, idx);
          }
          for (let x = canvas.width - edgeWidth; x < canvas.width; x++) {
            const idx = (y * canvas.width + x) * 4;
            analyzePixelForBackground(pixels, idx);
          }
        }

        function analyzePixelForBackground(pixels: Uint8ClampedArray, idx: number) {
          const r = pixels[idx];
          const g = pixels[idx + 1];
          const b = pixels[idx + 2];
          const a = pixels[idx + 3];
          edgeSampleCount++;

          // Transparent pixel (alpha < 200)
          if (a < 200) {
            edgeTransparentCount++;
            return;
          }

          // White/near-white pixel (all channels > 240)
          if (r > 240 && g > 240 && b > 240) {
            edgeWhiteCount++;
            return;
          }

          // Skin tone detection (could indicate people in image)
          if (isSkinTone(r, g, b)) {
            edgeSkinToneCount++;
            edgeColoredCount++;
            return;
          }

          // Colored background
          edgeColoredCount++;
        }

        function isSkinTone(r: number, g: number, b: number): boolean {
          // Skin tone ranges for various skin colors
          // Light skin: R > G > B, R > 180, G > 120, B > 80
          // Medium skin: R > G > B, R > 120, G > 80, B > 50
          // Dark skin: R > G > B, similar ratios
          if (r > g && g > b) {
            const rgRatio = r / g;
            const rbRatio = r / b;
            // Skin typically has R/G ratio between 1.1 and 1.6
            if (rgRatio > 1.05 && rgRatio < 1.7 && rbRatio > 1.2 && rbRatio < 2.5) {
              // Additional check: brightness in skin range
              const brightness = (r + g + b) / 3;
              if (brightness > 60 && brightness < 220) {
                return true;
              }
            }
          }
          return false;
        }

        onProgress?.(50);

        // Calculate background type
        const edgeWhiteRatio = edgeSampleCount > 0 ? edgeWhiteCount / edgeSampleCount : 0;
        const edgeTransparentRatio = edgeSampleCount > 0 ? edgeTransparentCount / edgeSampleCount : 0;
        const edgeCleanRatio = edgeWhiteRatio + edgeTransparentRatio;
        const edgeSkinRatio = edgeSampleCount > 0 ? edgeSkinToneCount / edgeSampleCount : 0;

        const hasWhiteBackground = edgeWhiteRatio > 0.7; // 70%+ of edges are white
        const hasTransparentBackground = edgeTransparentRatio > 0.5; // 50%+ transparent
        const hasCleanBackground = edgeCleanRatio > 0.75; // 75%+ white OR transparent
        const hasSkinTones = edgeSkinRatio > 0.05; // More than 5% skin tones = likely has people

        onProgress?.(60);

        // ========== TEXT/OVERLAY DETECTION ==========
        const overlayTypes: string[] = [];
        let hasOverlay = false;

        // Detect text by looking for high contrast edges (sharp transitions)
        let highContrastEdges = 0;
        for (let y = 1; y < canvas.height - 1; y += 2) {
          for (let x = 1; x < canvas.width - 1; x += 2) {
            const idx = (y * canvas.width + x) * 4;
            const brightness = (pixels[idx] + pixels[idx + 1] + pixels[idx + 2]) / 3;

            // Check adjacent pixels for sharp contrast
            const rightIdx = idx + 4;
            const downIdx = idx + canvas.width * 4;

            if (rightIdx < pixels.length && downIdx < pixels.length) {
              const rightBrightness = (pixels[rightIdx] + pixels[rightIdx + 1] + pixels[rightIdx + 2]) / 3;
              const downBrightness = (pixels[downIdx] + pixels[downIdx + 1] + pixels[downIdx + 2]) / 3;

              // Sharp edge = brightness difference > 100
              if (Math.abs(brightness - rightBrightness) > 100 || Math.abs(brightness - downBrightness) > 100) {
                highContrastEdges++;
              }
            }
          }
        }

        const highContrastRatio = highContrastEdges / (totalPixels / 4);

        // Text typically creates many high-contrast edges (letters)
        // Product images have fewer sharp edges
        if (highContrastRatio > 0.08) { // More than 8% high contrast = likely text
          hasOverlay = true;
          overlayTypes.push('Text detected');
        }

        onProgress?.(75);

        // Detect promotional graphics (bright saturated colors in large areas)
        let brightSaturatedCount = 0;
        let redCount = 0;
        let yellowCount = 0;

        for (let i = 0; i < pixels.length; i += 16) { // Sample every 4th pixel
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];

          const maxC = Math.max(r, g, b);
          const minC = Math.min(r, g, b);
          const saturation = maxC > 0 ? (maxC - minC) / maxC : 0;
          const brightness = (r + g + b) / 3;

          // Bright saturated colors (promotional banners)
          if (saturation > 0.5 && brightness > 150) {
            brightSaturatedCount++;

            // Count promotional colors (red, yellow - common in "SALE", "NEW", etc)
            if (r > 200 && g < 100 && b < 100) redCount++;
            if (r > 200 && g > 180 && b < 100) yellowCount++;
          }
        }

        const brightSaturatedRatio = brightSaturatedCount / (pixels.length / 16);
        const promotionalColorRatio = (redCount + yellowCount) / (pixels.length / 16);

        if (brightSaturatedRatio > 0.1) { // 10%+ bright saturated = promotional graphics
          hasOverlay = true;
          overlayTypes.push('Promotional graphics');
        }

        if (promotionalColorRatio > 0.02) { // 2%+ red/yellow = promotional text/banner
          hasOverlay = true;
          if (!overlayTypes.includes('Promotional banner')) {
            overlayTypes.push('Promotional banner');
          }
        }

        // Detect people (skin tone in center of image)
        let centerSkinCount = 0;
        let centerSampleCount = 0;
        const centerStartX = Math.floor(canvas.width * 0.2);
        const centerEndX = Math.floor(canvas.width * 0.8);
        const centerStartY = Math.floor(canvas.height * 0.2);
        const centerEndY = Math.floor(canvas.height * 0.8);

        for (let y = centerStartY; y < centerEndY; y += 3) {
          for (let x = centerStartX; x < centerEndX; x += 3) {
            const idx = (y * canvas.width + x) * 4;
            centerSampleCount++;
            if (isSkinTone(pixels[idx], pixels[idx + 1], pixels[idx + 2])) {
              centerSkinCount++;
            }
          }
        }

        const centerSkinRatio = centerSampleCount > 0 ? centerSkinCount / centerSampleCount : 0;
        const hasPeople = hasSkinTones || centerSkinRatio > 0.03; // 3%+ skin in center = likely has people

        if (hasPeople) {
          hasOverlay = true;
          overlayTypes.push('Person/hand detected');
        }

        onProgress?.(90);

        // ========== CALCULATE QUALITY SCORE ==========
        // STRICT scoring - only clean product shots get high scores
        let qualityScore = 0;

        // Background quality (max 50 points)
        if (hasWhiteBackground) {
          qualityScore += 50; // Pure white background = best
        } else if (hasTransparentBackground) {
          qualityScore += 45; // Transparent = nearly as good
        } else if (hasCleanBackground) {
          qualityScore += 30; // Mostly clean
        } else {
          qualityScore += 0; // Colored background = not suitable
        }

        // Clean from overlays (max 40 points)
        if (!hasOverlay) {
          qualityScore += 40;
        } else {
          // Deduct based on severity
          if (overlayTypes.includes('Text detected')) qualityScore -= 20;
          if (overlayTypes.includes('Promotional graphics')) qualityScore -= 15;
          if (overlayTypes.includes('Promotional banner')) qualityScore -= 15;
          if (overlayTypes.includes('Person/hand detected')) qualityScore -= 30;
        }

        // No people bonus (max 10 points)
        if (!hasPeople) {
          qualityScore += 10;
        }

        // Ensure score is 0-100
        qualityScore = Math.max(0, Math.min(100, qualityScore));

        const isCleanProductShot = hasCleanBackground && !hasOverlay && !hasPeople;

        onProgress?.(100);

        resolve({
          hasWhiteBackground: hasWhiteBackground || hasTransparentBackground,
          backgroundConfidence: Math.round(edgeCleanRatio * 100),
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

    img.src = imageUrl;
  });
}

/**
 * Check if SearchAPI is configured
 */
export function isSerpApiConfigured(): boolean {
  return SEARCHAPI_KEY.length > 0;
}

/**
 * Get configuration help message
 */
export function getConfigurationHelp(): string {
  return `To use SearchAPI Image Search, you need to:

1. Get a SearchAPI API Key:
   - Go to https://www.searchapi.io/
   - Sign up for an account
   - Copy your API key from the dashboard

2. Update .env.local:
   - Add: VITE_SEARCHAPI_KEY=your_api_key_here

Note: SearchAPI has a free tier of 100 searches/month, then paid plans starting at $20/month.`;
}
