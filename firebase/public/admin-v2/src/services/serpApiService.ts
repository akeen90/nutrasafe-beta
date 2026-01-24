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
  maxResults: number = 10
): Promise<SerpApiImageResult[]> {
  // Build search query
  let query = '';

  if (brandName && brandName.trim()) {
    query = `${brandName} ${productName}`;
  } else {
    query = productName;
  }

  // Add terms to find clean product shots (but keep it simple to get results)
  // Don't make it too restrictive or we'll get zero results
  query += ' white background';

  try {
    // Use SearchAPI.io Google Images
    return await searchGoogleImagesViaSearchAPI(query, maxResults);
  } catch (error) {
    console.error('SearchAPI search error:', error);
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
  const params = new URLSearchParams({
    api_key: SEARCHAPI_KEY,
    engine: 'google_images',
    q: query,
    hl: 'en',
    gl: 'uk',
    num: String(Math.min(maxResults, 20)), // SearchAPI supports up to 20
  });

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
  console.log('Number of results:', data.images_results?.length || 0);

  // SearchAPI returns images_results array for Google Images engine
  const imagesResults = data.images_results || [];

  if (imagesResults.length === 0) {
    console.warn('No images_results found in SearchAPI response:', data);
  }

  // Convert SearchAPI format to our format
  const images = imagesResults.map((item: any, index: number) => ({
    ...item,
    position: index + 1,
  }));

  const results: SerpApiImageResult[] = images.map((item: any) => {
    // SearchAPI Google Images format:
    // { position, thumbnail, source (string domain), title, link (page url),
    //   original (image url string), original_width, original_height }
    const url = item.original || item.link || item.thumbnail || '';
    let domain = '';

    try {
      // source is just the domain string, or extract from link
      domain = item.source || new URL(item.link || url).hostname.replace('www.', '');
    } catch (e) {
      domain = '';
    }

    const isManufacturer = MANUFACTURER_DOMAINS.some(d => domain.includes(d));
    const isExcluded = EXCLUDED_DOMAINS.some(d => domain.includes(d));

    let qualityScore = 50;
    if (isManufacturer) qualityScore += 30;
    if (item.position <= 3) qualityScore += 10;
    if (item.original_width > 800) qualityScore += 10;
    if (item.original_height > 800) qualityScore += 10;

    return {
      url,
      thumbnail: item.thumbnail || url,
      title: item.title || '',
      domain,
      width: item.original_width,
      height: item.original_height,
      isManufacturerSite: isManufacturer,
      qualityScore,
      disqualified: isExcluded,
      disqualifyReason: isExcluded ? `Retailer site (${domain})` : undefined,
      source: item.source,
    };
  });

  return results.sort((a, b) => b.qualityScore - a.qualityScore);
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
