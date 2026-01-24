/**
 * Google Image Scraper Page
 * Search Google for official white background product images
 */

import React, { useState, useCallback, useEffect, useRef } from 'react';
import {
  searchSerpApiImages,
  analyzeImageQuality,
  isSerpApiConfigured,
  getConfigurationHelp,
  SerpApiImageResult,
  ImageAnalysisResult,
} from '../services/serpApiService';
import { filterUKProducts } from '../services/ukProductDetection';
import { ALGOLIA_INDICES } from '../types';

// Algolia config
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';

interface FoodWithImage {
  id: string;
  objectID: string;
  name: string;
  brandName: string | null;
  barcode: string | null;
  currentImageUrl: string | null;
  sourceIndex: string;
  selected: boolean;

  // SerpApi search results
  searchResults: SerpApiImageResult[];
  selectedImageUrl: string | null;
  analysis: ImageAnalysisResult | null;

  // Processing status
  status: 'pending' | 'searching' | 'analyzing' | 'ready' | 'uploading' | 'completed' | 'failed' | 'no_results';
  error?: string;
  analysisProgress: number;
  confidence?: number; // 0-100 confidence score
}

interface ProcessingStats {
  total: number;
  completed: number;
  failed: number;
  noResults: number;
  processing: number;
}

export const GoogleImageScraperPage: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [foods, setFoods] = useState<FoodWithImage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingProgress, setLoadingProgress] = useState(0);
  const [loadingMessage, setLoadingMessage] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [filter, setFilter] = useState<'all' | 'pending' | 'ready' | 'selected'>('pending');
  const [currentPage, setCurrentPage] = useState(0);
  const [stats, setStats] = useState<ProcessingStats>({
    total: 0, completed: 0, failed: 0, noResults: 0, processing: 0
  });
  const [processingLog, setProcessingLog] = useState<string[]>([]);
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(new Set(ALGOLIA_INDICES));
  const [showIndexSelector, setShowIndexSelector] = useState(true);
  const [apiConfigured, setApiConfigured] = useState(false);
  const [filterUKOnly, setFilterUKOnly] = useState(true); // UK filter enabled by default
  const [ukFilterStats, setUkFilterStats] = useState<{
    total: number;
    ukCount: number;
    nonUkCount: number;
    ukPercentage: number;
    nonUkPercentage: number;
  } | null>(null);

  // Preview modal
  const [previewImage, setPreviewImage] = useState<{
    url: string;
    title: string;
    analysis?: ImageAnalysisResult;
  } | null>(null);

  const pauseRef = useRef(false);
  const abortRef = useRef(false);
  const ITEMS_PER_PAGE = 50;

  const addLog = (message: string) => {
    console.log(message);
    setProcessingLog(prev => [...prev.slice(-50), `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  // Check API configuration
  useEffect(() => {
    const configured = isSerpApiConfigured();
    setApiConfigured(configured);
    if (!configured) {
      addLog('⚠️ SearchAPI not configured');
    } else {
      addLog('✓ SearchAPI configured');
    }
  }, []);

  // ESC to close preview
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && previewImage) {
        setPreviewImage(null);
      }
    };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [previewImage]);

  // Load foods from Algolia
  const loadFoodsFromIndices = useCallback(async () => {
    if (selectedIndices.size === 0) {
      addLog('No indices selected');
      return;
    }

    setIsLoading(true);
    setShowIndexSelector(false);
    setLoadingProgress(0);
    addLog('Loading foods from Algolia...');

    const allFoods: FoodWithImage[] = [];
    const indicesToLoad = Array.from(selectedIndices);

    try {
      for (let i = 0; i < indicesToLoad.length; i++) {
        const indexName = indicesToLoad[i];
        setLoadingMessage(`Loading ${indexName}...`);
        setLoadingProgress(Math.round((i / indicesToLoad.length) * 100));
        addLog(`Loading index: ${indexName}`);

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
              attributesToRetrieve: ['objectID', 'name', 'foodName', 'brandName', 'brand', 'barcode', 'imageUrl'],
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
            allFoods.push({
              id: `${indexName}:${hit.objectID}`,
              objectID: hit.objectID,
              name: hit.name || hit.foodName || 'Unknown',
              brandName: hit.brandName || hit.brand || null,
              barcode: hit.barcode || null,
              currentImageUrl: hit.imageUrl || null,
              sourceIndex: indexName,
              selected: false,
              searchResults: [],
              selectedImageUrl: null,
              analysis: null,
              status: 'pending',
              analysisProgress: 0,
            });
          }
        } catch (err) {
          addLog(`Error loading ${indexName}: ${err}`);
        }
      }

      addLog(`Total foods loaded: ${allFoods.length}`);

      // Apply UK filter if enabled
      let foodsToUse = allFoods;
      if (filterUKOnly) {
        const filterResult = filterUKProducts(allFoods, 40); // 40% confidence threshold
        foodsToUse = filterResult.ukProducts;
        setUkFilterStats(filterResult.stats);
        addLog(`UK filter applied: ${filterResult.stats.ukCount} UK products (${filterResult.stats.ukPercentage}%), ${filterResult.stats.nonUkCount} non-UK products (${filterResult.stats.nonUkPercentage}%) filtered out`);
      } else {
        setUkFilterStats(null);
      }

      setFoods(foodsToUse);
      updateStats(foodsToUse);
      setLoadingProgress(100);
      setLoadingMessage('');
    } catch (error) {
      addLog(`Error: ${error}`);
    } finally {
      setIsLoading(false);
    }
  }, [selectedIndices, filterUKOnly]);

  const updateStats = (foodList: FoodWithImage[]) => {
    setStats({
      total: foodList.length,
      completed: foodList.filter(f => f.status === 'completed').length,
      failed: foodList.filter(f => f.status === 'failed').length,
      noResults: foodList.filter(f => f.status === 'no_results').length,
      processing: foodList.filter(f => ['searching', 'analyzing', 'uploading'].includes(f.status)).length,
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

  // Search and analyze a single food
  const searchFood = async (food: FoodWithImage): Promise<FoodWithImage> => {
    if (abortRef.current) return { ...food, status: 'pending' };

    while (pauseRef.current) {
      await new Promise(r => setTimeout(r, 100));
      if (abortRef.current) return { ...food, status: 'pending' };
    }

    const searchTerm = food.brandName ? `${food.brandName} ${food.name}` : food.name;
    addLog(`Searching SearchAPI for: ${searchTerm}`);

    try {
      // Step 1: Search via SearchAPI
      setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'searching' as const } : f));

      const results = await searchSerpApiImages(food.name, food.brandName, 10);

      if (results.length === 0) {
        addLog(`No results for ${food.name}`);
        return { ...food, status: 'no_results', searchResults: [], error: 'No images found' };
      }

      addLog(`Found ${results.length} images for ${food.name}`);

      // Filter out disqualified results
      const validResults = results.filter(r => !r.disqualified);
      if (validResults.length === 0) {
        addLog(`All images disqualified for ${food.name}`);
        return { ...food, status: 'no_results', searchResults: results, error: 'All images disqualified' };
      }

      // Step 2: Analyze top results and score them
      let bestResult = null;
      let bestAnalysis = null;
      let bestConfidence = 0;

      for (let i = 0; i < Math.min(validResults.length, 8); i++) {
        const candidate = validResults[i];
        addLog(`Analyzing result ${i + 1}/${validResults.length} for ${food.name} (${candidate.domain})`);

        setFoods(prev => prev.map(f => f.id === food.id ? {
          ...f,
          status: 'analyzing' as const,
          searchResults: results,
          selectedImageUrl: candidate.url,
        } : f));

        try {
          const analysis = await analyzeImageQuality(candidate.url, (progress) => {
            setFoods(prev => prev.map(f => f.id === food.id ? { ...f, analysisProgress: progress } : f));
          });

          // Calculate confidence score (0-100)
          let confidence = 0;

          // Transparent/no background detected: MAXIMUM SCORE (check for very high whiteness = 95%+)
          if (analysis.backgroundConfidence >= 95 && analysis.hasWhiteBackground) {
            confidence = 95; // Nearly perfect - transparent or pure white
          } else {
            // White background: +40 points
            if (analysis.hasWhiteBackground) confidence += 40;

            // No overlays: +30 points
            if (!analysis.hasOverlay) confidence += 30;

            // High background confidence: up to +20 points
            confidence += Math.min(20, analysis.backgroundConfidence * 0.2);
          }

          // Manufacturer site: +5 bonus points (less important if image is already perfect)
          if (candidate.isManufacturerSite) confidence += 5;

          addLog(`Analysis: ${food.name} - Confidence: ${Math.round(confidence)}% (BG: ${analysis.backgroundConfidence}%, Overlay: ${analysis.hasOverlay ? 'Yes' : 'No'})`);

          // If confidence >= 80%, use it immediately
          if (confidence >= 80) {
            addLog(`✓ High confidence (${Math.round(confidence)}%) - Auto-selecting`);
            bestResult = candidate;
            bestAnalysis = analysis;
            bestConfidence = confidence;
            break;
          }

          // Otherwise, remember the best we've found
          if (confidence > bestConfidence) {
            bestResult = candidate;
            bestAnalysis = analysis;
            bestConfidence = confidence;
          }

        } catch (error) {
          addLog(`Failed to analyze image from ${candidate.domain}: ${error instanceof Error ? error.message : 'CORS error'}`);
          continue;
        }
      }

      if (!bestResult || !bestAnalysis) {
        addLog(`Could not analyze any images for ${food.name} (CORS blocked)`);
        return {
          ...food,
          searchResults: results,
          status: 'failed',
          error: 'All images blocked by CORS',
        };
      }

      const confidence = Math.round(bestConfidence);
      const status = confidence >= 80 ? 'ready' : 'analyzing'; // Use 'analyzing' status for review needed
      const message = confidence >= 80
        ? `✓ High confidence (${confidence}%) - Ready to use`
        : `⚠ Low confidence (${confidence}%) - Review needed`;

      addLog(message);

      return {
        ...food,
        searchResults: results,
        selectedImageUrl: bestResult.url,
        analysis: bestAnalysis,
        status,
        confidence,
        error: confidence < 80 ? `Low confidence (${confidence}%) - ${bestAnalysis.overlayTypes.join(', ') || 'Check image quality'}` : undefined,
        analysisProgress: 100,
      };
    } catch (error) {
      addLog(`Error searching ${food.name}: ${error}`);
      return {
        ...food,
        status: 'failed',
        error: error instanceof Error ? error.message : String(error),
      };
    }
  };

  // Batch search
  const startBatchSearch = async () => {
    if (!apiConfigured) {
      alert('Please configure SearchAPI first. See the console log for instructions.');
      addLog(getConfigurationHelp());
      return;
    }

    setIsProcessing(true);
    pauseRef.current = false;
    abortRef.current = false;

    const selectedFoods = foods.filter(f => f.selected);
    const toProcess = selectedFoods.length > 0
      ? selectedFoods
      : foods.filter(f => f.status === 'pending');

    addLog(`Starting batch search of ${toProcess.length} foods`);

    if (toProcess.length === 0) {
      addLog('No foods to process!');
      setIsProcessing(false);
      return;
    }

    for (let i = 0; i < toProcess.length; i++) {
      if (abortRef.current) {
        addLog('Search stopped by user');
        break;
      }

      const food = toProcess[i];
      addLog(`[${i + 1}/${toProcess.length}] Processing ${food.name}`);

      const result = await searchFood(food);

      setFoods(prev => {
        const updated = prev.map(f => f.id === food.id ? result : f);
        updateStats(updated);
        return updated;
      });

      // Delay to avoid rate limiting
      await new Promise(r => setTimeout(r, 1000));
    }

    addLog('Batch search complete');
    setIsProcessing(false);
    setIsPaused(false);
  };

  const pauseProcessing = () => { pauseRef.current = true; setIsPaused(true); addLog('Paused'); };
  const resumeProcessing = () => { pauseRef.current = false; setIsPaused(false); addLog('Resumed'); };
  const stopProcessing = () => { abortRef.current = true; setIsProcessing(false); setIsPaused(false); addLog('Stopped'); };

  // Filter foods
  const getFilteredFoods = useCallback(() => {
    switch (filter) {
      case 'pending': return foods.filter(f => f.status === 'pending');
      case 'ready': return foods.filter(f => f.status === 'ready');
      case 'selected': return foods.filter(f => f.selected);
      default: return foods;
    }
  }, [foods, filter]);

  const filteredFoods = getFilteredFoods();
  const paginatedFoods = filteredFoods.slice(currentPage * ITEMS_PER_PAGE, (currentPage + 1) * ITEMS_PER_PAGE);
  const totalPages = Math.ceil(filteredFoods.length / ITEMS_PER_PAGE);
  const selectedCount = foods.filter(f => f.selected).length;
  const pendingCount = foods.filter(f => f.status === 'pending').length;
  const readyCount = foods.filter(f => f.status === 'ready').length;

  const statusColors: Record<FoodWithImage['status'], string> = {
    pending: 'bg-gray-100 text-gray-600',
    searching: 'bg-blue-100 text-blue-600',
    analyzing: 'bg-yellow-100 text-yellow-600',
    ready: 'bg-green-100 text-green-600',
    uploading: 'bg-purple-100 text-purple-600',
    completed: 'bg-green-500 text-white',
    failed: 'bg-red-100 text-red-600',
    no_results: 'bg-gray-200 text-gray-500',
  };

  const statusLabels: Record<FoodWithImage['status'], string> = {
    pending: 'Pending',
    searching: 'Searching...',
    analyzing: 'Analyzing...',
    ready: 'Ready',
    uploading: 'Uploading...',
    completed: 'Done',
    failed: 'Failed',
    no_results: 'No Results',
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
              <h1 className="text-xl font-semibold text-gray-900">Google Image Scraper</h1>
              <p className="text-sm text-gray-500">
                Find official white background product images from manufacturer sites
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {foods.length > 0 && !isProcessing && (
              <button
                onClick={() => {
                  setFoods([]);
                  setShowIndexSelector(true);
                  setStats({ total: 0, completed: 0, failed: 0, noResults: 0, processing: 0 });
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
              apiConfigured ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}>
              <div className={`w-2 h-2 rounded-full ${apiConfigured ? 'bg-green-500' : 'bg-red-500'}`} />
              {apiConfigured ? 'API Configured' : 'API Not Configured'}
            </div>

            {!isProcessing ? (
              <button
                onClick={startBatchSearch}
                disabled={isLoading || !apiConfigured || (selectedCount === 0 && pendingCount === 0)}
                className="flex items-center gap-2 px-5 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                {selectedCount > 0 ? `Search Selected (${selectedCount})` : `Search All (${pendingCount})`}
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

          {!isLoading && foods.length > 0 && (
            <>
              <div className="h-3 bg-gray-200 rounded-full overflow-hidden flex">
                <div className="h-full bg-green-500 transition-all" style={{ width: `${(stats.completed / Math.max(stats.total, 1)) * 100}%` }} />
                <div className="h-full bg-blue-400 transition-all" style={{ width: `${(readyCount / Math.max(stats.total, 1)) * 100}%` }} />
                <div className="h-full bg-red-400 transition-all" style={{ width: `${(stats.failed / Math.max(stats.total, 1)) * 100}%` }} />
                <div className="h-full bg-gray-400 transition-all" style={{ width: `${(stats.noResults / Math.max(stats.total, 1)) * 100}%` }} />
                <div className="h-full bg-yellow-400 animate-pulse" style={{ width: `${(stats.processing / Math.max(stats.total, 1)) * 100}%` }} />
              </div>

              <div className="flex flex-wrap gap-4 text-sm">
                <span className="text-gray-600">Total: <strong>{stats.total.toLocaleString()}</strong></span>
                <span className="text-green-600">Completed: <strong>{stats.completed.toLocaleString()}</strong></span>
                <span className="text-blue-600">Ready: <strong>{readyCount.toLocaleString()}</strong></span>
                <span className="text-red-600">Failed: <strong>{stats.failed.toLocaleString()}</strong></span>
                <span className="text-gray-500">No Results: <strong>{stats.noResults.toLocaleString()}</strong></span>
                {stats.processing > 0 && (
                  <span className="text-yellow-600 animate-pulse">Processing: <strong>{stats.processing}</strong></span>
                )}
                {selectedCount > 0 && (
                  <span className="text-primary-600">Selected: <strong>{selectedCount}</strong></span>
                )}
                {ukFilterStats && (
                  <span className="text-blue-600">
                    🇬🇧 UK Filter: <strong>{ukFilterStats.ukCount}</strong> kept ({ukFilterStats.ukPercentage}%), <strong>{ukFilterStats.nonUkCount}</strong> filtered ({ukFilterStats.nonUkPercentage}%)
                  </span>
                )}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Filter tabs */}
      <div className="bg-white border-b border-gray-200 px-6 flex items-center justify-between">
        <div className="flex gap-1">
          {[
            { value: 'all', label: 'All', count: foods.length },
            { value: 'pending', label: 'Pending', count: pendingCount },
            { value: 'ready', label: 'Ready', count: readyCount },
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

      {/* Main content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Food list */}
        <div className="flex-1 overflow-auto p-6">
          {/* Index selector */}
          {showIndexSelector && !isLoading && foods.length === 0 ? (
            <div className="max-w-3xl mx-auto">
              <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
                <div className="bg-gradient-to-r from-primary-600 to-primary-700 px-6 py-5 text-white">
                  <h2 className="text-xl font-bold">Google Image Scraper</h2>
                  <p className="text-primary-100 text-sm mt-1">
                    Search Google for official white background product images from manufacturer sites
                  </p>
                </div>

                {!apiConfigured && (
                  <div className="px-6 py-4 bg-yellow-50 border-b border-yellow-100">
                    <div className="flex items-start gap-3">
                      <svg className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                      </svg>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-yellow-800">Google API Not Configured</p>
                        <p className="text-xs text-yellow-700 mt-1">
                          You need a Google API key and Custom Search Engine ID. Check the browser console for setup instructions.
                        </p>
                        <button
                          onClick={() => addLog(getConfigurationHelp())}
                          className="mt-2 text-xs text-yellow-800 underline hover:text-yellow-900"
                        >
                          Show setup instructions in console
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                <div className="p-6">
                  <div className="flex items-center gap-2 mb-4 text-sm text-gray-500">
                    <span className="flex items-center justify-center w-6 h-6 bg-primary-600 text-white rounded-full text-xs font-bold">1</span>
                    <span className="font-medium text-gray-700">Select indices to load foods from</span>
                  </div>

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

                  {/* UK Product Filter */}
                  <div className="mb-6 pb-6 border-b border-gray-200">
                    <div className="flex items-center gap-2 mb-3 text-sm text-gray-500">
                      <span className="flex items-center justify-center w-6 h-6 bg-primary-600 text-white rounded-full text-xs font-bold">2</span>
                      <span className="font-medium text-gray-700">Filter products by region</span>
                    </div>

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-blue-200 bg-blue-50 cursor-pointer hover:bg-blue-100 transition-colors">
                      <input
                        type="checkbox"
                        checked={filterUKOnly}
                        onChange={(e) => setFilterUKOnly(e.target.checked)}
                        className="w-4 h-4 text-blue-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">🇬🇧 UK Products Only</span>
                          <span className="px-2 py-0.5 text-xs font-semibold text-blue-700 bg-blue-200 rounded-full">Recommended</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Filter out non-UK products before searching images. Detects US spelling (color vs colour), foreign languages, and non-UK brands. Allows up to 10% non-UK content to include French-named UK products (e.g., "crème fraîche").
                        </p>
                      </div>
                    </label>
                  </div>

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
              <div className="grid gap-3">
                {paginatedFoods.map(food => (
                  <div
                    key={food.id}
                    className={`bg-white rounded-lg border p-4 transition-colors ${
                      food.selected ? 'border-primary-500 bg-primary-50' : 'border-gray-200'
                    }`}
                  >
                    <div className="flex items-start gap-4">
                      {/* Checkbox */}
                      <input
                        type="checkbox"
                        checked={food.selected}
                        onChange={() => toggleSelect(food.id)}
                        className="w-4 h-4 text-primary-600 rounded mt-1"
                      />

                      {/* Current image */}
                      <div className="flex-shrink-0">
                        <div className="text-xs text-gray-400 mb-1 text-center">Current</div>
                        <div
                          className="w-20 h-20 bg-gray-100 rounded flex items-center justify-center overflow-hidden cursor-pointer hover:ring-2 hover:ring-gray-400"
                          onClick={() => {
                            if (food.currentImageUrl) setPreviewImage({ url: food.currentImageUrl, title: `${food.name} - Current` });
                          }}
                        >
                          {food.currentImageUrl ? (
                            <img src={food.currentImageUrl} alt="" className="w-full h-full object-contain" />
                          ) : (
                            <span className="text-xs text-gray-400">None</span>
                          )}
                        </div>
                      </div>

                      {/* Food info */}
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-gray-900">{food.name}</div>
                        {food.brandName && (
                          <div className="text-sm text-gray-500">{food.brandName}</div>
                        )}
                        <div className="flex items-center gap-2 text-xs text-gray-400 mt-1">
                          <span className="px-1.5 py-0.5 bg-gray-100 rounded">{food.sourceIndex.replace(/_/g, ' ')}</span>
                        </div>

                        {/* Search results thumbnails */}
                        {food.searchResults.length > 0 && (
                          <div className="mt-3">
                            <div className="text-xs text-gray-500 mb-2">
                              Found {food.searchResults.length} images
                              {food.confidence !== undefined && (
                                <span className={`ml-2 font-semibold ${
                                  food.confidence >= 80 ? 'text-green-600' :
                                  food.confidence >= 60 ? 'text-yellow-600' :
                                  'text-red-600'
                                }`}>
                                  {food.confidence >= 80 ? '✓' : '⚠'} {food.confidence}% confidence
                                </span>
                              )}
                            </div>
                            <div className="flex gap-2 overflow-x-auto pb-2">
                              {food.searchResults.slice(0, 10).map((result, idx) => (
                                <div
                                  key={idx}
                                  className="flex-shrink-0 relative"
                                >
                                  <div
                                    className={`w-20 h-20 bg-gray-100 rounded overflow-hidden cursor-pointer hover:ring-2 hover:ring-blue-400 ${
                                      food.selectedImageUrl === result.url ? 'ring-2 ring-primary-500' : ''
                                    }`}
                                    onClick={() => {
                                      setPreviewImage({
                                        url: result.url,
                                        title: `${food.name} - Result ${idx + 1} (${result.domain})`,
                                      });
                                    }}
                                  >
                                    <img src={result.thumbnail} alt="" className="w-full h-full object-cover" />
                                  </div>
                                  {result.isManufacturerSite && (
                                    <div className="absolute top-0 right-0 w-4 h-4 bg-green-500 rounded-full flex items-center justify-center">
                                      <svg className="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                      </svg>
                                    </div>
                                  )}
                                  {food.selectedImageUrl === result.url && (
                                    <div className="absolute inset-0 bg-primary-500/20 rounded flex items-center justify-center">
                                      <svg className="w-8 h-8 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                      </svg>
                                    </div>
                                  )}
                                  <button
                                    onClick={async (e) => {
                                      e.stopPropagation();

                                      // Mark as uploading
                                      setFoods(prev => prev.map(f =>
                                        f.id === food.id
                                          ? { ...f, selectedImageUrl: result.url, status: 'uploading' as const }
                                          : f
                                      ));

                                      try {
                                        addLog(`Uploading image for ${food.name} to Firebase...`);

                                        // Upload to Firebase Storage via Cloud Function
                                        const uploadResponse = await fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/uploadFoodImage', {
                                          method: 'POST',
                                          headers: {
                                            'Content-Type': 'application/json',
                                          },
                                          body: JSON.stringify({
                                            imageUrl: result.url,
                                            index: food.sourceIndex,
                                            objectID: food.objectID,
                                          }),
                                        });

                                        if (!uploadResponse.ok) {
                                          throw new Error('Upload failed');
                                        }

                                        const uploadData = await uploadResponse.json();
                                        addLog(`✓ Uploaded to Firebase: ${uploadData.imageUrl}`);

                                        // Update Algolia with Firebase URL
                                        addLog(`Updating Algolia with Firebase URL...`);
                                        // The API endpoint should handle Algolia update

                                        setFoods(prev => prev.map(f =>
                                          f.id === food.id
                                            ? { ...f, status: 'completed' as const, currentImageUrl: uploadData.imageUrl }
                                            : f
                                        ));

                                        addLog(`✓ Complete: ${food.name}`);

                                      } catch (error) {
                                        addLog(`✗ Upload failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
                                        setFoods(prev => prev.map(f =>
                                          f.id === food.id
                                            ? { ...f, status: 'failed' as const, error: 'Upload failed' }
                                            : f
                                        ));
                                      }
                                    }}
                                    className="absolute bottom-0 left-0 right-0 bg-primary-600 text-white text-[9px] py-0.5 hover:bg-primary-700 opacity-0 group-hover:opacity-100 transition-opacity"
                                  >
                                    Use This
                                  </button>
                                  <div className="text-[8px] text-gray-400 mt-0.5 truncate w-20 text-center">
                                    {result.domain}
                                  </div>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Status */}
                      <div className="flex-shrink-0 text-right">
                        <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${statusColors[food.status]}`}>
                          {['searching', 'analyzing', 'uploading'].includes(food.status) && (
                            <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                            </svg>
                          )}
                          {statusLabels[food.status]}
                        </span>
                        {food.status === 'analyzing' && (
                          <div className="text-xs text-gray-500 mt-1">{food.analysisProgress}%</div>
                        )}
                        {food.error && (
                          <div className="text-[10px] text-red-500 mt-1 max-w-[120px]" title={food.error}>
                            {food.error}
                          </div>
                        )}
                      </div>
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
            <button
              onClick={() => setPreviewImage(null)}
              className="absolute -top-12 right-0 p-2 text-white/80 hover:text-white transition-colors"
            >
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            <div className="absolute -top-12 left-0 text-white font-medium">
              {previewImage.title}
            </div>

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

            {previewImage.analysis && (
              <div className="mt-4 bg-white/10 backdrop-blur-md rounded-lg px-4 py-3 text-white text-sm">
                <div className="flex items-center gap-4">
                  <span>Background: {previewImage.analysis.hasWhiteBackground ? '✓' : '✗'} White ({previewImage.analysis.backgroundConfidence}%)</span>
                  <span>Overlay: {previewImage.analysis.hasOverlay ? '✗ Yes' : '✓ None'}</span>
                  <span>Quality: {previewImage.analysis.qualityScore}/100</span>
                </div>
                {previewImage.analysis.overlayTypes.length > 0 && (
                  <div className="text-xs text-white/70 mt-1">
                    Issues: {previewImage.analysis.overlayTypes.join(', ')}
                  </div>
                )}
              </div>
            )}

            <div className="mt-4 text-white/60 text-sm">
              Click outside or press ESC to close
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default GoogleImageScraperPage;
