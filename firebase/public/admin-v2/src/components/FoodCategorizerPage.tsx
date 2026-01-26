/**
 * Food Categorizer Page
 * AI-powered food categorization with test mode and review UI
 */

import React, { useState, useCallback, useEffect } from 'react';
import {
  categorizeFoods,
  categorizeFoodsSmart,
  FOOD_CATEGORIES,
  AIModel,
  CategorizationResult,
  CategorizationBatchResult,
} from '../services/foodCategorizationService';
import { ALGOLIA_INDICES } from '../types';

// Firebase Functions base URL
const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

interface FoodItem {
  objectID: string;
  name: string;
  brand?: string;
  brandName?: string;
  servingSizeG?: number;
  serving_size_g?: number;
  category?: string;
  foodCategory?: string;
  sourceIndex?: string;
}

type ReviewStatus = 'pending' | 'approved' | 'rejected' | 'edited';

interface ReviewableResult extends CategorizationResult {
  reviewStatus: ReviewStatus;
  editedCategoryId?: string;
  sourceIndex?: string;
}

export const FoodCategorizerPage: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  // API Keys
  const [claudeApiKey, setClaudeApiKey] = useState(localStorage.getItem('claude_api_key') || '');
  const [openaiApiKey, setOpenaiApiKey] = useState(localStorage.getItem('openai_api_key') || '');
  const [selectedModel, setSelectedModel] = useState<AIModel>('claude-sonnet');

  // Data loading
  const [selectedIndices, setSelectedIndices] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState(false);
  const [loadedFoods, setLoadedFoods] = useState<FoodItem[]>([]);
  const [loadingProgress, setLoadingProgress] = useState(0);

  // Categorization
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingProgress, setProcessingProgress] = useState({ current: 0, total: 0 });
  const [results, setResults] = useState<ReviewableResult[]>([]);
  const [batchStats, setBatchStats] = useState<CategorizationBatchResult | null>(null);

  // Test mode
  const [testMode, setTestMode] = useState(true);
  const [testSampleSize, setTestSampleSize] = useState(500);
  const [skipAlreadyCategorized, setSkipAlreadyCategorized] = useState(true);
  const [smartMode, setSmartMode] = useState(true); // Smart mode = minimal prompts, cheaper & often better

  // Review
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [filterReviewStatus, setFilterReviewStatus] = useState<ReviewStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(0);
  const itemsPerPage = 50;

  // Save API keys
  useEffect(() => {
    if (claudeApiKey) localStorage.setItem('claude_api_key', claudeApiKey);
    if (openaiApiKey) localStorage.setItem('openai_api_key', openaiApiKey);
  }, [claudeApiKey, openaiApiKey]);

  // Load foods from selected indices using browseAllIndices cloud function
  const loadFoods = useCallback(async () => {
    if (selectedIndices.size === 0) return;

    setIsLoading(true);
    setLoadingProgress(0);
    const allFoods: FoodItem[] = [];

    try {
      const indices = Array.from(selectedIndices);
      const PAGE_SIZE = 5000; // Request 5k products at a time
      const MAX_ITERATIONS = 2000; // Safety: max 10M products

      for (let i = 0; i < indices.length; i++) {
        const indexName = indices[i];
        console.log(`📦 Loading ${indexName}...`);

        let offset = 0;
        let hasMore = true;
        let indexProducts: FoodItem[] = [];
        let totalForIndex = 0;
        let iterations = 0;

        while (hasMore && iterations < MAX_ITERATIONS) {
          iterations++;

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
            console.error(`❌ ${indexName}: HTTP ${response.status}`);
            break;
          }

          const result = await response.json();

          if (result.success && result.products) {
            const products = result.products || [];
            const pagination = result.pagination || {};

            // Safety: If we got no products, stop pagination
            if (products.length === 0) {
              console.log(`  ✓ ${indexName}: Reached end (0 products returned)`);
              hasMore = false;
              break;
            }

            // Safety: If we got less than PAGE_SIZE, this is likely the last page
            if (products.length < PAGE_SIZE) {
              console.log(`  ✓ ${indexName}: Last page (${products.length} products)`);
              hasMore = false;
            }

            // Convert to FoodItem format
            const foodItems: FoodItem[] = products.map((hit: Record<string, unknown>) => ({
              objectID: hit.objectID as string,
              name: (hit.name || hit.foodName || 'Unknown') as string,
              brand: (hit.brand as string) || undefined,
              brandName: (hit.brandName as string) || undefined,
              servingSizeG: (hit.servingSizeG as number) || undefined,
              serving_size_g: (hit.serving_size_g as number) || undefined,
              category: (hit.category as string) || undefined,
              foodCategory: (hit.foodCategory as string) || undefined,
              sourceIndex: indexName,
            }));

            indexProducts.push(...foodItems);
            totalForIndex = pagination?.total || indexProducts.length;

            // Update progress
            const indexProgress = (i / indices.length) * 100;
            const itemProgress = totalForIndex > 0
              ? ((indexProducts.length / totalForIndex) * 100) / indices.length
              : 0;
            setLoadingProgress(Math.round(indexProgress + itemProgress));

            console.log(`  → ${indexName}: ${indexProducts.length.toLocaleString()} / ${totalForIndex.toLocaleString()}`);

            // Check if there's more data from backend
            if (!pagination.hasMore) {
              hasMore = false;
            } else {
              offset += PAGE_SIZE;
            }

            // Safety: If we've reached the expected total, stop
            if (totalForIndex > 0 && indexProducts.length >= totalForIndex) {
              hasMore = false;
            }
          } else {
            console.error(`❌ ${indexName}: ${result.error || 'Failed'}`);
            break;
          }
        }

        if (iterations >= MAX_ITERATIONS) {
          console.warn(`⚠️ ${indexName}: Hit safety limit`);
        }

        console.log(`✅ ${indexName}: Loaded ${indexProducts.length.toLocaleString()} products`);
        allFoods.push(...indexProducts);

        // Update progress for this index
        setLoadingProgress(Math.round(((i + 1) / indices.length) * 100));
      }

      setLoadedFoods(allFoods);
      setLoadingProgress(100);
      console.log(`✅ Total foods loaded: ${allFoods.length.toLocaleString()}`);
    } catch (error) {
      console.error('Error loading foods:', error);
      alert(`Error loading foods: ${error}`);
    } finally {
      setIsLoading(false);
    }
  }, [selectedIndices]);

  // Get sample for test mode
  const getTestSample = useCallback((foods: FoodItem[], size: number): FoodItem[] => {
    // Get a diverse sample - try to include tricky items
    const trickyKeywords = [
      'milk', 'chocolate', 'milkshake', 'dairy', 'cream',
      'bread', 'muffin', 'crumpet', 'brioche',
      'chicken', 'nugget', 'kiev',
      'fruit', 'juice', 'smoothie',
      'cake', 'biscuit', 'cookie',
    ];

    const trickyItems: FoodItem[] = [];
    const regularItems: FoodItem[] = [];

    foods.forEach(food => {
      const nameLower = food.name.toLowerCase();
      const isTricky = trickyKeywords.some(kw => nameLower.includes(kw));
      if (isTricky && trickyItems.length < size * 0.4) {
        trickyItems.push(food);
      } else {
        regularItems.push(food);
      }
    });

    // Shuffle regular items
    const shuffledRegular = regularItems.sort(() => Math.random() - 0.5);

    // Combine tricky + regular to reach desired size
    const combined = [...trickyItems, ...shuffledRegular].slice(0, size);

    return combined;
  }, []);

  // Run categorization
  const runCategorization = useCallback(async () => {
    const apiKey = selectedModel === 'claude-sonnet' ? claudeApiKey : openaiApiKey;
    if (!apiKey) {
      alert(`Please enter your ${selectedModel === 'claude-sonnet' ? 'Claude' : 'OpenAI'} API key`);
      return;
    }

    if (loadedFoods.length === 0) {
      alert('Please load foods first');
      return;
    }

    setIsProcessing(true);
    setResults([]);
    setBatchStats(null);

    try {
      // Filter out already categorized foods if option is enabled
      let eligibleFoods = loadedFoods;
      if (skipAlreadyCategorized) {
        eligibleFoods = loadedFoods.filter(f => !f.category && !f.foodCategory);
        console.log(`Skipping ${loadedFoods.length - eligibleFoods.length} already categorized foods`);
      }

      if (eligibleFoods.length === 0) {
        alert('No uncategorized foods found. All foods already have categories.');
        setIsProcessing(false);
        return;
      }

      const foodsToProcess = testMode
        ? getTestSample(eligibleFoods, testSampleSize)
        : eligibleFoods;

      setProcessingProgress({ current: 0, total: foodsToProcess.length });

      // Create a map to look up source index by food ID
      const foodSourceMap = new Map(foodsToProcess.map(f => [f.objectID, f.sourceIndex]));

      const foodData = foodsToProcess.map(f => ({
        id: f.objectID,
        name: f.name,
        brand: f.brand || f.brandName || null,
        servingSizeG: f.servingSizeG || f.serving_size_g || null,
      }));

      // Use smart mode (minimal prompts) or verbose mode
      const categorizeFunc = smartMode ? categorizeFoodsSmart : categorizeFoods;
      const result = await categorizeFunc(
        foodData,
        selectedModel,
        apiKey,
        (processed, total) => setProcessingProgress({ current: processed, total })
      );

      // Convert to reviewable results with sourceIndex
      const reviewableResults: ReviewableResult[] = result.results.map(r => ({
        ...r,
        reviewStatus: 'pending' as ReviewStatus,
        sourceIndex: foodSourceMap.get(r.foodId),
      }));

      // Debug: Log the results
      console.log('📊 Categorization complete:', {
        totalResults: reviewableResults.length,
        sampleResults: reviewableResults.slice(0, 5).map(r => ({
          foodName: r.foodName,
          categoryId: r.categoryId,
          categoryName: r.categoryName,
        })),
        uniqueCategories: [...new Set(reviewableResults.map(r => r.categoryId))],
      });

      setResults(reviewableResults);
      setBatchStats(result);
    } catch (error) {
      console.error('Categorization failed:', error);
      alert(`Categorization failed: ${error}`);
    } finally {
      setIsProcessing(false);
    }
  }, [selectedModel, claudeApiKey, openaiApiKey, loadedFoods, testMode, testSampleSize, getTestSample]);

  // Update result review status
  const updateResultStatus = useCallback((foodId: string, status: ReviewStatus, editedCategoryId?: string) => {
    setResults(prev => prev.map(r => {
      if (r.foodId === foodId) {
        return { ...r, reviewStatus: status, editedCategoryId };
      }
      return r;
    }));
  }, []);

  // Bulk approve all visible - using functional update to capture current filteredResults
  const approveAllVisible = useCallback(() => {
    // Get the current filtered food IDs at the time of click
    const currentFilteredIds = new Set(
      results
        .filter(r => {
          if (filterCategory !== 'all' && r.categoryId !== filterCategory) return false;
          if (filterReviewStatus !== 'all' && r.reviewStatus !== filterReviewStatus) return false;
          if (searchQuery) {
            const query = searchQuery.toLowerCase();
            if (!r.foodName.toLowerCase().includes(query) &&
                !(r.brand?.toLowerCase().includes(query))) return false;
          }
          return true;
        })
        .map(r => r.foodId)
    );

    setResults(prev => prev.map(r => {
      if (currentFilteredIds.has(r.foodId) && r.reviewStatus === 'pending') {
        return { ...r, reviewStatus: 'approved' };
      }
      return r;
    }));
  }, [results, filterCategory, filterReviewStatus, searchQuery]);

  // Save state
  const [isSaving, setIsSaving] = useState(false);

  // Save approved/edited categorizations to database
  const saveApprovedToDatabase = useCallback(async () => {
    const toSave = results.filter(r => r.reviewStatus === 'approved' || r.reviewStatus === 'edited');

    if (toSave.length === 0) {
      alert('No approved or edited items to save.');
      return;
    }

    if (!confirm(`Save ${toSave.length} categorizations to the database?\n\nThis will update:\n- Category\n- Serving size (validated or estimated)`)) {
      return;
    }

    setIsSaving(true);

    try {
      // Prepare the data for the cloud function
      const foodsToSave = toSave.map(r => {
        return {
          objectID: r.foodId,
          sourceIndex: r.sourceIndex || 'unknown',
          categoryId: r.editedCategoryId || r.categoryId,
          servingSizeG: r.suggestedServingG, // Uses the tiered system (validated > pack_size > category_default)
          servingValidated: r.servingValidated || false,
          servingSource: r.servingSource || 'category_default',
        };
      });

      // Call the cloud function
      const response = await fetch(`${FUNCTIONS_BASE}/batchSaveFoodCategories`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ foods: foodsToSave }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'Failed to save');
      }

      // Mark saved items as completed (remove from results or show success state)
      // Note: Firestore-backed indices sync to Algolia via triggers (async)
      const firestoreMsg = result.firestoreUpdated > 0
        ? `Firestore: ${result.firestoreUpdated} (→ Algolia syncs automatically)`
        : '';
      const algoliaMsg = result.algoliaUpdated > 0
        ? `Algolia-only: ${result.algoliaUpdated}`
        : '';
      const details = [firestoreMsg, algoliaMsg].filter(Boolean).join('\n');
      alert(`Successfully saved ${result.total} categorizations!\n\n${details}`);

      // Remove saved items from results
      setResults(prev => prev.filter(r => r.reviewStatus !== 'approved' && r.reviewStatus !== 'edited'));

    } catch (error) {
      console.error('Save failed:', error);
      alert(`Save failed: ${error}`);
    } finally {
      setIsSaving(false);
    }
  }, [results]);

  // Filter results
  const filteredResults = results.filter(r => {
    if (filterCategory !== 'all' && r.categoryId !== filterCategory) return false;
    if (filterReviewStatus !== 'all' && r.reviewStatus !== filterReviewStatus) return false;
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      if (!r.foodName.toLowerCase().includes(query) &&
          !(r.brand?.toLowerCase().includes(query))) return false;
    }
    return true;
  });

  // Pagination
  const totalPages = Math.ceil(filteredResults.length / itemsPerPage);
  const paginatedResults = filteredResults.slice(
    currentPage * itemsPerPage,
    (currentPage + 1) * itemsPerPage
  );

  // Stats
  const reviewStats = {
    pending: results.filter(r => r.reviewStatus === 'pending').length,
    approved: results.filter(r => r.reviewStatus === 'approved').length,
    rejected: results.filter(r => r.reviewStatus === 'rejected').length,
    edited: results.filter(r => r.reviewStatus === 'edited').length,
  };

  // Category distribution
  const categoryDistribution = FOOD_CATEGORIES.map(cat => ({
    ...cat,
    count: results.filter(r => r.categoryId === cat.id).length,
  })).filter(c => c.count > 0).sort((a, b) => b.count - a.count);

  return (
    <div style={{ padding: '24px', maxWidth: '1600px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <button
            onClick={onBack}
            style={{
              padding: '8px 16px',
              background: '#6b7280',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              marginBottom: '8px',
            }}
          >
            ← Back
          </button>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Food Categorizer</h1>
          <p style={{ margin: '8px 0 0', color: '#6b7280' }}>
            AI-powered food categorization with tiered serving sizes
          </p>
        </div>
      </div>

      {/* Configuration Panel */}
      <div style={{
        background: 'white',
        borderRadius: '12px',
        padding: '20px',
        marginBottom: '24px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      }}>
        <h2 style={{ margin: '0 0 16px', fontSize: '18px' }}>Configuration</h2>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
          {/* Model Selection */}
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>AI Model</label>
            <div style={{ display: 'flex', gap: '12px' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                <input
                  type="radio"
                  checked={selectedModel === 'claude-sonnet'}
                  onChange={() => setSelectedModel('claude-sonnet')}
                />
                Claude 3.5 Sonnet
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                <input
                  type="radio"
                  checked={selectedModel === 'gpt-4o'}
                  onChange={() => setSelectedModel('gpt-4o')}
                />
                GPT-4o
              </label>
            </div>
          </div>

          {/* API Keys */}
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
              {selectedModel === 'claude-sonnet' ? 'Claude API Key' : 'OpenAI API Key'}
            </label>
            {selectedModel === 'claude-sonnet' ? (
              <input
                type="password"
                value={claudeApiKey}
                onChange={(e) => setClaudeApiKey(e.target.value)}
                placeholder="sk-ant-..."
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontSize: '14px',
                }}
              />
            ) : (
              <input
                type="password"
                value={openaiApiKey}
                onChange={(e) => setOpenaiApiKey(e.target.value)}
                placeholder="sk-..."
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontSize: '14px',
                }}
              />
            )}
          </div>

          {/* Test Mode */}
          <div>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={testMode}
                onChange={(e) => setTestMode(e.target.checked)}
              />
              <span style={{ fontWeight: '500' }}>Test Mode</span>
              <span style={{ color: '#6b7280', fontSize: '14px' }}>
                (Process {testSampleSize} foods first)
              </span>
            </label>
            {testMode && (
              <input
                type="number"
                value={testSampleSize}
                onChange={(e) => setTestSampleSize(Math.max(50, Math.min(1000, parseInt(e.target.value) || 500)))}
                min={50}
                max={1000}
                style={{
                  marginTop: '8px',
                  width: '120px',
                  padding: '8px 12px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                }}
              />
            )}
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', marginTop: '12px' }}>
              <input
                type="checkbox"
                checked={skipAlreadyCategorized}
                onChange={(e) => setSkipAlreadyCategorized(e.target.checked)}
              />
              <span style={{ fontWeight: '500' }}>Skip Already Categorized</span>
              <span style={{ color: '#6b7280', fontSize: '14px' }}>
                (Ignore foods with existing category)
              </span>
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', marginTop: '12px' }}>
              <input
                type="checkbox"
                checked={smartMode}
                onChange={(e) => setSmartMode(e.target.checked)}
              />
              <span style={{ fontWeight: '500', color: '#059669' }}>🧠 Smart Mode</span>
              <span style={{ color: '#6b7280', fontSize: '14px' }}>
                (Minimal prompts - ~50% cheaper, lets AI use its knowledge)
              </span>
            </label>
          </div>
        </div>

        {/* Index Selection */}
        <div style={{ marginTop: '20px' }}>
          <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Select Databases</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {ALGOLIA_INDICES.map((indexName) => (
              <label
                key={indexName}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 12px',
                  background: selectedIndices.has(indexName) ? '#dbeafe' : '#f3f4f6',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  border: selectedIndices.has(indexName) ? '1px solid #3b82f6' : '1px solid transparent',
                }}
              >
                <input
                  type="checkbox"
                  checked={selectedIndices.has(indexName)}
                  onChange={(e) => {
                    const newSet = new Set(selectedIndices);
                    if (e.target.checked) {
                      newSet.add(indexName);
                    } else {
                      newSet.delete(indexName);
                    }
                    setSelectedIndices(newSet);
                  }}
                />
                {indexName.replace(/_/g, ' ')}
              </label>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div style={{ display: 'flex', gap: '12px', marginTop: '20px' }}>
          <button
            onClick={loadFoods}
            disabled={isLoading || selectedIndices.size === 0}
            style={{
              padding: '12px 24px',
              background: isLoading ? '#9ca3af' : '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '15px',
              fontWeight: '500',
              cursor: isLoading ? 'not-allowed' : 'pointer',
            }}
          >
            {isLoading ? `Loading... ${loadingProgress}%` : 'Load Foods'}
          </button>

          <button
            onClick={runCategorization}
            disabled={isProcessing || loadedFoods.length === 0}
            style={{
              padding: '12px 24px',
              background: isProcessing ? '#9ca3af' : '#10b981',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '15px',
              fontWeight: '500',
              cursor: isProcessing ? 'not-allowed' : 'pointer',
            }}
          >
            {isProcessing
              ? `Processing... ${processingProgress.current}/${processingProgress.total}`
              : testMode
                ? `Run Test (${testSampleSize} foods)`
                : `Categorize All (${loadedFoods.length} foods)`
            }
          </button>

          {loadedFoods.length > 0 && (
            <span style={{ display: 'flex', alignItems: 'center', color: '#6b7280' }}>
              {loadedFoods.length.toLocaleString()} foods loaded
            </span>
          )}
        </div>
      </div>

      {/* Results Panel */}
      {results.length > 0 && (
        <>
          {/* Stats */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '16px',
            marginBottom: '24px',
          }}>
            <div style={{
              background: 'white',
              borderRadius: '12px',
              padding: '16px',
              boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            }}>
              <div style={{ fontSize: '14px', color: '#6b7280' }}>Total Processed</div>
              <div style={{ fontSize: '28px', fontWeight: 'bold' }}>{results.length}</div>
            </div>
            <div style={{
              background: '#fef3c7',
              borderRadius: '12px',
              padding: '16px',
            }}>
              <div style={{ fontSize: '14px', color: '#92400e' }}>Pending Review</div>
              <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#92400e' }}>{reviewStats.pending}</div>
            </div>
            <div style={{
              background: '#d1fae5',
              borderRadius: '12px',
              padding: '16px',
            }}>
              <div style={{ fontSize: '14px', color: '#065f46' }}>Approved</div>
              <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#065f46' }}>{reviewStats.approved}</div>
            </div>
            <div style={{
              background: '#fee2e2',
              borderRadius: '12px',
              padding: '16px',
            }}>
              <div style={{ fontSize: '14px', color: '#991b1b' }}>Rejected</div>
              <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#991b1b' }}>{reviewStats.rejected}</div>
            </div>
            {batchStats && (
              <div style={{
                background: 'white',
                borderRadius: '12px',
                padding: '16px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
              }}>
                <div style={{ fontSize: '14px', color: '#6b7280' }}>Estimated Cost</div>
                <div style={{ fontSize: '28px', fontWeight: 'bold' }}>
                  ${batchStats.cost.estimatedCost.toFixed(2)}
                </div>
                <div style={{ fontSize: '12px', color: '#9ca3af' }}>
                  {batchStats.cost.inputTokens.toLocaleString()} in / {batchStats.cost.outputTokens.toLocaleString()} out
                </div>
              </div>
            )}
          </div>

          {/* Category Distribution */}
          <div style={{
            background: 'white',
            borderRadius: '12px',
            padding: '20px',
            marginBottom: '24px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          }}>
            <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Category Distribution</h3>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
              {categoryDistribution.slice(0, 20).map(cat => (
                <span
                  key={cat.id}
                  onClick={() => setFilterCategory(filterCategory === cat.id ? 'all' : cat.id)}
                  style={{
                    padding: '6px 12px',
                    background: filterCategory === cat.id ? '#3b82f6' : '#f3f4f6',
                    color: filterCategory === cat.id ? 'white' : '#374151',
                    borderRadius: '16px',
                    fontSize: '13px',
                    cursor: 'pointer',
                  }}
                >
                  {cat.name}: {cat.count}
                </span>
              ))}
            </div>
          </div>

          {/* Filters */}
          <div style={{
            display: 'flex',
            gap: '16px',
            marginBottom: '16px',
            alignItems: 'center',
            flexWrap: 'wrap',
          }}>
            <input
              type="text"
              placeholder="Search foods..."
              value={searchQuery}
              onChange={(e) => { setSearchQuery(e.target.value); setCurrentPage(0); }}
              style={{
                padding: '10px 14px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
                width: '250px',
              }}
            />

            <select
              value={filterReviewStatus}
              onChange={(e) => { setFilterReviewStatus(e.target.value as ReviewStatus | 'all'); setCurrentPage(0); }}
              style={{
                padding: '10px 14px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
              }}
            >
              <option value="all">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
              <option value="edited">Edited</option>
            </select>

            <select
              value={filterCategory}
              onChange={(e) => { setFilterCategory(e.target.value); setCurrentPage(0); }}
              style={{
                padding: '10px 14px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
              }}
            >
              <option value="all">All Categories</option>
              {FOOD_CATEGORIES.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>

            <button
              onClick={approveAllVisible}
              style={{
                padding: '10px 16px',
                background: '#10b981',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
              }}
            >
              Approve All Visible ({filteredResults.filter(r => r.reviewStatus === 'pending').length})
            </button>

            <button
              onClick={saveApprovedToDatabase}
              disabled={isSaving || (reviewStats.approved + reviewStats.edited) === 0}
              style={{
                padding: '10px 16px',
                background: (reviewStats.approved + reviewStats.edited) > 0 ? '#3b82f6' : '#9ca3af',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: (reviewStats.approved + reviewStats.edited) > 0 ? 'pointer' : 'not-allowed',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              {isSaving ? (
                <>Saving...</>
              ) : (
                <>
                  💾 Save to Database ({reviewStats.approved + reviewStats.edited})
                </>
              )}
            </button>

            <span style={{ color: '#6b7280', marginLeft: 'auto' }}>
              Showing {filteredResults.length} of {results.length}
            </span>
          </div>

          {/* Results Table */}
          <div style={{
            background: 'white',
            borderRadius: '12px',
            overflow: 'hidden',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: '#f9fafb', borderBottom: '1px solid #e5e7eb' }}>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', fontSize: '13px' }}>Food</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', fontSize: '13px' }}>Category</th>
                  <th style={{ padding: '12px 16px', textAlign: 'center', fontWeight: '600', fontSize: '13px' }}>Confidence</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', fontSize: '13px' }}>Serving</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', fontSize: '13px' }}>Reasoning</th>
                  <th style={{ padding: '12px 16px', textAlign: 'center', fontWeight: '600', fontSize: '13px' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {paginatedResults.map((result, idx) => {
                  return (
                    <tr
                      key={result.foodId}
                      style={{
                        borderBottom: '1px solid #e5e7eb',
                        background: result.reviewStatus === 'approved' ? '#f0fdf4' :
                                   result.reviewStatus === 'rejected' ? '#fef2f2' :
                                   result.reviewStatus === 'edited' ? '#fefce8' :
                                   idx % 2 === 0 ? 'white' : '#f9fafb',
                      }}
                    >
                      <td style={{ padding: '12px 16px' }}>
                        <div style={{ fontWeight: '500' }}>{result.foodName}</div>
                        {result.brand && (
                          <div style={{ fontSize: '12px', color: '#6b7280' }}>{result.brand}</div>
                        )}
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <select
                          value={result.editedCategoryId || result.categoryId}
                          onChange={(e) => {
                            if (e.target.value !== result.categoryId) {
                              updateResultStatus(result.foodId, 'edited', e.target.value);
                            }
                          }}
                          style={{
                            padding: '6px 10px',
                            border: '1px solid #d1d5db',
                            borderRadius: '4px',
                            fontSize: '13px',
                            maxWidth: '200px',
                          }}
                        >
                          {FOOD_CATEGORIES.map(cat => (
                            <option key={cat.id} value={cat.id}>{cat.name}</option>
                          ))}
                        </select>
                      </td>
                      <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                        <span style={{
                          display: 'inline-block',
                          padding: '4px 8px',
                          borderRadius: '12px',
                          fontSize: '12px',
                          fontWeight: '500',
                          background: result.confidence >= 90 ? '#d1fae5' :
                                     result.confidence >= 70 ? '#fef3c7' : '#fee2e2',
                          color: result.confidence >= 90 ? '#065f46' :
                                result.confidence >= 70 ? '#92400e' : '#991b1b',
                        }}>
                          {result.confidence}%
                        </span>
                      </td>
                      <td style={{ padding: '12px 16px', fontSize: '13px' }}>
                        <div>
                          {/* T0 = validated DB serving, T1 = pack size fallback, T2 = category default */}
                          {result.servingSource === 'validated' ? (
                            <>
                              <span style={{
                                display: 'inline-block',
                                padding: '2px 6px',
                                borderRadius: '4px',
                                fontSize: '11px',
                                fontWeight: '500',
                                background: '#d1fae5',
                                color: '#065f46',
                                marginRight: '6px',
                              }}>
                                Validated
                              </span>
                              {result.suggestedServingG}g
                            </>
                          ) : result.servingSource === 'pack_size' ? (
                            <>
                              <span style={{
                                display: 'inline-block',
                                padding: '2px 6px',
                                borderRadius: '4px',
                                fontSize: '11px',
                                fontWeight: '500',
                                background: '#dbeafe',
                                color: '#1e40af',
                                marginRight: '4px',
                              }}>
                                Pack Size
                              </span>
                              <span
                                title="Using pack size from product name to prevent over-portioning. The category default was higher than the actual pack size."
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  width: '14px',
                                  height: '14px',
                                  borderRadius: '50%',
                                  background: '#bfdbfe',
                                  color: '#1e40af',
                                  fontSize: '10px',
                                  fontWeight: '600',
                                  cursor: 'help',
                                  marginRight: '6px',
                                }}
                              >
                                i
                              </span>
                              {result.suggestedServingG}g
                            </>
                          ) : (
                            <>
                              <span style={{
                                display: 'inline-block',
                                padding: '2px 6px',
                                borderRadius: '4px',
                                fontSize: '11px',
                                fontWeight: '500',
                                background: '#fef3c7',
                                color: '#92400e',
                                marginRight: '4px',
                              }}>
                                Estimated
                              </span>
                              <span
                                title="We couldn't guarantee the serving size. Check on the label and edit before you add."
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  width: '14px',
                                  height: '14px',
                                  borderRadius: '50%',
                                  background: '#d1d5db',
                                  color: '#4b5563',
                                  fontSize: '10px',
                                  fontWeight: '600',
                                  cursor: 'help',
                                  marginRight: '6px',
                                }}
                              >
                                i
                              </span>
                              {result.suggestedServingG}g
                            </>
                          )}
                        </div>
                        {result.packSizeG && result.servingSource !== 'pack_size' && (
                          <div style={{ fontSize: '11px', color: '#6b7280' }}>
                            Pack: {result.packSizeG}g
                          </div>
                        )}
                        {result.currentServingG && !result.servingValidated && (
                          <div style={{ fontSize: '11px', color: '#9ca3af' }}>
                            DB: {result.currentServingG}g (out of range)
                          </div>
                        )}
                        {!result.currentServingG && (
                          <div style={{ fontSize: '11px', color: '#9ca3af' }}>
                            No DB serving
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '12px 16px', fontSize: '12px', color: '#6b7280', maxWidth: '250px' }}>
                        {result.reasoning}
                      </td>
                      <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                        <div style={{ display: 'flex', gap: '4px', justifyContent: 'center' }}>
                          <button
                            onClick={() => updateResultStatus(result.foodId, 'approved')}
                            title="Approve"
                            style={{
                              padding: '6px 10px',
                              background: result.reviewStatus === 'approved' ? '#10b981' : '#e5e7eb',
                              color: result.reviewStatus === 'approved' ? 'white' : '#374151',
                              border: 'none',
                              borderRadius: '4px',
                              cursor: 'pointer',
                              fontSize: '12px',
                            }}
                          >
                            ✓
                          </button>
                          <button
                            onClick={() => updateResultStatus(result.foodId, 'rejected')}
                            title="Reject"
                            style={{
                              padding: '6px 10px',
                              background: result.reviewStatus === 'rejected' ? '#ef4444' : '#e5e7eb',
                              color: result.reviewStatus === 'rejected' ? 'white' : '#374151',
                              border: 'none',
                              borderRadius: '4px',
                              cursor: 'pointer',
                              fontSize: '12px',
                            }}
                          >
                            ✗
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div style={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              gap: '8px',
              marginTop: '16px',
            }}>
              <button
                onClick={() => setCurrentPage(p => Math.max(0, p - 1))}
                disabled={currentPage === 0}
                style={{
                  padding: '8px 16px',
                  background: currentPage === 0 ? '#e5e7eb' : '#3b82f6',
                  color: currentPage === 0 ? '#9ca3af' : 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: currentPage === 0 ? 'not-allowed' : 'pointer',
                }}
              >
                Previous
              </button>
              <span style={{ color: '#6b7280' }}>
                Page {currentPage + 1} of {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(p => Math.min(totalPages - 1, p + 1))}
                disabled={currentPage >= totalPages - 1}
                style={{
                  padding: '8px 16px',
                  background: currentPage >= totalPages - 1 ? '#e5e7eb' : '#3b82f6',
                  color: currentPage >= totalPages - 1 ? '#9ca3af' : 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: currentPage >= totalPages - 1 ? 'not-allowed' : 'pointer',
                }}
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default FoodCategorizerPage;
