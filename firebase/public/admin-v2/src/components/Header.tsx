/**
 * Header Component
 * Top navigation bar with search, filters, and actions
 */

import React, { useState, useCallback, useEffect, useRef } from 'react';
import { useGridStore } from '../store';
import { searchAllIndices } from '../services/algoliaService';
import { ALGOLIA_INDICES, AlgoliaIndexName } from '../types';

interface HeaderProps {
  onSave: () => void;
  onRefresh: () => void;
  onDeleteSelected: () => void;
  isSaving: boolean;
  isDeleting: boolean;
}

export const Header: React.FC<HeaderProps> = ({ onSave, onRefresh, onDeleteSelected, isSaving, isDeleting }) => {
  const {
    filters,
    setFilters,
    selectedFoodIds,
    deselectAll,
    stats,
    getDirtyFoods,
    setSearchResults,
    clearSearch,
    isSearching,
  } = useGridStore();

  const [showIndexFilter, setShowIndexFilter] = useState(false);
  const [isSearchLoading, setIsSearchLoading] = useState(false);
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const dirtyCount = getDirtyFoods().length;

  // Debounced Algolia search
  const performSearch = useCallback(async (query: string) => {
    if (!query.trim()) {
      clearSearch();
      return;
    }

    setIsSearchLoading(true);
    try {
      const { foods } = await searchAllIndices(query, filters.indices, {
        hitsPerPage: 500, // Get more results when searching
      });
      setSearchResults(foods);
    } catch (error) {
      console.error('Search error:', error);
    } finally {
      setIsSearchLoading(false);
    }
  }, [filters.indices, setSearchResults, clearSearch]);

  const handleSearchChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setFilters({ searchQuery: value });

    // Clear previous timeout
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    // Debounce search - wait 300ms after typing stops
    searchTimeoutRef.current = setTimeout(() => {
      performSearch(value);
    }, 300);
  }, [setFilters, performSearch]);

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
    };
  }, []);

  const handleVerifiedFilterChange = useCallback((value: 'all' | 'verified' | 'unverified') => {
    setFilters({ verified: value });
  }, [setFilters]);

  const toggleIndex = useCallback((index: AlgoliaIndexName) => {
    const currentIndices = filters.indices;
    const newIndices = currentIndices.includes(index)
      ? currentIndices.filter(i => i !== index)
      : [...currentIndices, index];
    setFilters({ indices: newIndices });
  }, [filters.indices, setFilters]);

  const selectAllIndices = useCallback(() => {
    setFilters({ indices: [...ALGOLIA_INDICES] });
  }, [setFilters]);

  const deselectAllIndices = useCallback(() => {
    setFilters({ indices: [] });
  }, [setFilters]);

  const indexShortNames: Record<AlgoliaIndexName, string> = {
    'verified_foods': 'Verified',
    'foods': 'Foods',
    'manual_foods': 'Manual',
    'user_added': 'User',
    'ai_enhanced': 'AI Enhanced',
    'ai_manually_added': 'AI Manual',
    'tesco_products': 'Tesco',
    'uk_foods_cleaned': 'UK Cleaned',
    'fast_foods_database': 'Fast Food',
    'generic_database': 'Generic',
  };

  return (
    <header className="bg-white border-b border-gray-200 px-4 py-3">
      <div className="flex items-center justify-between gap-4">
        {/* Logo and Title */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">NS</span>
          </div>
          <div>
            <h1 className="text-lg font-semibold text-gray-900">Food Database Manager</h1>
            {stats && (
              <p className="text-xs text-gray-500">
                {stats.totalFoods.toLocaleString()} foods across {ALGOLIA_INDICES.length} indices
              </p>
            )}
          </div>
        </div>

        {/* Search */}
        <div className="flex-1 max-w-md">
          <div className="relative">
            <input
              type="text"
              placeholder="Search all foods across Algolia..."
              value={filters.searchQuery}
              onChange={handleSearchChange}
              className={`w-full px-4 py-2 pl-10 pr-10 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent ${
                isSearching ? 'border-primary-400 bg-primary-50' : 'border-gray-300'
              }`}
            />
            {isSearchLoading ? (
              <svg
                className="absolute left-3 top-2.5 w-5 h-5 text-primary-500 animate-spin"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
            ) : (
              <svg
                className="absolute left-3 top-2.5 w-5 h-5 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            )}
            {filters.searchQuery && (
              <button
                onClick={() => {
                  setFilters({ searchQuery: '' });
                  clearSearch();
                }}
                className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
          </div>
          {isSearching && (
            <p className="mt-1 text-xs text-primary-600">
              Searching across all Algolia indices
            </p>
          )}
        </div>

        {/* Filters */}
        <div className="flex items-center gap-2">
          {/* Verified Filter */}
          <div className="flex rounded-lg border border-gray-300 overflow-hidden">
            <button
              onClick={() => handleVerifiedFilterChange('all')}
              className={`px-3 py-1.5 text-sm ${filters.verified === 'all' ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'}`}
            >
              All
            </button>
            <button
              onClick={() => handleVerifiedFilterChange('verified')}
              className={`px-3 py-1.5 text-sm border-l ${filters.verified === 'verified' ? 'bg-green-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'}`}
            >
              Verified
            </button>
            <button
              onClick={() => handleVerifiedFilterChange('unverified')}
              className={`px-3 py-1.5 text-sm border-l ${filters.verified === 'unverified' ? 'bg-yellow-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'}`}
            >
              Unverified
            </button>
          </div>

          {/* Index Filter Dropdown */}
          <div className="relative">
            <button
              onClick={() => setShowIndexFilter(!showIndexFilter)}
              className="flex items-center gap-2 px-3 py-1.5 text-sm border border-gray-300 rounded-lg bg-white hover:bg-gray-50"
            >
              <span>Indices ({filters.indices.length})</span>
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {showIndexFilter && (
              <div className="absolute right-0 mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-50">
                <div className="p-2 border-b border-gray-100 flex justify-between">
                  <button
                    onClick={selectAllIndices}
                    className="text-xs text-primary-600 hover:underline"
                  >
                    Select All
                  </button>
                  <button
                    onClick={deselectAllIndices}
                    className="text-xs text-gray-500 hover:underline"
                  >
                    Deselect All
                  </button>
                </div>
                <div className="p-2 max-h-64 overflow-y-auto">
                  {ALGOLIA_INDICES.map((index) => (
                    <label
                      key={index}
                      className="flex items-center gap-2 px-2 py-1.5 hover:bg-gray-50 rounded cursor-pointer"
                    >
                      <input
                        type="checkbox"
                        checked={filters.indices.includes(index)}
                        onChange={() => toggleIndex(index)}
                        className="rounded text-primary-600 focus:ring-primary-500"
                      />
                      <span className="text-sm text-gray-700">{indexShortNames[index]}</span>
                      {stats && (
                        <span className="text-xs text-gray-400 ml-auto">
                          {stats.byIndex[index]?.toLocaleString() || 0}
                        </span>
                      )}
                    </label>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Issues Filter */}
          <button
            onClick={() => setFilters({ hasIssues: !filters.hasIssues })}
            className={`px-3 py-1.5 text-sm border rounded-lg ${filters.hasIssues ? 'bg-red-100 text-red-700 border-red-300' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'}`}
          >
            Issues
          </button>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2">
          {/* Selection info and delete */}
          {selectedFoodIds.length > 0 && (
            <div className="flex items-center gap-2">
              <div className="flex items-center gap-2 px-3 py-1.5 bg-primary-50 text-primary-700 rounded-lg">
                <span className="text-sm font-medium">
                  {selectedFoodIds.length} selected
                </span>
                <button
                  onClick={deselectAll}
                  className="text-primary-600 hover:text-primary-800"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <button
                onClick={onDeleteSelected}
                disabled={isDeleting}
                className="flex items-center gap-2 px-3 py-1.5 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isDeleting ? (
                  <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                )}
                <span className="text-sm font-medium">Delete</span>
              </button>
            </div>
          )}

          {/* Refresh */}
          <button
            onClick={onRefresh}
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg"
            title="Refresh data"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>

          {/* Save */}
          <button
            onClick={onSave}
            disabled={dirtyCount === 0 || isSaving}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              dirtyCount > 0
                ? 'bg-primary-600 text-white hover:bg-primary-700'
                : 'bg-gray-100 text-gray-400 cursor-not-allowed'
            }`}
          >
            {isSaving ? (
              <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            ) : (
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            )}
            <span>Save {dirtyCount > 0 ? `(${dirtyCount})` : ''}</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
