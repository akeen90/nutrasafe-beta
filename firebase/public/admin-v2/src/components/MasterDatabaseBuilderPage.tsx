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
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(new Set(ALGOLIA_INDICES));
  const [isPulling, setIsPulling] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [isBuilding, setIsBuilding] = useState(false);
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

  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [...prev.slice(-100), `${timestamp}: ${message}`]);
    console.log(message);
  };

  // Normalize product name for matching
  const normalizeProductKey = (product: Product): string => {
    const name = (product.name || product.foodName || '').toLowerCase().trim();
    const brand = (product.brandName || product.brand || '').toLowerCase().trim();
    const size = (product.servingSize || '').toLowerCase().replace(/[^0-9]/g, '');
    const unit = (product.servingUnit || '').toLowerCase().substring(0, 2);

    return `${brand}_${name}_${size}${unit}`.replace(/\s+/g, '-');
  };

  // Score product quality (0-100)
  const scoreProduct = (product: Product): number => {
    let score = 0;

    // UK content check (0-40 points)
    const ukAnalysis = filterUKProducts([{
      id: product.objectID,
      objectID: product.objectID,
      name: product.name || product.foodName || '',
      brandName: product.brandName || product.brand || null,
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

    const ukScore = ukAnalysis.ukProducts.length > 0 ? 40 : 0;
    score += ukScore;

    // Completeness (0-30 points)
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
    score += (filledFields / fields.length) * 30;

    // Has barcode (10 points)
    if (product.barcode && (Array.isArray(product.barcode) ? product.barcode.length > 0 : product.barcode.length > 0)) {
      score += 10;
    }

    // Has image (10 points)
    if (product.imageUrl && product.imageUrl.trim().length > 0) {
      score += 10;
    }

    // Index priority (10 points)
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

    return Math.round(score);
  };

  // Step 1: Pull all data from indices
  const pullAllData = useCallback(async () => {
    if (selectedIndices.size === 0) {
      addLog('❌ No indices selected');
      return;
    }

    setIsPulling(true);
    setProgress(0);
    setAllProducts([]);
    setDuplicateGroups([]);
    addLog('📥 Starting data pull from all selected indices...');
    addLog('⚠️ This will pull ALL products from each index (may take several minutes)');

    const indicesToScan = Array.from(selectedIndices);

    try {
      setProgress(10);
      addLog('🔄 Calling Cloud Function to browse all records...');

      // Call Cloud Function to browse all indices
      const response = await fetch(`${FUNCTIONS_BASE}/browseAllIndices`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          indices: indicesToScan,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }

      setProgress(50);
      addLog('📦 Receiving data from Cloud Function...');

      const result = await response.json();

      if (!result.success) {
        throw new Error(result.error || 'Failed to browse indices');
      }

      const pulledProducts = result.products || [];
      addLog(`📊 Total products pulled: ${pulledProducts.length.toLocaleString()}`);

      setAllProducts(pulledProducts);
      setStats(prev => ({
        ...prev,
        totalScanned: pulledProducts.length,
      }));
      setProgress(100);
      addLog('✅ Data pull complete! Ready to scan for duplicates.');

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : JSON.stringify(error);
      addLog(`❌ Error pulling data: ${errorMsg}`);
      console.error('Error pulling data:', error);
    } finally {
      setIsPulling(false);
    }
  }, [selectedIndices]);

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

      // Filter out foreign products (>10% foreign content)
      addLog('🇬🇧 Filtering out products with >10% foreign content...');
      const ukFilterResult = filterUKProducts(
        allProducts.map(p => ({
          id: p.objectID,
          objectID: p.objectID,
          name: p.name || p.foodName || '',
          brandName: p.brandName || p.brand || null,
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
        10 // Max 10% foreign content
      );

      const ukProducts = allProducts.filter(p =>
        ukFilterResult.ukProducts.some(uk => uk.objectID === p.objectID)
      );

      addLog(`✅ Kept ${ukProducts.length} UK products, filtered ${allProducts.length - ukProducts.length} foreign products`);
      setProgress(70);

      // Group duplicates
      addLog('🔍 Detecting duplicates...');
      const groupMap = new Map<string, Product[]>();

      ukProducts.forEach(product => {
        const key = normalizeProductKey(product);
        if (!groupMap.has(key)) {
          groupMap.set(key, []);
        }
        groupMap.get(key)!.push(product);
      });

      // Filter to only groups with duplicates
      const duplicates: DuplicateGroup[] = [];
      groupMap.forEach((products, key) => {
        if (products.length > 1) {
          // Collect all barcodes
          const allBarcodes: string[] = [];
          products.forEach(p => {
            if (p.barcode) {
              if (Array.isArray(p.barcode)) {
                allBarcodes.push(...p.barcode);
              } else {
                allBarcodes.push(p.barcode);
              }
            }
          });

          // Score each product
          const scoredProducts = products.map(p => ({
            product: p,
            score: scoreProduct(p),
          }));

          // Sort by score (highest first)
          scoredProducts.sort((a, b) => b.score - a.score);
          const bestProduct = scoredProducts[0].product;

          duplicates.push({
            key,
            products,
            bestProduct,
            allBarcodes: [...new Set(allBarcodes)], // Remove duplicates
            score: scoredProducts[0].score,
          });
        }
      });

      duplicates.sort((a, b) => b.products.length - a.products.length);

      addLog(`✅ Found ${duplicates.length} duplicate groups`);
      const totalMerges = duplicates.reduce((sum, g) => sum + g.products.length, 0);
      addLog(`📦 ${totalMerges} products will be merged into ${duplicates.length} master products`);

      setDuplicateGroups(duplicates);
      setStats({
        totalScanned: allProducts.length,
        duplicateGroups: duplicates.length,
        productsToMerge: totalMerges,
        filteredForeign: allProducts.length - ukProducts.length,
        finalMasterCount: ukProducts.length - totalMerges + duplicates.length,
        processing: false,
      });
      setProgress(100);
      addLog('✅ Scan complete!');

    } catch (error) {
      addLog(`❌ Error during scan: ${error}`);
    } finally {
      setIsScanning(false);
    }
  }, [allProducts]);

  // Build master database
  const buildMasterDatabase = useCallback(async () => {
    if (duplicateGroups.length === 0) {
      addLog('❌ No duplicate groups to merge. Run scan first.');
      return;
    }

    setIsBuilding(true);
    setProgress(0);
    addLog('🏗️ Building master database...');

    try {
      const masterProducts: any[] = [];

      // Process each duplicate group
      for (let i = 0; i < duplicateGroups.length; i++) {
        const group = duplicateGroups[i];
        const best = group.bestProduct!;

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
        setProgress(Math.round((i / duplicateGroups.length) * 100));
      }

      addLog(`✅ Created ${masterProducts.length} merged products`);
      addLog('📤 Ready to export to master_database index');
      addLog('⚠️ Note: You need to deploy the Algolia upload function to complete this step');

      // TODO: Upload to master_database index via Cloud Function
      // This would require creating a new Cloud Function to accept the master products
      // and upload them to a new 'master_database' Algolia index

      setProgress(100);
      addLog('✅ Master database built successfully!');

    } catch (error) {
      addLog(`❌ Error building master database: ${error}`);
    } finally {
      setIsBuilding(false);
    }
  }, [duplicateGroups]);

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
                Step 1: Pull all data → Step 2: Scan for duplicates → Step 3: Build master database
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {allProducts.length > 0 && !isPulling && (
              <div className="px-3 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium">
                {allProducts.length.toLocaleString()} products loaded
              </div>
            )}

            <button
              onClick={pullAllData}
              disabled={isPulling || isScanning || isBuilding || selectedIndices.size === 0}
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
              Pull All Data
            </button>

            <button
              onClick={scanForDuplicates}
              disabled={isPulling || isScanning || isBuilding || allProducts.length === 0}
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

            <button
              onClick={buildMasterDatabase}
              disabled={isPulling || isScanning || isBuilding || duplicateGroups.length === 0}
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
          </div>
        </div>

        {/* Progress */}
        {(isPulling || isScanning || isBuilding) && (
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
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Select Indices to Scan</h2>
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
          </div>

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
