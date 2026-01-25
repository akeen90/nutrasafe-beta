/**
 * Master Database Builder
 * Scans all indices, finds duplicates, merges to best UK version, keeps all barcodes
 */

import React, { useState, useCallback } from 'react';
import { ALGOLIA_INDICES } from '../types';
import { filterUKProducts } from '../services/ukProductDetection';

const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

interface Product {
  objectID: string;
  name: string;
  foodName?: string;
  brandName?: string;
  brand?: string;
  barcode?: string | string[];
  imageUrl?: string;
  ingredients?: string;
  servingSize?: string;
  servingUnit?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
  sodium?: number;
  sourceIndex: string;
  [key: string]: any;
}

interface DuplicateGroup {
  key: string; // e.g., "coca-cola_330ml"
  products: Product[];
  bestProduct?: Product;
  allBarcodes: string[];
  score: number;
}

interface BuilderStats {
  totalScanned: number;
  duplicateGroups: number;
  productsToMerge: number;
  filteredForeign: number;
  finalMasterCount: number;
  processing: boolean;
}

export const MasterDatabaseBuilderPage: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(() => new Set(ALGOLIA_INDICES));
  const [isPulling, setIsPulling] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [isBuilding, setIsBuilding] = useState(false);
  const [isMerging, setIsMerging] = useState(false);
  const [allProducts, setAllProducts] = useState<Product[]>([]);
  const [stats, setStats] = useState<BuilderStats>({
    totalScanned: 0,
    duplicateGroups: 0,
    productsToMerge: 0,
    filteredForeign: 0,
    finalMasterCount: 0,
    processing: false,
  });
  const [duplicateGroups, setDuplicateGroups] = useState<DuplicateGroup[]>([]);
  const [logs, setLogs] = useState<string[]>([]);
  const [progress, setProgress] = useState(0);
  const [testMode, setTestMode] = useState(false); // Default to full scan - use checkbox to enable test mode
  const [indexStats, setIndexStats] = useState<Record<string, { count: number; error?: string }>>({});
  const [singleIndexMode, setSingleIndexMode] = useState(false);
  const [selectedSingleIndex, setSelectedSingleIndex] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [searchField, setSearchField] = useState<'all' | 'brand' | 'name' | 'barcode'>('all');
  const [selectedProductIds, setSelectedProductIds] = useState<Set<string>>(new Set());
  const [isDeleting, setIsDeleting] = useState(false);

  const addLog = useCallback((message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [...prev.slice(-100), `${timestamp}: ${message}`]);
    console.log(message);
  }, []);

  // Select all filtered products
  const handleSelectAll = useCallback(() => {
    // Filter products based on current search
    const filtered = searchQuery
      ? allProducts.filter(product => {
          const query = searchQuery.toLowerCase().trim();
          const name = (product.name || product.foodName || '').toLowerCase();
          const brand = (product.brand || product.brandName || '').toLowerCase();
          const barcode = Array.isArray(product.barcode)
            ? product.barcode.join(' ').toLowerCase()
            : (product.barcode || '').toLowerCase();

          if (searchField === 'all') {
            return name.includes(query) || brand.includes(query) || barcode.includes(query);
          } else if (searchField === 'brand') {
            return brand.includes(query);
          } else if (searchField === 'name') {
            return name.includes(query);
          } else if (searchField === 'barcode') {
            return barcode.includes(query);
          }
          return false;
        })
      : allProducts;

    const ids = new Set(filtered.map(p => p.objectID));
    setSelectedProductIds(ids);
  }, [searchQuery, searchField, allProducts]);

  // Deselect all
  const handleDeselectAll = useCallback(() => {
    setSelectedProductIds(new Set());
  }, []);

  // Toggle individual product selection
  const toggleProductSelection = useCallback((productId: string) => {
    setSelectedProductIds(prev => {
      const next = new Set(prev);
      if (next.has(productId)) {
        next.delete(productId);
      } else {
        next.add(productId);
      }
      return next;
    });
  }, []);

  // Delete selected products
  const handleDeleteSelected = useCallback(async () => {
    if (selectedProductIds.size === 0) {
      alert('No products selected');
      return;
    }

    const confirmDelete = window.confirm(
      `Are you sure you want to DELETE ${selectedProductIds.size} product(s)? This action CANNOT be undone!`
    );

    if (!confirmDelete) return;

    setIsDeleting(true);
    addLog(`🗑️ Deleting ${selectedProductIds.size} selected products...`);

    try {
      // Group products by source index for deletion
      const productsByIndex = new Map<string, string[]>();

      for (const productId of selectedProductIds) {
        const product = allProducts.find(p => p.objectID === productId);
        if (product) {
          const indexName = product.sourceIndex;
          if (!productsByIndex.has(indexName)) {
            productsByIndex.set(indexName, []);
          }
          productsByIndex.get(indexName)!.push(productId);
        }
      }

      let totalDeleted = 0;
      let totalFailed = 0;

      // Delete from each index
      for (const [indexName, objectIDs] of productsByIndex) {
        addLog(`  → Deleting ${objectIDs.length} products from ${indexName}...`);

        const response = await fetch(`${FUNCTIONS_BASE}/deleteFromIndex`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            indexName,
            objectIDs,
          }),
        });

        if (response.ok) {
          const result = await response.json();
          if (result.success) {
            totalDeleted += objectIDs.length;
            addLog(`  ✅ Deleted ${objectIDs.length} from ${indexName}`);
          } else {
            totalFailed += objectIDs.length;
            addLog(`  ❌ Failed to delete from ${indexName}: ${result.error}`);
          }
        } else {
          totalFailed += objectIDs.length;
          addLog(`  ❌ Failed to delete from ${indexName}: HTTP ${response.status}`);
        }
      }

      // Remove deleted products from local state
      if (totalDeleted > 0) {
        const deletedIds = new Set(selectedProductIds);
        const remainingProducts = allProducts.filter(p => !deletedIds.has(p.objectID));
        setAllProducts(remainingProducts);
        setSelectedProductIds(new Set());

        addLog(`✅ Successfully deleted ${totalDeleted} products`);
        if (totalFailed > 0) {
          addLog(`⚠️ Failed to delete ${totalFailed} products`);
        }
      } else {
        addLog(`❌ No products were deleted`);
      }
    } catch (error) {
      addLog(`❌ Error deleting products: ${error}`);
      alert('Error deleting products. Check logs for details.');
    } finally {
      setIsDeleting(false);
    }
  }, [selectedProductIds, allProducts, addLog]);

  // Calculate Levenshtein distance for fuzzy string matching
  const levenshteinDistance = (str1: string, str2: string): number => {
    try {
      // Validate inputs
      if (!str1 || !str2 || typeof str1 !== 'string' || typeof str2 !== 'string') {
        return Math.max(str1?.length || 0, str2?.length || 0);
      }

      // Limit string length to prevent memory issues
      const maxLen = 1000;
      const s1 = str1.length > maxLen ? str1.substring(0, maxLen) : str1;
      const s2 = str2.length > maxLen ? str2.substring(0, maxLen) : str2;

      const matrix: number[][] = [];

      for (let i = 0; i <= s2.length; i++) {
        matrix[i] = [i];
      }

      for (let j = 0; j <= s1.length; j++) {
        matrix[0][j] = j;
      }

      for (let i = 1; i <= s2.length; i++) {
        for (let j = 1; j <= s1.length; j++) {
          if (s2.charAt(i - 1) === s1.charAt(j - 1)) {
            matrix[i][j] = matrix[i - 1][j - 1];
          } else {
            matrix[i][j] = Math.min(
              matrix[i - 1][j - 1] + 1,
              matrix[i][j - 1] + 1,
              matrix[i - 1][j] + 1
            );
          }
        }
      }

      return matrix[s2.length][s1.length];
    } catch {
      return Math.max(str1?.length || 0, str2?.length || 0);
    }
  };

  // Normalize text for comparison
  const normalizeText = (text: string): string => {
    try {
      if (!text || typeof text !== 'string') return '';
      return text
        .toLowerCase()
        .trim()
        .replace(/[^\w\s]/g, '')
        .replace(/\s+/g, ' ');
    } catch {
      return '';
    }
  };

  // Calculate similarity score between two products (0-100)
  interface SimilarityResult {
    score: number;
    reasons: string[];
  }

  const calculateSimilarity = (p1: Product, p2: Product): SimilarityResult => {
    // Defensive checks
    if (!p1 || !p2) {
      return { score: 0, reasons: ['Invalid product(s)'] };
    }

    let score = 0;
    const reasons: string[] = [];

    try {
      // 1. Barcode match = 100% certainty (strongest signal)
      // Extract all barcodes from both products
      const barcodes1 = typeof p1.barcode === 'string'
        ? [p1.barcode]
        : Array.isArray(p1.barcode) ? p1.barcode.filter(b => b && typeof b === 'string') : [];
      const barcodes2 = typeof p2.barcode === 'string'
        ? [p2.barcode]
        : Array.isArray(p2.barcode) ? p2.barcode.filter(b => b && typeof b === 'string') : [];

      // Check if ANY barcode from p1 matches ANY barcode from p2
      const matchingBarcode = barcodes1.find(b1 => b1 && barcodes2.includes(b1));

      if (matchingBarcode) {
        score = 100;
        reasons.push(`Exact barcode match: ${matchingBarcode}`);
        return { score, reasons }; // Barcode match is definitive
      }
    } catch (err) {
      // Non-fatal, continue with other signals
    }

    // 2. Brand name matching (with fuzzy tolerance) - 30 points
    try {
      const brand1 = normalizeText(p1.brandName || p1.brand || '');
      const brand2 = normalizeText(p2.brandName || p2.brand || '');

      if (brand1 && brand2) {
        if (brand1 === brand2) {
          score += 30;
          reasons.push('Exact brand match');
        } else {
          // Fuzzy brand match (allow minor spelling differences)
          const distance = levenshteinDistance(brand1, brand2);
          const maxLength = Math.max(brand1.length, brand2.length);
          if (maxLength > 0) {
            const similarity = 1 - (distance / maxLength);

            if (similarity >= 0.8) {
              const fuzzyScore = Math.round(similarity * 30);
              score += fuzzyScore;
              reasons.push(`Fuzzy brand match (${Math.round(similarity * 100)}% similar)`);
            }
          }
        }
      }
    } catch (err) {
      // Non-fatal, skip brand matching
    }

    // 3. Food name matching (with fuzzy tolerance) - 40 points
    try {
      const name1 = normalizeText(p1.name || p1.foodName || '');
      const name2 = normalizeText(p2.name || p2.foodName || '');

      if (name1 && name2) {
        if (name1 === name2) {
          score += 40;
          reasons.push('Exact name match');
        } else {
          // Fuzzy name match
          const distance = levenshteinDistance(name1, name2);
          const maxLength = Math.max(name1.length, name2.length);
          if (maxLength > 0) {
            const similarity = 1 - (distance / maxLength);

            if (similarity >= 0.7) {
              const fuzzyScore = Math.round(similarity * 40);
              score += fuzzyScore;
              reasons.push(`Fuzzy name match (${Math.round(similarity * 100)}% similar)`);
            }
          }
        }
      }
    } catch (err) {
      // Non-fatal, skip name matching
    }

    // 4. Macro comparison - 30 points
    try {
      const hasValidMacros = (p: Product): boolean => {
        try {
          const cals = p.calories || 0;
          const prot = p.protein || 0;
          const carbs = p.carbs || 0;
          const fat = p.fat || 0;

          // Check if macros are reasonable (not impossibly high)
          if (cals > 900 || prot > 100 || carbs > 100 || fat > 100) {
            return false;
          }

          // Check if calorie calculation is roughly correct (protein*4 + carbs*4 + fat*9)
          const calculatedCals = (prot * 4) + (carbs * 4) + (fat * 9);
          const diff = Math.abs(cals - calculatedCals);
          const tolerance = Math.max(calculatedCals * 0.2, 1); // 20% tolerance, min 1

          return diff <= tolerance;
        } catch {
          return false;
        }
      };

      const macrosMatch = (p1: Product, p2: Product): number => {
        try {
          const fields = [
            { key: 'calories', tolerance: 0.1 },
            { key: 'protein', tolerance: 0.1 },
            { key: 'carbs', tolerance: 0.1 },
            { key: 'fat', tolerance: 0.1 },
          ];

          let matches = 0;
          let validFields = 0;
          for (const field of fields) {
            const v1 = (p1 as any)[field.key] || 0;
            const v2 = (p2 as any)[field.key] || 0;

            if (v1 === 0 && v2 === 0) continue;

            validFields++;
            const diff = Math.abs(v1 - v2);
            const avg = (v1 + v2) / 2;

            if (avg > 0 && diff <= avg * field.tolerance) {
              matches++;
            }
          }

          return validFields > 0 ? matches / validFields : 0;
        } catch {
          return 0;
        }
      };

      const macroSimilarity = macrosMatch(p1, p2);
      if (macroSimilarity >= 0.75) {
        const macroScore = Math.round(macroSimilarity * 30);
        score += macroScore;
        reasons.push(`Macros match (${Math.round(macroSimilarity * 100)}% similar)`);
      }

      // Bonus: If one has invalid macros but everything else matches well, note it
      if (score >= 50) {
        const p1Valid = hasValidMacros(p1);
        const p2Valid = hasValidMacros(p2);

        if (p1Valid && !p2Valid) {
          reasons.push('p1 has valid macros, p2 has invalid macros');
        } else if (!p1Valid && p2Valid) {
          reasons.push('p2 has valid macros, p1 has invalid macros');
        }
      }
    } catch (err) {
      // Non-fatal, skip macro matching
    }

    return { score, reasons };
  };

  // Check if macros are valid
  const hasValidMacros = (product: Product): boolean => {
    const cals = product.calories || 0;
    const prot = product.protein || 0;
    const carbs = product.carbs || 0;
    const fat = product.fat || 0;

    // Check if macros are reasonable (not impossibly high)
    if (cals > 900 || prot > 100 || carbs > 100 || fat > 100) {
      return false;
    }

    // Check if calorie calculation is roughly correct (protein*4 + carbs*4 + fat*9)
    const calculatedCals = (prot * 4) + (carbs * 4) + (fat * 9);
    const diff = Math.abs(cals - calculatedCals);
    const tolerance = calculatedCals * 0.2; // 20% tolerance

    return diff <= tolerance;
  };

  // Score product quality (0-100)
  const scoreProduct = (product: Product): number => {
    try {
      if (!product) return 0;

      let score = 0;

      // UK content check (0-30 points)
      try {
        const ukAnalysis = filterUKProducts([{
      id: product.objectID,
      objectID: product.objectID,
      name: product.name || product.foodName || '',
      brandName: product.brandName || product.brand || null,
      ingredients: product.ingredients || null,
      barcode: typeof product.barcode === 'string' ? product.barcode : product.barcode?.[0] || null,
      currentImageUrl: product.imageUrl || null,
      sourceIndex: product.sourceIndex,
      selected: false,
      searchResults: [],
      selectedImageUrl: null,
      analysis: null,
      status: 'pending',
      analysisProgress: 0,
    }], 0);

        const ukScore = ukAnalysis.ukProducts.length > 0 ? 30 : 0;
        score += ukScore;
      } catch {
        // UK analysis failed, skip this score component
      }

      // Valid macros (0-20 points) - CRITICAL
      try {
        if (hasValidMacros(product)) {
          score += 20;
        }
      } catch {
        // Skip macro validation
      }

      // Completeness (0-20 points)
      try {
        const fields = [
          product.ingredients,
          product.imageUrl,
          product.calories,
          product.protein,
          product.carbs,
          product.fat,
          product.fiber,
          product.sugar,
          product.sodium,
          product.servingSize,
        ];
        const filledFields = fields.filter(f => f !== null && f !== undefined && f !== '').length;
        score += (filledFields / fields.length) * 20;
      } catch {
        // Skip completeness scoring
      }

      // Has barcode (10 points)
      try {
        if (product.barcode && (Array.isArray(product.barcode) ? product.barcode.length > 0 : product.barcode.length > 0)) {
          score += 10;
        }
      } catch {
        // Skip barcode check
      }

      // Has image (10 points)
      try {
        if (product.imageUrl && typeof product.imageUrl === 'string' && product.imageUrl.trim().length > 0) {
          score += 10;
        }
      } catch {
        // Skip image check
      }

      // Index priority (10 points)
      try {
        const indexPriority: Record<string, number> = {
          'verified_foods': 10,
          'uk_foods_cleaned': 9,
          'tesco_products': 8,
          'manual_foods': 7,
          'ai_enhanced': 6,
          'foods': 5,
          'user_added': 4,
          'ai_manually_added': 3,
          'fast_foods_database': 2,
          'generic_database': 1,
        };
        score += (indexPriority[product.sourceIndex] || 0);
      } catch {
        // Skip index priority
      }

      return Math.round(score);
    } catch {
      return 0; // Complete failure, return 0 score
    }
  };

  // Step 1: Pull all data - ONE INDEX AT A TIME to avoid 10MB limit
  const pullAllData = useCallback(async () => {
    if (singleIndexMode && !selectedSingleIndex) {
      addLog('❌ No index selected');
      return;
    }
    if (!singleIndexMode && selectedIndices.size === 0) {
      addLog('❌ No indices selected');
      return;
    }

    setIsPulling(true);
    setProgress(0);
    setAllProducts([]);
    setDuplicateGroups([]);

    addLog('📥 Starting data pull (one index at a time)...');
    if (testMode) {
      addLog('🧪 TEST MODE ENABLED: Limited to 1000 products per index');
    } else {
      addLog('📊 FULL SCAN MODE: Pulling ALL products from selected indices');
    }

    const indicesToScan = singleIndexMode ? [selectedSingleIndex] : Array.from(selectedIndices);
    const allFetchedProducts: Product[] = [];
    const allStats: Record<string, { count: number; error?: string }> = {};

    try {
      // Call Cloud Function with pagination to handle large indices
      const PAGE_SIZE = 5000; // Request 5k products at a time

      for (let i = 0; i < indicesToScan.length; i++) {
        const indexName = indicesToScan[i];
        addLog(`📦 Pulling ${indexName}...`);

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
              limit: testMode ? 1000 : undefined, // No limit when testMode is false
            }),
          });

          if (!response.ok) {
            addLog(`❌ ${indexName}: HTTP ${response.status}`);
            allStats[indexName] = { count: totalForIndex, error: `HTTP ${response.status}` };
            break;
          }

          const result = await response.json();

          if (result.success && result.products) {
            const products = result.products || [];
            const pagination = result.pagination || {};

            // Debug logging
            console.log(`[${indexName}] Page ${iterations}: Got ${products.length} products, hasMore=${pagination.hasMore}, total=${pagination.total}`);

            // Safety: If we got no products, stop pagination even if hasMore is true
            if (products.length === 0) {
              addLog(`  ✓ ${indexName}: Reached end of index (0 products returned)`);
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

            // Update progress in real-time (update UI every page)
            const progressPct = Math.floor(((i + (indexProducts.length / Math.max(totalForIndex, 1))) / indicesToScan.length) * 100);
            setProgress(progressPct);

            // Show progress for EVERY page to confirm it's working
            const pct = totalForIndex > 0 ? Math.round((indexProducts.length / totalForIndex) * 100) : 0;
            addLog(`  → Page ${iterations}: ${indexProducts.length.toLocaleString()} / ${totalForIndex.toLocaleString()} (${pct}%) - hasMore=${pagination.hasMore}`);

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
            allStats[indexName] = { count: totalForIndex, error: result.error || 'Failed' };
            break;
          }
        }

        // Warn if we hit the safety limit
        if (iterations >= MAX_ITERATIONS) {
          addLog(`⚠️ ${indexName}: Hit safety limit (${MAX_ITERATIONS} iterations), stopping pagination`);
        }

        // Add all products from this index
        if (indexProducts.length > 0) {
          allFetchedProducts.push(...indexProducts);
          allStats[indexName] = { count: indexProducts.length };
          addLog(`✅ ${indexName}: ${indexProducts.length.toLocaleString()} products`);
        }

        // Update progress
        setProgress(Math.floor(((i + 1) / indicesToScan.length) * 100));
      }

      addLog(`📊 Total: ${allFetchedProducts.length.toLocaleString()} products`);
      setIndexStats(allStats);
      setAllProducts(allFetchedProducts);
      setStats(prev => ({ ...prev, totalScanned: allFetchedProducts.length }));
      addLog('✅ Data pull complete! Ready to scan for duplicates.');

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      addLog(`❌ Error: ${errorMsg}`);
    } finally {
      setIsPulling(false);
    }
  }, [selectedIndices, testMode, singleIndexMode, selectedSingleIndex, addLog]);

  // Step 2: Scan for duplicates (on already-pulled data)
  const scanForDuplicates = useCallback(async () => {
    if (allProducts.length === 0) {
      addLog('❌ No data to scan. Pull data first.');
      return;
    }

    setIsScanning(true);
    setProgress(0);
    addLog('🔍 Scanning for duplicates...');
    addLog(`📊 Analyzing ${allProducts.length.toLocaleString()} products`);

    try {
      setProgress(10);

      // In single-index mode, skip UK filtering - just scan for duplicates within the index
      const productsToScan = singleIndexMode ? allProducts : (() => {
        // Filter out foreign products (>5% US spelling in ingredients)
        addLog('🇬🇧 Filtering out non-UK products (US spelling, foreign brands, foreign characters)...');
        const ukFilterResult = filterUKProducts(
          allProducts.map(p => ({
            id: p.objectID,
            objectID: p.objectID,
            name: p.name || p.foodName || '',
            brandName: p.brandName || p.brand || null,
            ingredients: p.ingredients || null,
            barcode: typeof p.barcode === 'string' ? p.barcode : p.barcode?.[0] || null,
            currentImageUrl: p.imageUrl || null,
            sourceIndex: p.sourceIndex,
            selected: false,
            searchResults: [],
            selectedImageUrl: null,
            analysis: null,
            status: 'pending',
            analysisProgress: 0,
          })),
          40 // Min 40% UK confidence
        );

        const ukProducts = allProducts.filter(p =>
          ukFilterResult.ukProducts.some(uk => uk.objectID === p.objectID)
        );

        addLog(`✅ Kept ${ukProducts.length} UK products, filtered ${allProducts.length - ukProducts.length} foreign products`);
        return ukProducts;
      })();

      setProgress(70);

      // OPTIMIZED: Use hash-based bucketing to avoid O(n²) comparisons
      addLog('🔍 OPTIMIZED duplicate detection (hash-based bucketing)...');
      addLog('  → Building barcode and name indices...');

      const processedIds = new Set<string>();
      const duplicates: DuplicateGroup[] = [];
      const startTime = Date.now();

      // Step 1: Build indices (O(n) - fast!)
      const barcodeIndex = new Map<string, Product[]>();
      const nameIndex = new Map<string, Product[]>();

      for (const product of productsToScan) {
        // Index by barcode
        const barcodes = typeof product.barcode === 'string'
          ? [product.barcode]
          : Array.isArray(product.barcode) ? product.barcode : [];

        for (const barcode of barcodes) {
          if (barcode && typeof barcode === 'string') {
            const bc = barcode.trim();
            if (!barcodeIndex.has(bc)) barcodeIndex.set(bc, []);
            barcodeIndex.get(bc)!.push(product);
          }
        }

        // Index by normalized name (for fuzzy matching)
        const name = normalizeText(product.name || product.foodName || '');
        if (name) {
          const nameKey = name.substring(0, 15); // First 15 chars as key
          if (!nameIndex.has(nameKey)) nameIndex.set(nameKey, []);
          nameIndex.get(nameKey)!.push(product);
        }
      }

      addLog(`  ✓ Barcode index: ${barcodeIndex.size.toLocaleString()} unique codes`);
      addLog(`  ✓ Name index: ${nameIndex.size.toLocaleString()} buckets`);
      addLog('  → Finding duplicates (compares only similar products)...');

      setProgress(75);

      // Step 2: Find duplicates within buckets (much faster!)
      const processedPairs = new Set<string>();
      let bucketsProcessed = 0;
      const totalBuckets = barcodeIndex.size + nameIndex.size;

      // Process barcode matches (exact duplicates - highest priority)
      for (const [barcode, products] of barcodeIndex) {
        if (products.length > 1) {
          const validProducts = products.filter(p => p && p.objectID && !processedIds.has(p.objectID));

          if (validProducts.length > 1) {
            for (const p of validProducts) processedIds.add(p.objectID);

            const scoredProducts = validProducts.map(p => ({ product: p, score: scoreProduct(p) }));
            scoredProducts.sort((a, b) => b.score - a.score);

            duplicates.push({
              key: `barcode-${barcode}`,
              products: validProducts,
              bestProduct: scoredProducts[0].product,
              allBarcodes: [barcode],
              score: scoredProducts[0].score,
            });
          }
        }

        bucketsProcessed++;
        if (bucketsProcessed % 500 === 0) {
          const pct = 75 + Math.round((bucketsProcessed / totalBuckets) * 20);
          setProgress(pct);
          const elapsed = (Date.now() - startTime) / 1000;
          const rate = Math.round(bucketsProcessed / elapsed);
          addLog(`  → ${bucketsProcessed.toLocaleString()} / ${totalBuckets.toLocaleString()} buckets (${rate}/sec, ${duplicates.length} groups)`);
          await new Promise(resolve => setTimeout(resolve, 0));
        }
      }

      // Process name matches (fuzzy duplicates)
      for (const [nameKey, products] of nameIndex) {
        if (products.length > 1) {
          for (let i = 0; i < products.length; i++) {
            const p1 = products[i];
            if (!p1 || !p1.objectID || processedIds.has(p1.objectID)) continue;

            const group: Product[] = [p1];
            const allBarcodes: string[] = [];

            const bc1 = typeof p1.barcode === 'string' ? [p1.barcode] : Array.isArray(p1.barcode) ? p1.barcode : [];
            allBarcodes.push(...bc1.filter(b => b && typeof b === 'string').map(b => b.trim()));

            for (let j = i + 1; j < products.length; j++) {
              const p2 = products[j];
              if (!p2 || !p2.objectID || processedIds.has(p2.objectID)) continue;

              const pairKey = [p1.objectID, p2.objectID].sort().join('|');
              if (processedPairs.has(pairKey)) continue;
              processedPairs.add(pairKey);

              const similarity = calculateSimilarity(p1, p2);
              if (similarity.score >= 80) {
                group.push(p2);
                processedIds.add(p2.objectID);

                const bc2 = typeof p2.barcode === 'string' ? [p2.barcode] : Array.isArray(p2.barcode) ? p2.barcode : [];
                bc2.filter(b => b && typeof b === 'string').map(b => b.trim()).forEach(bc => {
                  if (!allBarcodes.includes(bc)) allBarcodes.push(bc);
                });
              }
            }

            if (group.length > 1) {
              processedIds.add(p1.objectID);
              const scoredProducts = group.map(p => ({ product: p, score: scoreProduct(p) }));
              scoredProducts.sort((a, b) => b.score - a.score);

              duplicates.push({
                key: `name-${nameKey}-${i}`,
                products: group,
                bestProduct: scoredProducts[0].product,
                allBarcodes: [...new Set(allBarcodes)],
                score: scoredProducts[0].score,
              });
            }
          }
        }

        bucketsProcessed++;
        if (bucketsProcessed % 500 === 0) {
          const pct = 75 + Math.round((bucketsProcessed / totalBuckets) * 20);
          setProgress(pct);
          const elapsed = (Date.now() - startTime) / 1000;
          const rate = Math.round(bucketsProcessed / elapsed);
          addLog(`  → ${bucketsProcessed.toLocaleString()} / ${totalBuckets.toLocaleString()} buckets (${rate}/sec, ${duplicates.length} groups)`);
          await new Promise(resolve => setTimeout(resolve, 0));
        }
      }

      const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);
      addLog(`✅ OPTIMIZED scan: ${totalTime}s (vs. 16+ hours with old O(n²) algorithm!)`)

      // Sort by number of duplicates (most duplicates first)
      duplicates.sort((a, b) => b.products.length - a.products.length);

      addLog(`✅ Found ${duplicates.length} duplicate groups`);
      const totalMerges = duplicates.reduce((sum, g) => sum + g.products.length, 0);
      addLog(`📦 ${totalMerges} products will be merged into ${duplicates.length} master products`);

      setDuplicateGroups(duplicates);
      setStats({
        totalScanned: allProducts.length,
        duplicateGroups: duplicates.length,
        productsToMerge: totalMerges,
        filteredForeign: singleIndexMode ? 0 : (allProducts.length - productsToScan.length),
        finalMasterCount: productsToScan.length - totalMerges + duplicates.length,
        processing: false,
      });
      setProgress(100);
      addLog('✅ Scan complete!');

    } catch (error) {
      addLog(`❌ Error during scan: ${error}`);
    } finally {
      setIsScanning(false);
    }
  }, [allProducts, singleIndexMode, addLog]);

  // Merge all duplicates and update the source index (single-index mode)
  const mergeAllDuplicates = useCallback(async () => {
    if (!singleIndexMode || !selectedSingleIndex) {
      addLog('❌ This function only works in single-index mode');
      return;
    }

    if (duplicateGroups.length === 0) {
      addLog('❌ No duplicates to merge. Scan first.');
      return;
    }

    setIsMerging(true);
    setProgress(0);
    addLog('🔄 Merging all duplicates and updating database...');

    try {
      const cleanedProducts: any[] = [];
      const processedIds = new Set<string>();
      const idsToDelete: string[] = [];

      // Step 1: Create merged products from duplicate groups
      addLog(`📋 Processing ${duplicateGroups.length} duplicate groups...`);
      for (let i = 0; i < duplicateGroups.length; i++) {
        const group = duplicateGroups[i];
        const best = group.bestProduct!;

        // Mark all products in this group as processed
        group.products.forEach(p => {
          processedIds.add(p.objectID);
          // Mark duplicates for deletion (except the best one)
          if (p.objectID !== best.objectID) {
            idsToDelete.push(p.objectID);
          }
        });

        // Create merged product with all barcodes
        const mergedProduct = {
          ...best,
          objectID: best.objectID,
          barcodes: group.allBarcodes, // Array of all barcodes
          barcode: group.allBarcodes[0], // Primary barcode
          mergedFrom: group.products
            .filter(p => p.objectID !== best.objectID)
            .map(p => ({
              objectID: p.objectID,
              sourceIndex: p.sourceIndex,
            })),
          isMerged: true,
          mergedAt: new Date().toISOString(),
          qualityScore: group.score,
        };

        cleanedProducts.push(mergedProduct);
        setProgress(Math.round((i / duplicateGroups.length) * 30)); // 0-30%
      }

      addLog(`✅ Created ${cleanedProducts.length} merged products`);
      addLog(`🗑️ Marking ${idsToDelete.length} duplicates for deletion`);

      // Step 2: Add products that weren't duplicates
      addLog(`📋 Adding non-duplicate products...`);
      let addedCount = 0;
      for (const product of allProducts) {
        if (!processedIds.has(product.objectID)) {
          cleanedProducts.push({
            ...product,
            objectID: product.objectID,
            barcodes: product.barcode ? (Array.isArray(product.barcode) ? product.barcode : [product.barcode]) : [],
            barcode: Array.isArray(product.barcode) ? product.barcode[0] : product.barcode,
            isMerged: false,
          });
          addedCount++;
        }
      }

      addLog(`✅ Added ${addedCount} non-duplicate products`);
      setProgress(50);

      // Step 3: Update Algolia index
      addLog(`📤 Updating ${selectedSingleIndex} index...`);

      // Delete duplicates first
      if (idsToDelete.length > 0) {
        const deleteBatchSize = 100;
        const deleteBatches = Math.ceil(idsToDelete.length / deleteBatchSize);

        for (let i = 0; i < deleteBatches; i++) {
          const start = i * deleteBatchSize;
          const end = Math.min((i + 1) * deleteBatchSize, idsToDelete.length);
          const batch = idsToDelete.slice(start, end);

          const response = await fetch(`${FUNCTIONS_BASE}/deleteFromIndex`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              indexName: selectedSingleIndex,
              objectIDs: batch
            }),
          });

          if (!response.ok) {
            addLog(`⚠️ Failed to delete batch ${i + 1}/${deleteBatches}`);
          } else {
            addLog(`  → Deleted batch ${i + 1}/${deleteBatches}`);
          }

          setProgress(50 + Math.round((i / deleteBatches) * 20)); // 50-70%
        }
      }

      // Upload cleaned/merged products
      const uploadBatchSize = 100;
      const uploadBatches = Math.ceil(cleanedProducts.length / uploadBatchSize);

      for (let i = 0; i < uploadBatches; i++) {
        const start = i * uploadBatchSize;
        const end = Math.min((i + 1) * uploadBatchSize, cleanedProducts.length);
        const batch = cleanedProducts.slice(start, end);

        const response = await fetch(`${FUNCTIONS_BASE}/updateAlgoliaIndex`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            indexName: selectedSingleIndex,
            products: batch
          }),
        });

        if (!response.ok) {
          addLog(`⚠️ Failed to upload batch ${i + 1}/${uploadBatches}`);
        } else {
          addLog(`  → Uploaded batch ${i + 1}/${uploadBatches}`);
        }

        setProgress(70 + Math.round((i / uploadBatches) * 30)); // 70-100%
      }

      setProgress(100);
      addLog(`✅ Successfully merged duplicates and updated ${selectedSingleIndex}!`);
      addLog(`📊 Final count: ${cleanedProducts.length.toLocaleString()} products (removed ${idsToDelete.length} duplicates)`);

      // Clear duplicate groups since they're merged
      setDuplicateGroups([]);

    } catch (error) {
      addLog(`❌ Error merging duplicates: ${error}`);
    } finally {
      setIsMerging(false);
    }
  }, [duplicateGroups, allProducts, singleIndexMode, selectedSingleIndex, addLog]);

  // Build master database
  const buildMasterDatabase = useCallback(async () => {
    if (allProducts.length === 0) {
      addLog('❌ No products to build from. Pull data first.');
      return;
    }

    setIsBuilding(true);
    setProgress(0);
    addLog('🏗️ Building master database...');

    try {
      const masterProducts: any[] = [];
      const processedIds = new Set<string>();

      // Step 1: Process duplicate groups and merge them
      addLog(`📋 Merging ${duplicateGroups.length} duplicate groups...`);
      for (let i = 0; i < duplicateGroups.length; i++) {
        const group = duplicateGroups[i];
        const best = group.bestProduct!;

        // Mark all products in this group as processed
        group.products.forEach(p => processedIds.add(p.objectID));

        // Create merged product with all barcodes
        const mergedProduct = {
          ...best,
          objectID: best.objectID,
          barcodes: group.allBarcodes, // Array of all barcodes
          barcode: group.allBarcodes[0], // Primary barcode
          mergedFrom: group.products.map(p => ({
            objectID: p.objectID,
            sourceIndex: p.sourceIndex,
          })),
          isMerged: true,
          mergedAt: new Date().toISOString(),
          qualityScore: group.score,
        };

        masterProducts.push(mergedProduct);
        setProgress(Math.round((i / duplicateGroups.length) * 50)); // 0-50%
      }

      addLog(`✅ Created ${masterProducts.length} merged products from duplicate groups`);

      // Step 2: Add all products that were NOT in any duplicate group
      addLog(`📋 Adding non-duplicate products...`);
      const ukProducts = allProducts.filter(p => {
        // Check if this product passed UK filtering
        const ukAnalysis = filterUKProducts([{
          id: p.objectID,
          objectID: p.objectID,
          name: p.name || p.foodName || '',
          brandName: p.brandName || p.brand || null,
          ingredients: p.ingredients || null,
          barcode: typeof p.barcode === 'string' ? p.barcode : p.barcode?.[0] || null,
          currentImageUrl: p.imageUrl || null,
          sourceIndex: p.sourceIndex,
          selected: false,
          searchResults: [],
          selectedImageUrl: null,
          analysis: null,
          status: 'pending',
          analysisProgress: 0,
        }], 40);

        return ukAnalysis.ukProducts.length > 0;
      });

      let addedCount = 0;
      for (let i = 0; i < ukProducts.length; i++) {
        const product = ukProducts[i];

        // Skip if already processed in a duplicate group
        if (processedIds.has(product.objectID)) {
          continue;
        }

        // Add as-is (not a duplicate)
        masterProducts.push({
          ...product,
          objectID: product.objectID,
          barcodes: product.barcode ? (Array.isArray(product.barcode) ? product.barcode : [product.barcode]) : [],
          barcode: Array.isArray(product.barcode) ? product.barcode[0] : product.barcode,
          isMerged: false,
        });

        addedCount++;
        if (addedCount % 5000 === 0) {
          setProgress(50 + Math.round((i / ukProducts.length) * 30)); // 50-80%
        }
      }

      addLog(`✅ Added ${addedCount} non-duplicate products`);
      addLog('📤 Uploading to Firestore...');

      // Upload to Firestore in batches
      const batchSize = 100;
      const batches = Math.ceil(masterProducts.length / batchSize);

      for (let i = 0; i < batches; i++) {
        const start = i * batchSize;
        const end = Math.min((i + 1) * batchSize, masterProducts.length);
        const batch = masterProducts.slice(start, end);

        const response = await fetch(`${FUNCTIONS_BASE}/uploadMasterDatabase`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ products: batch }),
        });

        if (!response.ok) {
          addLog(`⚠️ Failed to upload batch ${i + 1}/${batches}`);
        } else {
          addLog(`  → Uploaded batch ${i + 1}/${batches}`);
        }

        setProgress(Math.round(((i + 1) / batches) * 100));
      }

      setProgress(100);
      addLog(`✅ Master database built and uploaded to Firestore!`);
      addLog(`📊 Total products in master database: ${masterProducts.length.toLocaleString()}`);

    } catch (error) {
      addLog(`❌ Error building master database: ${error}`);
    } finally {
      setIsBuilding(false);
    }
  }, [duplicateGroups, allProducts, addLog]);

  // Filter products based on search query and selected field
  const filteredProducts = React.useMemo(() => {
    if (!searchQuery.trim()) {
      return allProducts;
    }

    const queryLower = searchQuery.toLowerCase().trim();

    return allProducts.filter(product => {
      const name = (product.name || product.foodName || '').toLowerCase();
      const brand = (product.brand || product.brandName || '').toLowerCase();
      const barcode = Array.isArray(product.barcode)
        ? product.barcode.join(' ').toLowerCase()
        : (product.barcode || '').toLowerCase();

      switch (searchField) {
        case 'brand':
          return brand.includes(queryLower);
        case 'name':
          return name.includes(queryLower);
        case 'barcode':
          return barcode.includes(queryLower);
        case 'all':
        default:
          return name.includes(queryLower) || brand.includes(queryLower) || barcode.includes(queryLower);
      }
    });
  }, [allProducts, searchQuery, searchField]);

  return (
    <div className="h-full flex flex-col bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={onBack} className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <div>
              <h1 className="text-xl font-semibold text-gray-900">Master Database Builder</h1>
              <p className="text-sm text-gray-500">
                {singleIndexMode
                  ? 'Single-Index Mode: Pull → Scan → Merge duplicates within one index'
                  : 'Multi-Index Mode: Pull → Scan → Build master database from multiple indices'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="flex items-center gap-2 px-3 py-2 bg-purple-50 text-purple-700 rounded-lg text-sm cursor-pointer hover:bg-purple-100 border border-purple-200">
              <input
                type="checkbox"
                checked={singleIndexMode}
                onChange={() => {
                  setSingleIndexMode(!singleIndexMode);
                  setAllProducts([]);
                  setDuplicateGroups([]);
                  setLogs([]);
                }}
                className="w-4 h-4 text-purple-600 rounded"
              />
              <span className="font-medium">Single-Index Mode</span>
            </label>

            <label className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm cursor-pointer border-2 transition-all ${
              testMode
                ? 'bg-yellow-50 text-yellow-800 border-yellow-300 hover:bg-yellow-100'
                : 'bg-green-50 text-green-800 border-green-300 hover:bg-green-100'
            }`}>
              <input
                type="checkbox"
                checked={testMode}
                onChange={() => setTestMode(!testMode)}
                className="w-4 h-4 text-primary-600 rounded"
              />
              <span className="font-medium">
                {testMode ? '🧪 Test Mode (1k/index)' : '✅ Full Scan (ALL products)'}
              </span>
            </label>

            {allProducts.length > 0 && !isPulling && (
              <>
                <div className="flex gap-2 items-center">
                  <select
                    value={searchField}
                    onChange={(e) => setSearchField(e.target.value as 'all' | 'brand' | 'name' | 'barcode')}
                    className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
                  >
                    <option value="all">All Fields</option>
                    <option value="brand">Brand</option>
                    <option value="name">Name</option>
                    <option value="barcode">Barcode</option>
                  </select>
                  <div className="relative">
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder={`Search by ${searchField === 'all' ? 'any field' : searchField}...`}
                      className="px-3 py-2 pr-10 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-80"
                    />
                    {searchQuery && (
                      <button
                        onClick={() => setSearchQuery('')}
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    )}
                  </div>
                </div>
                <div className="px-3 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium">
                  {searchQuery ? (
                    <>
                      {filteredProducts.length.toLocaleString()} / {allProducts.length.toLocaleString()} products
                    </>
                  ) : (
                    <>{allProducts.length.toLocaleString()} products loaded</>
                  )}
                </div>

                {/* Bulk actions when there are filtered products */}
                {searchQuery && filteredProducts.length > 0 && (
                  <div className="flex gap-2">
                    <button
                      onClick={selectedProductIds.size === filteredProducts.length ? handleDeselectAll : handleSelectAll}
                      className="px-3 py-2 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 rounded-lg text-sm font-medium border border-indigo-200"
                    >
                      {selectedProductIds.size === filteredProducts.length ? 'Deselect All' : `Select All (${filteredProducts.length})`}
                    </button>

                    {selectedProductIds.size > 0 && (
                      <>
                        <div className="px-3 py-2 bg-purple-50 text-purple-700 rounded-lg text-sm font-medium border border-purple-200">
                          {selectedProductIds.size} selected
                        </div>
                        <button
                          onClick={handleDeleteSelected}
                          disabled={isDeleting}
                          className="px-3 py-2 bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 rounded-lg text-sm font-medium flex items-center gap-2"
                        >
                          {isDeleting ? (
                            <>
                              <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                              </svg>
                              Deleting...
                            </>
                          ) : (
                            <>
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                              </svg>
                              Delete Selected
                            </>
                          )}
                        </button>
                      </>
                    )}
                  </div>
                )}
              </>
            )}

            <button
              onClick={pullAllData}
              disabled={isPulling || isScanning || isBuilding || isMerging || (singleIndexMode ? !selectedSingleIndex : selectedIndices.size === 0)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium"
            >
              {isPulling ? (
                <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
              )}
              {singleIndexMode ? 'Pull Index' : 'Pull All Data'}
            </button>

            <button
              onClick={scanForDuplicates}
              disabled={isPulling || isScanning || isBuilding || isMerging || allProducts.length === 0}
              className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 font-medium"
            >
              {isScanning ? (
                <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              )}
              Scan for Duplicates
            </button>

            {singleIndexMode ? (
              <button
                onClick={mergeAllDuplicates}
                disabled={isPulling || isScanning || isBuilding || isMerging || duplicateGroups.length === 0}
                className="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 font-medium"
              >
                {isMerging ? (
                  <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                  </svg>
                )}
                Merge All Duplicates
              </button>
            ) : (
              <button
                onClick={buildMasterDatabase}
                disabled={isPulling || isScanning || isBuilding || isMerging || duplicateGroups.length === 0}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 font-medium"
              >
                {isBuilding ? (
                  <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                  </svg>
                )}
                Build Master Database
              </button>
            )}
          </div>
        </div>

        {/* Progress */}
        {(isPulling || isScanning || isBuilding || isMerging) && (
          <div className="mt-4">
            <div className="flex items-center gap-3">
              <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div className="h-full bg-primary-500 transition-all" style={{ width: `${progress}%` }} />
              </div>
              <span className="text-sm text-gray-500">{progress}%</span>
            </div>
          </div>
        )}
      </div>

      {/* Main content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Configuration & Stats */}
        <div className="flex-1 overflow-auto p-6">
          {/* Index selector */}
          <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              {singleIndexMode ? 'Select Index to Clean' : 'Select Indices to Scan'}
            </h2>

            {singleIndexMode ? (
              <div className="space-y-3">
                <select
                  value={selectedSingleIndex}
                  onChange={(e) => setSelectedSingleIndex(e.target.value)}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-purple-500 focus:outline-none font-medium"
                >
                  <option value="">-- Select an index --</option>
                  {ALGOLIA_INDICES.map(index => (
                    <option key={index} value={index}>
                      {index.replace(/_/g, ' ')}
                    </option>
                  ))}
                </select>
                {selectedSingleIndex && (
                  <div className="p-3 bg-purple-50 border border-purple-200 rounded-lg text-sm text-purple-700">
                    <strong>Selected:</strong> {selectedSingleIndex.replace(/_/g, ' ')}
                  </div>
                )}
              </div>
            ) : (
              <>
                <div className="grid grid-cols-3 gap-3 mb-4">
                  {ALGOLIA_INDICES.map(index => (
                    <label
                      key={index}
                      className={`flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-all ${
                        selectedIndices.has(index)
                          ? 'border-primary-500 bg-primary-50'
                          : 'border-gray-200 hover:border-gray-300'
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
                      <span className="text-sm font-medium text-gray-700">{index.replace(/_/g, ' ')}</span>
                    </label>
                  ))}
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => setSelectedIndices(new Set(ALGOLIA_INDICES))}
                    className="px-3 py-1.5 text-sm text-primary-700 bg-primary-50 hover:bg-primary-100 rounded-lg"
                  >
                    Select All
                  </button>
                  <button
                    onClick={() => setSelectedIndices(new Set())}
                    className="px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100 rounded-lg"
                  >
                    Clear All
                  </button>
                  <span className="px-3 py-1.5 text-sm text-gray-500">
                    {selectedIndices.size} of {ALGOLIA_INDICES.length} selected
                  </span>
                </div>
              </>
            )}
          </div>

          {/* Index Stats (if available) */}
          {Object.keys(indexStats).length > 0 && (
            <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Index Pull Results</h2>
              <div className="grid grid-cols-2 gap-3">
                {Object.entries(indexStats).map(([indexName, stat]) => (
                  <div
                    key={indexName}
                    className={`rounded-lg p-3 ${
                      stat.error ? 'bg-red-50' : 'bg-green-50'
                    }`}
                  >
                    <div className={`text-xl font-bold ${
                      stat.error ? 'text-red-900' : 'text-green-900'
                    }`}>
                      {stat.error ? '❌' : stat.count.toLocaleString()}
                    </div>
                    <div className={`text-xs ${
                      stat.error ? 'text-red-700' : 'text-green-700'
                    }`}>
                      {indexName.replace(/_/g, ' ')}
                    </div>
                    {stat.error && (
                      <div className="text-xs text-red-600 mt-1 truncate" title={stat.error}>
                        {stat.error}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Stats */}
          <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Statistics</h2>
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-blue-50 rounded-lg p-4">
                <div className="text-3xl font-bold text-blue-900">{stats.totalScanned.toLocaleString()}</div>
                <div className="text-sm text-blue-700">Total Scanned</div>
              </div>
              <div className="bg-red-50 rounded-lg p-4">
                <div className="text-3xl font-bold text-red-900">{stats.filteredForeign.toLocaleString()}</div>
                <div className="text-sm text-red-700">Filtered (Foreign)</div>
              </div>
              <div className="bg-yellow-50 rounded-lg p-4">
                <div className="text-3xl font-bold text-yellow-900">{stats.duplicateGroups.toLocaleString()}</div>
                <div className="text-sm text-yellow-700">Duplicate Groups</div>
              </div>
              <div className="bg-purple-50 rounded-lg p-4">
                <div className="text-3xl font-bold text-purple-900">{stats.productsToMerge.toLocaleString()}</div>
                <div className="text-sm text-purple-700">Products to Merge</div>
              </div>
              <div className="bg-green-50 rounded-lg p-4 col-span-2">
                <div className="text-4xl font-bold text-green-900">{stats.finalMasterCount.toLocaleString()}</div>
                <div className="text-sm text-green-700">Final Master Database Count</div>
              </div>
            </div>
          </div>

          {/* Filtered products list */}
          {searchQuery && filteredProducts.length > 0 && (
            <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Search Results ({filteredProducts.length.toLocaleString()} products)
                <span className="ml-2 text-sm font-normal text-blue-600">
                  {searchField === 'all' ? 'All Fields' : searchField.charAt(0).toUpperCase() + searchField.slice(1)}: "{searchQuery}"
                </span>
              </h2>
              <div className="space-y-3 max-h-96 overflow-auto">
                {filteredProducts.slice(0, 100).map((product, idx) => (
                  <div key={idx} className="border border-gray-200 rounded-lg p-3 hover:bg-gray-50">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-gray-900 truncate">
                          {product.name || product.foodName}
                        </div>
                        <div className="text-sm text-gray-600 truncate">
                          {product.brand || product.brandName || 'No brand'}
                        </div>
                        <div className="flex gap-3 mt-1">
                          <span className="text-xs text-gray-500">
                            Index: {product.sourceIndex}
                          </span>
                          {product.calories && (
                            <span className="text-xs text-gray-500">
                              {product.calories} kcal
                            </span>
                          )}
                        </div>
                        {product.barcode && (
                          <div className="text-xs text-gray-400 mt-1 font-mono">
                            {Array.isArray(product.barcode) ? product.barcode.join(', ') : product.barcode}
                          </div>
                        )}
                      </div>
                      <div className="flex-shrink-0">
                        {product.imageUrl && (
                          <img
                            src={product.imageUrl}
                            alt={product.name || product.foodName}
                            className="w-16 h-16 object-cover rounded"
                            onError={(e) => {
                              (e.target as HTMLImageElement).style.display = 'none';
                            }}
                          />
                        )}
                      </div>
                    </div>
                  </div>
                ))}
                {filteredProducts.length > 100 && (
                  <div className="text-center text-sm text-gray-500 py-3">
                    Showing first 100 of {filteredProducts.length.toLocaleString()} results
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Search results with selection */}
          {searchQuery && filteredProducts.length > 0 && (
            <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Search Results ({filteredProducts.length} products)
              </h2>
              <div className="space-y-2 max-h-96 overflow-auto">
                {filteredProducts.map((product) => (
                  <label
                    key={product.objectID}
                    className={`flex items-start gap-3 p-3 rounded-lg border-2 cursor-pointer transition-all ${
                      selectedProductIds.has(product.objectID)
                        ? 'border-indigo-500 bg-indigo-50'
                        : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={selectedProductIds.has(product.objectID)}
                      onChange={() => toggleProductSelection(product.objectID)}
                      className="w-5 h-5 text-indigo-600 rounded mt-0.5 flex-shrink-0"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-gray-900 truncate">
                        {product.name || product.foodName || 'Unnamed Product'}
                      </div>
                      <div className="text-sm text-gray-500 truncate">
                        {product.brandName || product.brand || 'No brand'}
                      </div>
                      <div className="flex gap-2 mt-1 flex-wrap">
                        <span className="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-xs">
                          {product.sourceIndex}
                        </span>
                        {(typeof product.barcode === 'string' ? [product.barcode] : product.barcode || [])
                          .filter(b => b)
                          .map((barcode, i) => (
                            <span key={i} className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-mono">
                              {barcode}
                            </span>
                          ))}
                      </div>
                    </div>
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Duplicate groups preview */}
          {duplicateGroups.length > 0 && (
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">
                Top Duplicate Groups ({duplicateGroups.length} total)
              </h2>
              <div className="space-y-4 max-h-96 overflow-auto">
                {duplicateGroups.slice(0, 20).map((group, idx) => (
                  <div key={idx} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex-1">
                        <div className="font-medium text-gray-900">
                          {group.bestProduct?.name || group.bestProduct?.foodName}
                        </div>
                        <div className="text-sm text-gray-500">
                          {group.bestProduct?.brandName || group.bestProduct?.brand}
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-medium rounded">
                          {group.products.length} duplicates
                        </span>
                        <span className="px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded">
                          Score: {group.score}
                        </span>
                      </div>
                    </div>
                    <div className="text-xs text-gray-400 space-y-1">
                      <div>Best from: {group.bestProduct?.sourceIndex}</div>
                      <div>All barcodes: {group.allBarcodes.join(', ') || 'None'}</div>
                      <div className="flex gap-2 flex-wrap mt-2">
                        {group.products.map((p, i) => (
                          <span key={i} className="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-xs">
                            {p.sourceIndex}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Processing log */}
        <div className="w-96 border-l border-gray-200 bg-gray-900 flex flex-col">
          <div className="px-4 py-2 border-b border-gray-700 text-gray-400 text-xs font-medium uppercase">
            Processing Log
          </div>
          <div className="flex-1 overflow-auto p-3 font-mono text-xs text-gray-300 space-y-1">
            {logs.length === 0 ? (
              <div className="text-gray-500">No activity yet. Click "Scan & Detect Duplicates" to start.</div>
            ) : (
              logs.map((log, i) => (
                <div key={i} className="break-all">{log}</div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MasterDatabaseBuilderPage;
