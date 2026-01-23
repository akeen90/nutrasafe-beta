/**
 * Image Processing Page
 * Batch process food images: fetch from OpenFoodFacts, remove backgrounds, upload to Firebase
 */

import React, { useState, useCallback, useEffect, useRef } from 'react';
import { removeImageBackground, isCloudRembgAvailable } from '../services/imageProcessingService';
import { ALGOLIA_INDICES } from '../types';

// Algolia config
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e'; // Search-only key

interface FoodImage {
  id: string;
  objectID: string;
  name: string;
  brandName: string | null;
  barcode: string | null;
  currentImageUrl: string | null;
  offImageUrl: string | null;
  processedBlob: Blob | null;
  status: 'pending' | 'fetching_off' | 'processing' | 'uploading' | 'completed' | 'failed' | 'no_image' | 'skipped';
  error?: string;
  sourceIndex: string;
  selected: boolean;
}

interface ProcessingStats {
  total: number;
  withBarcode: number;
  completed: number;
  failed: number;
  noImage: number;
  processing: number;
  skipped: number;
}

// Upload to Firebase via Cloud Function
async function uploadToFirebase(
  blob: Blob,
  foodId: string,
  sourceIndex: string
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    console.log(`[Upload] Starting upload for ${foodId} from ${sourceIndex}`);

    const base64 = await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });

    const response = await fetch(
      'https://us-central1-nutrasafe-705c7.cloudfunctions.net/uploadFoodImage',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          foodId,
          objectID: foodId,
          imageData: base64,
          sourceIndex,
        }),
      }
    );

    const result = await response.json();
    console.log(`[Upload] Result for ${foodId}:`, result);
    return result;
  } catch (error) {
    console.error(`[Upload] Error for ${foodId}:`, error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export const ImageProcessingPage: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [foods, setFoods] = useState<FoodImage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingProgress, setLoadingProgress] = useState(0);
  const [loadingMessage, setLoadingMessage] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [cloudAvailable, setCloudAvailable] = useState(false);
  const [filter, setFilter] = useState<'all' | 'with_barcode' | 'no_image' | 'pending' | 'selected'>('with_barcode');
  const [currentPage, setCurrentPage] = useState(0);
  const [stats, setStats] = useState<ProcessingStats>({
    total: 0, withBarcode: 0, completed: 0, failed: 0, noImage: 0, processing: 0, skipped: 0
  });
  const [processingLog, setProcessingLog] = useState<string[]>([]);
  // Default to all indices selected
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(new Set(ALGOLIA_INDICES));
  const [showIndexSelector, setShowIndexSelector] = useState(true);

  const pauseRef = useRef(false);
  const abortRef = useRef(false);
  const ITEMS_PER_PAGE = 100;

  // Image preview modal state
  const [previewImage, setPreviewImage] = useState<{ url: string; title: string } | null>(null);

  const addLog = (message: string) => {
    console.log(message);
    setProcessingLog(prev => [...prev.slice(-50), `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  // Check cloud service
  useEffect(() => {
    isCloudRembgAvailable().then(available => {
      setCloudAvailable(available);
      addLog(`Cloud rembg available: ${available}`);
    });
  }, []);

  // ESC key to close preview modal
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && previewImage) {
        setPreviewImage(null);
      }
    };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [previewImage]);

  // Load foods using Algolia search (simpler than browse)
  const loadFoodsFromIndices = useCallback(async () => {
    if (selectedIndices.size === 0) {
      addLog('No indices selected');
      return;
    }

    setIsLoading(true);
    setShowIndexSelector(false);
    setLoadingProgress(0);
    addLog('Starting to load foods from Algolia...');

    const allFoods: FoodImage[] = [];
    const seenBarcodes = new Set<string>();
    const indicesToLoad = Array.from(selectedIndices);

    try {
      for (let i = 0; i < indicesToLoad.length; i++) {
        const indexName = indicesToLoad[i];
        setLoadingMessage(`Loading ${indexName}...`);
        setLoadingProgress(Math.round((i / indicesToLoad.length) * 100));
        addLog(`Loading index: ${indexName}`);

        // Use search with empty query to get all records (up to 1000 per index)
        const url = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes/${indexName}/query`;

        try {
          const response = await fetch(url, {
            method: 'POST',
            headers: {
              'X-Algolia-Application-Id': ALGOLIA_APP_ID,
              'X-Algolia-API-Key': ALGOLIA_SEARCH_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              query: '',
              hitsPerPage: 1000,
              attributesToRetrieve: ['objectID', 'name', 'foodName', 'brandName', 'brand', 'barcode', 'barcodes', 'imageUrl'],
            }),
          });

          if (!response.ok) {
            addLog(`Error loading ${indexName}: ${response.status}`);
            continue;
          }

          const data = await response.json();
          const hits = data.hits || [];
          addLog(`${indexName}: ${hits.length} records`);

          for (const hit of hits) {
            const barcode = hit.barcode || hit.barcodes?.[0] || null;

            // Skip duplicates based on barcode
            if (barcode && seenBarcodes.has(barcode)) {
              continue;
            }
            if (barcode) {
              seenBarcodes.add(barcode);
            }

            allFoods.push({
              id: `${indexName}:${hit.objectID}`,
              objectID: hit.objectID,
              name: hit.name || hit.foodName || 'Unknown',
              brandName: hit.brandName || hit.brand || null,
              barcode,
              currentImageUrl: hit.imageUrl || null,
              offImageUrl: null,
              processedBlob: null,
              status: 'pending',
              sourceIndex: indexName,
              selected: false,
            });
          }
        } catch (err) {
          addLog(`Error loading ${indexName}: ${err}`);
        }
      }

      addLog(`Total foods loaded: ${allFoods.length}`);
      addLog(`Foods with barcodes: ${allFoods.filter(f => f.barcode).length}`);

      setFoods(allFoods);
      updateStats(allFoods);
      setLoadingProgress(100);
      setLoadingMessage('');
    } catch (error) {
      addLog(`Error loading foods: ${error}`);
    } finally {
      setIsLoading(false);
    }
  }, [selectedIndices]);

  const updateStats = (foodList: FoodImage[]) => {
    setStats({
      total: foodList.length,
      withBarcode: foodList.filter(f => f.barcode).length,
      completed: foodList.filter(f => f.status === 'completed').length,
      failed: foodList.filter(f => f.status === 'failed').length,
      noImage: foodList.filter(f => f.status === 'no_image').length,
      processing: foodList.filter(f => ['fetching_off', 'processing', 'uploading'].includes(f.status)).length,
      skipped: foodList.filter(f => f.status === 'skipped').length,
    });
  };

  // Toggle selection
  const toggleSelect = (id: string) => {
    setFoods(prev => prev.map(f => f.id === id ? { ...f, selected: !f.selected } : f));
  };

  const selectAll = () => {
    const filtered = getFilteredFoods();
    const ids = new Set(filtered.map(f => f.id));
    setFoods(prev => prev.map(f => ids.has(f.id) ? { ...f, selected: true } : f));
  };

  const deselectAll = () => {
    setFoods(prev => prev.map(f => ({ ...f, selected: false })));
  };

  // Fetch OFF image with quality validation
  const fetchOFFImage = async (barcode: string): Promise<string | null> => {
    const endpoints = [
      `https://uk.openfoodfacts.org/api/v0/product/${barcode}.json`,
      `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`,
    ];

    for (const url of endpoints) {
      try {
        const response = await fetch(url);
        if (!response.ok) continue;

        const data = await response.json();
        if (data.status === 1 && data.product) {
          const product = data.product;

          // Check image dimensions from OFF metadata
          const frontW = product.images?.front?.sizes?.full?.w || product.images?.front?.sizes?.['400']?.w || 0;
          const frontH = product.images?.front?.sizes?.full?.h || product.images?.front?.sizes?.['400']?.h || 0;

          // Skip if image is too small (likely cropped or low quality)
          if (frontW > 0 && frontH > 0) {
            const minDimension = Math.min(frontW, frontH);
            const maxDimension = Math.max(frontW, frontH);
            const aspectRatio = maxDimension / minDimension;

            // Skip images that are:
            // - Too small (under 200px on shortest side)
            // - Too narrow/cropped (aspect ratio > 2.5 means likely a cropped/partial shot)
            if (minDimension < 200) {
              addLog(`Skipping ${barcode}: image too small (${frontW}x${frontH})`);
              continue;
            }
            if (aspectRatio > 2.5) {
              addLog(`Skipping ${barcode}: bad aspect ratio ${aspectRatio.toFixed(1)} (likely cropped)`);
              continue;
            }
          }

          // Prefer selected_images (curated) over raw uploads
          // Also prefer larger versions for quality
          const frontImage =
            product.selected_images?.front?.display?.en ||
            product.selected_images?.front?.display?.uk ||
            product.selected_images?.front?.url?.en ||
            product.selected_images?.front?.url?.uk ||
            product.image_front_url ||
            product.image_url;

          if (frontImage) {
            // Final validation: load the image and check it's reasonable
            try {
              const imgCheck = await fetch(frontImage, { method: 'HEAD' });
              if (!imgCheck.ok) {
                addLog(`Skipping ${barcode}: image URL returned ${imgCheck.status}`);
                continue;
              }
              const contentLength = imgCheck.headers.get('content-length');
              // Skip very small files (likely placeholder or error images)
              if (contentLength && parseInt(contentLength) < 5000) {
                addLog(`Skipping ${barcode}: image file too small (${contentLength} bytes)`);
                continue;
              }
            } catch {
              // If HEAD fails, still try to use the image
            }

            addLog(`Found valid OFF image for ${barcode} (${frontW}x${frontH})`);
            return frontImage;
          }
        }
      } catch {
        continue;
      }
    }
    return null;
  };

  // Process single food
  const processFood = async (food: FoodImage): Promise<FoodImage> => {
    if (abortRef.current) return { ...food, status: 'pending' };

    while (pauseRef.current) {
      await new Promise(r => setTimeout(r, 100));
      if (abortRef.current) return { ...food, status: 'pending' };
    }

    if (!food.barcode) {
      addLog(`Skipping ${food.name}: no barcode`);
      return { ...food, status: 'skipped', error: 'No barcode' };
    }

    // Skip if already has a processed image from our storage
    if (food.currentImageUrl && food.currentImageUrl.includes('storage.googleapis.com')) {
      addLog(`Skipping ${food.name}: already has processed image`);
      return { ...food, status: 'skipped', error: 'Already processed' };
    }

    addLog(`Processing: ${food.name} (${food.barcode})`);

    try {
      // Step 1: Fetch from OFF
      setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'fetching_off' as const } : f));

      const offUrl = await fetchOFFImage(food.barcode);
      if (!offUrl) {
        addLog(`No OFF image for ${food.barcode}`);
        return { ...food, status: 'no_image', error: 'No image on OpenFoodFacts' };
      }

      // Step 2: Remove background
      addLog(`Removing background for ${food.name}...`);
      setFoods(prev => prev.map(f => f.id === food.id ? { ...f, offImageUrl: offUrl, status: 'processing' as const } : f));

      const result = await removeImageBackground(offUrl);
      if (!result.success || !result.blob) {
        addLog(`Background removal failed for ${food.name}: ${result.error}`);
        return { ...food, offImageUrl: offUrl, status: 'failed', error: result.error || 'Processing failed' };
      }

      addLog(`Background removed for ${food.name}, uploading...`);

      // Step 3: Upload to Firebase
      setFoods(prev => prev.map(f => f.id === food.id ? {
        ...f,
        offImageUrl: offUrl,
        processedBlob: result.blob!,
        status: 'uploading' as const
      } : f));

      const uploadResult = await uploadToFirebase(result.blob, food.objectID, food.sourceIndex);
      if (!uploadResult.success) {
        addLog(`Upload failed for ${food.name}: ${uploadResult.error}`);
        return {
          ...food,
          offImageUrl: offUrl,
          processedBlob: result.blob,
          status: 'failed',
          error: uploadResult.error || 'Upload failed'
        };
      }

      addLog(`Completed: ${food.name}`);
      return {
        ...food,
        offImageUrl: offUrl,
        processedBlob: result.blob,
        currentImageUrl: uploadResult.url ?? null,
        status: 'completed',
      };
    } catch (error) {
      addLog(`Error processing ${food.name}: ${error}`);
      return { ...food, status: 'failed', error: error instanceof Error ? error.message : String(error) };
    }
  };

  // Process foods (selected or all pending)
  const startBatchProcessing = async () => {
    setIsProcessing(true);
    pauseRef.current = false;
    abortRef.current = false;

    const selectedFoods = foods.filter(f => f.selected);
    const toProcess = selectedFoods.length > 0
      ? selectedFoods.filter(f => f.barcode)
      : foods.filter(f => f.status === 'pending' && f.barcode);

    addLog(`Starting batch processing of ${toProcess.length} foods`);

    if (toProcess.length === 0) {
      addLog('No foods to process!');
      setIsProcessing(false);
      return;
    }

    for (let i = 0; i < toProcess.length; i++) {
      if (abortRef.current) {
        addLog('Processing stopped by user');
        break;
      }

      const food = toProcess[i];
      addLog(`[${i + 1}/${toProcess.length}] Processing ${food.name}`);

      const result = await processFood(food);

      setFoods(prev => {
        const updated = prev.map(f => f.id === food.id ? result : f);
        updateStats(updated);
        return updated;
      });

      // Small delay between requests
      await new Promise(r => setTimeout(r, 300));
    }

    addLog('Batch processing complete');
    setIsProcessing(false);
    setIsPaused(false);
  };

  const pauseProcessing = () => { pauseRef.current = true; setIsPaused(true); addLog('Paused'); };
  const resumeProcessing = () => { pauseRef.current = false; setIsPaused(false); addLog('Resumed'); };
  const stopProcessing = () => { abortRef.current = true; setIsProcessing(false); setIsPaused(false); addLog('Stopped'); };

  // Filter foods
  const getFilteredFoods = useCallback(() => {
    switch (filter) {
      case 'with_barcode': return foods.filter(f => f.barcode);
      case 'no_image': return foods.filter(f => !f.currentImageUrl);
      case 'pending': return foods.filter(f => f.status === 'pending' && f.barcode);
      case 'selected': return foods.filter(f => f.selected);
      default: return foods;
    }
  }, [foods, filter]);

  const filteredFoods = getFilteredFoods();
  const paginatedFoods = filteredFoods.slice(currentPage * ITEMS_PER_PAGE, (currentPage + 1) * ITEMS_PER_PAGE);
  const totalPages = Math.ceil(filteredFoods.length / ITEMS_PER_PAGE);
  const selectedCount = foods.filter(f => f.selected).length;
  const pendingCount = foods.filter(f => f.status === 'pending' && f.barcode).length;

  const statusColors: Record<FoodImage['status'], string> = {
    pending: 'bg-gray-100 text-gray-600',
    fetching_off: 'bg-blue-100 text-blue-600',
    processing: 'bg-yellow-100 text-yellow-600',
    uploading: 'bg-purple-100 text-purple-600',
    completed: 'bg-green-100 text-green-600',
    failed: 'bg-red-100 text-red-600',
    no_image: 'bg-gray-200 text-gray-500',
    skipped: 'bg-gray-100 text-gray-400',
  };

  const statusLabels: Record<FoodImage['status'], string> = {
    pending: 'Pending',
    fetching_off: 'Fetching...',
    processing: 'Cleaning...',
    uploading: 'Uploading...',
    completed: 'Done',
    failed: 'Failed',
    no_image: 'No OFF Image',
    skipped: 'Skipped',
  };

  return (
    <div className="h-full flex flex-col bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-4">
            <button onClick={onBack} className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <div>
              <h1 className="text-xl font-semibold text-gray-900">Batch Image Processing</h1>
              <p className="text-sm text-gray-500">
                Pull from OpenFoodFacts → Remove backgrounds → Upload to Firebase
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {foods.length > 0 && !isProcessing && (
              <button
                onClick={() => {
                  setFoods([]);
                  setShowIndexSelector(true);
                  setStats({ total: 0, withBarcode: 0, completed: 0, failed: 0, noImage: 0, processing: 0, skipped: 0 });
                }}
                className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Change Indices
              </button>
            )}

            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-sm ${
              cloudAvailable ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
            }`}>
              <div className={`w-2 h-2 rounded-full ${cloudAvailable ? 'bg-green-500' : 'bg-yellow-500'}`} />
              {cloudAvailable ? 'Cloud rembg' : 'Browser mode'}
            </div>

            {!isProcessing ? (
              <button
                onClick={startBatchProcessing}
                disabled={isLoading || (selectedCount === 0 && pendingCount === 0)}
                className="flex items-center gap-2 px-5 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {selectedCount > 0 ? `Process Selected (${selectedCount})` : `Process All (${pendingCount})`}
              </button>
            ) : (
              <>
                {isPaused ? (
                  <button onClick={resumeProcessing} className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                    Resume
                  </button>
                ) : (
                  <button onClick={pauseProcessing} className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700">
                    Pause
                  </button>
                )}
                <button onClick={stopProcessing} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">
                  Stop
                </button>
              </>
            )}
          </div>
        </div>

        {/* Progress */}
        <div className="space-y-3">
          {isLoading && (
            <div className="flex items-center gap-3">
              <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div className="h-full bg-primary-500 transition-all" style={{ width: `${loadingProgress}%` }} />
              </div>
              <span className="text-sm text-gray-500">{loadingMessage || `Loading... ${loadingProgress}%`}</span>
            </div>
          )}

          {!isLoading && (
            <>
              <div className="h-3 bg-gray-200 rounded-full overflow-hidden flex">
                <div className="h-full bg-green-500 transition-all" style={{ width: `${(stats.completed / Math.max(stats.withBarcode, 1)) * 100}%` }} />
                <div className="h-full bg-red-400 transition-all" style={{ width: `${(stats.failed / Math.max(stats.withBarcode, 1)) * 100}%` }} />
                <div className="h-full bg-gray-400 transition-all" style={{ width: `${(stats.noImage / Math.max(stats.withBarcode, 1)) * 100}%` }} />
                <div className="h-full bg-yellow-400 animate-pulse" style={{ width: `${(stats.processing / Math.max(stats.withBarcode, 1)) * 100}%` }} />
              </div>

              <div className="flex flex-wrap gap-4 text-sm">
                <span className="text-gray-600">Total: <strong>{stats.total.toLocaleString()}</strong></span>
                <span className="text-gray-600">With Barcode: <strong>{stats.withBarcode.toLocaleString()}</strong></span>
                <span className="text-green-600">Completed: <strong>{stats.completed.toLocaleString()}</strong></span>
                <span className="text-red-600">Failed: <strong>{stats.failed.toLocaleString()}</strong></span>
                <span className="text-gray-500">No OFF: <strong>{stats.noImage.toLocaleString()}</strong></span>
                {stats.processing > 0 && (
                  <span className="text-yellow-600 animate-pulse">Processing: <strong>{stats.processing}</strong></span>
                )}
                {selectedCount > 0 && (
                  <span className="text-primary-600">Selected: <strong>{selectedCount}</strong></span>
                )}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Filter tabs + selection controls */}
      <div className="bg-white border-b border-gray-200 px-6 flex items-center justify-between">
        <div className="flex gap-1">
          {[
            { value: 'all', label: 'All', count: foods.length },
            { value: 'with_barcode', label: 'With Barcode', count: stats.withBarcode },
            { value: 'pending', label: 'Pending', count: pendingCount },
            { value: 'no_image', label: 'No Image', count: foods.filter(f => !f.currentImageUrl).length },
            { value: 'selected', label: 'Selected', count: selectedCount },
          ].map(tab => (
            <button
              key={tab.value}
              onClick={() => { setFilter(tab.value as typeof filter); setCurrentPage(0); }}
              className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                filter === tab.value ? 'border-primary-600 text-primary-600' : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab.label} ({tab.count.toLocaleString()})
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          <button onClick={selectAll} className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">
            Select All
          </button>
          <button onClick={deselectAll} className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">
            Deselect All
          </button>
        </div>
      </div>

      {/* Main content - food list and log */}
      <div className="flex-1 flex overflow-hidden">
        {/* Food list */}
        <div className="flex-1 overflow-auto p-6">
          {/* Index selector */}
          {showIndexSelector && !isLoading && foods.length === 0 ? (
            <div className="max-w-3xl mx-auto">
              <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
                {/* Header */}
                <div className="bg-gradient-to-r from-primary-600 to-primary-700 px-6 py-5 text-white">
                  <h2 className="text-xl font-bold">Batch Image Processing</h2>
                  <p className="text-primary-100 text-sm mt-1">
                    Fetch images from OpenFoodFacts, remove backgrounds, straighten products, and upload to Firebase
                  </p>
                </div>

                <div className="p-6">
                  {/* Step indicator */}
                  <div className="flex items-center gap-2 mb-4 text-sm text-gray-500">
                    <span className="flex items-center justify-center w-6 h-6 bg-primary-600 text-white rounded-full text-xs font-bold">1</span>
                    <span className="font-medium text-gray-700">Select indices to load foods from</span>
                  </div>

                  {/* Index grid */}
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 mb-6">
                    {ALGOLIA_INDICES.map(index => (
                      <label
                        key={index}
                        className={`flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-all ${
                          selectedIndices.has(index)
                            ? 'border-primary-500 bg-primary-50 shadow-sm'
                            : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                        }`}
                      >
                        <input
                          type="checkbox"
                          checked={selectedIndices.has(index)}
                          onChange={() => {
                            setSelectedIndices(prev => {
                              const next = new Set(prev);
                              if (next.has(index)) {
                                next.delete(index);
                              } else {
                                next.add(index);
                              }
                              return next;
                            });
                          }}
                          className="w-4 h-4 text-primary-600 rounded"
                        />
                        <span className="text-sm font-medium text-gray-700 truncate">{index.replace(/_/g, ' ')}</span>
                      </label>
                    ))}
                  </div>

                  {/* Quick actions */}
                  <div className="flex items-center gap-3 mb-6 pb-6 border-b border-gray-200">
                    <button
                      onClick={() => setSelectedIndices(new Set(ALGOLIA_INDICES))}
                      className="px-3 py-1.5 text-sm text-primary-700 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
                    >
                      Select All
                    </button>
                    <button
                      onClick={() => setSelectedIndices(new Set())}
                      className="px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                    >
                      Clear All
                    </button>
                    <span className="text-sm text-gray-400">
                      {selectedIndices.size} of {ALGOLIA_INDICES.length} selected
                    </span>
                  </div>

                  {/* Load button - large and prominent */}
                  <button
                    onClick={loadFoodsFromIndices}
                    disabled={selectedIndices.size === 0}
                    className="w-full flex items-center justify-center gap-3 px-6 py-4 text-lg font-semibold text-white bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 rounded-xl shadow-lg hover:shadow-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    Load {selectedIndices.size > 0 ? `Foods from ${selectedIndices.size} ${selectedIndices.size === 1 ? 'Index' : 'Indices'}` : 'Foods'}
                  </button>

                  {selectedIndices.size === 0 && (
                    <p className="text-center text-sm text-red-500 mt-3">Select at least one index to continue</p>
                  )}
                </div>
              </div>
            </div>
          ) : isLoading ? (
            <div className="flex items-center justify-center h-64">
              <div className="flex flex-col items-center gap-3">
                <svg className="w-8 h-8 animate-spin text-primary-600" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                <span className="text-gray-500">{loadingMessage || 'Loading foods...'}</span>
              </div>
            </div>
          ) : (
            <>
              <div className="grid gap-2">
                {paginatedFoods.map(food => (
                  <div
                    key={food.id}
                    className={`bg-white rounded-lg border p-3 flex items-center gap-3 cursor-pointer transition-colors ${
                      food.selected ? 'border-primary-500 bg-primary-50' : 'border-gray-200 hover:border-gray-300'
                    }`}
                    onClick={() => toggleSelect(food.id)}
                  >
                    {/* Checkbox */}
                    <input
                      type="checkbox"
                      checked={food.selected}
                      onChange={() => toggleSelect(food.id)}
                      onClick={e => e.stopPropagation()}
                      className="w-4 h-4 text-primary-600 rounded"
                    />

                    {/* Images - clickable for full preview */}
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <div
                        className="w-10 h-10 bg-gray-100 rounded flex items-center justify-center overflow-hidden cursor-pointer hover:ring-2 hover:ring-primary-400 transition-all"
                        onClick={(e) => {
                          e.stopPropagation();
                          if (food.currentImageUrl) setPreviewImage({ url: food.currentImageUrl, title: `${food.name} - Current` });
                        }}
                      >
                        {food.currentImageUrl ? (
                          <img src={food.currentImageUrl} alt="" className="w-full h-full object-contain" />
                        ) : (
                          <span className="text-[8px] text-gray-400">None</span>
                        )}
                      </div>
                      <svg className="w-3 h-3 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                      <div
                        className="w-10 h-10 bg-gray-100 rounded flex items-center justify-center overflow-hidden cursor-pointer hover:ring-2 hover:ring-blue-400 transition-all"
                        onClick={(e) => {
                          e.stopPropagation();
                          if (food.offImageUrl) setPreviewImage({ url: food.offImageUrl, title: `${food.name} - OpenFoodFacts` });
                        }}
                      >
                        {food.offImageUrl ? (
                          <img src={food.offImageUrl} alt="" className="w-full h-full object-contain" />
                        ) : (
                          <span className="text-[8px] text-gray-400">OFF</span>
                        )}
                      </div>
                      <svg className="w-3 h-3 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                      <div
                        className="w-10 h-10 bg-[#e8e8e8] rounded flex items-center justify-center overflow-hidden cursor-pointer hover:ring-2 hover:ring-green-400 transition-all"
                        onClick={(e) => {
                          e.stopPropagation();
                          if (food.processedBlob) setPreviewImage({ url: URL.createObjectURL(food.processedBlob), title: `${food.name} - Cleaned` });
                        }}
                      >
                        {food.processedBlob ? (
                          <img src={URL.createObjectURL(food.processedBlob)} alt="" className="w-full h-full object-contain" />
                        ) : (
                          <span className="text-[8px] text-gray-400">Clean</span>
                        )}
                      </div>
                    </div>

                    {/* Food info */}
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-gray-900 truncate text-sm">{food.name}</div>
                      <div className="flex items-center gap-2 text-xs text-gray-500">
                        {food.barcode && <span className="font-mono">{food.barcode}</span>}
                        <span className="px-1.5 py-0.5 bg-gray-100 rounded text-[10px]">{food.sourceIndex.replace(/_/g, ' ')}</span>
                      </div>
                    </div>

                    {/* Status */}
                    <div className="flex-shrink-0 text-right">
                      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${statusColors[food.status]}`}>
                        {['fetching_off', 'processing', 'uploading'].includes(food.status) && (
                          <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                          </svg>
                        )}
                        {statusLabels[food.status]}
                      </span>
                      {food.error && (
                        <div className="text-[10px] text-red-500 mt-0.5 max-w-[100px] truncate" title={food.error}>
                          {food.error}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2 mt-4">
                  <button
                    onClick={() => setCurrentPage(p => Math.max(0, p - 1))}
                    disabled={currentPage === 0}
                    className="px-3 py-1 text-sm bg-white border rounded hover:bg-gray-50 disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <span className="text-sm text-gray-600">
                    Page {currentPage + 1} of {totalPages}
                  </span>
                  <button
                    onClick={() => setCurrentPage(p => Math.min(totalPages - 1, p + 1))}
                    disabled={currentPage >= totalPages - 1}
                    className="px-3 py-1 text-sm bg-white border rounded hover:bg-gray-50 disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              )}
            </>
          )}
        </div>

        {/* Processing log */}
        <div className="w-80 border-l border-gray-200 bg-gray-900 flex flex-col">
          <div className="px-4 py-2 border-b border-gray-700 text-gray-400 text-xs font-medium uppercase">
            Processing Log
          </div>
          <div className="flex-1 overflow-auto p-3 font-mono text-xs text-gray-300 space-y-1">
            {processingLog.length === 0 ? (
              <div className="text-gray-500">No activity yet...</div>
            ) : (
              processingLog.map((log, i) => (
                <div key={i} className="break-all">{log}</div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Image Preview Modal */}
      {previewImage && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
          onClick={() => setPreviewImage(null)}
        >
          <div className="relative max-w-[90vw] max-h-[90vh] flex flex-col items-center">
            {/* Close button */}
            <button
              onClick={() => setPreviewImage(null)}
              className="absolute -top-12 right-0 p-2 text-white/80 hover:text-white transition-colors"
            >
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            {/* Title */}
            <div className="absolute -top-12 left-0 text-white font-medium">
              {previewImage.title}
            </div>

            {/* Image container with checkerboard background for transparency */}
            <div
              className="rounded-lg overflow-hidden shadow-2xl"
              style={{
                backgroundImage: 'linear-gradient(45deg, #ccc 25%, transparent 25%), linear-gradient(-45deg, #ccc 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #ccc 75%), linear-gradient(-45deg, transparent 75%, #ccc 75%)',
                backgroundSize: '20px 20px',
                backgroundPosition: '0 0, 0 10px, 10px -10px, -10px 0px',
                backgroundColor: '#fff',
              }}
              onClick={(e) => e.stopPropagation()}
            >
              <img
                src={previewImage.url}
                alt={previewImage.title}
                className="max-w-[85vw] max-h-[80vh] object-contain"
              />
            </div>

            {/* Help text */}
            <div className="mt-4 text-white/60 text-sm">
              Click outside or press ESC to close
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ImageProcessingPage;
