/**
 * Grid Store
 * Zustand store for managing grid state and data
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import {
  UnifiedFood,
  UnifiedFoodUpdate,
  ALGOLIA_INDICES,
  FilterState,
  DatabaseStats,
  DuplicateGroup,
} from '../types';

interface UndoAction {
  type: 'update' | 'delete' | 'create';
  food: UnifiedFood;
  previousState?: UnifiedFood;
}

interface GridState {
  // Data
  foods: UnifiedFood[];
  searchResults: UnifiedFood[]; // Results from Algolia search
  isSearching: boolean; // Whether we're showing search results vs local data
  selectedFoodIds: string[];
  duplicateGroups: DuplicateGroup[];

  // Loading states
  isLoading: boolean;
  loadingProgress: number;
  loadingMessage: string;

  // Filter state
  filters: FilterState;

  // Stats
  stats: DatabaseStats | null;

  // Undo/Redo
  undoStack: UndoAction[];
  redoStack: UndoAction[];

  // Column configuration (persisted)
  columnOrder: string[];

  // Dirty tracking
  dirtyFoodIds: Set<string>;

  // User reports tracking
  foodReportIds: Set<string>; // IDs of foods that have user reports

  // Actions
  setFoods: (foods: UnifiedFood[]) => void;
  addFoods: (foods: UnifiedFood[]) => void;
  updateFood: (id: string, updates: UnifiedFoodUpdate) => void;
  markFoodDeleted: (id: string) => void;
  restoreFood: (id: string) => void;

  setSelectedFoodIds: (ids: string[]) => void;
  toggleFoodSelection: (id: string) => void;
  selectAll: () => void;
  deselectAll: () => void;

  setFilters: (filters: Partial<FilterState>) => void;
  clearFilters: () => void;

  setLoading: (isLoading: boolean, message?: string) => void;
  setLoadingProgress: (progress: number) => void;

  setStats: (stats: DatabaseStats) => void;
  setDuplicateGroups: (groups: DuplicateGroup[]) => void;

  setColumnOrder: (order: string[]) => void;

  undo: () => void;
  redo: () => void;
  pushUndo: (action: UndoAction) => void;

  clearDirty: () => void;
  getDirtyFoods: () => UnifiedFood[];

  // Search
  setSearchResults: (foods: UnifiedFood[]) => void;
  setIsSearching: (isSearching: boolean) => void;
  clearSearch: () => void;

  // User reports
  setFoodReportIds: (ids: Set<string>) => void;

  // Computed
  getFilteredFoods: () => UnifiedFood[];
  getFoodById: (id: string) => UnifiedFood | undefined;
}

const defaultFilters: FilterState = {
  searchQuery: '',
  indices: [...ALGOLIA_INDICES],
  verified: 'all',
  hasIssues: false,
  hasDuplicates: false,
  hasBarcode: false,
  zeroCalories: false,
  hasReport: false,
};

const defaultColumnOrder = [
  'selection',
  'imageUrl',
  'name',
  'brandName',
  'barcode',
  '_sourceIndex',
  'calories',
  'protein',
  'carbs',
  'fat',
  'fiber',
  'sugar',
  'sodium',
  'servingSizeG',
  'servingDescription',
  'isVerified',
  '_reviewFlags',
  'actions',
];

export const useGridStore = create<GridState>()(
  persist(
    (set, get) => ({
      // Initial state
      foods: [],
      searchResults: [],
      isSearching: false,
      selectedFoodIds: [],
      duplicateGroups: [],
      isLoading: false,
      loadingProgress: 0,
      loadingMessage: '',
      filters: defaultFilters,
      stats: null,
      undoStack: [],
      redoStack: [],
      columnOrder: defaultColumnOrder,
      dirtyFoodIds: new Set(),
      foodReportIds: new Set(),

      // Actions
      setFoods: (foods) =>
        set({ foods, dirtyFoodIds: new Set() }),

      addFoods: (newFoods) =>
        set((state) => ({
          foods: [...state.foods, ...newFoods],
        })),

      updateFood: (id, updates) =>
        set((state) => {
          const foodIndex = state.foods.findIndex((f) => f._id === id);
          if (foodIndex === -1) return state;

          const oldFood = state.foods[foodIndex];
          const newFood: UnifiedFood = {
            ...oldFood,
            ...updates,
            _isDirty: true,
          };

          const newFoods = [...state.foods];
          newFoods[foodIndex] = newFood;

          const newDirtyIds = new Set(state.dirtyFoodIds);
          newDirtyIds.add(id);

          // Push to undo stack
          const undoAction: UndoAction = {
            type: 'update',
            food: newFood,
            previousState: oldFood,
          };

          return {
            foods: newFoods,
            dirtyFoodIds: newDirtyIds,
            undoStack: [...state.undoStack, undoAction],
            redoStack: [],
          };
        }),

      markFoodDeleted: (id) =>
        set((state) => {
          const foodIndex = state.foods.findIndex((f) => f._id === id);
          if (foodIndex === -1) return state;

          const oldFood = state.foods[foodIndex];
          const newFoods = [...state.foods];
          newFoods[foodIndex] = { ...oldFood, _isDeleted: true };

          const undoAction: UndoAction = {
            type: 'delete',
            food: newFoods[foodIndex],
            previousState: oldFood,
          };

          return {
            foods: newFoods,
            undoStack: [...state.undoStack, undoAction],
            redoStack: [],
          };
        }),

      restoreFood: (id) =>
        set((state) => {
          const foodIndex = state.foods.findIndex((f) => f._id === id);
          if (foodIndex === -1) return state;

          const newFoods = [...state.foods];
          newFoods[foodIndex] = { ...newFoods[foodIndex], _isDeleted: false };

          return { foods: newFoods };
        }),

      setSelectedFoodIds: (ids) =>
        set({ selectedFoodIds: ids }),

      toggleFoodSelection: (id) =>
        set((state) => {
          const isSelected = state.selectedFoodIds.includes(id);
          return {
            selectedFoodIds: isSelected
              ? state.selectedFoodIds.filter((fid) => fid !== id)
              : [...state.selectedFoodIds, id],
          };
        }),

      selectAll: () =>
        set(() => ({
          selectedFoodIds: get().getFilteredFoods().map((f) => f._id),
        })),

      deselectAll: () =>
        set({ selectedFoodIds: [] }),

      setFilters: (newFilters) =>
        set((state) => ({
          filters: { ...state.filters, ...newFilters },
        })),

      clearFilters: () =>
        set({ filters: defaultFilters }),

      setLoading: (isLoading, message = '') =>
        set({ isLoading, loadingMessage: message }),

      setLoadingProgress: (progress) =>
        set({ loadingProgress: progress }),

      setStats: (stats) =>
        set({ stats }),

      setDuplicateGroups: (groups) =>
        set({ duplicateGroups: groups }),

      setColumnOrder: (order) =>
        set({ columnOrder: order }),

      undo: () =>
        set((state) => {
          if (state.undoStack.length === 0) return state;

          const lastAction = state.undoStack[state.undoStack.length - 1];
          const newUndoStack = state.undoStack.slice(0, -1);

          if (!lastAction.previousState) return { undoStack: newUndoStack };

          const foodIndex = state.foods.findIndex((f) => f._id === lastAction.food._id);
          if (foodIndex === -1) return { undoStack: newUndoStack };

          const newFoods = [...state.foods];
          newFoods[foodIndex] = lastAction.previousState;

          return {
            foods: newFoods,
            undoStack: newUndoStack,
            redoStack: [...state.redoStack, lastAction],
          };
        }),

      redo: () =>
        set((state) => {
          if (state.redoStack.length === 0) return state;

          const lastAction = state.redoStack[state.redoStack.length - 1];
          const newRedoStack = state.redoStack.slice(0, -1);

          const foodIndex = state.foods.findIndex((f) => f._id === lastAction.food._id);
          if (foodIndex === -1) return { redoStack: newRedoStack };

          const newFoods = [...state.foods];
          newFoods[foodIndex] = lastAction.food;

          return {
            foods: newFoods,
            redoStack: newRedoStack,
            undoStack: [...state.undoStack, lastAction],
          };
        }),

      pushUndo: (action) =>
        set((state) => ({
          undoStack: [...state.undoStack, action],
          redoStack: [],
        })),

      clearDirty: () =>
        set((state) => ({
          dirtyFoodIds: new Set(),
          foods: state.foods.map((f) => ({ ...f, _isDirty: false })),
        })),

      getDirtyFoods: () => {
        const state = get();
        return state.foods.filter((f) => f._isDirty);
      },

      // Search
      setSearchResults: (foods) =>
        set({ searchResults: foods, isSearching: true }),

      setIsSearching: (isSearching) =>
        set({ isSearching }),

      clearSearch: () =>
        set({ searchResults: [], isSearching: false }),

      // User reports
      setFoodReportIds: (ids) =>
        set({ foodReportIds: ids }),

      // Computed
      getFilteredFoods: () => {
        const state = get();
        const { filters, foods, searchResults, isSearching } = state;

        // If we're showing Algolia search results, use those instead
        const dataSource = isSearching ? searchResults : foods;

        return dataSource.filter((food) => {
          // Exclude deleted
          if (food._isDeleted) return false;

          // Index filter
          if (!filters.indices.includes(food._sourceIndex)) return false;

          // Verified filter
          if (filters.verified === 'verified' && !food.isVerified) return false;
          if (filters.verified === 'unverified' && food.isVerified) return false;

          // Issues filter
          if (filters.hasIssues && food._reviewFlags.length === 0) return false;

          // Barcode filter
          if (filters.hasBarcode && !food.barcode) return false;

          // Zero calories filter
          if (filters.zeroCalories && food.calories !== 0) return false;

          // Has report filter (check objectID since report IDs don't include index prefix)
          if (filters.hasReport && !state.foodReportIds.has(food.objectID)) return false;

          // When searching via Algolia, don't filter again by search query
          // (Algolia already did that). Only filter locally when not searching.
          if (!isSearching && filters.searchQuery) {
            const query = filters.searchQuery.toLowerCase();
            const searchableText = `${food.name} ${food.brandName || ''} ${food.barcode || ''} ${food.ingredientsText || ''}`.toLowerCase();
            if (!searchableText.includes(query)) return false;
          }

          return true;
        });
      },

      getFoodById: (id) => {
        const state = get();
        // Check both foods and searchResults since user may have selected from search
        return state.foods.find((f) => f._id === id)
          || state.searchResults.find((f) => f._id === id);
      },
    }),
    {
      name: 'nutrasafe-grid-store',
      partialize: (state) => ({
        columnOrder: state.columnOrder,
        filters: {
          indices: state.filters.indices,
        },
      }),
    }
  )
);
