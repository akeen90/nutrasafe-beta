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
} from 'ag-grid-community';
import { useGridStore } from '../../store';
import { UnifiedFood, AlgoliaIndexName, ALGOLIA_INDICES } from '../../types';

// Cloud Function for saving
const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

// Custom cell renderers
const ImageRenderer: React.FC<ICellRendererParams<UnifiedFood>> = (params) => {
  const imageUrl = params.value as string | null;

  if (!imageUrl) {
    return (
      <div className="flex items-center justify-center w-12 h-12 bg-gray-100 rounded text-gray-400 text-xs">
        No img
      </div>
    );
  }

  return (
    <img
      src={imageUrl}
      alt=""
      className="w-12 h-12 object-cover rounded"
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
    </div>
  );
};

export default FoodGrid;
