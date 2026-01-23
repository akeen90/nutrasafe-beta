/**
 * Image Processing Service
 * Supports both:
 * 1. Browser-based (free, @imgly/background-removal) - slower but no API costs
 * 2. Cloud Run rembg service (higher quality, faster) - requires deployment
 */

import { removeBackground } from '@imgly/background-removal';

// Cloud Run rembg service URL
const REMBG_SERVICE_URL = 'https://rembg-service-128150759188.us-central1.run.app';
// Cloud rembg is deployed and ready
const USE_CLOUD_REMBG = true;

export type ProcessingMethod = 'browser' | 'cloud';

export interface ProcessingResult {
  success: boolean;
  processedUrl?: string;
  blob?: Blob;
  error?: string;
  method?: ProcessingMethod;
}

/**
 * Remove background from an image URL using Cloud Run rembg service
 * Higher quality results, faster processing
 */
async function removeBackgroundCloud(imageUrl: string): Promise<ProcessingResult> {
  try {
    const response = await fetch(`${REMBG_SERVICE_URL}/remove-background`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ imageUrl }),
    });

    if (!response.ok) {
      throw new Error(`Cloud service error: ${response.status}`);
    }

    const result = await response.json();

    if (!result.success) {
      throw new Error(result.error || 'Unknown error');
    }

    // Convert base64 data URL to blob
    const base64Data = result.imageData.split(',')[1];
    const binaryData = atob(base64Data);
    const bytes = new Uint8Array(binaryData.length);
    for (let i = 0; i < binaryData.length; i++) {
      bytes[i] = binaryData.charCodeAt(i);
    }
    const blob = new Blob([bytes], { type: 'image/png' });
    const processedUrl = URL.createObjectURL(blob);

    return {
      success: true,
      processedUrl,
      blob,
      method: 'cloud',
    };
  } catch (error) {
    console.error('Cloud background removal error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
      method: 'cloud',
    };
  }
}

/**
 * Remove background from an image URL using browser-based processing
 * Runs entirely in browser - FREE, no API costs
 */
async function removeBackgroundBrowser(
  imageUrl: string,
  onProgress?: (progress: number) => void
): Promise<ProcessingResult> {
  try {
    // Fetch the image
    const response = await fetch(imageUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch image: ${response.status}`);
    }

    const imageBlob = await response.blob();

    // Process with background removal
    const resultBlob = await removeBackground(imageBlob, {
      progress: (_key, current, total) => {
        if (onProgress && total > 0) {
          onProgress(Math.round((current / total) * 100));
        }
      },
    });

    // Create object URL for preview
    const processedUrl = URL.createObjectURL(resultBlob);

    return {
      success: true,
      processedUrl,
      blob: resultBlob,
      method: 'browser',
    };
  } catch (error) {
    console.error('Browser background removal error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
      method: 'browser',
    };
  }
}

/**
 * Remove background from an image URL
 * Automatically chooses between cloud (if available) and browser-based processing
 *
 * @param imageUrl - URL of the image to process
 * @param onProgress - Progress callback (only works for browser-based method)
 * @param preferredMethod - Force a specific method ('browser' | 'cloud')
 */
export async function removeImageBackground(
  imageUrl: string,
  onProgress?: (progress: number) => void,
  preferredMethod?: ProcessingMethod
): Promise<ProcessingResult> {
  // Determine which method to use
  const useCloud = preferredMethod === 'cloud' || (USE_CLOUD_REMBG && preferredMethod !== 'browser');

  if (useCloud) {
    // Try cloud first, fall back to browser if it fails
    const cloudResult = await removeBackgroundCloud(imageUrl);
    if (cloudResult.success) {
      return cloudResult;
    }

    console.warn('Cloud processing failed, falling back to browser:', cloudResult.error);
    // Fall through to browser method
  }

  return removeBackgroundBrowser(imageUrl, onProgress);
}

/**
 * Check if Cloud Run rembg service is available
 */
export async function isCloudRembgAvailable(): Promise<boolean> {
  if (!USE_CLOUD_REMBG) return false;

  try {
    const response = await fetch(REMBG_SERVICE_URL, { method: 'GET' });
    const data = await response.json();
    return data.status === 'healthy';
  } catch {
    return false;
  }
}

/**
 * Convert blob to base64 data URL
 */
export function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

/**
 * Upload processed image to Firebase Storage and get URL
 */
export async function uploadProcessedImage(
  blob: Blob,
  foodId: string
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    // Convert to base64
    const dataUrl = await blobToDataUrl(blob);

    // Call Cloud Function to upload
    const response = await fetch(
      'https://us-central1-nutrasafe-705c7.cloudfunctions.net/uploadFoodImage',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          foodId,
          imageData: dataUrl,
          type: 'processed',
        }),
      }
    );

    const result = await response.json();

    if (result.success) {
      return { success: true, url: result.imageUrl };
    } else {
      return { success: false, error: result.error };
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}
