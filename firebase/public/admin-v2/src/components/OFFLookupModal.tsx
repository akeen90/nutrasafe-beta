/**
 * OpenFoodFacts Lookup Modal
 * Smart UK product detection with data comparison and apply options
 */

import React, { useState, useCallback, useEffect } from 'react';
import {
  lookupByBarcode,
  transformOFFProduct,
  OFFLookupResult,
} from '../services/openFoodFactsService';
import { addFood, updateFood } from '../services/firebaseService';
import { removeImageBackground, blobToDataUrl } from '../services/imageProcessingService';
import { UnifiedFood } from '../types';

// Data quality comparison
interface DataComparison {
  field: string;
  ours: number | string | null;
  theirs: number | string | null;
  difference: number | null; // percentage difference for numbers
  theirsIsBetter: boolean;
  matches: boolean;
}

interface SelectedFoodResult {
  food: UnifiedFood;
  offResult: OFFLookupResult | null;
  offTransformed: ReturnType<typeof transformOFFProduct> | null;
  isLoading: boolean;
  error?: string;
  comparison: DataComparison[];
  hasImage: boolean;
  hasBetterImage: boolean;
  nutritionMatches: boolean;
  nutritionScore: number; // 0-100, how well nutrition matches
  isApplying: boolean;
  applied: 'none' | 'image' | 'nutrition' | 'all';
  // Image cleaning
  isCleaningImage: boolean;
  cleaningProgress: number;
  cleanedImageUrl: string | null;
  cleanedImageBlob: Blob | null;
}

interface OFFLookupModalProps {
  onClose: () => void;
  onImport: () => void;
  selectedFoods?: UnifiedFood[];
}

// Compare two values and determine quality
function compareValues(field: string, ours: number | null, theirs: number | null): DataComparison {
  if (ours === null && theirs === null) {
    return { field, ours, theirs, difference: null, theirsIsBetter: false, matches: true };
  }
  if (ours === null && theirs !== null) {
    return { field, ours, theirs, difference: null, theirsIsBetter: true, matches: false };
  }
  if (ours !== null && theirs === null) {
    return { field, ours, theirs, difference: null, theirsIsBetter: false, matches: false };
  }

  const diff = ours !== 0 ? Math.abs(((theirs! - ours!) / ours!) * 100) : (theirs !== 0 ? 100 : 0);
  const matches = diff < 10; // Within 10% is a match

  return {
    field,
    ours,
    theirs,
    difference: Math.round(diff),
    theirsIsBetter: false, // For nutrition, we can't say one is "better"
    matches,
  };
}

// Calculate overall nutrition match score
function calculateNutritionScore(comparisons: DataComparison[]): number {
  const nutritionFields = ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'sodium'];
  const nutritionComparisons = comparisons.filter(c => nutritionFields.includes(c.field));

  if (nutritionComparisons.length === 0) return 0;

  const matchingCount = nutritionComparisons.filter(c => c.matches).length;
  return Math.round((matchingCount / nutritionComparisons.length) * 100);
}

export const OFFLookupModal: React.FC<OFFLookupModalProps> = ({
  onClose,
  onImport,
  selectedFoods = [],
}) => {
  const [barcode, setBarcode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<OFFLookupResult | null>(null);
  const [isImporting, setIsImporting] = useState(false);

  // For batch lookup of selected foods
  const [selectedResults, setSelectedResults] = useState<SelectedFoodResult[]>([]);
  const [isBatchLookup, setIsBatchLookup] = useState(selectedFoods.length > 0);
  const [batchProgress, setBatchProgress] = useState(0);
  const [expandedRow, setExpandedRow] = useState<string | null>(null);

  // Auto-lookup selected foods on mount
  useEffect(() => {
    if (selectedFoods.length > 0) {
      lookupSelectedFoods();
    }
  }, []);

  const lookupSelectedFoods = async () => {
    const foodsWithBarcodes = selectedFoods.filter(f => f.barcode);

    if (foodsWithBarcodes.length === 0) {
      setSelectedResults(selectedFoods.map(f => ({
        food: f,
        offResult: null,
        offTransformed: null,
        isLoading: false,
        error: 'No barcode',
        comparison: [],
        hasImage: false,
        hasBetterImage: false,
        nutritionMatches: false,
        nutritionScore: 0,
        isApplying: false,
        applied: 'none',
        isCleaningImage: false,
        cleaningProgress: 0,
        cleanedImageUrl: null,
        cleanedImageBlob: null,
      })));
      return;
    }

    // Initialize results
    setSelectedResults(selectedFoods.map(f => ({
      food: f,
      offResult: null,
      offTransformed: null,
      isLoading: !!f.barcode,
      error: f.barcode ? undefined : 'No barcode',
      comparison: [],
      hasImage: false,
      hasBetterImage: false,
      nutritionMatches: false,
      nutritionScore: 0,
      isApplying: false,
      applied: 'none',
      isCleaningImage: false,
      cleaningProgress: 0,
      cleanedImageUrl: null,
      cleanedImageBlob: null,
    })));

    // Lookup each food
    let completed = 0;
    for (const food of selectedFoods) {
      if (!food.barcode) continue;

      try {
        const offResult = await lookupByBarcode(food.barcode, 'UK');

        if (offResult.product) {
          const offTransformed = transformOFFProduct(offResult.product);

          // Build comparison
          const comparison: DataComparison[] = [
            compareValues('calories', food.calories, offTransformed.calories),
            compareValues('protein', food.protein, offTransformed.protein),
            compareValues('carbs', food.carbs, offTransformed.carbs),
            compareValues('fat', food.fat, offTransformed.fat),
            compareValues('fiber', food.fiber, offTransformed.fiber),
            compareValues('sugar', food.sugar, offTransformed.sugar),
            compareValues('sodium', food.sodium, offTransformed.sodium),
          ];

          const nutritionScore = calculateNutritionScore(comparison);
          const hasImage = !!offResult.bestImageUrl;
          const hasBetterImage = hasImage && (!food.imageUrl || food.imageUrl.includes('placeholder'));

          setSelectedResults(prev => prev.map(r =>
            r.food._id === food._id
              ? {
                  ...r,
                  offResult,
                  offTransformed,
                  isLoading: false,
                  comparison,
                  hasImage,
                  hasBetterImage,
                  nutritionMatches: nutritionScore >= 70,
                  nutritionScore,
                }
              : r
          ));
        } else {
          setSelectedResults(prev => prev.map(r =>
            r.food._id === food._id
              ? { ...r, offResult, isLoading: false, error: 'Not found in OFF' }
              : r
          ));
        }
      } catch (error) {
        setSelectedResults(prev => prev.map(r =>
          r.food._id === food._id
            ? { ...r, isLoading: false, error: String(error) }
            : r
        ));
      }

      completed++;
      setBatchProgress(Math.round((completed / foodsWithBarcodes.length) * 100));
    }
  };

  // Apply image only
  const handleApplyImage = async (item: SelectedFoodResult) => {
    if (!item.offResult?.bestImageUrl) return;

    setSelectedResults(prev => prev.map(r =>
      r.food._id === item.food._id ? { ...r, isApplying: true } : r
    ));

    try {
      await updateFood(item.food, { imageUrl: item.offResult.bestImageUrl });
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false, applied: 'image' } : r
      ));
    } catch (error) {
      console.error('Failed to apply image:', error);
      alert(`Failed to apply image: ${error}`);
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false } : r
      ));
    }
  };

  // Apply nutrition data
  const handleApplyNutrition = async (item: SelectedFoodResult) => {
    if (!item.offTransformed) return;

    setSelectedResults(prev => prev.map(r =>
      r.food._id === item.food._id ? { ...r, isApplying: true } : r
    ));

    try {
      await updateFood(item.food, {
        calories: item.offTransformed.calories,
        protein: item.offTransformed.protein,
        carbs: item.offTransformed.carbs,
        fat: item.offTransformed.fat,
        saturatedFat: item.offTransformed.saturatedFat,
        fiber: item.offTransformed.fiber,
        sugar: item.offTransformed.sugar,
        sodium: item.offTransformed.sodium,
        salt: item.offTransformed.salt,
      });
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false, applied: 'nutrition' } : r
      ));
    } catch (error) {
      console.error('Failed to apply nutrition:', error);
      alert(`Failed to apply nutrition: ${error}`);
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false } : r
      ));
    }
  };

  // Apply all (image + nutrition + ingredients)
  const handleApplyAll = async (item: SelectedFoodResult) => {
    if (!item.offTransformed || !item.offResult) return;

    setSelectedResults(prev => prev.map(r =>
      r.food._id === item.food._id ? { ...r, isApplying: true } : r
    ));

    try {
      await updateFood(item.food, {
        imageUrl: item.offResult.bestImageUrl || item.food.imageUrl,
        calories: item.offTransformed.calories,
        protein: item.offTransformed.protein,
        carbs: item.offTransformed.carbs,
        fat: item.offTransformed.fat,
        saturatedFat: item.offTransformed.saturatedFat,
        fiber: item.offTransformed.fiber,
        sugar: item.offTransformed.sugar,
        sodium: item.offTransformed.sodium,
        salt: item.offTransformed.salt,
        ingredientsText: item.offTransformed.ingredientsText || item.food.ingredientsText,
      });
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false, applied: 'all' } : r
      ));
    } catch (error) {
      console.error('Failed to apply all:', error);
      alert(`Failed to apply changes: ${error}`);
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false } : r
      ));
    }
  };

  // Clean image (remove background) - runs in browser, FREE
  const handleCleanImage = async (item: SelectedFoodResult) => {
    const imageUrl = item.offResult?.bestImageUrl || item.food.imageUrl;
    if (!imageUrl) return;

    setSelectedResults(prev => prev.map(r =>
      r.food._id === item.food._id ? { ...r, isCleaningImage: true, cleaningProgress: 0 } : r
    ));

    try {
      const result = await removeImageBackground(imageUrl, (progress) => {
        setSelectedResults(prev => prev.map(r =>
          r.food._id === item.food._id ? { ...r, cleaningProgress: progress } : r
        ));
      });

      if (result.success && result.processedUrl && result.blob) {
        setSelectedResults(prev => prev.map(r =>
          r.food._id === item.food._id ? {
            ...r,
            isCleaningImage: false,
            cleanedImageUrl: result.processedUrl!,
            cleanedImageBlob: result.blob!,
          } : r
        ));
      } else {
        throw new Error(result.error || 'Failed to process image');
      }
    } catch (error) {
      console.error('Failed to clean image:', error);
      alert(`Failed to clean image: ${error}`);
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isCleaningImage: false } : r
      ));
    }
  };

  // Apply cleaned image
  const handleApplyCleanedImage = async (item: SelectedFoodResult) => {
    if (!item.cleanedImageBlob) return;

    setSelectedResults(prev => prev.map(r =>
      r.food._id === item.food._id ? { ...r, isApplying: true } : r
    ));

    try {
      // Convert blob to data URL for storage
      const dataUrl = await blobToDataUrl(item.cleanedImageBlob);

      // For now, we'll store the data URL directly (or you could upload to Firebase Storage)
      // In production, you'd want to upload to Storage and get a proper URL
      await updateFood(item.food, { imageUrl: dataUrl });

      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false, applied: 'image' } : r
      ));
    } catch (error) {
      console.error('Failed to apply cleaned image:', error);
      alert(`Failed to apply cleaned image: ${error}`);
      setSelectedResults(prev => prev.map(r =>
        r.food._id === item.food._id ? { ...r, isApplying: false } : r
      ));
    }
  };

  const handleLookup = useCallback(async () => {
    if (!barcode.trim()) return;

    setIsLoading(true);
    setResult(null);

    try {
      const lookupResult = await lookupByBarcode(barcode.trim(), 'UK');
      setResult(lookupResult);
    } catch (error) {
      console.error('Lookup error:', error);
      setResult({
        product: null,
        isUKProduct: false,
        ukConfidenceScore: 0,
        ukSignals: [],
        bestImageUrl: null,
        imageConfidenceScore: 0,
        isRegionMatch: false,
        error: String(error),
      });
    } finally {
      setIsLoading(false);
    }
  }, [barcode]);

  const handleImport = useCallback(async () => {
    if (!result?.product) return;

    setIsImporting(true);

    try {
      const transformedFood = transformOFFProduct(result.product);

      // Add to verified_foods via Cloud Function
      const addResult = await addFood({
        objectID: `off_${result.product.code}`,
        name: transformedFood.name,
        brandName: transformedFood.brandName,
        barcode: transformedFood.barcode,
        barcodes: [result.product.code],
        ingredients: transformedFood.ingredientsText?.split(/,\s*/) || [],
        ingredientsText: transformedFood.ingredientsText,
        calories: transformedFood.calories,
        protein: transformedFood.protein,
        carbs: transformedFood.carbs,
        fat: transformedFood.fat,
        saturatedFat: transformedFood.saturatedFat,
        fiber: transformedFood.fiber,
        sugar: transformedFood.sugar,
        sodium: transformedFood.sodium,
        salt: transformedFood.salt,
        servingDescription: result.product.serving_size || null,
        servingSizeG: null,
        isPerUnit: false,
        isVerified: false,
        verifiedBy: null,
        verifiedAt: null,
        imageUrl: result.bestImageUrl,
        category: result.product.categories?.split(',')[0]?.trim() || null,
        source: 'OpenFoodFacts',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      if (addResult.success) {
        onImport();
        onClose();
        setBarcode('');
        setResult(null);
      } else {
        alert(`Failed to import: ${addResult.error}`);
      }
    } catch (error) {
      console.error('Import error:', error);
      alert(`Import error: ${error}`);
    } finally {
      setIsImporting(false);
    }
  }, [result, onImport, onClose]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && barcode.trim()) {
      handleLookup();
    }
    if (e.key === 'Escape') {
      onClose();
    }
  }, [barcode, handleLookup, onClose]);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">OpenFoodFacts Lookup</h2>
            <p className="text-sm text-gray-500">
              {isBatchLookup
                ? `Checking ${selectedFoods.length} selected item${selectedFoods.length > 1 ? 's' : ''} for UK products`
                : 'Smart UK product detection'}
            </p>
          </div>
          <div className="flex items-center gap-3">
            {selectedFoods.length > 0 && (
              <button
                onClick={() => setIsBatchLookup(!isBatchLookup)}
                className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                {isBatchLookup ? 'Manual Search' : `Back to Selected (${selectedFoods.length})`}
              </button>
            )}
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        {/* Batch Lookup Mode */}
        {isBatchLookup ? (
          <>
            {/* Progress bar */}
            {batchProgress > 0 && batchProgress < 100 && (
              <div className="px-6 py-2 bg-gray-50 border-b border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="flex-1 bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-primary-600 h-2 rounded-full transition-all"
                      style={{ width: `${batchProgress}%` }}
                    />
                  </div>
                  <span className="text-sm text-gray-500">{batchProgress}%</span>
                </div>
              </div>
            )}

            {/* Selected Foods Results */}
            <div className="flex-1 overflow-y-auto divide-y divide-gray-200">
              {selectedResults.map((item) => (
                <div key={item.food._id} className="p-4">
                  {/* Main row */}
                  <div className="flex items-start gap-4">
                    {/* Images comparison */}
                    <div className="flex gap-2 flex-shrink-0">
                      <div className="text-center">
                        <div className="text-xs text-gray-400 mb-1">Ours</div>
                        {item.food.imageUrl ? (
                          <img src={item.food.imageUrl} alt="" className="w-16 h-16 object-cover rounded border border-gray-200" />
                        ) : (
                          <div className="w-16 h-16 bg-gray-100 rounded border border-gray-200 flex items-center justify-center text-gray-400 text-xs">
                            None
                          </div>
                        )}
                      </div>
                      <div className="text-center">
                        <div className="text-xs text-gray-400 mb-1">OFF</div>
                        {item.offResult?.bestImageUrl ? (
                          <img src={item.offResult.bestImageUrl} alt="" className="w-16 h-16 object-cover rounded border-2 border-green-400" />
                        ) : (
                          <div className="w-16 h-16 bg-gray-100 rounded border border-gray-200 flex items-center justify-center text-gray-400 text-xs">
                            {item.isLoading ? '...' : 'None'}
                          </div>
                        )}
                      </div>
                      {/* Cleaned image preview */}
                      {(item.cleanedImageUrl || item.isCleaningImage) && (
                        <div className="text-center">
                          <div className="text-xs text-orange-500 mb-1 font-medium">Cleaned</div>
                          {item.cleanedImageUrl ? (
                            <img
                              src={item.cleanedImageUrl}
                              alt="Cleaned"
                              className="w-16 h-16 object-contain rounded border-2 border-orange-400 bg-white"
                              style={{ imageRendering: 'auto' }}
                            />
                          ) : (
                            <div className="w-16 h-16 bg-orange-50 rounded border-2 border-orange-200 flex items-center justify-center">
                              <svg className="w-5 h-5 animate-spin text-orange-500" fill="none" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                              </svg>
                            </div>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Food info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <h4 className="font-medium text-gray-900">{item.food.name}</h4>
                          {item.food.brandName && (
                            <p className="text-sm text-gray-500">{item.food.brandName}</p>
                          )}
                          <p className="text-xs text-gray-400 font-mono mt-1">{item.food.barcode || 'No barcode'}</p>
                        </div>

                        {/* Status badges */}
                        <div className="flex flex-col items-end gap-1">
                          {item.isLoading ? (
                            <span className="inline-flex items-center gap-1 px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded-full">
                              <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                              </svg>
                              Searching
                            </span>
                          ) : item.error ? (
                            <span className="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded-full">{item.error}</span>
                          ) : item.offResult?.product ? (
                            <>
                              <span className={`px-2 py-1 text-xs rounded-full ${
                                item.offResult.isUKProduct ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                              }`}>
                                {item.offResult.isUKProduct ? `✓ UK (${item.offResult.ukConfidenceScore}%)` : `⚠ Non-UK (${item.offResult.ukConfidenceScore}%)`}
                              </span>
                              <span className={`px-2 py-1 text-xs rounded-full ${
                                item.nutritionScore >= 70 ? 'bg-green-100 text-green-700' :
                                item.nutritionScore >= 40 ? 'bg-yellow-100 text-yellow-700' :
                                'bg-red-100 text-red-700'
                              }`}>
                                Nutrition: {item.nutritionScore}% match
                              </span>
                              {item.hasBetterImage && (
                                <span className="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded-full">
                                  Better image available
                                </span>
                              )}
                            </>
                          ) : (
                            <span className="px-2 py-1 text-xs bg-gray-100 text-gray-500 rounded-full">Not in OFF</span>
                          )}

                          {item.applied !== 'none' && (
                            <span className="px-2 py-1 text-xs bg-green-500 text-white rounded-full">
                              ✓ Applied {item.applied}
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Nutrition comparison table */}
                      {item.offResult?.product && item.comparison.length > 0 && (
                        <div className="mt-3">
                          <button
                            onClick={() => setExpandedRow(expandedRow === item.food._id ? null : item.food._id)}
                            className="text-xs text-primary-600 hover:underline"
                          >
                            {expandedRow === item.food._id ? 'Hide' : 'Show'} nutrition comparison
                          </button>

                          {expandedRow === item.food._id && (
                            <div className="mt-2 grid grid-cols-7 gap-1 text-xs">
                              <div className="font-medium text-gray-500"></div>
                              {item.comparison.slice(0, 6).map(c => (
                                <div key={c.field} className="font-medium text-gray-500 text-center capitalize">
                                  {c.field.slice(0, 3)}
                                </div>
                              ))}
                              <div className="text-gray-500">Ours</div>
                              {item.comparison.slice(0, 6).map(c => (
                                <div key={`ours-${c.field}`} className="text-center text-gray-700">
                                  {c.ours !== null ? c.ours : '-'}
                                </div>
                              ))}
                              <div className="text-gray-500">OFF</div>
                              {item.comparison.slice(0, 6).map(c => (
                                <div
                                  key={`theirs-${c.field}`}
                                  className={`text-center ${
                                    c.matches ? 'text-green-600' :
                                    c.difference && c.difference > 20 ? 'text-red-600 font-medium' :
                                    'text-yellow-600'
                                  }`}
                                >
                                  {c.theirs !== null ? c.theirs : '-'}
                                </div>
                              ))}
                              <div className="text-gray-400">Diff</div>
                              {item.comparison.slice(0, 6).map(c => (
                                <div
                                  key={`diff-${c.field}`}
                                  className={`text-center text-xs ${
                                    c.matches ? 'text-green-500' :
                                    c.difference && c.difference > 20 ? 'text-red-500' :
                                    'text-yellow-500'
                                  }`}
                                >
                                  {c.difference !== null ? `${c.difference}%` : '-'}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Action buttons */}
                    {item.offResult?.product && item.applied === 'none' && (
                      <div className="flex flex-col gap-2 flex-shrink-0">
                        {item.isApplying ? (
                          <div className="flex items-center justify-center p-4">
                            <svg className="w-5 h-5 animate-spin text-primary-600" fill="none" viewBox="0 0 24 24">
                              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                            </svg>
                          </div>
                        ) : (
                          <>
                            {/* Clean Image Button */}
                            {(item.hasImage || item.food.imageUrl) && !item.cleanedImageUrl && (
                              <button
                                onClick={() => handleCleanImage(item)}
                                disabled={item.isCleaningImage}
                                className="px-3 py-1.5 text-xs bg-orange-50 text-orange-700 rounded hover:bg-orange-100 whitespace-nowrap disabled:opacity-50"
                              >
                                {item.isCleaningImage ? (
                                  <span className="flex items-center gap-1">
                                    <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                    </svg>
                                    {item.cleaningProgress}%
                                  </span>
                                ) : (
                                  'Clean Image'
                                )}
                              </button>
                            )}
                            {/* Apply Cleaned Image */}
                            {item.cleanedImageUrl && (
                              <button
                                onClick={() => handleApplyCleanedImage(item)}
                                className="px-3 py-1.5 text-xs bg-green-100 text-green-700 rounded hover:bg-green-200 whitespace-nowrap font-medium"
                              >
                                Apply Cleaned
                              </button>
                            )}
                            {item.hasImage && !item.cleanedImageUrl && (
                              <button
                                onClick={() => handleApplyImage(item)}
                                className="px-3 py-1.5 text-xs bg-blue-50 text-blue-700 rounded hover:bg-blue-100 whitespace-nowrap"
                              >
                                Apply Original
                              </button>
                            )}
                            <button
                              onClick={() => handleApplyNutrition(item)}
                              className="px-3 py-1.5 text-xs bg-purple-50 text-purple-700 rounded hover:bg-purple-100 whitespace-nowrap"
                            >
                              Apply Nutrition
                            </button>
                            <button
                              onClick={() => handleApplyAll(item)}
                              className="px-3 py-1.5 text-xs bg-green-600 text-white rounded hover:bg-green-700 whitespace-nowrap font-medium"
                            >
                              Apply All
                            </button>
                          </>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Batch Summary Footer */}
            <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 text-sm">
                  <span className="text-gray-500">
                    Found: <span className="font-medium text-green-600">{selectedResults.filter(r => r.offResult?.product).length}</span>
                  </span>
                  <span className="text-gray-500">
                    UK: <span className="font-medium text-green-600">{selectedResults.filter(r => r.offResult?.isUKProduct).length}</span>
                  </span>
                  <span className="text-gray-500">
                    Better Images: <span className="font-medium text-blue-600">{selectedResults.filter(r => r.hasBetterImage).length}</span>
                  </span>
                  <span className="text-gray-500">
                    Applied: <span className="font-medium text-green-600">{selectedResults.filter(r => r.applied !== 'none').length}</span>
                  </span>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      onImport();
                      onClose();
                    }}
                    className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
                  >
                    Done
                  </button>
                </div>
              </div>
            </div>
          </>
        ) : (
          <>
            {/* Manual Search Mode */}
            <div className="px-6 py-4 border-b border-gray-100">
              <div className="flex gap-3">
                <input
                  type="text"
                  value={barcode}
                  onChange={(e) => setBarcode(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Enter barcode (e.g., 5000128000000)"
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  autoFocus={!isBatchLookup}
                />
                <button
                  onClick={handleLookup}
                  disabled={!barcode.trim() || isLoading}
                  className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                >
                  {isLoading ? (
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                  ) : (
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                  )}
                  <span>Search</span>
                </button>
              </div>
            </div>

            {/* Results */}
            <div className="flex-1 overflow-y-auto p-6">
              {result?.error && !result.product && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
                  <p className="font-medium">Error</p>
                  <p className="text-sm">{result.error}</p>
                </div>
              )}

              {result?.product && (
                <div className="space-y-6">
                  {/* Product Info */}
                  <div className="flex gap-6">
                    {/* Image */}
                    <div className="flex-shrink-0">
                      {result.bestImageUrl ? (
                        <img
                          src={result.bestImageUrl}
                          alt={result.product.product_name || 'Product'}
                          className="w-32 h-32 object-cover rounded-lg border border-gray-200"
                        />
                      ) : (
                        <div className="w-32 h-32 bg-gray-100 rounded-lg flex items-center justify-center text-gray-400">
                          <span className="text-sm">No image</span>
                        </div>
                      )}
                      {result.imageConfidenceScore > 0 && (
                        <div className="mt-2 text-xs text-center text-gray-500">
                          Image score: {result.imageConfidenceScore}/10
                          {result.isRegionMatch && (
                            <span className="ml-1 text-green-600">UK</span>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Details */}
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900">
                        {result.product.product_name_en || result.product.product_name || 'Unknown Product'}
                      </h3>
                      {result.product.brands && (
                        <p className="text-gray-600">{result.product.brands}</p>
                      )}
                      <p className="text-sm text-gray-500 mt-1">Barcode: {result.product.code}</p>

                      {/* UK Detection Badge */}
                      <div className="mt-3 flex items-center gap-2">
                        <span
                          className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                            result.isUKProduct
                              ? 'bg-green-100 text-green-800'
                              : 'bg-yellow-100 text-yellow-800'
                          }`}
                        >
                          {result.isUKProduct ? '✓ UK Product' : '⚠ Non-UK Product'}
                        </span>
                        <span className="text-sm text-gray-500">
                          {result.ukConfidenceScore}% confidence
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* UK Detection Signals */}
                  <div className="bg-gray-50 rounded-lg p-4">
                    <h4 className="font-medium text-gray-900 mb-3 flex items-center gap-2">
                      <svg className="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                      </svg>
                      UK Detection Signals
                    </h4>
                    <div className="space-y-2">
                      {result.ukSignals.map((signal, idx) => (
                        <div
                          key={idx}
                          className={`flex items-start gap-3 p-2 rounded ${
                            signal.matched ? 'bg-green-50' : 'bg-white'
                          }`}
                        >
                          <div className={`mt-0.5 ${signal.matched ? 'text-green-600' : 'text-gray-400'}`}>
                            {signal.matched ? (
                              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                              </svg>
                            ) : (
                              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                              </svg>
                            )}
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center justify-between">
                              <span className={`text-sm font-medium ${signal.matched ? 'text-green-800' : 'text-gray-600'}`}>
                                {signal.signal}
                              </span>
                              <span className="text-xs text-gray-400">
                                Weight: {signal.weight}
                              </span>
                            </div>
                            {signal.details && (
                              <p className="text-xs text-gray-500 mt-0.5">{signal.details}</p>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Nutrition */}
                  <div>
                    <h4 className="font-medium text-gray-900 mb-3">Nutrition (per 100g)</h4>
                    <div className="grid grid-cols-4 gap-3">
                      {(() => {
                        const transformed = transformOFFProduct(result.product);
                        return (
                          <>
                            <NutritionCard label="Calories" value={transformed.calories} unit="kcal" />
                            <NutritionCard label="Protein" value={transformed.protein} unit="g" />
                            <NutritionCard label="Carbs" value={transformed.carbs} unit="g" />
                            <NutritionCard label="Fat" value={transformed.fat} unit="g" />
                            <NutritionCard label="Sat. Fat" value={transformed.saturatedFat} unit="g" />
                            <NutritionCard label="Fibre" value={transformed.fiber} unit="g" />
                            <NutritionCard label="Sugar" value={transformed.sugar} unit="g" />
                            <NutritionCard label="Salt" value={transformed.salt} unit="g" />
                          </>
                        );
                      })()}
                    </div>
                  </div>

                  {/* Ingredients */}
                  {result.product.ingredients_text_en || result.product.ingredients_text ? (
                    <div>
                      <h4 className="font-medium text-gray-900 mb-2">Ingredients</h4>
                      <p className="text-sm text-gray-600 bg-gray-50 p-3 rounded-lg">
                        {result.product.ingredients_text_en || result.product.ingredients_text}
                      </p>
                    </div>
                  ) : null}
                </div>
              )}

              {!result && !isLoading && (
                <div className="text-center py-12 text-gray-500">
                  <svg className="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                  </svg>
                  <p>Enter a barcode to search OpenFoodFacts</p>
                  <p className="text-sm mt-1">UK products will be automatically detected</p>
                </div>
              )}
            </div>

            {/* Footer */}
            {result?.product && (
              <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
                <div className="text-sm text-gray-500">
                  {!result.isUKProduct && (
                    <span className="text-yellow-600">
                      This may not be a UK product. Import with caution.
                    </span>
                  )}
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={onClose}
                    className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleImport}
                    disabled={isImporting}
                    className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 flex items-center gap-2"
                  >
                    {isImporting ? (
                      <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                      </svg>
                    ) : (
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                      </svg>
                    )}
                    <span>Import to Database</span>
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

// Nutrition card component
const NutritionCard: React.FC<{
  label: string;
  value: number | null;
  unit: string;
}> = ({ label, value, unit }) => (
  <div className="bg-white border border-gray-200 rounded-lg p-3 text-center">
    <p className="text-xs text-gray-500">{label}</p>
    <p className="text-lg font-semibold text-gray-900">
      {value !== null ? value.toFixed(1) : '-'}
    </p>
    <p className="text-xs text-gray-400">{unit}</p>
  </div>
);

export default OFFLookupModal;
