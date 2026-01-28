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
import { searchByBarcode } from '../services/algoliaService';
import { ALGOLIA_INDICES } from '../types';

// Algolia config
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';

interface NutritionData {
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  saturatedFat?: number;
  fiber?: number;
  sugar?: number;
  sodium?: number;
  salt?: number;
  servingSize?: string;
  ingredients?: string; // Ingredient list
  source?: string; // Where the data came from (e.g., "Open Food Facts", "Tesco", "Web Scrape")
  sourceUrl?: string; // URL where the data was scraped from
}

interface FoodWithImage {
  id: string;
  objectID: string;
  name: string;
  brandName: string | null;
  barcode: string | null;
  currentImageUrl: string | null;
  sourceIndex: string;
  selected: boolean;

  // Original nutrition from database
  calories?: number;

  // Tesco-specific flags
  dontShowImage?: boolean; // Tesco image quality flag

  // SerpApi search results
  searchResults: SerpApiImageResult[];
  selectedImageUrl: string | null;
  analysis: ImageAnalysisResult | null;

  // Nutrition data scraping
  nutritionData: NutritionData | null;
  nutritionStatus: 'pending' | 'searching' | 'found' | 'not_found' | 'failed';

  // Processing status
  status: 'pending' | 'searching' | 'analyzing' | 'ready' | 'uploading' | 'completed' | 'failed' | 'no_results';
  error?: string;
  analysisProgress: number;
  confidence?: number; // 0-100 confidence score

  // Persistent tracking - marks if this food has been processed in any session
  wasProcessed?: boolean; // True if we've attempted to process this (even if failed)
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
  const [currentProcessingIndex, setCurrentProcessingIndex] = useState(0);
  const [totalToProcess, setTotalToProcess] = useState(0);
  const [filter, setFilter] = useState<'all' | 'pending' | 'ready' | 'selected' | 'nutrition_found' | 'nutrition_failed'>('pending');
  const [currentPage, setCurrentPage] = useState(0);
  const [stats, setStats] = useState<ProcessingStats>({
    total: 0, completed: 0, failed: 0, noResults: 0, processing: 0
  });
  const [processingLog, setProcessingLog] = useState<string[]>([]);
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(new Set()); // No indices selected by default
  const [showIndexSelector, setShowIndexSelector] = useState(true);
  const [apiConfigured, setApiConfigured] = useState(false);
  const [filterUKOnly, setFilterUKOnly] = useState(false); // UK filter disabled by default
  const [filterNoImages, setFilterNoImages] = useState(false); // Show all foods by default
  const [filterZeroCalories, setFilterZeroCalories] = useState(false); // Filter for very low calorie foods (0-5 kcal)
  const [excludeDrinks, setExcludeDrinks] = useState(false); // Exclude drinks when filtering very low calorie
  // filterTescoBadImages REMOVED - Tesco images now always display regardless of dontShowImage flag
  const [scrapeNutrition, setScrapeNutrition] = useState(false); // Nutrition scraping disabled by default
  const [scrapeServingSize, setScrapeServingSize] = useState(false); // Serving size scraping disabled by default
  const [scrapeIngredients, setScrapeIngredients] = useState(false); // Ingredients scraping disabled by default
  const [nutritionOnlyMode, setNutritionOnlyMode] = useState(false); // Nutrition scraping only (skip images)
  const [ukFilterStats, setUkFilterStats] = useState<{
    total: number;
    ukCount: number;
    nonUkCount: number;
    ukPercentage: number;
    nonUkPercentage: number;
  } | null>(null);
  const [imageFilterStats, setImageFilterStats] = useState<{
    total: number;
    withImages: number;
    withoutImages: number;
  } | null>(null);
  const [barcodeQuery, setBarcodeQuery] = useState('');
  const [isBarcodeSearching, setIsBarcodeSearching] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);

  // Preview modal
  const [previewImage, setPreviewImage] = useState<{
    url: string;
    title: string;
    analysis?: ImageAnalysisResult;
  } | null>(null);

  const pauseRef = useRef(false);
  const abortRef = useRef(false);
  const ITEMS_PER_PAGE = 500; // Increased from 50 for better scrolling experience
  const STORAGE_KEY = 'nutrasafe_image_scraper_progress';

  // ========== AUTO-SAVE PROGRESS TO LOCALSTORAGE ==========
  // Save progress whenever foods state changes (with debounce)
  const saveTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Save current progress to localStorage
  const saveProgress = useCallback(() => {
    if (foods.length === 0) return;

    // Only save foods that have been processed or have results
    const progressData = {
      savedAt: new Date().toISOString(),
      foods: foods.map(f => ({
        id: f.id,
        objectID: f.objectID,
        name: f.name,
        brandName: f.brandName,
        barcode: f.barcode,
        currentImageUrl: f.currentImageUrl,
        sourceIndex: f.sourceIndex,
        status: f.status,
        selectedImageUrl: f.selectedImageUrl,
        confidence: f.confidence,
        nutritionData: f.nutritionData,
        nutritionStatus: f.nutritionStatus,
        error: f.error,
        wasProcessed: f.wasProcessed,
        // Don't save searchResults to keep storage small
      })),
      stats,
      processingLog: processingLog.slice(-20), // Keep last 20 log entries
      currentProcessingIndex,
      totalToProcess,
      isPaused,
      // SAVE SETTINGS - critical for resume functionality
      settings: {
        scrapeNutrition,
        scrapeServingSize,
        scrapeIngredients,
        nutritionOnlyMode,
        filterUKOnly,
        filterNoImages,
        filterZeroCalories,
        excludeDrinks,
      },
    };

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(progressData));
      console.log(`💾 Progress saved: ${foods.length} foods`);
    } catch (e) {
      console.warn('Failed to save progress to localStorage:', e);
    }
  }, [foods, stats, processingLog, currentProcessingIndex, totalToProcess, isPaused, scrapeNutrition, scrapeServingSize, scrapeIngredients, nutritionOnlyMode, filterUKOnly, filterNoImages, filterZeroCalories, excludeDrinks]);

  // Auto-save with debounce (save 2 seconds after last change)
  useEffect(() => {
    if (foods.length === 0) return;

    // Clear existing timeout
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }

    // Set new timeout
    saveTimeoutRef.current = setTimeout(() => {
      saveProgress();
    }, 2000);

    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
    };
  }, [foods, saveProgress]);

  // Load saved progress on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const data = JSON.parse(saved);
        const savedAt = new Date(data.savedAt);
        const ageHours = (Date.now() - savedAt.getTime()) / (1000 * 60 * 60);

        // Only restore if less than 24 hours old
        if (ageHours < 24 && data.foods?.length > 0) {
          console.log(`📂 Found saved progress from ${savedAt.toLocaleString()} (${data.foods.length} foods)`);

          // Build settings description
          const settings = data.settings || {};
          const settingsDesc = [];
          if (settings.nutritionOnlyMode) {
            settingsDesc.push('🍎 Nutrition only (no images)');
          } else {
            settingsDesc.push('📷 Image search');
          }
          if (settings.scrapeNutrition) settingsDesc.push('nutrition');
          if (settings.scrapeServingSize) settingsDesc.push('serving size');
          if (settings.scrapeIngredients) settingsDesc.push('ingredients');

          const processedCount = data.foods.filter((f: any) => f.wasProcessed || f.status === 'ready' || f.status === 'completed').length;
          const pendingCount = data.foods.length - processedCount;

          // Ask user if they want to restore
          const shouldRestore = window.confirm(
            `Found saved progress from ${savedAt.toLocaleString()}:\n\n` +
            `• ${data.foods.length} foods loaded\n` +
            `• ${processedCount} processed / ${pendingCount} remaining\n` +
            `• Settings: ${settingsDesc.join(', ') || 'default'}\n\n` +
            `Restore this progress?\n` +
            `(Settings will be restored as they were. You can change them later without losing progress.)`
          );

          if (shouldRestore) {
            // Restore foods with default values for missing fields
            const restoredFoods: FoodWithImage[] = data.foods.map((f: any) => ({
              ...f,
              selected: false,
              calories: f.calories || undefined,
              dontShowImage: f.dontShowImage || false,
              searchResults: [], // Don't restore search results
              analysis: null,
              analysisProgress: 0,
              wasProcessed: f.wasProcessed || false,
            }));

            setFoods(restoredFoods);
            if (data.stats) setStats(data.stats);
            if (data.processingLog) setProcessingLog(data.processingLog);
            if (data.currentProcessingIndex !== undefined) setCurrentProcessingIndex(data.currentProcessingIndex);
            if (data.totalToProcess !== undefined) setTotalToProcess(data.totalToProcess);
            if (data.isPaused !== undefined) {
              setIsPaused(data.isPaused);
              pauseRef.current = data.isPaused;
            }

            // RESTORE SETTINGS - critical!
            if (settings.scrapeNutrition !== undefined) setScrapeNutrition(settings.scrapeNutrition);
            if (settings.scrapeServingSize !== undefined) setScrapeServingSize(settings.scrapeServingSize);
            if (settings.scrapeIngredients !== undefined) setScrapeIngredients(settings.scrapeIngredients);
            if (settings.nutritionOnlyMode !== undefined) setNutritionOnlyMode(settings.nutritionOnlyMode);
            if (settings.filterUKOnly !== undefined) setFilterUKOnly(settings.filterUKOnly);
            if (settings.filterNoImages !== undefined) setFilterNoImages(settings.filterNoImages);
            if (settings.filterZeroCalories !== undefined) setFilterZeroCalories(settings.filterZeroCalories);
            if (settings.excludeDrinks !== undefined) setExcludeDrinks(settings.excludeDrinks);

            setShowIndexSelector(false); // Hide selector since we loaded data

            console.log(`✅ Restored ${restoredFoods.length} foods from saved progress`);
            console.log(`⚙️ Restored settings:`, settings);
            if (data.currentProcessingIndex > 0) {
              console.log(`📍 Processing was at item ${data.currentProcessingIndex}/${data.totalToProcess}`);
            }
          }
        }
      }
    } catch (e) {
      console.warn('Failed to load saved progress:', e);
    }
  }, []);

  // Clear saved progress
  const clearSavedProgress = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    console.log('🗑️ Cleared saved progress');
  }, []);

  // Reset processed flags - allows reprocessing all foods
  const resetProcessedFlags = useCallback(() => {
    setFoods(prev => prev.map(f => ({ ...f, wasProcessed: false })));
    setProcessingLog(prev => [...prev, `${new Date().toLocaleTimeString()}: 🔄 Reset all processed flags - foods can be reprocessed`]);
  }, []);

  // Helper function to detect if a food is a drink based on its name
  const isDrink = (name: string): boolean => {
    if (!name) return false;
    const lowerName = name.toLowerCase();

    // Common drink keywords
    const drinkKeywords = [
      'water', 'drink', 'juice', 'soda', 'cola', 'pepsi', 'coke',
      'tea', 'coffee', 'latte', 'cappuccino', 'espresso', 'mocha',
      'beverage', 'smoothie', 'shake', 'milkshake', 'frappuccino',
      'lemonade', 'squash', 'cordial', 'pop', 'fizzy',
      'sprite', 'fanta', 'irn bru', 'ribena', 'lucozade',
      'energy drink', 'sports drink', 'vitamin water',
      'iced tea', 'green tea', 'black tea', 'herbal tea',
      'hot chocolate', 'cocoa drink', 'chocolate drink',
      'milk drink', 'flavoured milk', 'almond milk', 'oat milk', 'soy milk',
      'protein shake', 'meal replacement drink'
    ];

    return drinkKeywords.some(keyword => lowerName.includes(keyword));
  };

  const addLog = (message: string) => {
    console.log(message);
    setProcessingLog(prev => [...prev.slice(-50), `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  // Scrape nutrition data from Google Search - fetches and parses actual page content
  const scrapeNutritionData = async (food: FoodWithImage): Promise<NutritionData | null> => {
    try {
      // STEP 1: Try Google search first
      const SEARCHAPI_KEY = import.meta.env.VITE_SEARCHAPI_KEY || '';
      if (!SEARCHAPI_KEY) {
        console.warn('⚠️ SearchAPI key not configured - skipping Google search (Knowledge Graph, Answer Box, web scraping)');
        console.warn('   Will try Open Food Facts API as fallback if barcode exists');
        return null;
      }

      // Build search query - prioritize UK supermarket sites for nutrition info
      let query = `${food.brandName || ''} ${food.name} nutrition serving size site:asda.com OR site:tesco.com`.trim();

      const params = new URLSearchParams({
        api_key: SEARCHAPI_KEY,
        engine: 'google',
        q: query,
        hl: 'en',
        gl: 'uk',
        num: '5', // Get top 5 results (increased from 3)
      });

      const response = await fetch(`https://www.searchapi.io/api/v1/search?${params}`, {
        method: 'GET',
        headers: { 'Accept': 'application/json' },
      });

      if (!response.ok) {
        console.error('SearchAPI nutrition request failed:', response.status);
        return null;
      }

      const data = await response.json();

      // Google often returns nutrition info in knowledge_graph or answer_box
      const knowledgeGraph = data.knowledge_graph;
      const answerBox = data.answer_box;

      // Try to extract nutrition from knowledge graph
      if (knowledgeGraph && knowledgeGraph.nutrition_facts) {
        const facts = knowledgeGraph.nutrition_facts;
        const nutritionData = {
          calories: parseFloat(facts.calories) || undefined,
          protein: parseFloat(facts.protein) || undefined,
          carbs: parseFloat(facts.carbohydrates) || undefined,
          fat: parseFloat(facts.fat) || undefined,
          saturatedFat: parseFloat(facts.saturated_fat) || undefined,
          fiber: parseFloat(facts.fiber) || undefined,
          sugar: parseFloat(facts.sugar) || undefined,
          sodium: parseFloat(facts.sodium) || undefined,
          servingSize: facts.serving_size,
          source: 'Google Knowledge Graph',
        };

        // Filter based on user preferences
        const filteredData: Partial<NutritionData> = { source: nutritionData.source };

        if (scrapeNutrition) {
          if (nutritionData.calories !== undefined) filteredData.calories = nutritionData.calories;
          if (nutritionData.protein !== undefined) filteredData.protein = nutritionData.protein;
          if (nutritionData.carbs !== undefined) filteredData.carbs = nutritionData.carbs;
          if (nutritionData.fat !== undefined) filteredData.fat = nutritionData.fat;
          if (nutritionData.saturatedFat !== undefined) filteredData.saturatedFat = nutritionData.saturatedFat;
          if (nutritionData.fiber !== undefined) filteredData.fiber = nutritionData.fiber;
          if (nutritionData.sugar !== undefined) filteredData.sugar = nutritionData.sugar;
          if (nutritionData.sodium !== undefined) filteredData.sodium = nutritionData.sodium;
        }

        if (scrapeServingSize && nutritionData.servingSize) {
          filteredData.servingSize = nutritionData.servingSize;
        }

        return filteredData as NutritionData;
      }

      // Try to extract from answer box
      if (answerBox && answerBox.nutrition_info) {
        const info = answerBox.nutrition_info;
        const nutritionData = {
          calories: parseFloat(info.calories) || undefined,
          protein: parseFloat(info.protein) || undefined,
          carbs: parseFloat(info.carbs) || undefined,
          fat: parseFloat(info.fat) || undefined,
          source: 'Google Answer Box',
        };

        // Filter based on user preferences
        const filteredData: Partial<NutritionData> = { source: nutritionData.source };

        if (scrapeNutrition) {
          if (nutritionData.calories !== undefined) filteredData.calories = nutritionData.calories;
          if (nutritionData.protein !== undefined) filteredData.protein = nutritionData.protein;
          if (nutritionData.carbs !== undefined) filteredData.carbs = nutritionData.carbs;
          if (nutritionData.fat !== undefined) filteredData.fat = nutritionData.fat;
        }

        return filteredData as NutritionData;
      }

      // Fetch and parse actual page content from top results
      const organicResults = data.organic_results || [];
      if (organicResults.length > 0) {
        // Try to fetch actual page content from top 3 results
        // Keep searching if a site only has per-100g data (we want per-serving)
        let bestPer100gResult: { data: Partial<NutritionData>; source: string; url: string } | null = null;

        for (let i = 0; i < Math.min(3, organicResults.length); i++) {
          const result = organicResults[i];
          const pageUrl = result.link;

          if (!pageUrl) continue;

          try {
            // Fetch the actual page content via CORS proxy
            const proxyUrl = `https://corsproxy.io/?${encodeURIComponent(pageUrl)}`;
            console.log(`Fetching page ${i + 1}: ${pageUrl}`);

            const pageResponse = await fetch(proxyUrl, {
              headers: {
                'Accept': 'text/html,application/xhtml+xml,application/xml',
              },
            });

            if (!pageResponse.ok) {
              console.log(`Page fetch failed with status ${pageResponse.status}`);
              continue;
            }

            const pageHtml = await pageResponse.text();
            console.log(`Fetched ${pageHtml.length} bytes from page ${i + 1}`);

            // Check if this page has per-serving data (not just per-100g)
            // Per-serving can be labeled many ways: "per piece", "per bar", "per 30g", "per slice", "per biscuit", etc.
            // We look for any "per X" pattern that ISN'T "per 100g"
            const lowerHtml = pageHtml.toLowerCase();
            const has100g = /per\s*100\s*g/i.test(lowerHtml);

            // Find ALL "per X" patterns in the page for debugging
            const allPerMatches = [...lowerHtml.matchAll(/per\s+[^\s<]{1,20}/gi)];
            console.log(`🔍 Page ${i + 1} - All "per X" patterns found:`, allPerMatches.slice(0, 10).map(m => m[0]));

            // Match "per Xg" where X isn't 100, or "per piece/bar/slice/serving/portion/biscuit/etc"
            const hasOtherPerColumn = /per\s+(?!100\s*g)(\d+\s*g\b|piece|bar|slice|serving|portion|biscuit|pack|sachet|pot|unit|item|cookie|cracker|tablet|capsule|scoop)/i.test(lowerHtml);
            const hasServingData = hasOtherPerColumn;
            const hasOnly100g = has100g && !hasServingData;

            console.log(`🔍 Page ${i + 1} - has100g=${has100g}, hasOtherPerColumn=${hasOtherPerColumn}, hasOnly100g=${hasOnly100g}`);

            // Parse HTML to extract nutrition data
            const nutritionData = parseNutritionFromHtml(pageHtml);

            if (nutritionData && Object.keys(nutritionData).length > 2) {
              const source = new URL(pageUrl).hostname.replace('www.', '');

              // If this page has per-serving data, use it immediately
              if (hasServingData) {
                console.log(`✅ Page ${i + 1} has per-serving data - using this source`);

                // Filter based on user preferences
                const filteredData: Partial<NutritionData> = { source, sourceUrl: pageUrl };

                if (scrapeNutrition) {
                  if (nutritionData.calories !== undefined) filteredData.calories = nutritionData.calories;
                  if (nutritionData.protein !== undefined) filteredData.protein = nutritionData.protein;
                  if (nutritionData.carbs !== undefined) filteredData.carbs = nutritionData.carbs;
                  if (nutritionData.fat !== undefined) filteredData.fat = nutritionData.fat;
                  if (nutritionData.saturatedFat !== undefined) filteredData.saturatedFat = nutritionData.saturatedFat;
                  if (nutritionData.fiber !== undefined) filteredData.fiber = nutritionData.fiber;
                  if (nutritionData.sugar !== undefined) filteredData.sugar = nutritionData.sugar;
                  if (nutritionData.sodium !== undefined) filteredData.sodium = nutritionData.sodium;
                  if (nutritionData.salt !== undefined) filteredData.salt = nutritionData.salt;
                }

                if (scrapeServingSize && nutritionData.servingSize) {
                  filteredData.servingSize = nutritionData.servingSize;
                }

                if (scrapeIngredients && nutritionData.ingredients) {
                  filteredData.ingredients = nutritionData.ingredients;
                }

                // CRITICAL: Only return data if we have a SPECIFIC serving size
                if (scrapeServingSize) {
                  if (!filteredData.servingSize) {
                    console.log(`⚠️ Page ${i + 1} has "per serving" indicators but NO serving size quantity found`);
                    console.log(`   Looked for: "serving size: Xg", "per piece (Xg)", header "Per Xg"`);
                    console.log(`   Rejecting data - will try next site`);
                    // Save as fallback but DON'T return yet
                    if (!bestPer100gResult) {
                      bestPer100gResult = { data: nutritionData, source, url: pageUrl };
                    }
                    continue; // Try next site
                  }

                  // Reject vague serving sizes without quantities
                  const vagueSizes = ['per serving', 'per portion', 'serving', 'portion'];
                  if (vagueSizes.includes(String(filteredData.servingSize).toLowerCase().trim())) {
                    console.log(`⚠️ Page ${i + 1} has vague serving size "${filteredData.servingSize}" (no quantity)`);
                    console.log(`   Need specific size like "30g", "per piece (50g)", etc.`);
                    if (!bestPer100gResult) {
                      bestPer100gResult = { data: nutritionData, source, url: pageUrl };
                    }
                    continue; // Try next site
                  }
                }

                console.log(`✅ Page ${i + 1} validated: per-serving data with serving size "${filteredData.servingSize}"`);
                return filteredData as NutritionData;
              }

              // If only per-100g, save as fallback but keep searching
              if (hasOnly100g && !bestPer100gResult) {
                console.log(`⚠️ Page ${i + 1} only has per-100g data - saving as fallback, trying next site...`);
                bestPer100gResult = { data: nutritionData, source, url: pageUrl };
              }
            } else {
              console.log(`Insufficient nutrition data from page ${i + 1}: ${Object.keys(nutritionData || {}).length} fields`);
            }
          } catch (pageError) {
            console.log(`Failed to fetch page ${i + 1}:`, pageError instanceof Error ? pageError.message : 'Unknown error');
            continue;
          }
        }

        // Reject per-100g fallback if scrapeServingSize is enabled OR if this is fast food
        // Fast food items MUST be per-meal/per-item, never per 100g
        const isFastFood = food.sourceIndex === 'fast_foods_database';
        const rejectPer100g = scrapeServingSize || isFastFood;

        if (bestPer100gResult && rejectPer100g) {
          if (isFastFood) {
            console.log(`🍔 Fast food: No per-meal data found - per-100g data REJECTED`);
            console.log(`   Fast food must have per-meal nutrition (e.g., "1 Big Mac = 550 kcal")`);
          } else {
            console.log(`❌ No per-serving data found in 3 sites - per-100g data REJECTED`);
            console.log(`   Found per-100g data from ${bestPer100gResult.source} but no serving size specified`);
            console.log(`   To accept this data, page must have serving size like "per 30g serving" or "per piece (50g)"`);
          }
          // Don't return anything - let other extraction methods try
        } else if (bestPer100gResult && !rejectPer100g) {
          // If not scraping serving size, allow per-100g fallback (old behavior)
          console.log(`📊 No per-serving data found - using per-100g fallback (serving size scraping disabled)`);
          const filteredData: Partial<NutritionData> = {
            source: bestPer100gResult.source + ' (per 100g)',
            sourceUrl: bestPer100gResult.url
          };

          if (scrapeNutrition) {
            const nutritionData = bestPer100gResult.data;
            if (nutritionData.calories !== undefined) filteredData.calories = nutritionData.calories;
            if (nutritionData.protein !== undefined) filteredData.protein = nutritionData.protein;
            if (nutritionData.carbs !== undefined) filteredData.carbs = nutritionData.carbs;
            if (nutritionData.fat !== undefined) filteredData.fat = nutritionData.fat;
            if (nutritionData.saturatedFat !== undefined) filteredData.saturatedFat = nutritionData.saturatedFat;
            if (nutritionData.fiber !== undefined) filteredData.fiber = nutritionData.fiber;
            if (nutritionData.sugar !== undefined) filteredData.sugar = nutritionData.sugar;
            if (nutritionData.sodium !== undefined) filteredData.sodium = nutritionData.sodium;
            if (nutritionData.salt !== undefined) filteredData.salt = nutritionData.salt;
          }

          if (scrapeServingSize && bestPer100gResult.data.servingSize) {
            filteredData.servingSize = bestPer100gResult.data.servingSize;
          }

          if (scrapeIngredients && bestPer100gResult.data.ingredients) {
            filteredData.ingredients = bestPer100gResult.data.ingredients;
          }

          return filteredData as NutritionData;
        }

        // Fallback: parse from search snippets if page scraping failed
        const combinedText = organicResults.slice(0, 3)
          .map((r: any) => `${r.snippet || ''} ${r.title || ''}`)
          .join(' ');

        const caloriesMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*(?:calories|kcal|cal)/i);
        const proteinMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*protein/i);
        const carbsMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:carb(?:ohydrate)?s?|carbs)/i);
        const fatMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:total\s+)?fat/i);
        const saturatedFatMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*saturated\s*fat/i);
        const fiberMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:fiber|fibre)/i);
        const sugarMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*sugar/i);
        const sodiumMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*(?:mg|g)?\s*sodium/i);
        const saltMatch = combinedText.match(/(\d+(?:\.\d+)?)\s*g?\s*salt/i);
        const servingSizeMatch = combinedText.match(/(?:serving\s+size|per\s+serving):\s*([^.,;\n]*?\d+\s*(?:g|ml|oz|fl\s*oz|cup|tbsp|tsp|litre|liter|l)[^.,;\n]*)/i);
        const ingredientsMatch = combinedText.match(/ingredients?[:\s]+([^.]{30,500})/i);

        if (caloriesMatch || proteinMatch || carbsMatch || fatMatch) {
          const snippetData: Partial<NutritionData> = { source: 'Google Snippets' };

          // Only include fields user wants
          if (scrapeNutrition) {
            if (caloriesMatch) snippetData.calories = parseFloat(caloriesMatch[1]);
            if (proteinMatch) snippetData.protein = parseFloat(proteinMatch[1]);
            if (carbsMatch) snippetData.carbs = parseFloat(carbsMatch[1]);
            if (fatMatch) snippetData.fat = parseFloat(fatMatch[1]);
            if (saturatedFatMatch) snippetData.saturatedFat = parseFloat(saturatedFatMatch[1]);
            if (fiberMatch) snippetData.fiber = parseFloat(fiberMatch[1]);
            if (sugarMatch) snippetData.sugar = parseFloat(sugarMatch[1]);
            if (sodiumMatch) snippetData.sodium = parseFloat(sodiumMatch[1]);
            if (saltMatch) snippetData.salt = parseFloat(saltMatch[1]);
          }

          if (scrapeServingSize && servingSizeMatch) {
            snippetData.servingSize = servingSizeMatch[1].trim();
          }

          if (scrapeIngredients && ingredientsMatch) {
            snippetData.ingredients = ingredientsMatch[1].trim();
          }

          // CRITICAL: Reject if serving size is required but not found
          if (scrapeServingSize && !snippetData.servingSize) {
            console.log(`⚠️ Google Snippets: Found nutrition but NO serving size - rejecting`);
            console.log(`   Need serving size to accept data when "Require Serving Size" is enabled`);
            // Don't return - fall through to next method (Open Food Facts)
          } else {
            return snippetData as NutritionData;
          }
        }
      }

      // STEP 4 (FINAL): Try Open Food Facts API as last resort if we have a barcode
      if (food.barcode) {
        console.log(`🔍 Final fallback: Trying Open Food Facts API with barcode: ${food.barcode}`);
        try {
          const offResponse = await fetch(`https://world.openfoodfacts.org/api/v2/product/${food.barcode}.json`, {
            headers: { 'Accept': 'application/json' },
          });

          if (offResponse.ok) {
            const offData = await offResponse.json();
            if (offData.status === 1 && offData.product) {
              const product = offData.product;
              const nutriments = product.nutriments || {};

              // Check if we have per-serving data
              const hasServingData = nutriments['energy-kcal_serving'] !== undefined ||
                                     nutriments.energy_serving !== undefined;

              if (hasServingData || nutriments['energy-kcal_100g'] !== undefined) {
                // Prefer per-serving values, fall back to per-100g
                const useServing = hasServingData;
                const suffix = useServing ? '_serving' : '_100g';

                // Get serving size
                let servingSize: string | undefined;
                if (product.serving_size) {
                  servingSize = product.serving_size;
                } else if (product.serving_quantity) {
                  servingSize = `${product.serving_quantity}g`;
                }

                const nutritionData: NutritionData = {
                  calories: nutriments[`energy-kcal${suffix}`] || (nutriments[`energy${suffix}`] ? nutriments[`energy${suffix}`] / 4.184 : undefined),
                  protein: nutriments[`proteins${suffix}`],
                  carbs: nutriments[`carbohydrates${suffix}`],
                  fat: nutriments[`fat${suffix}`],
                  saturatedFat: nutriments[`saturated-fat${suffix}`],
                  fiber: nutriments[`fiber${suffix}`],
                  sugar: nutriments[`sugars${suffix}`],
                  sodium: nutriments[`sodium${suffix}`],
                  salt: nutriments[`salt${suffix}`],
                  servingSize,
                  ingredients: product.ingredients_text_en || product.ingredients_text,
                  source: `Open Food Facts (${useServing ? 'per serving' : 'per 100g'})`,
                };

                // Count valid fields
                const validFields = Object.entries(nutritionData)
                  .filter(([k, v]) => v !== undefined && k !== 'source' && k !== 'ingredients' && k !== 'servingSize')
                  .length;

                if (validFields >= 3) {
                  console.log(`✅ Open Food Facts found ${validFields} nutrition fields (${useServing ? 'per serving' : 'per 100g'})`);
                  if (servingSize) console.log(`   📏 Serving size: ${servingSize}`);

                  // Filter based on user preferences (same as web scraping)
                  const offUrl = `https://world.openfoodfacts.org/product/${food.barcode}`;
                  const filteredData: Partial<NutritionData> = { source: nutritionData.source, sourceUrl: offUrl };

                  if (scrapeNutrition) {
                    if (nutritionData.calories !== undefined) filteredData.calories = nutritionData.calories;
                    if (nutritionData.protein !== undefined) filteredData.protein = nutritionData.protein;
                    if (nutritionData.carbs !== undefined) filteredData.carbs = nutritionData.carbs;
                    if (nutritionData.fat !== undefined) filteredData.fat = nutritionData.fat;
                    if (nutritionData.saturatedFat !== undefined) filteredData.saturatedFat = nutritionData.saturatedFat;
                    if (nutritionData.fiber !== undefined) filteredData.fiber = nutritionData.fiber;
                    if (nutritionData.sugar !== undefined) filteredData.sugar = nutritionData.sugar;
                    if (nutritionData.sodium !== undefined) filteredData.sodium = nutritionData.sodium;
                    if (nutritionData.salt !== undefined) filteredData.salt = nutritionData.salt;
                  }

                  if (scrapeServingSize && nutritionData.servingSize) {
                    filteredData.servingSize = nutritionData.servingSize;
                  }

                  if (scrapeIngredients && nutritionData.ingredients) {
                    filteredData.ingredients = nutritionData.ingredients;
                  }

                  // CRITICAL: Reject per-100g data if serving size is required but not found
                  // OR if this is a fast food item (fast food MUST be per-meal)
                  const isFastFood = food.sourceIndex === 'fast_foods_database';
                  const needsServingSize = scrapeServingSize || isFastFood;

                  if (needsServingSize && !filteredData.servingSize) {
                    if (isFastFood) {
                      console.log(`🍔 Fast food: Open Food Facts has per-100g data but NO per-meal data - rejecting`);
                      console.log(`   Fast food items must have per-meal nutrition, not per 100g`);
                    } else {
                      console.log(`❌ Open Food Facts: Has per-100g data but NO serving size - rejecting`);
                      console.log(`   Need serving size to accept data when "Require Serving Size" is enabled`);
                      console.log(`   To accept this data, Open Food Facts needs serving_size or serving_quantity in the API response`);
                    }
                    return null; // Reject - no more fallbacks
                  }

                  console.log(`   Filtered to ${Object.keys(filteredData).length - 1} fields based on checkboxes`);
                  return filteredData as NutritionData;
                }
              }
            }
          }
          console.log(`   Open Food Facts: No data found for barcode ${food.barcode}`);
        } catch (offError) {
          console.log(`   Open Food Facts API error:`, offError);
        }
      }

      return null;
    } catch (error) {
      console.error('Error scraping nutrition from Google:', error);
      return null;
    }
  };

  // Parse nutrition data from HTML page content
  const parseNutritionFromHtml = (html: string): Partial<NutritionData> | null => {
    console.log(`🔍 Parsing HTML: ${html.length} bytes`);
    const lowerHtml = html.toLowerCase();

    // Look for nutrition data in the HTML - very aggressive pattern matching
    const nutritionData: Partial<NutritionData> = {};

    // STEP 1: Try to extract from JSON-LD structured data (most reliable)
    console.log(`📋 Step 1: Checking for JSON-LD structured data...`);
    const jsonLdMatches = html.matchAll(/<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/gis);
    for (const match of jsonLdMatches) {
      try {
        const jsonData = JSON.parse(match[1]);
        if (jsonData.nutrition || jsonData['@type'] === 'NutritionInformation') {
          const nutrition = jsonData.nutrition || jsonData;
          if (nutrition.calories) nutritionData.calories = parseFloat(String(nutrition.calories).replace(/[^0-9.]/g, ''));
          if (nutrition.proteinContent) nutritionData.protein = parseFloat(String(nutrition.proteinContent).replace(/[^0-9.]/g, ''));
          if (nutrition.carbohydrateContent) nutritionData.carbs = parseFloat(String(nutrition.carbohydrateContent).replace(/[^0-9.]/g, ''));
          if (nutrition.fatContent) nutritionData.fat = parseFloat(String(nutrition.fatContent).replace(/[^0-9.]/g, ''));
          if (nutrition.saturatedFatContent) nutritionData.saturatedFat = parseFloat(String(nutrition.saturatedFatContent).replace(/[^0-9.]/g, ''));
          if (nutrition.fiberContent) nutritionData.fiber = parseFloat(String(nutrition.fiberContent).replace(/[^0-9.]/g, ''));
          if (nutrition.sugarContent) nutritionData.sugar = parseFloat(String(nutrition.sugarContent).replace(/[^0-9.]/g, ''));
          if (nutrition.sodiumContent) nutritionData.sodium = parseFloat(String(nutrition.sodiumContent).replace(/[^0-9.]/g, ''));
          if (nutrition.servingSize) nutritionData.servingSize = String(nutrition.servingSize);

          // If we found good data, return early
          if (Object.keys(nutritionData).length >= 3) {
            console.log(`✅ Step 1 success: Found ${Object.keys(nutritionData).length} fields from JSON-LD`);
            return nutritionData;
          }
        }
      } catch (e) {
        // Invalid JSON, continue
      }
    }
    console.log(`⏭️ Step 1 complete: ${Object.keys(nutritionData).length} fields from JSON-LD (need 3+ for early return)`);

    // STEP 2: Look for "per serving/piece/bar/etc" sections with nearby nutrition values (prefer over per 100g)
    console.log(`📋 Step 2: Checking for per-serving sections (per piece, per bar, per 30g, etc)...`);
    // This catches nutrition tables where values are in a structured format
    // Prioritize any "per X" that isn't "per 100g" - could be per piece, per bar, per 30g, etc.
    const perServingSection = lowerHtml.match(/(per\s+(?!100\s*g)(?:\d+\s*g|piece|bar|slice|serving|portion|biscuit|pack|sachet|pot|unit|item)[^<]*?(?:<[^>]+>[^<]*?){0,50}?(?:calories|kcal|energy|protein|fat|carb)[^<]*?(?:<[^>]+>[^<]*?){0,100})/gis);
    const per100gSection = !perServingSection ? lowerHtml.match(/(per\s*100\s*g[^<]*?(?:<[^>]+>[^<]*?){0,50}?(?:calories|kcal|energy|protein|fat|carb)[^<]*?(?:<[^>]+>[^<]*?){0,100})/gis) : null;
    const nutritionSection = perServingSection || per100gSection;
    if (nutritionSection) {
      const sectionText = nutritionSection[0];
      // Extract all numbers followed by units from this section
      const matches = sectionText.matchAll(/(\w+)[:\s]*(\d+(?:\.\d+)?)\s*(g|mg|kcal)?/gi);
      for (const match of matches) {
        const label = match[1].toLowerCase();
        const value = parseFloat(match[2]);

        if (label.includes('calor') || label.includes('kcal') || label.includes('energy')) {
          nutritionData.calories = value;
        } else if (label.includes('protein')) {
          nutritionData.protein = value;
        } else if (label.includes('carb')) {
          nutritionData.carbs = value;
        } else if (label.includes('fat') && !label.includes('saturat')) {
          nutritionData.fat = value;
        } else if (label.includes('saturat')) {
          nutritionData.saturatedFat = value;
        } else if (label.includes('sugar')) {
          nutritionData.sugar = value;
        } else if (label.includes('fib')) {
          nutritionData.fiber = value;
        } else if (label.includes('sodium')) {
          nutritionData.sodium = value;
        } else if (label.includes('salt')) {
          nutritionData.salt = value;
        }
      }
    }
    console.log(`⏭️ Step 2 complete: ${Object.keys(nutritionData).length} fields total`);

    // STEP 2.5: Extract from HTML tables (common on product pages)
    // Simple approach: Find all "per X" headers. If one is "per 100g", use the other one.
    console.log(`📋 Step 2.5: Extracting from HTML tables (looking for per-serving column)...`);

    // Find all "per ..." patterns in the HTML and their column positions
    const allPerMatches = [...lowerHtml.matchAll(/per\s+(\d+\s*g|100\s*g|\w+)/gi)];
    const perHeaders: { text: string; is100g: boolean }[] = [];

    for (const match of allPerMatches) {
      const fullMatch = match[0].toLowerCase();
      const is100g = /per\s*100\s*g/i.test(fullMatch);
      // Avoid duplicates
      if (!perHeaders.find(h => h.text === fullMatch)) {
        perHeaders.push({ text: fullMatch, is100g });
      }
    }

    console.log(`   Found ${perHeaders.length} "per" headers:`, perHeaders.map(h => h.text));

    // Find column indices by scanning table headers
    let servingColumnIndex = -1;
    let per100gColumnIndex = -1;
    let servingColumnExplicitlyFound = false; // Track if we found a real "per piece" etc header

    const allRows = [...html.matchAll(/<tr[^>]*>(.*?)<\/tr>/gis)];
    for (const rowMatch of allRows) {
      const rowHtml = rowMatch[1];
      const cells = [...rowHtml.matchAll(/<t[dh][^>]*>(.*?)<\/t[dh]>/gis)];

      for (let idx = 0; idx < cells.length; idx++) {
        // Strip HTML tags to get plain text
        const cellText = cells[idx][1].replace(/<[^>]*>/g, ' ').toLowerCase().trim();
        console.log(`      Cell ${idx}: "${cellText.substring(0, 50)}"`);

        // Match "per 100g" or "for 100g" or "100 g" or "per: 100g" patterns
        if (/(?:per|for)[:\s]*100\s*g/i.test(cellText) || /\b100\s*g\b/i.test(cellText)) {
          per100gColumnIndex = idx;
          console.log(`   Found "per 100g" in column ${idx}`);
        } else if (/(?:per|for)[:\s]+(?!100\s*g)/i.test(cellText) && !/per\s*kg/i.test(cellText) && !/inspiration/i.test(cellText)) {
          // This is a "per X" or "for X" that isn't "per 100g" - this is our serving column
          // Handles "per piece", "per: 1 gyoza", "for serving", etc.
          servingColumnIndex = idx;
          servingColumnExplicitlyFound = true;
          console.log(`   Found serving column "${cellText.substring(0, 30)}" in column ${idx}`);

          // NEW: Extract serving size from header when serving column is found
          const servingSizeMatch = cellText.match(/per\s+(?:(\d+(?:\.\d+)?)\s*(g|ml)|(\w+)\s*\((\d+(?:\.\d+)?)\s*(g|ml)\))/i);
          if (servingSizeMatch && !nutritionData.servingSize) {
            if (servingSizeMatch[1]) {
              // "Per 30g" format
              nutritionData.servingSize = `${servingSizeMatch[1]}${servingSizeMatch[2]}`;
              console.log(`   📏 Extracted serving size from header: ${nutritionData.servingSize}`);
            } else if (servingSizeMatch[3] && servingSizeMatch[4]) {
              // "Per piece (50g)" format
              nutritionData.servingSize = `per ${servingSizeMatch[3]} (${servingSizeMatch[4]}${servingSizeMatch[5]})`;
              console.log(`   📏 Extracted serving size from header: ${nutritionData.servingSize}`);
            }
          }
        }
      }
      // Stop after finding both
      if (per100gColumnIndex >= 0 && servingColumnIndex >= 0) break;
    }

    // If we found per 100g but not the other serving column explicitly,
    // the serving column is likely the one AFTER per 100g
    if (per100gColumnIndex >= 0 && servingColumnIndex < 0) {
      servingColumnIndex = per100gColumnIndex + 1;
      console.log(`   ⚠️ Inferring serving column as ${servingColumnIndex} (RISKY - not explicitly found in header)`);
      console.log(`      Will validate that this column exists in data rows and has different values`);
      console.log(`      If validation fails, this page likely only has per-100g data`);
    }

    const isMultiColumnTable = per100gColumnIndex >= 0;

    // CRITICAL: Check if the serving column is just an inference or was actually found in headers
    // Only mark as inferred if we did NOT explicitly find a serving column header
    const servingColumnWasInferred = servingColumnIndex >= 0 && !servingColumnExplicitlyFound;

    console.log(`   Table structure: servingCol=${servingColumnIndex}, per100gCol=${per100gColumnIndex}, isMultiColumn=${isMultiColumnTable}, servingColInferred=${servingColumnWasInferred}`);

    // Track if we actually found data in the serving column
    // If we inferred a serving column but data rows don't have it, we should NOT extract per-100g values
    let foundAnyServingData = false;
    let servingColumnMissing = false;

    // Look for <tr> rows with nutrition labels and values
    const tableMatches = html.matchAll(/<tr[^>]*>(.*?)<\/tr>/gis);
    for (const tableMatch of tableMatches) {
      const rowHtml = tableMatch[1];
      const rowLower = rowHtml.toLowerCase();

      // Check if this row contains a nutrition label
      const hasNutritionLabel = /calor|kcal|protein|carb|fat|sugar|fib|sodium|salt/i.test(rowLower);
      if (!hasNutritionLabel) continue;

      // Extract all cells from the row
      const cells = [...rowHtml.matchAll(/<t[dh][^>]*>(.*?)<\/t[dh]>/gis)];

      // Extract numbers from each cell, keeping track of their positions
      const cellData: { index: number; value: number; text: string }[] = [];
      for (let idx = 0; idx < cells.length; idx++) {
        const cellContent = cells[idx][1];
        const numMatch = cellContent.match(/(\d+(?:\.\d+)?)/);
        if (numMatch) {
          cellData.push({ index: idx, value: parseFloat(numMatch[1]), text: cellContent });
        }
      }

      if (cellData.length === 0) continue;

      // Debug: Log all cell data for this row
      console.log(`   Row cells: ${cellData.map(c => `[${c.index}]=${c.value}`).join(', ')}`);

      // Determine which value to use based on column detection
      let value = 0;

      if (servingColumnIndex >= 0) {
        // We know exactly which column is the serving column
        const servingCell = cellData.find(c => c.index === servingColumnIndex);
        if (servingCell) {
          value = servingCell.value;
          foundAnyServingData = true;
          console.log(`   ✓ Using serving column ${servingColumnIndex}: ${value}`);
        } else {
          // The serving column doesn't exist in this data row
          // This means the table only has per-100g data - DO NOT use any values
          servingColumnMissing = true;
          console.log(`   ⚠️ Serving column ${servingColumnIndex} doesn't exist in data row (cells: ${cellData.map(c => c.index).join(',')}) - skipping row to avoid per-100g`);
          continue; // Skip this row entirely
        }
      } else if (per100gColumnIndex >= 0 && cellData.length >= 2) {
        // We know which column is 100g, so use the OTHER column
        const nonPer100gCell = cellData.find(c => c.index !== per100gColumnIndex);
        if (nonPer100gCell) {
          value = nonPer100gCell.value;
          foundAnyServingData = true;
          console.log(`   ✓ Using non-100g column ${nonPer100gCell.index}: ${value}`);
        }
      } else if (isMultiColumnTable && cellData.length >= 2) {
        // Fallback: assume second numeric value is per-serving
        value = cellData[1].value;
        foundAnyServingData = true;
        console.log(`   ✓ Fallback: using second value: ${value}`);
      } else {
        // Single column: DON'T take per-100g values - we want per-serving only
        // Skip this extraction since it's likely per-100g data
        console.log(`   ⚠️ Single-column table (likely per-100g only) - skipping to find per-serving data`);
        continue;
      }

      if (value === 0 || value >= 10000) continue;

      // Match to nutrient based on label in row
      if (!nutritionData.calories && /calor|kcal|energy/i.test(rowLower)) {
        if (value <= 2000) nutritionData.calories = value; // Per serving can be higher than 900
      } else if (!nutritionData.protein && /protein/i.test(rowLower)) {
        if (value <= 200) nutritionData.protein = value;
      } else if (!nutritionData.carbs && /carb/i.test(rowLower) && !/fib/i.test(rowLower)) {
        if (value <= 200) nutritionData.carbs = value;
      } else if (!nutritionData.fat && /\bfat\b/i.test(rowLower) && !/saturat/i.test(rowLower)) {
        if (value <= 200) nutritionData.fat = value;
      } else if (!nutritionData.saturatedFat && /saturat/i.test(rowLower)) {
        if (value <= 100) nutritionData.saturatedFat = value;
      } else if (!nutritionData.sugar && /sugar/i.test(rowLower)) {
        if (value <= 200) nutritionData.sugar = value;
      } else if (!nutritionData.fiber && /fib/i.test(rowLower)) {
        if (value <= 100) nutritionData.fiber = value;
      } else if (!nutritionData.sodium && /sodium/i.test(rowLower)) {
        if (value <= 10000) nutritionData.sodium = value;
      } else if (!nutritionData.salt && /\bsalt\b/i.test(rowLower) && !/unsalt/i.test(rowLower)) {
        if (value <= 20) nutritionData.salt = value;
      }
    }

    // Log whether we found per-serving data from the table
    // CRITICAL: If we detected a multi-column table but couldn't extract from serving column,
    // this page only has per-100g data in the table - don't proceed with aggressive extraction
    let skipAggressiveExtraction = false;
    if (servingColumnMissing && !foundAnyServingData) {
      console.log(`   ⚠️ Table has per-100g column but inferred serving column doesn't exist in data rows - NO per-serving data extracted`);
      skipAggressiveExtraction = true;
    } else if (foundAnyServingData && nutritionData.servingSize) {
      console.log(`   ✅ Table: Extracted per-serving data WITH serving size`);
    } else if (foundAnyServingData && !nutritionData.servingSize) {
      console.log(`   ⚠️ Table: Extracted per-serving data but NO serving size found`);
      console.log(`      This data will be rejected unless serving size is found elsewhere`);
    }

    // Extract serving size - look for actual serving patterns only (NOT pack size/weight)
    // Pack size ≠ serving size - a 350g pack doesn't mean 350g per serving
    if (!nutritionData.servingSize) {
      const servingSizePatterns = [
        /serving\s+size[:\s]*(\d+(?:\.\d+)?)\s*(g|ml|oz|fl\s*oz)/gi,
        /per\s+serving[:\s]*(\d+(?:\.\d+)?)\s*(g|ml)/gi,
        /per\s+portion[:\s]*(\d+(?:\.\d+)?)\s*(g|ml)/gi,
        /recommended\s+serving[:\s]*(\d+(?:\.\d+)?)\s*(g|ml)/gi,
        /typical\s+serving[:\s]*(\d+(?:\.\d+)?)\s*(g|ml)/gi,
        /serves?\s+(\d+(?:\.\d+)?)\s*(g|ml)/gi,
        // UK supermarket table header patterns like "per piece (5 g)" or "per portion (20 g)"
        /per\s+(?:piece|portion|bar|slice|biscuit|serving)\s*\((\d+(?:\.\d+)?)\s*(g|ml)\)/gi,
        // Note: Removed pack size, net weight, bottle, can, weight patterns
        // These are PACK sizes, not serving sizes
      ];

      for (const pattern of servingSizePatterns) {
        const matches = lowerHtml.matchAll(pattern);
        for (const match of matches) {
          if (match[1] && match[2]) {
            const value = parseFloat(match[1]);
            const unit = match[2].trim();
            // Only accept reasonable serving sizes (between 1g and 5000g/ml)
            if (value >= 1 && value <= 5000) {
              nutritionData.servingSize = `${value}${unit}`;
              // Debug: Show exactly what was matched and where
              const matchedText = match[0];
              const matchIndex = match.index || 0;
              const surroundingText = lowerHtml.substring(
                Math.max(0, matchIndex - 50),
                Math.min(lowerHtml.length, matchIndex + matchedText.length + 50)
              );
              console.log(`   📏 Serving size matched: "${matchedText}" → ${value}${unit}`);
              console.log(`      Context: ...${surroundingText.replace(/\s+/g, ' ')}...`);
              break;
            }
          }
        }
        if (nutritionData.servingSize) break;
      }

      // Enhanced debugging: Log serving size extraction result
      if (nutritionData.servingSize) {
        console.log(`   ✅ Serving size found: "${nutritionData.servingSize}"`);
      } else {
        console.log(`   ⚠️ No serving size found - tried ${servingSizePatterns.length} patterns`);
        console.log(`      Patterns checked: "serving size: Xg", "per serving: Xg", "per piece (Xg)", etc.`);
      }
    }
    console.log(`⏭️ Step 2.5 complete: ${Object.keys(nutritionData).length} fields total`);

    // STEP 3: Aggressive pattern matching for individual nutrients
    // SKIP this step if we detected a multi-column table but couldn't find the serving column
    // (This means the page only has per-100g data in usable format)
    if (skipAggressiveExtraction) {
      console.log(`⏭️ Step 3: SKIPPED - page appears to have per-100g only, trying next site instead`);
      console.log(`⏭️ Returning with ${Object.keys(nutritionData).length} fields (may be insufficient to trigger fallback)`);
      return nutritionData;
    }

    console.log(`📋 Step 3: Aggressive pattern matching for nutrients...`);
    // Calories - look for various patterns (if not already found)
    if (!nutritionData.calories) {
      const calPatterns = [
        /calories[:\s]*(\d+(?:\.\d+)?)/gi,
        /(\d+(?:\.\d+)?)\s*(?:kcal|calories|cal)(?:\s*\/?\s*100\s*g)?/gi,
        /energy[:\s]*(\d+(?:\.\d+)?)\s*kcal/gi,
        /per\s*100\s*g[:\s]*(\d+(?:\.\d+)?)\s*cal/gi,
        /(\d+(?:\.\d+)?)\s*kj\s*\/\s*(\d+(?:\.\d+)?)\s*kcal/gi, // "2000kj / 478kcal"
      ];
      for (const pattern of calPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          const numMatch = match[0].match(/(\d+(?:\.\d+)?)\s*kcal/i) || match;
          if (numMatch && numMatch[1]) {
            const value = parseFloat(numMatch[1]);
            // Sanity check: calories per 100g should be 0-900
            if (value > 0 && value <= 900) {
              nutritionData.calories = value;
              break;
            }
          }
        }
        if (nutritionData.calories) break;
      }
    }

    // Protein
    if (!nutritionData.protein) {
      const proteinPatterns = [
        /protein[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*protein/gi,
        /protein[:\s<>]*(\d+(?:\.\d+)?)/gi, // More flexible - captures "Protein<td>15</td>"
      ];
      for (const pattern of proteinPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 100) { // Sanity check
              nutritionData.protein = value;
              break;
            }
          }
        }
        if (nutritionData.protein) break;
      }
    }

    // Carbs
    if (!nutritionData.carbs) {
      const carbPatterns = [
        /carbohydrate[s]?[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /carbs[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*carb/gi,
        /carbohydrate[s]?[:\s<>]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of carbPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 100) {
              nutritionData.carbs = value;
              break;
            }
          }
        }
        if (nutritionData.carbs) break;
      }
    }

    // Fat (total fat, not saturated)
    if (!nutritionData.fat) {
      const fatPatterns = [
        /(?:total\s+)?fat[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*(?:total\s+)?fat/gi,
        /(?:total\s+)?fat[:\s<>]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of fatPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          // Skip if it's part of "saturated fat"
          if (match[0].toLowerCase().includes('saturat')) continue;
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 100) {
              nutritionData.fat = value;
              break;
            }
          }
        }
        if (nutritionData.fat) break;
      }
    }

    // Saturated Fat
    if (!nutritionData.saturatedFat) {
      const satFatPatterns = [
        /saturated[s]?\s*fat[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /saturates[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /of\s*which\s*saturates[:\s]*(\d+(?:\.\d+)?)/gi,
        /saturated[s]?\s*fat[:\s<>]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of satFatPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 100) {
              nutritionData.saturatedFat = value;
              break;
            }
          }
        }
        if (nutritionData.saturatedFat) break;
      }
    }

    // Sugar
    if (!nutritionData.sugar) {
      const sugarPatterns = [
        /sugar[s]?[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*sugar/gi,
        /of\s*which\s*sugars[:\s]*(\d+(?:\.\d+)?)/gi,
        /sugar[s]?[:\s<>]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of sugarPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 100) {
              nutritionData.sugar = value;
              break;
            }
          }
        }
        if (nutritionData.sugar) break;
      }
    }

    // Fiber/Fibre
    if (!nutritionData.fiber) {
      const fiberPatterns = [
        /fib[re]{2}[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*fib[re]{2}/gi,
        /fib[re]{2}[:\s<>]*(\d+(?:\.\d+)?)/gi,
        /dietary\s*fib[re]{2}[:\s]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of fiberPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 50) {
              nutritionData.fiber = value;
              break;
            }
          }
        }
        if (nutritionData.fiber) break;
      }
    }

    // Sodium (in mg)
    if (!nutritionData.sodium) {
      const sodiumPatterns = [
        /sodium[:\s]*(\d+(?:\.\d+)?)\s*mg/gi,
        /(\d+(?:\.\d+)?)\s*mg\s*sodium/gi,
        /sodium[:\s<>]*(\d+(?:\.\d+)?)\s*mg/gi,
      ];
      for (const pattern of sodiumPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 5000) { // Reasonable range for sodium in mg per 100g
              nutritionData.sodium = value;
              break;
            }
          }
        }
        if (nutritionData.sodium) break;
      }
    }

    // Salt (in g)
    if (!nutritionData.salt) {
      const saltPatterns = [
        /salt[:\s]*(\d+(?:\.\d+)?)\s*g/gi,
        /(\d+(?:\.\d+)?)\s*g\s*salt/gi,
        /salt[:\s<>]*(\d+(?:\.\d+)?)/gi,
      ];
      for (const pattern of saltPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          // Skip if it's "unsalted" or "no salt"
          if (match[0].toLowerCase().includes('unsalt') || match[0].toLowerCase().includes('no salt')) continue;
          if (match[1]) {
            const value = parseFloat(match[1]);
            if (value >= 0 && value <= 10) { // Reasonable range for salt in g per 100g
              nutritionData.salt = value;
              break;
            }
          }
        }
        if (nutritionData.salt) break;
      }
    }

    // STEP 4: Extract ingredients if requested
    console.log(`📋 Step 4: Extracting ingredients...`);
    if (!nutritionData.ingredients) {
      // Look for common ingredients patterns
      const ingredientsPatterns = [
        /ingredients?[:\s]*([^<.]*(?:flour|sugar|water|salt|oil|milk|egg|butter|corn|wheat|soy|palm)[^<.]*)/gi,
        /<[^>]*>ingredients?[:\s]*<\/[^>]*>([^<]+)/gi,
        /(?:contains?|made with)[:\s]*([^<.]*(?:flour|sugar|water|salt|oil|milk)[^<.]*)/gi,
      ];

      for (const pattern of ingredientsPatterns) {
        const matches = [...lowerHtml.matchAll(pattern)];
        for (const match of matches) {
          const ingredientsText = match[1]?.trim();
          if (ingredientsText && ingredientsText.length > 20 && ingredientsText.length < 2000) {
            // Clean up HTML entities and tags
            const cleaned = ingredientsText
              .replace(/<[^>]+>/g, '') // Remove HTML tags
              .replace(/&[a-z]+;/gi, ' ') // Remove HTML entities
              .replace(/\s+/g, ' ') // Normalize whitespace
              .trim();

            if (cleaned.length > 20) {
              nutritionData.ingredients = cleaned;
              console.log(`✅ Found ingredients: ${cleaned.substring(0, 100)}...`);
              break;
            }
          }
        }
        if (nutritionData.ingredients) break;
      }

      // Alternative: Look for ingredients in structured data
      const ingredientsJsonMatch = html.match(/"ingredients":\s*"([^"]+)"/i);
      if (!nutritionData.ingredients && ingredientsJsonMatch) {
        nutritionData.ingredients = ingredientsJsonMatch[1].replace(/\\n/g, ' ').trim();
        console.log(`✅ Found ingredients from JSON: ${nutritionData.ingredients.substring(0, 100)}...`);
      }
    }
    console.log(`⏭️ Step 4 complete: ${nutritionData.ingredients ? 'Found ingredients' : 'No ingredients'}`);

    // Return results if we found useful data
    // Be more lenient if we found calories (the most important field)
    const foundFields = Object.keys(nutritionData).length;
    const hasCalories = nutritionData.calories !== undefined;
    const hasProtein = nutritionData.protein !== undefined;
    const hasCarbs = nutritionData.carbs !== undefined;
    const hasFat = nutritionData.fat !== undefined;

    console.log(`📊 Final nutrition data:`, nutritionData);
    console.log(`📈 Found fields (${foundFields}): ${Object.keys(nutritionData).join(', ')}`);

    // Return if we found calories + at least 1 other macro OR 3+ fields total
    if (hasCalories && (hasProtein || hasCarbs || hasFat)) {
      console.log(`✅ SUCCESS: Found calories + macros (${foundFields} fields total)`);
      return nutritionData;
    }
    if (foundFields >= 3) {
      console.log(`✅ SUCCESS: Found ${foundFields} fields total`);
      return nutritionData;
    }

    console.log(`❌ INSUFFICIENT: Only ${foundFields} fields found, need calories+macro or 3+ fields`);
    return null;
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

  // Load foods from Algolia (with pagination to get ALL products)
  const loadFoodsFromIndices = useCallback(async () => {
    if (selectedIndices.size === 0) {
      addLog('No indices selected');
      return;
    }

    setIsLoading(true);
    setShowIndexSelector(false);
    setLoadingProgress(0);
    addLog('📥 Loading ALL foods from selected indices (with pagination)...');

    const allFoods: FoodWithImage[] = [];
    const indicesToLoad = Array.from(selectedIndices);
    const PAGE_SIZE = 5000; // Request 5k products at a time
    const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

    try {
      for (let i = 0; i < indicesToLoad.length; i++) {
        const indexName = indicesToLoad[i];
        addLog(`📦 Loading ${indexName}...`);

        let offset = 0;
        let hasMore = true;
        let indexProducts: any[] = [];
        let totalForIndex = 0;

        // Paginate through the index (with safety limits)
        const MAX_ITERATIONS = 2000; // Safety: max 10M products (2000 * 5000)
        let iterations = 0;

        while (hasMore && iterations < MAX_ITERATIONS) {
          iterations++;

          // Log progress every 5 iterations (25k products)
          if (iterations > 1 && iterations % 5 === 0) {
            addLog(`  → ${indexName}: ${indexProducts.length.toLocaleString()} products pulled, fetching more...`);
          }

          const response = await fetch(`${FUNCTIONS_BASE}/browseAllIndices`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              indices: [indexName],
              offset,
              pageSize: PAGE_SIZE,
            }),
          });

          if (!response.ok) {
            addLog(`❌ ${indexName}: HTTP ${response.status}`);
            break;
          }

          const result = await response.json();

          if (result.success && result.products) {
            const products = result.products || [];
            const pagination = result.pagination || {};

            // Safety: If we got no products, stop pagination
            if (products.length === 0) {
              addLog(`  ✓ ${indexName}: Reached end (0 products returned)`);
              hasMore = false;
              break;
            }

            // Safety: If we got less than PAGE_SIZE, this is likely the last page
            if (products.length < PAGE_SIZE) {
              addLog(`  ✓ ${indexName}: Last page (${products.length} products)`);
              hasMore = false;
            }

            indexProducts.push(...products);
            totalForIndex = pagination?.total || indexProducts.length;

            // Update progress
            const progressPct = Math.floor(((i + (indexProducts.length / Math.max(totalForIndex, 1))) / indicesToLoad.length) * 100);
            setLoadingProgress(progressPct);

            const pct = totalForIndex > 0 ? Math.round((indexProducts.length / totalForIndex) * 100) : 0;
            addLog(`  → Page ${iterations}: ${indexProducts.length.toLocaleString()} / ${totalForIndex.toLocaleString()} (${pct}%)`);

            // Check if there's more data from backend
            if (!pagination.hasMore) {
              addLog(`  ✓ ${indexName}: Backend says no more data`);
              hasMore = false;
            } else {
              hasMore = true;
              offset += PAGE_SIZE;
            }

            // Safety: If we've reached the expected total, stop
            if (totalForIndex > 0 && indexProducts.length >= totalForIndex) {
              addLog(`  ✓ ${indexName}: Reached total count (${indexProducts.length} >= ${totalForIndex})`);
              hasMore = false;
            }

          } else {
            addLog(`❌ ${indexName}: ${result.error || 'Failed'}`);
            break;
          }
        }

        // Warn if we hit the safety limit
        if (iterations >= MAX_ITERATIONS) {
          addLog(`⚠️ ${indexName}: Hit safety limit (${MAX_ITERATIONS} iterations)`);
        }

        addLog(`✅ ${indexName}: Loaded ${indexProducts.length.toLocaleString()} products`);

        // Convert to FoodWithImage format
        for (const hit of indexProducts) {
          allFoods.push({
            id: `${indexName}:${hit.objectID}`,
            objectID: hit.objectID,
            name: hit.name || hit.foodName || 'Unknown',
            brandName: hit.brandName || hit.brand || null,
            barcode: hit.barcode || null,
            currentImageUrl: hit.imageUrl || null,
            sourceIndex: indexName,
            calories: hit.calories,
            dontShowImage: hit.dontShowImage || false,
            selected: false,
            searchResults: [],
            selectedImageUrl: null,
            analysis: null,
            nutritionData: null,
            nutritionStatus: 'pending',
            status: 'pending',
            analysisProgress: 0,
          });
        }

        // Update progress for this index
        setLoadingProgress(Math.round(((i + 1) / indicesToLoad.length) * 100));
      }

      addLog(`✅ Total foods loaded: ${allFoods.length.toLocaleString()}`);

      // Apply UK filter if enabled
      let foodsToUse = allFoods;
      if (filterUKOnly) {
        const filterResult = filterUKProducts(allFoods, 40); // 40% confidence threshold
        foodsToUse = filterResult.ukProducts;
        setUkFilterStats(filterResult.stats);
        addLog(`🇬🇧 UK filter applied: ${filterResult.stats.ukCount.toLocaleString()} UK products (${filterResult.stats.ukPercentage}%), ${filterResult.stats.nonUkCount.toLocaleString()} filtered out (${filterResult.stats.nonUkPercentage}%)`);
      } else {
        setUkFilterStats(null);
      }

      // Apply "no images" filter if enabled
      const beforeImageFilter = foodsToUse.length;
      if (filterNoImages) {
        const withImages = foodsToUse.filter(f => f.currentImageUrl);
        const withoutImages = foodsToUse.filter(f => !f.currentImageUrl);

        setImageFilterStats({
          total: beforeImageFilter,
          withImages: withImages.length,
          withoutImages: withoutImages.length,
        });

        foodsToUse = withoutImages;
        addLog(`🖼️ Image filter applied: ${withoutImages.length.toLocaleString()} without images, ${withImages.length.toLocaleString()} with images hidden`);
      } else {
        setImageFilterStats(null);
      }

      // Apply "very low calories" filter if enabled
      if (filterZeroCalories) {
        const beforeZeroCalFilter = foodsToUse.length;
        foodsToUse = foodsToUse.filter(f => {
          // Check if food has 0-5 calories (catches sweeteners, zero-cal items with trace amounts)
          const isLowCalorie = f.calories !== undefined && f.calories >= 0 && f.calories <= 5;

          // If excluding drinks, also check if this is a drink
          if (isLowCalorie && excludeDrinks) {
            return !isDrink(f.name);
          }

          return isLowCalorie;
        });
        const filtered = beforeZeroCalFilter - foodsToUse.length;
        const drinkNote = excludeDrinks ? ' (drinks excluded)' : '';
        addLog(`0️⃣ Very low calorie filter${drinkNote}: ${foodsToUse.length.toLocaleString()} with 0-5 kcal, ${filtered.toLocaleString()} filtered out`);
      }

      // Tesco bad image filter DISABLED - show all Tesco images
      // (Previously filtered out items with dontShowImage flag)
      // if (filterTescoBadImages) {
      //   const beforeTescoFilter = foodsToUse.length;
      //   foodsToUse = foodsToUse.filter(f => {
      //     if (f.sourceIndex === 'tesco_products') {
      //       return !f.dontShowImage;
      //     }
      //     return true;
      //   });
      //   const filtered = beforeTescoFilter - foodsToUse.length;
      //   if (filtered > 0) {
      //     addLog(`🚫 Tesco bad images filter: ${foodsToUse.length.toLocaleString()} kept, ${filtered.toLocaleString()} with bad images filtered out`);
      //   }
      // }

      setFoods(foodsToUse);
      updateStats(foodsToUse);
      setLoadingProgress(100);
      setLoadingMessage('');
    } catch (error) {
      addLog(`❌ Error: ${error}`);
    } finally {
      setIsLoading(false);
    }
  }, [selectedIndices, filterUKOnly, filterNoImages, filterZeroCalories, excludeDrinks]);

  // Search Algolia for foods by name/brand/barcode
  const handleSearch = useCallback(async () => {
    if (!searchQuery.trim()) {
      addLog('❌ No search query entered');
      return;
    }

    if (selectedIndices.size === 0) {
      addLog('❌ No indices selected');
      return;
    }

    setIsSearching(true);
    setIsLoading(true);
    setShowIndexSelector(false);
    setLoadingProgress(0);
    addLog(`🔍 Searching for: ${searchQuery}`);

    const allFoods: FoodWithImage[] = [];
    const indicesToSearch = Array.from(selectedIndices);

    try {
      for (let i = 0; i < indicesToSearch.length; i++) {
        const indexName = indicesToSearch[i];
        setLoadingMessage(`Searching ${indexName}...`);
        setLoadingProgress(Math.round((i / indicesToSearch.length) * 100));

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
              query: searchQuery.trim(),
              hitsPerPage: 1000,
              attributesToRetrieve: ['objectID', 'name', 'foodName', 'brandName', 'brand', 'barcode', 'imageUrl', 'calories', 'dontShowImage'],
            }),
          });

          if (!response.ok) {
            addLog(`Error searching ${indexName}: ${response.status}`);
            continue;
          }

          const data = await response.json();
          const hits = data.hits || [];
          addLog(`${indexName}: ${hits.length} results`);

          for (const hit of hits) {
            allFoods.push({
              id: `${indexName}:${hit.objectID}`,
              objectID: hit.objectID,
              name: hit.name || hit.foodName || 'Unknown',
              brandName: hit.brandName || hit.brand || null,
              barcode: hit.barcode || null,
              currentImageUrl: hit.imageUrl || null,
              sourceIndex: indexName,
              calories: hit.calories,
              dontShowImage: hit.dontShowImage || false,
              selected: false,
              searchResults: [],
              selectedImageUrl: null,
              analysis: null,
              nutritionData: null,
              nutritionStatus: 'pending',
              status: 'pending',
              analysisProgress: 0,
            });
          }
        } catch (err) {
          addLog(`Error searching ${indexName}: ${err}`);
        }
      }

      addLog(`✅ Found ${allFoods.length} foods matching "${searchQuery}"`);

      // Apply UK filter if enabled
      let foodsToUse = allFoods;
      if (filterUKOnly) {
        const filterResult = filterUKProducts(allFoods, 40);
        foodsToUse = filterResult.ukProducts;
        setUkFilterStats(filterResult.stats);
        addLog(`🇬🇧 UK Filter: ${filterResult.ukProducts.length} kept, ${filterResult.nonUkProducts.length} filtered`);
      }

      // Apply "no images" filter if enabled
      if (filterNoImages) {
        const withImages = foodsToUse.filter(f => f.currentImageUrl);
        const withoutImages = foodsToUse.filter(f => !f.currentImageUrl);

        setImageFilterStats({
          total: foodsToUse.length,
          withImages: withImages.length,
          withoutImages: withoutImages.length,
        });

        foodsToUse = withoutImages;
        addLog(`🖼️ Image Filter: ${withoutImages.length} without images, ${withImages.length} with images hidden`);
      } else {
        setImageFilterStats(null);
      }

      // Apply "very low calories" filter if enabled
      if (filterZeroCalories) {
        const beforeZeroCalFilter = foodsToUse.length;
        foodsToUse = foodsToUse.filter(f => {
          // Check if food has 0-5 calories (catches sweeteners, zero-cal items with trace amounts)
          const isLowCalorie = f.calories !== undefined && f.calories >= 0 && f.calories <= 5;

          // If excluding drinks, also check if this is a drink
          if (isLowCalorie && excludeDrinks) {
            return !isDrink(f.name);
          }

          return isLowCalorie;
        });
        const filtered = beforeZeroCalFilter - foodsToUse.length;
        const drinkNote = excludeDrinks ? ' (drinks excluded)' : '';
        addLog(`0️⃣ Very Low Cal Filter${drinkNote}: ${foodsToUse.length} with 0-5 kcal, ${filtered} filtered out`);
      }

      // Tesco bad image filter DISABLED - show all Tesco images
      // (Previously filtered out items with dontShowImage flag)
      // if (filterTescoBadImages) {
      //   const beforeTescoFilter = foodsToUse.length;
      //   foodsToUse = foodsToUse.filter(f => {
      //     if (f.sourceIndex === 'tesco_products') {
      //       return !f.dontShowImage;
      //     }
      //     return true;
      //   });
      //   const filtered = beforeTescoFilter - foodsToUse.length;
      //   if (filtered > 0) {
      //     addLog(`🚫 Tesco Filter: ${foodsToUse.length} kept, ${filtered} bad images filtered`);
      //   }
      // }

      setFoods(foodsToUse);
      setStats({
        total: foodsToUse.length,
        completed: 0,
        failed: 0,
        noResults: 0,
        processing: 0,
      });

    } catch (err) {
      addLog(`❌ Search failed: ${err}`);
    } finally {
      setIsSearching(false);
      setIsLoading(false);
      setLoadingProgress(100);
    }
  }, [searchQuery, selectedIndices, filterUKOnly, filterNoImages, filterZeroCalories, excludeDrinks, addLog]);

  // Search by barcode - finds foods with this barcode and searches Google Images using the barcode
  const handleBarcodeSearch = useCallback(async () => {
    if (!barcodeQuery.trim()) {
      addLog('❌ No barcode entered');
      return;
    }

    setIsBarcodeSearching(true);
    setIsLoading(true);
    setShowIndexSelector(false);
    setLoadingProgress(0);
    addLog(`🔍 Searching for barcode: ${barcodeQuery}`);

    try {
      const { foods: results } = await searchByBarcode(barcodeQuery.trim(), Array.from(selectedIndices) as any);

      if (results.length === 0) {
        addLog(`❌ No foods found with barcode: ${barcodeQuery}`);
        setIsLoading(false);
        setIsBarcodeSearching(false);
        return;
      }

      addLog(`✅ Found ${results.length} food(s) with barcode ${barcodeQuery}`);
      addLog(`🔎 Will search Google Images using barcode: ${barcodeQuery}`);

      // Map foods and immediately search Google Images using the BARCODE
      const foodsWithImage: FoodWithImage[] = results.map(result => ({
        id: result._id,
        objectID: result.objectID,
        name: result.name,
        brandName: result.brandName,
        barcode: result.barcode,
        currentImageUrl: result.imageUrl,
        sourceIndex: result._sourceIndex,
        calories: result.calories,
        dontShowImage: result.dontShowImage || false,
        selected: true, // Auto-select for processing
        searchResults: [],
        selectedImageUrl: null,
        analysis: null,
        nutritionData: null,
        nutritionStatus: 'pending',
        status: 'pending',
        analysisProgress: 0,
      }));

      setFoods(foodsWithImage);
      setStats({
        total: foodsWithImage.length,
        completed: 0,
        failed: 0,
        noResults: 0,
        processing: 0,
      });
      addLog(`📦 Loaded ${foodsWithImage.length} food(s) for image scraping`);

      // Auto-start processing using BARCODE as search query
      setIsLoading(false);
      setIsBarcodeSearching(false);

      // Start image search immediately using the barcode
      setTimeout(() => {
        processSelectedFoodsWithBarcode(foodsWithImage, barcodeQuery.trim());
      }, 500);

    } catch (err) {
      addLog(`❌ Barcode search failed: ${err}`);
      setIsLoading(false);
      setIsBarcodeSearching(false);
    }
  }, [barcodeQuery, selectedIndices, addLog]);

  // Process foods using barcode for Google Images search
  const processSelectedFoodsWithBarcode = async (foodsList: FoodWithImage[], barcode: string) => {
    if (!apiConfigured) {
      addLog('⚠️ SearchAPI not configured. Please set SERP_API_KEY in .env');
      return;
    }

    setIsProcessing(true);
    pauseRef.current = false;
    abortRef.current = false;

    const selectedFoods = foodsList.filter(f => f.selected);
    if (selectedFoods.length === 0) {
      addLog('No foods selected for processing');
      setIsProcessing(false);
      return;
    }

    addLog(`🚀 Starting image search for ${selectedFoods.length} food(s) using barcode: ${barcode}`);

    for (const food of selectedFoods) {
      if (abortRef.current) {
        addLog('⏹️ Processing aborted');
        break;
      }

      while (pauseRef.current) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }

      try {
        updateFoodStatus(food.id, 'searching', 0);
        addLog(`🔍 Searching Google Images for barcode: ${barcode} (${food.name})`);

        // Search using BARCODE instead of product name
        const results = await searchSerpApiImages(barcode);

        if (results.length === 0) {
          updateFoodStatus(food.id, 'no_results');
          addLog(`❌ No images found for barcode: ${barcode}`);
          continue;
        }

        addLog(`✅ Found ${results.length} images for ${barcode}`);
        setFoods(prev => prev.map(f =>
          f.id === food.id ? { ...f, searchResults: results, status: 'analyzing' } : f
        ));

        // Analyze images
        updateFoodStatus(food.id, 'analyzing', 0);
        const analyzed: Array<SerpApiImageResult & { analysis: ImageAnalysisResult }> = [];

        for (let i = 0; i < results.length; i++) {
          const result = results[i];
          const progress = Math.round(((i + 1) / results.length) * 100);
          updateFoodStatus(food.id, 'analyzing', progress);

          try {
            const analysis = await analyzeImageQuality(result.url);
            analyzed.push({ ...result, analysis });
          } catch (err) {
            console.error('Analysis error:', err);
          }
        }

        // Find best candidate
        const candidates = analyzed
          .map(item => {
            let confidence = 0;
            if (item.analysis.backgroundConfidence >= 95 && item.analysis.hasWhiteBackground) {
              confidence = 95;
            } else {
              if (item.analysis.hasWhiteBackground) confidence += 40;
              if (!item.analysis.hasOverlay) confidence += 30;
              confidence += Math.min(20, item.analysis.backgroundConfidence * 0.2);
            }
            if (item.isManufacturerSite) confidence += 5;
            return { ...item, confidence };
          })
          .sort((a, b) => b.confidence - a.confidence);

        if (candidates.length > 0) {
          const best = candidates[0];
          setFoods(prev => prev.map(f =>
            f.id === food.id
              ? {
                  ...f,
                  searchResults: candidates,
                  selectedImageUrl: best.confidence >= 80 ? best.url : null,
                  analysis: best.analysis,
                  status: best.confidence >= 80 ? 'ready' : 'pending',
                  confidence: best.confidence,
                }
              : f
          ));

          if (best.confidence >= 80) {
            addLog(`✅ ${food.name}: Auto-selected image (${best.confidence}% confidence)`);
          } else {
            addLog(`⚠️ ${food.name}: Manual selection needed (${best.confidence}% confidence)`);
          }
        }

      } catch (err) {
        updateFoodStatus(food.id, 'failed', 0, String(err));
        addLog(`❌ Error processing ${food.name}: ${err}`);
      }
    }

    setIsProcessing(false);
    addLog('✅ Processing complete');
  };

  const updateStats = (foodList: FoodWithImage[]) => {
    setStats({
      total: foodList.length,
      completed: foodList.filter(f => f.status === 'completed').length,
      failed: foodList.filter(f => f.status === 'failed').length,
      noResults: foodList.filter(f => f.status === 'no_results').length,
      processing: foodList.filter(f => ['searching', 'analyzing', 'uploading'].includes(f.status)).length,
    });
  };

  // Update food status
  const updateFoodStatus = (
    id: string,
    status: FoodWithImage['status'],
    progress?: number,
    error?: string
  ) => {
    setFoods(prev => {
      const updated = prev.map(f => {
        if (f.id === id) {
          return {
            ...f,
            status,
            analysisProgress: progress !== undefined ? progress : f.analysisProgress,
            error,
          };
        }
        return f;
      });
      updateStats(updated);
      return updated;
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

      const results = await searchSerpApiImages(food.name, food.brandName, 10, food.sourceIndex);

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

          // Special scoring for fast food restaurants - different criteria
          if (food.sourceIndex === 'fast_foods_database') {
            // For restaurants, we want storefront/building images, not white background
            // Base score on position and resolution
            confidence = 50;

            // Top 3 results: +20 points
            if (i < 3) confidence += 20;

            // No text overlays: +20 points
            if (!analysis.hasOverlay) confidence += 20;

            // Good resolution: +10 points
            if (candidate.width && candidate.width > 800) confidence += 10;

            addLog(`🍔 Fast food restaurant: ${food.name} - Confidence: ${Math.round(confidence)}% (Rank: ${i+1}, Overlay: ${analysis.hasOverlay ? 'Yes' : 'No'})`);
          } else {
            // Normal product scoring - requires white background
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
          }

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

      // Mark best result for preview
      const resultsWithBest = results.map(r => ({
        ...r,
        isBestResult: r.url === bestResult.url,
      }));

      // Step 3: Scrape nutrition data if any scraping option is enabled
      let nutritionData = null;
      let nutritionStatus: FoodWithImage['nutritionStatus'] = 'pending';

      if (scrapeNutrition || scrapeServingSize || scrapeIngredients) {
        const scrapeTypes = [];
        if (scrapeNutrition) scrapeTypes.push('nutrition');
        if (scrapeServingSize) scrapeTypes.push('serving size');
        if (scrapeIngredients) scrapeTypes.push('ingredients');
        addLog(`🍎 Scraping ${scrapeTypes.join(', ')} for ${food.name}...`);
        setFoods(prev => prev.map(f => f.id === food.id ? { ...f, nutritionStatus: 'searching' } : f));

        nutritionData = await scrapeNutritionData(food);

        if (nutritionData) {
          // Special handling for fast food database: default to "per unit" if no serving size found
          if (food.sourceIndex === 'fast_foods_database' && !nutritionData.servingSize) {
            nutritionData.servingSize = 'per unit';
            addLog(`🍔 Fast food item - defaulting to "per unit" serving size`);
          }

          nutritionStatus = 'found';
          addLog(`✓ Nutrition found for ${food.name} (${nutritionData.source})`);
        } else {
          nutritionStatus = 'not_found';
          addLog(`⚠ No nutrition data found for ${food.name}`);
        }
      }

      return {
        ...food,
        searchResults: resultsWithBest,
        selectedImageUrl: bestResult.url, // Show highest confidence in preview
        analysis: bestAnalysis,
        nutritionData,
        nutritionStatus,
        status,
        confidence,
        error: confidence < 80 ? `Low confidence (${confidence}%) - ${bestAnalysis.overlayTypes.join(', ') || 'Check image quality'}` : undefined,
        analysisProgress: 100,
        wasProcessed: true, // Mark as processed
      };
    } catch (error) {
      addLog(`Error searching ${food.name}: ${error}`);
      return {
        ...food,
        status: 'failed',
        error: error instanceof Error ? error.message : String(error),
        wasProcessed: true, // Mark as processed even if failed
      };
    }
  };

  // Process nutrition only (no images)
  const processNutritionOnly = async () => {
    setIsProcessing(true);
    pauseRef.current = false;
    abortRef.current = false;

    const selectedFoods = foods.filter(f => f.selected);
    const toProcess = selectedFoods.length > 0
      ? selectedFoods
      : foods.filter(f => (f.status === 'pending' || f.nutritionStatus === 'pending') && !f.wasProcessed);

    addLog(`🍎 Starting nutrition scraping for ${toProcess.length} foods`);

    if (toProcess.length === 0) {
      const totalUnprocessed = foods.filter(f => !f.wasProcessed).length;
      if (totalUnprocessed === 0) {
        addLog('✅ All foods have been processed! Select specific foods to reprocess.');
      } else {
        addLog('No pending foods to process. Select specific foods or adjust filters.');
      }
      setIsProcessing(false);
      return;
    }

    // Initialize progress tracking
    setTotalToProcess(toProcess.length);
    setCurrentProcessingIndex(0);

    for (let i = 0; i < toProcess.length; i++) {
      // Update current progress
      setCurrentProcessingIndex(i + 1);

      if (abortRef.current) {
        addLog('Nutrition scraping stopped by user');
        break;
      }

      // Proper pause implementation
      while (pauseRef.current) {
        await new Promise(resolve => setTimeout(resolve, 500));
        if (abortRef.current) break;
      }

      const food = toProcess[i];
      addLog(`[${i + 1}/${toProcess.length}] Scraping nutrition for ${food.name}...`);

      // Update status
      setFoods(prev => prev.map(f => f.id === food.id ? { ...f, nutritionStatus: 'searching' } : f));

      const nutritionData = await scrapeNutritionData(food);

      if (nutritionData) {
        // Special handling for fast food database: default to "per unit" if no serving size found
        if (food.sourceIndex === 'fast_foods_database' && !nutritionData.servingSize) {
          nutritionData.servingSize = 'per unit';
          addLog(`🍔 Fast food item - defaulting to "per unit" serving size`);
        }

        setFoods(prev => prev.map(f =>
          f.id === food.id
            ? { ...f, nutritionData, nutritionStatus: 'found', status: 'uploading', wasProcessed: true }
            : f
        ));

        // Build detailed log message
        const foundFields = [];
        if (nutritionData.calories !== undefined) foundFields.push('calories');
        if (nutritionData.protein !== undefined) foundFields.push('protein');
        if (nutritionData.carbs !== undefined) foundFields.push('carbs');
        if (nutritionData.fat !== undefined) foundFields.push('fat');
        if (nutritionData.sugar !== undefined) foundFields.push('sugar');
        if (nutritionData.fiber !== undefined) foundFields.push('fiber');
        if (nutritionData.servingSize) foundFields.push(`serving: ${nutritionData.servingSize}`);
        if (nutritionData.ingredients) foundFields.push('ingredients');

        addLog(`✓ ${food.name}: Found ${foundFields.length} fields (${nutritionData.source}) ${nutritionData.servingSize ? '📏' : ''}${nutritionData.ingredients ? '🥕' : ''}`);
        if (nutritionData.sourceUrl) {
          addLog(`  🔗 Source: ${nutritionData.sourceUrl}`);
        }
        if (nutritionData.servingSize) {
          addLog(`  📏 Serving size: ${nutritionData.servingSize}`);
        }
        if (nutritionData.ingredients) {
          addLog(`  🥕 Ingredients: ${nutritionData.ingredients.substring(0, 100)}...`);
        }

        // Save nutrition data to database
        try {
          addLog(`💾 Saving nutrition for ${food.name}...`);

          // For fast food database, send ALL fields (even if undefined) to overwrite existing data
          const isFastFood = food.sourceIndex === 'fast_foods_database';

          // Build serving description for fast food items
          let servingDesc = null;
          if (isFastFood) {
            // Try to extract item type from name (burger, sandwich, etc.)
            const name = food.name.toLowerCase();
            let itemType = 'item';
            if (name.includes('burger')) itemType = 'burger';
            else if (name.includes('sandwich')) itemType = 'sandwich';
            else if (name.includes('wrap')) itemType = 'wrap';
            else if (name.includes('salad')) itemType = 'salad';
            else if (name.includes('fries') || name.includes('chips')) itemType = 'serving';
            else if (name.includes('nugget')) itemType = 'serving';
            else if (name.includes('pizza')) itemType = 'pizza';

            // Include the scraped serving size if available
            if (nutritionData.servingSize) {
              const sizeStr = typeof nutritionData.servingSize === 'number'
                ? `${nutritionData.servingSize}g`
                : nutritionData.servingSize;
              servingDesc = `${itemType} (${sizeStr})`;
            } else {
              servingDesc = itemType;
            }
          }

          // Debug: Log what's actually being saved
          console.log(`💾 Nutrition payload fields:`, Object.keys(nutritionData));
          console.log(`   Scrape settings: nutrition=${scrapeNutrition}, serving=${scrapeServingSize}, ingredients=${scrapeIngredients}`);

          const nutritionPayload = isFastFood ? {
            // Fast food: Send all fields to ensure complete overwrite
            // NOTE: Nutrition values are already for the FULL UNIT (not per 100g)
            calories: nutritionData.calories ?? null,
            protein: nutritionData.protein ?? null,
            carbs: nutritionData.carbs ?? null,
            fat: nutritionData.fat ?? null,
            saturatedFat: nutritionData.saturatedFat ?? null,
            fiber: nutritionData.fiber ?? null,
            sugar: nutritionData.sugar ?? null,
            sodium: nutritionData.sodium ?? null,
            salt: nutritionData.salt ?? null,
            servingSizeG: 1, // Always 1 for per-unit mode (don't multiply by grams!)
            servingDescription: servingDesc, // e.g., "burger (354g)"
            isPerUnit: true, // Nutrition is for FULL unit, not per 100g
            ingredients: nutritionData.ingredients ?? null,
            sourceUrl: nutritionData.sourceUrl ?? null,
          } : {
            // Other databases: Only send fields that were found (exclude undefined)
            ...(nutritionData.calories !== undefined && { calories: nutritionData.calories }),
            ...(nutritionData.protein !== undefined && { protein: nutritionData.protein }),
            ...(nutritionData.carbs !== undefined && { carbs: nutritionData.carbs }),
            ...(nutritionData.fat !== undefined && { fat: nutritionData.fat }),
            ...(nutritionData.saturatedFat !== undefined && { saturatedFat: nutritionData.saturatedFat }),
            ...(nutritionData.fiber !== undefined && { fiber: nutritionData.fiber }),
            ...(nutritionData.sugar !== undefined && { sugar: nutritionData.sugar }),
            ...(nutritionData.sodium !== undefined && { sodium: nutritionData.sodium }),
            ...(nutritionData.salt !== undefined && { salt: nutritionData.salt }),
            // Parse serving size - extract grams and description separately
            // e.g., "5 gyoza (100 g)" → servingSizeG: 100, servingDescription: "5 gyoza"
            // e.g., "1 pack (168 g)" → servingSizeG: 168, servingDescription: "1 pack"
            // e.g., "30g" → servingSizeG: 30, servingDescription: "per serving"
            ...(() => {
              const servingStr = nutritionData.servingSize;
              if (!servingStr) return {};

              // Try to extract grams from parentheses: "5 gyoza (100 g)" → 100
              const parenMatch = String(servingStr).match(/\((\d+(?:\.\d+)?)\s*g\)/i);
              if (parenMatch) {
                const grams = parseFloat(parenMatch[1]);
                // Description is everything before the parentheses, trimmed
                const desc = String(servingStr).replace(/\s*\(\d+(?:\.\d+)?\s*g\)\s*/i, '').trim();
                return {
                  servingSizeG: grams,
                  servingDescription: desc || 'per serving',
                };
              }

              // Try plain number with g: "30g" or "30 g" → 30
              const plainMatch = String(servingStr).match(/^(\d+(?:\.\d+)?)\s*g$/i);
              if (plainMatch) {
                return {
                  servingSizeG: parseFloat(plainMatch[1]),
                  servingDescription: 'per serving',
                };
              }

              // If it's just a number, use it as grams
              if (typeof servingStr === 'number') {
                return {
                  servingSizeG: servingStr,
                  servingDescription: 'per serving',
                };
              }

              // Validate serving size - reject vague descriptions without weight
              // e.g., "1 egg", "2 pieces", "1 bar" are invalid without gram weight
              const servingLower = String(servingStr).toLowerCase().trim();

              // Reject patterns like "1 egg", "2 pieces", "1 bar" (count + item, no grams)
              const vagueCountPattern = /^\d+\s*(egg|piece|bar|slice|biscuit|item|unit|portion|serving|pack|sachet|pot|cookie|cracker|tablet|capsule|scoop)s?$/i;
              if (vagueCountPattern.test(servingLower)) {
                console.log(`   ⚠️ Rejected vague serving size without weight: "${servingStr}"`);
                return {}; // Don't store invalid serving sizes
              }

              // Also reject very short vague descriptions
              const vagueSizes = ['per serving', 'per portion', 'serving', 'portion', 'per unit', 'unit'];
              if (vagueSizes.includes(servingLower)) {
                console.log(`   ⚠️ Rejected vague serving size: "${servingStr}"`);
                return {}; // Don't store invalid serving sizes
              }

              // Otherwise store as description only (no grams found)
              // This should only happen for valid descriptive sizes like "1/4 pizza" or "small bowl"
              return {
                servingDescription: String(servingStr),
              };
            })(),
            ...(nutritionData.ingredients !== undefined && { ingredients: nutritionData.ingredients }),
            ...(nutritionData.sourceUrl !== undefined && { sourceUrl: nutritionData.sourceUrl }),
          };

          if (isFastFood) {
            addLog(`🍔 Fast food mode: Setting isPerUnit=true, servingSizeG=1, description="${servingDesc}"`);
            addLog(`   Nutrition values are for FULL UNIT (not per 100g) - won't be multiplied by grams`);
          }

          // Debug: Show exactly what's being sent to the backend
          console.log(`📤 Sending to backend:`, nutritionPayload);
          addLog(`📤 Payload fields: ${Object.keys(nutritionPayload).join(', ')}`);

          const updateResponse = await fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/updateFoodNutrition', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              index: food.sourceIndex,
              objectID: food.objectID,
              nutritionData: nutritionPayload,
            }),
          });

          if (!updateResponse.ok) {
            throw new Error(`HTTP ${updateResponse.status}`);
          }

          setFoods(prev => prev.map(f =>
            f.id === food.id
              ? { ...f, status: 'completed', wasProcessed: true }
              : f
          ));
          addLog(`✅ ${food.name}: Saved to database`);
        } catch (error) {
          addLog(`⚠ ${food.name}: Nutrition found but save failed - ${error}`);
          setFoods(prev => prev.map(f =>
            f.id === food.id
              ? { ...f, status: 'ready', error: 'Save failed', wasProcessed: true }
              : f
          ));
        }
      } else {
        setFoods(prev => prev.map(f =>
          f.id === food.id
            ? { ...f, nutritionStatus: 'not_found', status: 'failed', wasProcessed: true }
            : f
        ));
        addLog(`✗ ${food.name}: No nutrition data found`);
      }

      // Small delay to avoid rate limiting
      await new Promise(r => setTimeout(r, 500));
    }

    addLog('✅ Nutrition scraping complete');
    setIsProcessing(false);
    setIsPaused(false);
    setCurrentProcessingIndex(0);
    setTotalToProcess(0);
  };

  // Batch search
  const startBatchSearch = async () => {
    // If nutrition-only mode is enabled, use that instead
    if (nutritionOnlyMode) {
      return processNutritionOnly();
    }

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
      : foods.filter(f => f.status === 'pending' && !f.wasProcessed); // Only process unprocessed foods

    addLog(`Starting batch search of ${toProcess.length} foods`);

    if (toProcess.length === 0) {
      const totalUnprocessed = foods.filter(f => !f.wasProcessed).length;
      if (totalUnprocessed === 0) {
        addLog('✅ All foods have been processed! Select specific foods to reprocess.');
      } else {
        addLog('No pending foods to process. Select specific foods or adjust filters.');
      }
      setIsProcessing(false);
      return;
    }

    // Initialize progress tracking
    setTotalToProcess(toProcess.length);
    setCurrentProcessingIndex(0);

    for (let i = 0; i < toProcess.length; i++) {
      // Update current progress
      setCurrentProcessingIndex(i + 1);

      if (abortRef.current) {
        addLog('Search stopped by user');
        break;
      }

      // Proper pause implementation - check ref AND wait
      while (pauseRef.current) {
        await new Promise(resolve => setTimeout(resolve, 500));
        if (abortRef.current) break;
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
    setCurrentProcessingIndex(0);
    setTotalToProcess(0);
  };

  const pauseProcessing = () => { pauseRef.current = true; setIsPaused(true); addLog('Paused'); };
  const resumeProcessing = () => { pauseRef.current = false; setIsPaused(false); addLog('Resumed'); };
  const stopProcessing = () => { abortRef.current = true; setIsProcessing(false); setIsPaused(false); addLog('Stopped'); };

  // Search images using each food's OWN barcode instead of product name
  const startBarcodeImageSearch = useCallback(async () => {
    if (!apiConfigured) {
      addLog('⚠️ SearchAPI not configured. Please set SERP_API_KEY in .env');
      return;
    }

    setIsProcessing(true);
    pauseRef.current = false;
    abortRef.current = false;

    const selectedFoods = foods.filter(f => f.selected);
    const toProcess = selectedFoods.length > 0
      ? selectedFoods
      : foods.filter(f => f.status === 'pending' && !f.wasProcessed);

    if (toProcess.length === 0) {
      const totalUnprocessed = foods.filter(f => !f.wasProcessed).length;
      if (totalUnprocessed === 0) {
        addLog('✅ All foods have been processed! Select specific foods to reprocess.');
      } else {
        addLog('No pending foods to process. Select specific foods or adjust filters.');
      }
      setIsProcessing(false);
      return;
    }

    addLog(`🔎 Starting barcode-based image search for ${toProcess.length} food(s)`);

    // Initialize progress tracking
    setTotalToProcess(toProcess.length);
    setCurrentProcessingIndex(0);

    for (let i = 0; i < toProcess.length; i++) {
      // Update current progress
      setCurrentProcessingIndex(i + 1);

      if (abortRef.current) {
        addLog('Search stopped by user');
        break;
      }

      // Proper pause implementation - check ref AND wait
      while (pauseRef.current) {
        await new Promise(resolve => setTimeout(resolve, 500));
        if (abortRef.current) break;
      }

      const food = toProcess[i];

      // Use food's own barcode
      if (!food.barcode) {
        addLog(`[${i + 1}/${toProcess.length}] ⚠️ ${food.name} - No barcode, skipping`);
        setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'failed' as const, error: 'No barcode', wasProcessed: true } : f));
        continue;
      }

      addLog(`[${i + 1}/${toProcess.length}] ${food.name} - Using barcode: ${food.barcode}`);

      // Update status to searching
      setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'searching' as const } : f));

      try {
        // Search using THIS FOOD'S barcode
        const results = await searchSerpApiImages(food.barcode, food.brandName || undefined);

        if (results.length === 0) {
          addLog(`  ❌ No results found`);
          setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'no_results' as const, wasProcessed: true } : f));
        } else {
          addLog(`  ✓ Found ${results.length} images`);

          // Analyze images
          setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'analyzing' as const, searchResults: results } : f));

          const analyses = await Promise.all(
            results.map(img => analyzeImageQuality(img.url))
          );

          const bestResult = analyses
            .map((analysis, idx) => ({ analysis, result: results[idx] }))
            .sort((a, b) => b.analysis.qualityScore - a.analysis.qualityScore)[0];

          if (bestResult && bestResult.analysis.qualityScore >= 70) {
            addLog(`  ✅ Best image: ${bestResult.analysis.qualityScore}% confidence`);
            setFoods(prev => prev.map(f =>
              f.id === food.id
                ? {
                    ...f,
                    status: 'ready' as const,
                    selectedImageUrl: bestResult.result.url,
                    analysis: bestResult.analysis,
                    confidence: bestResult.analysis.qualityScore,
                    wasProcessed: true
                  }
                : f
            ));
          } else {
            addLog(`  ⚠️ Low quality images (best: ${bestResult?.analysis.qualityScore || 0}%)`);
            setFoods(prev => prev.map(f =>
              f.id === food.id
                ? {
                    ...f,
                    status: 'ready' as const,
                    analysis: bestResult?.analysis || null,
                    confidence: bestResult?.analysis.qualityScore || 0,
                    wasProcessed: true
                  }
                : f
            ));
          }
        }
      } catch (error) {
        addLog(`  ❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
        setFoods(prev => prev.map(f =>
          f.id === food.id
            ? { ...f, status: 'failed' as const, error: 'Search failed', wasProcessed: true }
            : f
        ));
      }

      // Update stats
      setFoods(prev => {
        updateStats(prev);
        return prev;
      });

      // Delay to avoid rate limiting
      await new Promise(r => setTimeout(r, 1000));
    }

    addLog('Barcode image search complete');
    setIsProcessing(false);
    setIsPaused(false);
    setCurrentProcessingIndex(0);
    setTotalToProcess(0);
  }, [foods, apiConfigured, addLog]);

  // Filter foods by status and search query
  const getFilteredFoods = useCallback(() => {
    let filtered = foods;

    // Filter by status
    switch (filter) {
      case 'pending': filtered = filtered.filter(f => f.status === 'pending'); break;
      case 'ready': filtered = filtered.filter(f => f.status === 'ready'); break;
      case 'selected': filtered = filtered.filter(f => f.selected); break;
      case 'nutrition_found': filtered = filtered.filter(f => f.nutritionStatus === 'found'); break;
      case 'nutrition_failed': filtered = filtered.filter(f => f.nutritionStatus === 'not_found' || f.nutritionStatus === 'failed'); break;
      default: break;
    }

    // Filter by search query
    if (searchQuery.trim()) {
      // Normalize: remove special chars and extra spaces for flexible matching
      const normalizeText = (text: string) =>
        text.toLowerCase().replace(/[^\w\s]/g, '').replace(/\s+/g, ' ').trim();

      const query = normalizeText(searchQuery);
      filtered = filtered.filter(f =>
        normalizeText(f.name).includes(query) ||
        normalizeText(f.brandName || '').includes(query) ||
        f.barcode?.includes(searchQuery.trim()) || // Keep barcode exact
        normalizeText(f.objectID).includes(query)
      );
    }

    return filtered;
  }, [foods, filter, searchQuery]);

  const filteredFoods = getFilteredFoods();
  const paginatedFoods = filteredFoods.slice(currentPage * ITEMS_PER_PAGE, (currentPage + 1) * ITEMS_PER_PAGE);
  const totalPages = Math.ceil(filteredFoods.length / ITEMS_PER_PAGE);
  const selectedCount = foods.filter(f => f.selected).length;
  const pendingCount = foods.filter(f => f.status === 'pending').length;
  const readyCount = foods.filter(f => f.status === 'ready').length;
  const nutritionFoundCount = foods.filter(f => f.nutritionStatus === 'found').length;
  const nutritionFailedCount = foods.filter(f => f.nutritionStatus === 'not_found' || f.nutritionStatus === 'failed').length;

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
              <>
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
                <button
                  onClick={() => {
                    const processedCount = foods.filter(f => f.wasProcessed).length;
                    if (processedCount === 0) {
                      alert('No processed foods to reset.');
                      return;
                    }
                    if (confirm(`Reset processed flags for ${processedCount} foods?\n\nThis allows reprocessing with different settings without losing data.`)) {
                      resetProcessedFlags();
                    }
                  }}
                  className="flex items-center gap-2 px-3 py-2 text-sm text-orange-600 hover:bg-orange-50 rounded-lg"
                  title="Reset processed flags to allow reprocessing with different settings"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                  Reset Processed
                </button>
                <button
                  onClick={() => {
                    if (confirm('Clear ALL saved data?\n\nThis will remove everything from browser storage and reset to empty state.')) {
                      clearSavedProgress();
                      setFoods([]);
                      setShowIndexSelector(true);
                      setStats({ total: 0, completed: 0, failed: 0, noResults: 0, processing: 0 });
                      setProcessingLog([]);
                      setCurrentProcessingIndex(0);
                      setTotalToProcess(0);
                    }
                  }}
                  className="flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg"
                  title="Clear saved progress from browser storage"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  Clear All Data
                </button>
              </>
            )}

            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-sm ${
              apiConfigured ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}>
              <div className={`w-2 h-2 rounded-full ${apiConfigured ? 'bg-green-500' : 'bg-red-500'}`} />
              {apiConfigured ? 'API Configured' : 'API Not Configured'}
            </div>

            {!isProcessing ? (
              <>
                {/* Search by Product Barcode */}
                {foods.length > 0 && (
                  <button
                    onClick={startBarcodeImageSearch}
                    disabled={isLoading || !apiConfigured || (selectedCount === 0 && pendingCount === 0)}
                    className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                    title="Search for images using each food's barcode instead of product name"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                    </svg>
                    {selectedCount > 0 ? `Search by Barcode (${selectedCount})` : `Search All by Barcode (${pendingCount})`}
                  </button>
                )}

                <button
                  onClick={startBatchSearch}
                  disabled={isLoading || (!nutritionOnlyMode && !apiConfigured) || (selectedCount === 0 && pendingCount === 0)}
                  className="flex items-center gap-2 px-5 py-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {nutritionOnlyMode ? (
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ) : (
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                  )}
                  {nutritionOnlyMode
                    ? (selectedCount > 0 ? `Scrape Nutrition (${selectedCount})` : `Scrape All Nutrition (${pendingCount})`)
                    : (selectedCount > 0 ? `Search Selected (${selectedCount})` : `Search All (${pendingCount})`)
                  }
                </button>

                {/* Save Nutrition Button - Save selected items with nutrition data */}
                {selectedCount > 0 && foods.some(f => f.selected && f.nutritionData) && (
                  <button
                    onClick={async () => {
                      const selectedWithNutrition = foods.filter(f => f.selected && f.nutritionData);
                      if (selectedWithNutrition.length === 0) {
                        addLog('⚠️ No selected items have nutrition data to save');
                        return;
                      }

                      addLog(`💾 Saving nutrition for ${selectedWithNutrition.length} selected items...`);
                      setIsProcessing(true);

                      for (const food of selectedWithNutrition) {
                        const nutritionData = food.nutritionData!;

                        try {
                          addLog(`💾 Saving nutrition for ${food.name}...`);

                          const isFastFood = food.sourceIndex === 'fast_foods_database';
                          let servingDesc = null;

                          if (isFastFood) {
                            const name = food.name.toLowerCase();
                            let itemType = 'item';
                            if (name.includes('burger')) itemType = 'burger';
                            else if (name.includes('sandwich')) itemType = 'sandwich';
                            else if (name.includes('wrap')) itemType = 'wrap';
                            else if (name.includes('salad')) itemType = 'salad';
                            else if (name.includes('fries') || name.includes('chips')) itemType = 'serving';
                            else if (name.includes('nugget')) itemType = 'serving';
                            else if (name.includes('pizza')) itemType = 'pizza';

                            if (nutritionData.servingSize) {
                              const sizeStr = typeof nutritionData.servingSize === 'number'
                                ? `${nutritionData.servingSize}g`
                                : nutritionData.servingSize;
                              servingDesc = `${itemType} (${sizeStr})`;
                            } else {
                              servingDesc = itemType;
                            }
                          }

                          const nutritionPayload = isFastFood ? {
                            calories: nutritionData.calories ?? null,
                            protein: nutritionData.protein ?? null,
                            carbs: nutritionData.carbs ?? null,
                            fat: nutritionData.fat ?? null,
                            saturatedFat: nutritionData.saturatedFat ?? null,
                            fiber: nutritionData.fiber ?? null,
                            sugar: nutritionData.sugar ?? null,
                            sodium: nutritionData.sodium ?? null,
                            salt: nutritionData.salt ?? null,
                            servingSizeG: 1,
                            servingDescription: servingDesc,
                            isPerUnit: true,
                            ingredients: nutritionData.ingredients ?? null,
                            sourceUrl: nutritionData.sourceUrl ?? null,
                          } : {
                            ...(nutritionData.calories !== undefined && { calories: nutritionData.calories }),
                            ...(nutritionData.protein !== undefined && { protein: nutritionData.protein }),
                            ...(nutritionData.carbs !== undefined && { carbs: nutritionData.carbs }),
                            ...(nutritionData.fat !== undefined && { fat: nutritionData.fat }),
                            ...(nutritionData.saturatedFat !== undefined && { saturatedFat: nutritionData.saturatedFat }),
                            ...(nutritionData.fiber !== undefined && { fiber: nutritionData.fiber }),
                            ...(nutritionData.sugar !== undefined && { sugar: nutritionData.sugar }),
                            ...(nutritionData.sodium !== undefined && { sodium: nutritionData.sodium }),
                            ...(nutritionData.salt !== undefined && { salt: nutritionData.salt }),
                            ...(() => {
                              const servingStr = nutritionData.servingSize;
                              if (!servingStr) return {};

                              const parenMatch = String(servingStr).match(/\((\d+(?:\.\d+)?)\s*g\)/i);
                              if (parenMatch) {
                                const grams = parseFloat(parenMatch[1]);
                                const desc = String(servingStr).replace(/\s*\(\d+(?:\.\d+)?\s*g\)\s*/i, '').trim();
                                return {
                                  servingSizeG: grams,
                                  servingDescription: desc || 'per serving',
                                };
                              }

                              const plainMatch = String(servingStr).match(/^(\d+(?:\.\d+)?)\s*g$/i);
                              if (plainMatch) {
                                return {
                                  servingSizeG: parseFloat(plainMatch[1]),
                                  servingDescription: 'per serving',
                                };
                              }

                              if (typeof servingStr === 'number') {
                                return {
                                  servingSizeG: servingStr,
                                  servingDescription: 'per serving',
                                };
                              }

                              // Validate serving size - reject vague descriptions without weight
                              // e.g., "1 egg", "2 pieces", "1 bar" are invalid without gram weight
                              const servingLower = String(servingStr).toLowerCase().trim();

                              // Reject patterns like "1 egg", "2 pieces", "1 bar" (count + item, no grams)
                              const vagueCountPattern = /^\d+\s*(egg|piece|bar|slice|biscuit|item|unit|portion|serving|pack|sachet|pot|cookie|cracker|tablet|capsule|scoop)s?$/i;
                              if (vagueCountPattern.test(servingLower)) {
                                console.log(`   ⚠️ Rejected vague serving size without weight: "${servingStr}"`);
                                return {}; // Don't store invalid serving sizes
                              }

                              // Also reject very short vague descriptions
                              const vagueSizes = ['per serving', 'per portion', 'serving', 'portion', 'per unit', 'unit'];
                              if (vagueSizes.includes(servingLower)) {
                                console.log(`   ⚠️ Rejected vague serving size: "${servingStr}"`);
                                return {}; // Don't store invalid serving sizes
                              }

                              // Otherwise store as description only (no grams found)
                              // This should only happen for valid descriptive sizes like "1/4 pizza" or "small bowl"
                              return {
                                servingDescription: String(servingStr),
                              };
                            })(),
                            ...(nutritionData.ingredients !== undefined && { ingredients: nutritionData.ingredients }),
                            ...(nutritionData.sourceUrl !== undefined && { sourceUrl: nutritionData.sourceUrl }),
                          };

                          addLog(`📤 Payload fields: ${Object.keys(nutritionPayload).join(', ')}`);

                          const updateResponse = await fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/updateFoodNutrition', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                              index: food.sourceIndex,
                              objectID: food.objectID,
                              nutritionData: nutritionPayload,
                            }),
                          });

                          if (updateResponse.ok) {
                            addLog(`✅ ${food.name}: Saved to database`);
                          } else {
                            addLog(`⚠ ${food.name}: Save failed - ${updateResponse.status}`);
                          }
                        } catch (error) {
                          addLog(`⚠ ${food.name}: Save error - ${error}`);
                        }
                      }

                      addLog(`✅ Saved nutrition for ${selectedWithNutrition.length} items`);
                      setIsProcessing(false);
                    }}
                    disabled={isProcessing}
                    className="flex items-center gap-2 px-5 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
                    </svg>
                    Save Nutrition ({foods.filter(f => f.selected && f.nutritionData).length})
                  </button>
                )}

                {readyCount > 0 && (
                  <button
                    onClick={async () => {
                      const readyFoods = foods.filter(f => f.status === 'ready' && f.selectedImageUrl);
                      addLog(`Starting upload of ${readyFoods.length} ready items...`);

                      for (const food of readyFoods) {
                        setFoods(prev => prev.map(f => f.id === food.id ? { ...f, status: 'uploading' as const } : f));

                        try {
                          addLog(`Uploading ${food.name}...`);

                          const uploadResponse = await fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/uploadFoodImage', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                              imageUrl: food.selectedImageUrl,
                              index: food.sourceIndex,
                              objectID: food.objectID,
                            }),
                          });

                          if (!uploadResponse.ok) {
                            const errorText = await uploadResponse.text();
                            throw new Error(`HTTP ${uploadResponse.status}: ${errorText}`);
                          }

                          const uploadData = await uploadResponse.json();
                          addLog(`✓ ${food.name}`);

                          setFoods(prev => prev.map(f =>
                            f.id === food.id ? { ...f, status: 'completed' as const, currentImageUrl: uploadData.imageUrl } : f
                          ));

                          await new Promise(r => setTimeout(r, 500)); // Rate limit
                        } catch (error) {
                          addLog(`✗ ${food.name}: ${error instanceof Error ? error.message : 'Unknown error'}`);
                          setFoods(prev => prev.map(f =>
                            f.id === food.id ? { ...f, status: 'failed' as const, error: 'Upload failed' } : f
                          ));
                        }
                      }

                      addLog('Upload batch complete');
                    }}
                    className="flex items-center gap-2 px-5 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    Upload All Ready ({readyCount})
                  </button>
                )}
              </>
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

        {/* Active Settings - Interactive */}
        {foods.length > 0 && (
          <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-start gap-3">
              <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <div className="flex-1">
                <div className="text-sm font-medium text-blue-900 mb-3">Active Settings (Click to change)</div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {/* Nutrition Only Mode */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={nutritionOnlyMode}
                      onChange={(e) => setNutritionOnlyMode(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-purple-600 rounded"
                    />
                    <span className="text-sm font-medium">🍎 Nutrition Only (No Images)</span>
                  </label>

                  {/* Scrape Nutrition */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={scrapeNutrition}
                      onChange={(e) => setScrapeNutrition(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-green-600 rounded"
                    />
                    <span className="text-sm">Nutrition Values</span>
                  </label>

                  {/* Scrape Serving Size */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={scrapeServingSize}
                      onChange={(e) => setScrapeServingSize(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-blue-600 rounded"
                    />
                    <span className="text-sm font-medium">📏 Serving Size</span>
                  </label>

                  {/* Scrape Ingredients */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={scrapeIngredients}
                      onChange={(e) => setScrapeIngredients(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-purple-600 rounded"
                    />
                    <span className="text-sm">🥕 Ingredients</span>
                  </label>

                  {/* Filter UK Only */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={filterUKOnly}
                      onChange={(e) => setFilterUKOnly(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-gray-600 rounded"
                    />
                    <span className="text-sm">🇬🇧 UK Only</span>
                  </label>

                  {/* Exclude Drinks */}
                  <label className="flex items-center gap-2 p-2 rounded bg-white border border-blue-200 cursor-pointer hover:bg-blue-50 transition-colors">
                    <input
                      type="checkbox"
                      checked={excludeDrinks}
                      onChange={(e) => setExcludeDrinks(e.target.checked)}
                      disabled={isProcessing}
                      className="w-4 h-4 text-gray-600 rounded"
                    />
                    <span className="text-sm">Exclude Drinks</span>
                  </label>
                </div>

                {isProcessing && (
                  <div className="mt-2 text-xs text-yellow-700 bg-yellow-100 px-2 py-1 rounded">
                    ⚠️ Settings locked during processing. Stop to change settings.
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Progress */}
        <div className="space-y-3">
          {/* Processing Progress Bar */}
          {isProcessing && totalToProcess > 0 && (
            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-blue-900">
                  Processing: {currentProcessingIndex} / {totalToProcess}
                </span>
                <span className="text-sm text-blue-700">
                  {Math.round((currentProcessingIndex / totalToProcess) * 100)}%
                </span>
              </div>
              <div className="h-3 bg-blue-200 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-600 transition-all duration-300"
                  style={{ width: `${(currentProcessingIndex / totalToProcess) * 100}%` }}
                />
              </div>
              {isPaused && (
                <div className="mt-2 text-sm text-yellow-700 font-medium">
                  ⏸️ Paused - Click Resume to continue
                </div>
              )}
            </div>
          )}

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
                {(() => {
                  const processedCount = foods.filter(f => f.wasProcessed).length;
                  const unprocessedCount = foods.length - processedCount;
                  return (
                    <>
                      <span className="text-purple-600">Processed: <strong>{processedCount.toLocaleString()}</strong></span>
                      {unprocessedCount > 0 && (
                        <span className="text-orange-600">Remaining: <strong>{unprocessedCount.toLocaleString()}</strong></span>
                      )}
                    </>
                  );
                })()}
                {ukFilterStats && (
                  <span className="text-blue-600">
                    🇬🇧 UK Filter: <strong>{ukFilterStats.ukCount}</strong> kept ({ukFilterStats.ukPercentage}%), <strong>{ukFilterStats.nonUkCount}</strong> filtered ({ukFilterStats.nonUkPercentage}%)
                  </span>
                )}
                {imageFilterStats && (
                  <span className="text-purple-600">
                    🖼️ Image Filter: <strong>{imageFilterStats.withoutImages.toLocaleString()}</strong> without images, <strong>{imageFilterStats.withImages.toLocaleString()}</strong> with images hidden
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
            { value: 'nutrition_found', label: '✓ Nutrition Found', count: nutritionFoundCount },
            { value: 'nutrition_failed', label: '✗ No Nutrition', count: nutritionFailedCount },
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
        <div className="flex items-center gap-3">
          {/* Search input */}
          <div className="relative">
            <input
              type="text"
              placeholder="Search foods..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(0); // Reset to first page on search
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && searchQuery.trim() && foods.length === 0) {
                  handleSearch();
                }
              }}
              className="w-64 px-3 py-1.5 pl-9 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
            <svg
              className="absolute left-2.5 top-2 w-4 h-4 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            {searchQuery && (
              <button
                onClick={() => {
                  setSearchQuery('');
                  setCurrentPage(0);
                }}
                className="absolute right-2 top-2 text-gray-400 hover:text-gray-600"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
          </div>

          {/* Search Algolia button - only show when no foods are loaded */}
          {foods.length === 0 && (
            <button
              onClick={handleSearch}
              disabled={!searchQuery.trim() || isSearching || selectedIndices.size === 0}
              className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSearching ? (
                <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
              ) : (
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              )}
              Search Algolia
            </button>
          )}

          {searchQuery && foods.length > 0 && (
            <span className="text-xs text-gray-500">
              {filteredFoods.length} result{filteredFoods.length !== 1 ? 's' : ''} (filtered)
            </span>
          )}
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

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-purple-200 bg-purple-50 cursor-pointer hover:bg-purple-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={filterNoImages}
                        onChange={(e) => setFilterNoImages(e.target.checked)}
                        className="w-4 h-4 text-purple-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">🖼️ Hide Foods With Images</span>
                          <span className="px-2 py-0.5 text-xs font-semibold text-purple-700 bg-purple-200 rounded-full">Recommended</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Only show foods that are missing images. This helps you focus on products that actually need image scraping, saving time and API calls.
                        </p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-orange-200 bg-orange-50 cursor-pointer hover:bg-orange-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={filterZeroCalories}
                        onChange={(e) => setFilterZeroCalories(e.target.checked)}
                        className="w-4 h-4 text-orange-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">0️⃣ Very Low Calorie (0-5 kcal)</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Only show foods with 0-5 calories per 100g. Catches zero-calorie sweeteners, diet sodas, condiments, and other ultra-low calorie products (including 1-2 kcal items like sugar-free syrups).
                        </p>
                      </div>
                    </label>

                    {filterZeroCalories && (
                      <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-amber-200 bg-amber-50 cursor-pointer hover:bg-amber-100 transition-colors mt-3 ml-6">
                        <input
                          type="checkbox"
                          checked={excludeDrinks}
                          onChange={(e) => setExcludeDrinks(e.target.checked)}
                          className="w-4 h-4 text-amber-600 rounded mt-0.5"
                        />
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium text-gray-900">🥤 Exclude Drinks</span>
                          </div>
                          <p className="text-xs text-gray-600 mt-1">
                            When filtering very low calorie items, exclude beverages like water, diet sodas, tea, coffee, and other drinks. Focus on actual food items only.
                          </p>
                        </div>
                      </label>
                    )}

                    {/* Tesco bad image filter DISABLED - checkbox removed */}
                    {/* Previously: "Hide Tesco Bad Images" checkbox that filtered items with dontShowImage flag */}

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-green-200 bg-green-50 cursor-pointer hover:bg-green-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={scrapeNutrition}
                        onChange={(e) => setScrapeNutrition(e.target.checked)}
                        className="w-4 h-4 text-green-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">🍎 Scrape Nutrition Data</span>
                          <span className="px-2 py-0.5 text-xs font-semibold text-green-700 bg-green-200 rounded-full">Recommended</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Automatically fetch nutrition information from Google during processing. Includes calories, protein, carbs, fat, fiber, sugar, and sodium.
                        </p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-blue-200 bg-blue-50 cursor-pointer hover:bg-blue-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={scrapeServingSize}
                        onChange={(e) => setScrapeServingSize(e.target.checked)}
                        className="w-4 h-4 text-blue-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">📏 Require Serving Size (Recommended)</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Only extract nutrition data if an ACTUAL serving size is specified (e.g., "30g", "per piece (50g)").
                          Per-100g-only data will be rejected. This ensures all scraped data has real-world portion sizes.
                          Highly recommended to avoid misleading per-100g values.
                        </p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-purple-200 bg-purple-50 cursor-pointer hover:bg-purple-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={scrapeIngredients}
                        onChange={(e) => setScrapeIngredients(e.target.checked)}
                        className="w-4 h-4 text-purple-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">🥕 Scrape Ingredients</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Automatically extract ingredient lists from product pages. Essential for allergen detection and dietary restrictions.
                        </p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3 p-4 rounded-lg border-2 border-teal-200 bg-teal-50 cursor-pointer hover:bg-teal-100 transition-colors mt-3">
                      <input
                        type="checkbox"
                        checked={nutritionOnlyMode}
                        onChange={(e) => setNutritionOnlyMode(e.target.checked)}
                        className="w-4 h-4 text-teal-600 rounded mt-0.5"
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">🔬 Nutrition Only Mode</span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">
                          Skip image scraping entirely - only search for nutrition data. Much faster and uses fewer API calls. Great for quickly filling in missing nutrition information.
                        </p>
                      </div>
                    </label>
                  </div>

                  {/* Barcode Search OR Load All */}
                  <div className="mb-6 pb-6 border-b border-gray-200">
                    <div className="flex items-center gap-2 mb-3 text-sm text-gray-500">
                      <span className="flex items-center justify-center w-6 h-6 bg-primary-600 text-white rounded-full text-xs font-bold">3</span>
                      <span className="font-medium text-gray-700">Search by barcode or load all</span>
                    </div>

                    <div className="flex gap-3">
                      <div className="flex-1">
                        <input
                          type="text"
                          placeholder="Enter barcode (e.g., 5000159407236)"
                          value={barcodeQuery}
                          onChange={(e) => setBarcodeQuery(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter' && barcodeQuery.trim()) {
                              handleBarcodeSearch();
                            }
                          }}
                          className="w-full px-4 py-3 text-sm border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                        />
                      </div>
                      <button
                        onClick={handleBarcodeSearch}
                        disabled={!barcodeQuery.trim() || isBarcodeSearching || selectedIndices.size === 0}
                        className="flex items-center gap-2 px-5 py-3 text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg"
                      >
                        {isBarcodeSearching ? (
                          <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                          </svg>
                        ) : (
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                          </svg>
                        )}
                        Search
                      </button>
                    </div>
                    <p className="text-xs text-gray-500 mt-2">💡 Search for a specific product by barcode, or load all foods from selected indices below</p>
                  </div>

                  <button
                    onClick={loadFoodsFromIndices}
                    disabled={selectedIndices.size === 0}
                    className="w-full flex items-center justify-center gap-3 px-6 py-4 text-lg font-semibold text-white bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 rounded-xl shadow-lg hover:shadow-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    Load All {selectedIndices.size > 0 ? `Foods from ${selectedIndices.size} ${selectedIndices.size === 1 ? 'Index' : 'Indices'}` : 'Foods'}
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

                      {/* Current/Selected image preview */}
                      <div className="flex-shrink-0">
                        <div className="text-xs text-gray-400 mb-1 text-center">
                          {food.selectedImageUrl ? 'Selected' : 'Current'}
                        </div>
                        <div
                          className="w-20 h-20 bg-gray-100 rounded flex items-center justify-center overflow-hidden cursor-pointer hover:ring-2 hover:ring-primary-400"
                          onClick={() => {
                            const url = food.selectedImageUrl || food.currentImageUrl;
                            if (url) setPreviewImage({ url, title: `${food.name}` });
                          }}
                        >
                          {food.selectedImageUrl ? (
                            <img src={food.selectedImageUrl} alt="" className="w-full h-full object-contain" />
                          ) : food.currentImageUrl ? (
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
                          {food.calories !== undefined && (
                            <span className="px-1.5 py-0.5 bg-gray-100 rounded">{food.calories} cal</span>
                          )}
                        </div>

                        {/* Nutrition Data */}
                        {food.nutritionData && (
                          <div className="mt-2 p-2 bg-green-50 border border-green-200 rounded text-xs">
                            <div className="flex items-center justify-between mb-1">
                              <div className="font-semibold text-green-900 flex items-center gap-1">
                                🍎 Nutrition (per 100g)
                                {food.nutritionData.servingSize && <span className="text-blue-600">📏</span>}
                              </div>
                              <div className="text-[10px] text-green-700">
                                {food.nutritionData.sourceUrl ? (
                                  <a
                                    href={food.nutritionData.sourceUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="hover:underline text-blue-600 hover:text-blue-800"
                                  >
                                    {food.nutritionData.source} 🔗
                                  </a>
                                ) : (
                                  food.nutritionData.source
                                )}
                              </div>
                            </div>
                            {food.nutritionData.servingSize && (
                              <div className="px-2 py-1 bg-blue-50 border border-blue-200 rounded text-[11px] text-blue-900 font-medium mb-1">
                                📏 Serving: {food.nutritionData.servingSize}
                              </div>
                            )}
                            <div className="grid grid-cols-3 gap-2 text-gray-700">
                              {food.nutritionData.calories !== undefined && (
                                <div><span className="font-medium">Cal:</span> {food.nutritionData.calories}</div>
                              )}
                              {food.nutritionData.protein !== undefined && (
                                <div><span className="font-medium">Protein:</span> {food.nutritionData.protein}g</div>
                              )}
                              {food.nutritionData.carbs !== undefined && (
                                <div><span className="font-medium">Carbs:</span> {food.nutritionData.carbs}g</div>
                              )}
                              {food.nutritionData.fat !== undefined && (
                                <div><span className="font-medium">Fat:</span> {food.nutritionData.fat}g</div>
                              )}
                              {food.nutritionData.saturatedFat !== undefined && (
                                <div><span className="font-medium">Sat Fat:</span> {food.nutritionData.saturatedFat}g</div>
                              )}
                              {food.nutritionData.fiber !== undefined && (
                                <div><span className="font-medium">Fiber:</span> {food.nutritionData.fiber}g</div>
                              )}
                              {food.nutritionData.sugar !== undefined && (
                                <div><span className="font-medium">Sugar:</span> {food.nutritionData.sugar}g</div>
                              )}
                              {food.nutritionData.sodium !== undefined && (
                                <div><span className="font-medium">Sodium:</span> {food.nutritionData.sodium}mg</div>
                              )}
                              {food.nutritionData.salt !== undefined && (
                                <div><span className="font-medium">Salt:</span> {food.nutritionData.salt}g</div>
                              )}
                            </div>
                          </div>
                        )}

                        {/* Nutrition Status */}
                        {food.nutritionStatus !== 'pending' && !food.nutritionData && (
                          <div className="mt-2 text-xs">
                            <span className={`inline-flex items-center gap-1 px-2 py-1 rounded ${
                              food.nutritionStatus === 'searching' ? 'bg-blue-100 text-blue-700' :
                              food.nutritionStatus === 'not_found' ? 'bg-yellow-100 text-yellow-700' :
                              food.nutritionStatus === 'failed' ? 'bg-red-100 text-red-700' :
                              'bg-gray-100 text-gray-700'
                            }`}>
                              {food.nutritionStatus === 'searching' && '🔍 Searching nutrition...'}
                              {food.nutritionStatus === 'not_found' && '⚠ No nutrition data found'}
                              {food.nutritionStatus === 'failed' && '✗ Nutrition search failed'}
                            </span>
                          </div>
                        )}

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
                                  className="flex-shrink-0 relative group"
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
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      // Mark this image as selected and ready for upload
                                      setFoods(prev => prev.map(f =>
                                        f.id === food.id
                                          ? { ...f, selectedImageUrl: result.url, status: 'ready' as const, error: undefined }
                                          : f
                                      ));
                                      addLog(`Selected image for ${food.name} - ready for upload`);
                                    }}
                                    className="absolute bottom-0 left-0 right-0 bg-primary-600 text-white text-[9px] py-0.5 hover:bg-primary-700 opacity-0 group-hover:opacity-100 transition-opacity"
                                  >
                                    Select This
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
