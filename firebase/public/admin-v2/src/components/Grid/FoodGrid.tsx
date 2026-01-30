/**
 * Food Grid Component
 * AG Grid implementation with Excel-like editing
 */

import React, { useMemo, useCallback, useRef, useEffect, useState } from 'react';
import { AgGridReact } from 'ag-grid-react';
import {
  ColDef,
  GridApi,
  GridReadyEvent,
  CellValueChangedEvent,
  RowSelectedEvent,
  ColumnMovedEvent,
  ICellRendererParams,
  RowClassRules,
  RowDoubleClickedEvent,
} from 'ag-grid-community';
import { useGridStore } from '../../store';
import { UnifiedFood, AlgoliaIndexName, ALGOLIA_INDICES } from '../../types';
import { FoodDetailModal } from '../FoodDetailModal';

// Cloud Function for saving
const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

// Image Preview Modal Component
interface ImagePreviewModalProps {
  food: UnifiedFood;
  onClose: () => void;
  onDelete: () => void;
  onSaveImage: (imageUrl: string) => void;
  isDeleting: boolean;
  isSaving: boolean;
}

const ImagePreviewModal: React.FC<ImagePreviewModalProps> = ({ food, onClose, onDelete, onSaveImage, isDeleting, isSaving }) => {
  const [newImageUrl, setNewImageUrl] = useState(food.imageUrl || '');
  const [previewUrl, setPreviewUrl] = useState(food.imageUrl || '');
  const hasChanges = newImageUrl !== (food.imageUrl || '');

  const handlePreview = () => {
    setPreviewUrl(newImageUrl);
  };

  const handleSave = () => {
    if (newImageUrl.trim()) {
      onSaveImage(newImageUrl.trim());
    }
  };

  return (
    <div
      className="fixed inset-0 bg-black/60 flex items-center justify-center z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-lg shadow-2xl max-w-2xl w-full mx-4 overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">{food.name}</h3>
            {food.brandName && (
              <p className="text-sm text-gray-500">{food.brandName}</p>
            )}
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 p-1"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Image */}
        <div className="p-6 bg-gray-50 flex items-center justify-center min-h-[300px]">
          {previewUrl ? (
            <img
              src={previewUrl}
              alt={food.name}
              className="max-h-[400px] max-w-full object-contain rounded-lg shadow"
              onError={(e) => {
                (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"%3E%3Crect fill="%23f3f4f6" width="200" height="200"/%3E%3Ctext fill="%239ca3af" x="50%25" y="50%25" text-anchor="middle" dy=".3em" font-size="14"%3EImage failed to load%3C/text%3E%3C/svg%3E';
              }}
            />
          ) : (
            <div className="text-gray-400 text-center">
              <svg className="w-16 h-16 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <p>No image</p>
            </div>
          )}
        </div>

        {/* Image URL Input */}
        <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
          <label className="block text-sm font-medium text-gray-700 mb-2">Image URL</label>
          <div className="flex gap-2">
            <input
              type="url"
              value={newImageUrl}
              onChange={(e) => setNewImageUrl(e.target.value)}
              placeholder="https://example.com/image.jpg"
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            />
            <button
              onClick={handlePreview}
              disabled={!newImageUrl.trim()}
              className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
            >
              Preview
            </button>
          </div>
        </div>

        {/* Footer with action buttons */}
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between bg-white">
          <div className="text-sm text-gray-500">
            Source: <span className="font-medium">{food._sourceIndex}</span>
          </div>
          <div className="flex gap-2">
            {food.imageUrl && (
              <button
                onClick={onDelete}
                disabled={isDeleting || isSaving}
                className={`px-4 py-2 rounded-lg font-medium flex items-center gap-2 ${
                  isDeleting || isSaving
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-red-50 text-red-600 hover:bg-red-100'
                }`}
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
                    Delete
                  </>
                )}
              </button>
            )}
            {hasChanges && newImageUrl.trim() && (
              <button
                onClick={handleSave}
                disabled={isSaving || isDeleting}
                className={`px-4 py-2 rounded-lg font-medium flex items-center gap-2 ${
                  isSaving || isDeleting
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-blue-500 text-white hover:bg-blue-600'
                }`}
              >
                {isSaving ? (
                  <>
                    <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                    Saving...
                  </>
                ) : (
                  <>
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    Save Image
                  </>
                )}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

// Store for image preview state (shared across ImageRenderer instances)
let setImagePreviewFood: ((food: UnifiedFood | null) => void) | null = null;

// Custom cell renderers
const ImageRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const imageUrl = params.value as string | null;
  const food = params.data;

  const handleClick = () => {
    if (food && setImagePreviewFood) {
      setImagePreviewFood(food);
    }
  };

  if (!imageUrl) {
    return (
      <div
        className="flex items-center justify-center w-12 h-12 bg-gray-100 rounded text-gray-400 text-xs cursor-pointer hover:bg-gray-200"
        onClick={handleClick}
        title="Click to view/add image"
      >
        No img
      </div>
    );
  }

  return (
    <img
      src={imageUrl}
      alt=""
      className="w-12 h-12 object-cover rounded cursor-pointer hover:opacity-80 transition-opacity"
      onClick={handleClick}
      title="Click to view image"
      onError={(e) => {
        (e.target as HTMLImageElement).style.display = 'none';
      }}
    />
  );
};

const NameRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const name = params.value as string;
  const foodId = params.data?._id;
  const foodReportIds = useGridStore(state => state.foodReportIds);
  const hasReport = foodId && foodReportIds.has(foodId);

  return (
    <div className="flex items-center gap-2">
      <span>{name}</span>
      {hasReport && (
        <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-yellow-100 text-yellow-700" title="Has user report">
          📝
        </span>
      )}
    </div>
  );
};

const IndexBadgeRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const index = params.value as AlgoliaIndexName;

  const badgeColors: Record<AlgoliaIndexName, string> = {
    'verified_foods': 'bg-green-100 text-green-800',
    'foods': 'bg-blue-100 text-blue-800',
    'manual_foods': 'bg-purple-100 text-purple-800',
    'user_added': 'bg-yellow-100 text-yellow-800',
    'ai_enhanced': 'bg-pink-100 text-pink-800',
    'ai_manually_added': 'bg-indigo-100 text-indigo-800',
    'tesco_products': 'bg-orange-100 text-orange-800',
    'uk_foods_cleaned': 'bg-cyan-100 text-cyan-800',
    'fast_foods_database': 'bg-red-100 text-red-800',
    'generic_database': 'bg-gray-100 text-gray-800',
    'consumer_foods': 'bg-teal-100 text-teal-800',
  };

  const shortNames: Record<AlgoliaIndexName, string> = {
    'verified_foods': 'Verified',
    'foods': 'Foods',
    'manual_foods': 'Manual',
    'user_added': 'User',
    'ai_enhanced': 'AI',
    'ai_manually_added': 'AI Manual',
    'tesco_products': 'Tesco',
    'uk_foods_cleaned': 'UK Clean',
    'fast_foods_database': 'Fast Food',
    'generic_database': 'Generic',
    'consumer_foods': 'Consumer',
  };

  return (
    <span className={`px-2 py-1 rounded text-xs font-medium ${badgeColors[index]}`}>
      {shortNames[index]}
    </span>
  );
};

const VerifiedRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const isVerified = params.value as boolean;

  return (
    <span className={`inline-flex items-center ${isVerified ? 'text-green-600' : 'text-gray-400'}`}>
      {isVerified ? (
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
        </svg>
      ) : (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <circle cx="12" cy="12" r="10" strokeWidth="2" />
        </svg>
      )}
    </span>
  );
};

const PerUnitRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const isPerUnit = params.value as boolean;

  return (
    <span className={`inline-flex items-center px-2 py-1 rounded text-xs font-medium ${
      isPerUnit
        ? 'bg-purple-100 text-purple-800'
        : 'bg-gray-100 text-gray-600'
    }`}>
      {isPerUnit ? 'Per Unit' : 'Per 100g'}
    </span>
  );
};

const FlagsRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const flags = params.data?._reviewFlags || [];

  if (flags.length === 0) {
    return <span className="text-gray-400 text-xs">None</span>;
  }

  const errorCount = flags.filter(f => f.severity === 'error').length;
  const warningCount = flags.filter(f => f.severity === 'warning').length;
  const infoCount = flags.filter(f => f.severity === 'info').length;

  return (
    <div className="flex gap-1">
      {errorCount > 0 && (
        <span className="px-1.5 py-0.5 bg-red-100 text-red-700 rounded text-xs" title={flags.filter(f => f.severity === 'error').map(f => f.message).join('\n')}>
          {errorCount}
        </span>
      )}
      {warningCount > 0 && (
        <span className="px-1.5 py-0.5 bg-yellow-100 text-yellow-700 rounded text-xs" title={flags.filter(f => f.severity === 'warning').map(f => f.message).join('\n')}>
          {warningCount}
        </span>
      )}
      {infoCount > 0 && (
        <span className="px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded text-xs" title={flags.filter(f => f.severity === 'info').map(f => f.message).join('\n')}>
          {infoCount}
        </span>
      )}
    </div>
  );
};

const NutritionRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const value = params.value as number;

  if (value === null || value === undefined) {
    return <span className="text-gray-400">-</span>;
  }

  // Format to 1 decimal place if needed
  const formatted = Number.isInteger(value) ? value.toString() : value.toFixed(1);

  return <span className="font-mono text-right">{formatted}</span>;
};

interface FoodGridProps {
  onEditFood?: (food: UnifiedFood) => void;
  onDeleteFoods?: (foods: UnifiedFood[]) => void;
}

export const FoodGrid: React.FC<FoodGridProps> = () => {
  const gridRef = useRef<AgGridReact<UnifiedFood>>(null);
  const gridApiRef = useRef<GridApi<UnifiedFood> | null>(null);
  const saveTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const pendingSavesRef = useRef<Map<string, UnifiedFood>>(new Map());
  const [saveStatus, setSaveStatus] = useState<'idle' | 'saving' | 'saved' | 'error'>('idle');
  const [imagePreviewFood, setImagePreviewFoodState] = useState<UnifiedFood | null>(null);
  const [isDeletingImage, setIsDeletingImage] = useState(false);
  const [isSavingImage, setIsSavingImage] = useState(false);
  const [detailModalFood, setDetailModalFood] = useState<UnifiedFood | null>(null);

  // Share setter with ImageRenderer
  useEffect(() => {
    setImagePreviewFood = setImagePreviewFoodState;
    return () => {
      setImagePreviewFood = null;
    };
  }, []);

  const {
    getFilteredFoods,
    setSelectedFoodIds,
    updateFood,
    setColumnOrder,
  } = useGridStore();

  const foods = getFilteredFoods();

  // Auto-save function
  const saveToBackend = useCallback(async (food: UnifiedFood) => {
    try {
      const payload = {
        foodId: food.objectID,
        indexName: food._sourceIndex,
        updates: {
          foodName: food.name,
          brandName: food.brandName,
          barcode: food.barcode,
          servingSizeG: food.servingSizeG,
          servingSize: food.servingDescription, // Maps to servingDescription in backend
          isPerUnit: food.isPerUnit, // Per-unit nutrition flag
          nutrition: {
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium,
            saturatedFat: food.saturatedFat,
          },
        },
      };

      console.log('🔍 Saving to backend:', JSON.stringify(payload, null, 2));

      const response = await fetch(`${FUNCTIONS_BASE}/adminSaveFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const result = await response.json();
      return result.success;
    } catch (error) {
      console.error('Auto-save error:', error);
      return false;
    }
  }, []);

  // Debounced batch save
  const scheduleSave = useCallback((food: UnifiedFood) => {
    pendingSavesRef.current.set(food._id, food);

    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }

    setSaveStatus('saving');

    saveTimeoutRef.current = setTimeout(async () => {
      const foodsToSave = Array.from(pendingSavesRef.current.values());
      pendingSavesRef.current.clear();

      let allSuccess = true;
      for (const f of foodsToSave) {
        const success = await saveToBackend(f);
        if (!success) allSuccess = false;
      }

      setSaveStatus(allSuccess ? 'saved' : 'error');

      // Reset status after 2 seconds
      setTimeout(() => setSaveStatus('idle'), 2000);
    }, 1000); // Wait 1 second after last edit before saving
  }, [saveToBackend]);

  // Column definitions
  const columnDefs = useMemo<ColDef<UnifiedFood>[]>(() => [
    {
      headerCheckboxSelection: true,
      checkboxSelection: true,
      width: 50,
      pinned: 'left',
      lockPosition: true,
      suppressMenu: true,
      resizable: false,
    },
    {
      field: 'imageUrl',
      headerName: 'Image',
      width: 80,
      cellRenderer: ImageRenderer,
      editable: false,
      filter: false,
      sortable: false,
    },
    {
      field: 'name',
      headerName: 'Name',
      width: 250,
      editable: true,
      filter: 'agTextColumnFilter',
      sortable: true,
      cellClass: 'font-medium',
      cellRenderer: NameRenderer,
    },
    {
      field: 'brandName',
      headerName: 'Brand',
      width: 150,
      editable: true,
      filter: 'agTextColumnFilter',
      sortable: true,
    },
    {
      field: 'barcode',
      headerName: 'Barcode',
      width: 130,
      editable: true,
      filter: 'agTextColumnFilter',
      sortable: true,
      cellClass: 'font-mono text-sm',
    },
    {
      field: '_sourceIndex',
      headerName: 'Source',
      width: 100,
      cellRenderer: IndexBadgeRenderer,
      editable: false,
      filter: 'agSetColumnFilter',
      filterParams: {
        values: [...ALGOLIA_INDICES],
      },
      sortable: true,
    },
    {
      field: 'calories',
      headerName: 'Cal',
      width: 80,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'protein',
      headerName: 'Protein',
      width: 80,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'carbs',
      headerName: 'Carbs',
      width: 80,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'fat',
      headerName: 'Fat',
      width: 70,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'fiber',
      headerName: 'Fibre',
      width: 70,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'sugar',
      headerName: 'Sugar',
      width: 70,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'sodium',
      headerName: 'Sodium',
      width: 80,
      editable: true,
      cellRenderer: NutritionRenderer,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'servingSizeG',
      headerName: 'Serving (g)',
      width: 100,
      editable: true,
      valueGetter: (params) => {
        // Always return numeric value for editing
        return params.data?.servingSizeG;
      },
      valueFormatter: (params) => {
        // Display with 'g' suffix
        if (params.value == null) return '-';
        return `${params.value}g`;
      },
      valueParser: (params) => {
        // Parse user input: "45g" -> 45, "45" -> 45, "100" -> 100
        if (!params.newValue) return null;
        const str = String(params.newValue).toLowerCase().replace(/[^0-9.]/g, '');
        const parsed = parseFloat(str);
        console.log(`servingSizeG parser: "${params.newValue}" -> ${parsed}`);
        return isNaN(parsed) ? null : parsed;
      },
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
    },
    {
      field: 'servingDescription',
      headerName: 'Serving Desc',
      width: 120,
      editable: true,
      valueFormatter: (params) => params.value || '-',
      filter: 'agTextColumnFilter',
      sortable: true,
    },
    {
      field: 'isPerUnit',
      headerName: 'Per Unit',
      width: 90,
      cellRenderer: PerUnitRenderer,
      editable: true,
      filter: 'agSetColumnFilter',
      filterParams: {
        values: [true, false],
        valueFormatter: (params: { value: boolean }) => params.value ? 'Per Unit' : 'Per 100g',
      },
      sortable: true,
      cellEditor: 'agSelectCellEditor',
      cellEditorParams: {
        values: [true, false],
      },
      valueFormatter: (params) => params.value ? 'Per Unit' : 'Per 100g',
    },
    {
      field: 'isVerified',
      headerName: 'Verified',
      width: 90,
      cellRenderer: VerifiedRenderer,
      editable: false,
      filter: 'agSetColumnFilter',
      filterParams: {
        values: [true, false],
        valueFormatter: (params: { value: boolean }) => params.value ? 'Verified' : 'Unverified',
      },
      sortable: true,
    },
    {
      field: '_reviewFlags',
      headerName: 'Issues',
      width: 100,
      cellRenderer: FlagsRenderer,
      editable: false,
      filter: false,
      sortable: false,
    },
    {
      field: '_confidenceScore',
      headerName: 'Score',
      width: 80,
      editable: false,
      filter: 'agNumberColumnFilter',
      sortable: true,
      type: 'numericColumn',
      valueFormatter: (params) => params.value ? `${params.value}%` : '-',
    },
  ], []);

  // Default column properties
  const defaultColDef = useMemo<ColDef>(() => ({
    resizable: true,
    suppressMovable: false,
  }), []);

  // Grid ready handler
  const onGridReady = useCallback((params: GridReadyEvent<UnifiedFood>) => {
    gridApiRef.current = params.api;
  }, []);

  // Cell value changed handler (auto-save)
  const onCellValueChanged = useCallback((event: CellValueChangedEvent<UnifiedFood>) => {
    if (event.data && event.colDef.field) {
      const field = event.colDef.field as keyof UnifiedFood;
      updateFood(event.data._id, { [field]: event.newValue });

      // Get the updated food and schedule auto-save
      const updatedFood = { ...event.data, [field]: event.newValue };
      scheduleSave(updatedFood);
    }
  }, [updateFood, scheduleSave]);

  // Row selection handler
  const onRowSelected = useCallback((_event: RowSelectedEvent<UnifiedFood>) => {
    if (gridApiRef.current) {
      const selectedRows = gridApiRef.current.getSelectedRows();
      setSelectedFoodIds(selectedRows.map(r => r._id));
    }
  }, [setSelectedFoodIds]);

  // Column moved handler (persist order)
  const onColumnMoved = useCallback((_event: ColumnMovedEvent) => {
    if (gridApiRef.current) {
      const columns = gridApiRef.current.getAllDisplayedColumns();
      const order = columns.map(c => c.getColId());
      setColumnOrder(order);
    }
  }, [setColumnOrder]);

  // Row double-click handler (open detail modal)
  const onRowDoubleClicked = useCallback((event: RowDoubleClickedEvent<UnifiedFood>) => {
    if (event.data) {
      setDetailModalFood(event.data);
    }
  }, []);

  // Handle food update from detail modal
  const handleDetailModalSaved = useCallback((updatedFood: UnifiedFood) => {
    updateFood(updatedFood._id, {
      name: updatedFood.name,
      brandName: updatedFood.brandName,
      barcode: updatedFood.barcode,
      servingDescription: updatedFood.servingDescription,
      servingSizeG: updatedFood.servingSizeG,
      category: updatedFood.category,
      calories: updatedFood.calories,
      protein: updatedFood.protein,
      carbs: updatedFood.carbs,
      fat: updatedFood.fat,
      fiber: updatedFood.fiber,
      sugar: updatedFood.sugar,
      salt: updatedFood.salt,
      saturatedFat: updatedFood.saturatedFat,
      imageUrl: updatedFood.imageUrl,
      isPerUnit: updatedFood.isPerUnit,
    });
    // Refresh the grid
    if (gridApiRef.current) {
      gridApiRef.current.refreshCells({ force: true });
    }
  }, [updateFood]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Cmd/Ctrl + S to save
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault();
        // Trigger save action
        console.log('Save triggered');
      }

      // Cmd/Ctrl + Z to undo
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault();
        useGridStore.getState().undo();
      }

      // Cmd/Ctrl + Shift + Z to redo
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && e.shiftKey) {
        e.preventDefault();
        useGridStore.getState().redo();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Row class rules for styling
  const rowClassRules = useMemo<RowClassRules<UnifiedFood>>(() => ({
    'bg-red-50': (params) => params.data?._isDeleted === true,
    'bg-yellow-50': (params) => params.data?._isDirty === true,
    'bg-red-100': (params) =>
      params.data?._reviewFlags?.some(f => f.severity === 'error') === true,
  }), []);

  // Delete image handler
  const handleDeleteImage = useCallback(async () => {
    if (!imagePreviewFood) return;

    const confirmDelete = window.confirm(
      `Are you sure you want to delete the image for "${imagePreviewFood.name}"?\n\nThis action cannot be undone.`
    );

    if (!confirmDelete) return;

    setIsDeletingImage(true);

    try {
      const payload = {
        foodId: imagePreviewFood.objectID,
        indexName: imagePreviewFood._sourceIndex,
        updates: {
          imageUrl: null, // Setting to null will delete the image
        },
      };

      console.log('🗑️ Deleting image:', payload);

      const response = await fetch(`${FUNCTIONS_BASE}/adminSaveFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const result = await response.json();

      if (result.success) {
        // Update local state
        updateFood(imagePreviewFood._id, { imageUrl: null });

        // Refresh the grid
        if (gridApiRef.current) {
          gridApiRef.current.refreshCells({ force: true });
        }

        setImagePreviewFoodState(null);
        console.log('✅ Image deleted successfully');
      } else {
        throw new Error(result.error || 'Failed to delete image');
      }
    } catch (error) {
      console.error('Delete image error:', error);
      alert(`Failed to delete image: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      setIsDeletingImage(false);
    }
  }, [imagePreviewFood, updateFood]);

  // Save image handler
  const handleSaveImage = useCallback(async (imageUrl: string) => {
    if (!imagePreviewFood) return;

    setIsSavingImage(true);

    try {
      const payload = {
        foodId: imagePreviewFood.objectID,
        indexName: imagePreviewFood._sourceIndex,
        updates: {
          imageUrl: imageUrl,
        },
      };

      console.log('💾 Saving image:', payload);

      const response = await fetch(`${FUNCTIONS_BASE}/adminSaveFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const result = await response.json();

      if (result.success) {
        // Update local state
        updateFood(imagePreviewFood._id, { imageUrl: imageUrl });

        // Refresh the grid
        if (gridApiRef.current) {
          gridApiRef.current.refreshCells({ force: true });
        }

        setImagePreviewFoodState(null);
        console.log('✅ Image saved successfully');
      } else {
        throw new Error(result.error || 'Failed to save image');
      }
    } catch (error) {
      console.error('Save image error:', error);
      alert(`Failed to save image: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      setIsSavingImage(false);
    }
  }, [imagePreviewFood, updateFood]);

  return (
    <div className="ag-theme-alpine w-full h-full relative">
      {/* Auto-save status indicator */}
      {saveStatus !== 'idle' && (
        <div className={`absolute top-2 right-2 z-10 px-3 py-1.5 rounded-full text-sm font-medium shadow-lg flex items-center gap-2 ${
          saveStatus === 'saving' ? 'bg-yellow-100 text-yellow-800' :
          saveStatus === 'saved' ? 'bg-green-100 text-green-800' :
          'bg-red-100 text-red-800'
        }`}>
          {saveStatus === 'saving' && (
            <>
              <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Saving...
            </>
          )}
          {saveStatus === 'saved' && (
            <>
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              Saved
            </>
          )}
          {saveStatus === 'error' && (
            <>
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              Save failed
            </>
          )}
        </div>
      )}
      <AgGridReact<UnifiedFood>
        ref={gridRef}
        rowData={foods}
        columnDefs={columnDefs}
        defaultColDef={defaultColDef}
        rowSelection="multiple"
        suppressRowClickSelection={true}
        getRowId={(params) => params.data._id}
        onGridReady={onGridReady}
        onCellValueChanged={onCellValueChanged}
        onRowSelected={onRowSelected}
        onColumnMoved={onColumnMoved}
        onRowDoubleClicked={onRowDoubleClicked}
        rowClassRules={rowClassRules}
        animateRows={true}
        enableCellTextSelection={true}
        suppressCopyRowsToClipboard={false}
        // Performance optimizations
        rowBuffer={20}
        cacheBlockSize={100}
        maxBlocksInCache={10}
        // Styling
        rowHeight={56}
        headerHeight={40}
      />

      {/* Image Preview Modal */}
      {imagePreviewFood && (
        <ImagePreviewModal
          food={imagePreviewFood}
          onClose={() => setImagePreviewFoodState(null)}
          onDelete={handleDeleteImage}
          onSaveImage={handleSaveImage}
          isDeleting={isDeletingImage}
          isSaving={isSavingImage}
        />
      )}

      {/* Food Detail Modal (double-click to open) */}
      {detailModalFood && (
        <FoodDetailModal
          food={detailModalFood}
          onClose={() => setDetailModalFood(null)}
          onSaved={handleDetailModalSaved}
        />
      )}
    </div>
  );
};

export default FoodGrid;
