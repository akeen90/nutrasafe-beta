/**
 * Sidebar Component
 * Statistics and quick actions
 */

import React from 'react';
import { useGridStore } from '../store';
import { ALGOLIA_INDICES, AlgoliaIndexName } from '../types';

interface SidebarProps {
  onDetectDuplicates: () => void;
  onLookupOFF: () => void;
  onImageProcessing: () => void;
  onGoogleScraper: () => void;
  onReports: () => void;
  onMasterBuilder: () => void;
  onFoodCategorizer: () => void;
  onAnalytics: () => void;
  isDetectingDuplicates: boolean;
  pendingReportsCount?: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  onDetectDuplicates,
  onLookupOFF,
  onImageProcessing,
  onGoogleScraper,
  onReports,
  onMasterBuilder,
  onFoodCategorizer,
  onAnalytics,
  isDetectingDuplicates,
  pendingReportsCount = 0,
}) => {
  const { stats, duplicateGroups, filters, setFilters, getFilteredFoods, selectedFoodIds } = useGridStore();

  const filteredFoods = getFilteredFoods();
  const issueCount = filteredFoods.filter(f => f._reviewFlags.length > 0).length;

  const indexColors: Record<AlgoliaIndexName, string> = {
    'verified_foods': 'bg-green-500',
    'foods': 'bg-blue-500',
    'manual_foods': 'bg-purple-500',
    'user_added': 'bg-yellow-500',
    'ai_enhanced': 'bg-pink-500',
    'ai_manually_added': 'bg-indigo-500',
    'tesco_products': 'bg-orange-500',
    'uk_foods_cleaned': 'bg-cyan-500',
    'fast_foods_database': 'bg-red-500',
    'generic_database': 'bg-gray-500',
    'consumer_foods': 'bg-teal-500',
  };

  const indexShortNames: Record<AlgoliaIndexName, string> = {
    'verified_foods': 'Verified',
    'foods': 'Foods',
    'manual_foods': 'Manual',
    'user_added': 'User',
    'ai_enhanced': 'AI',
    'ai_manually_added': 'AI Manual',
    'tesco_products': 'Tesco',
    'uk_foods_cleaned': 'UK',
    'fast_foods_database': 'Fast',
    'generic_database': 'Generic',
    'consumer_foods': 'Consumer',
  };

  return (
    <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
      {/* Stats Summary */}
      <div className="p-4 border-b border-gray-100">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Overview
        </h2>
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-gray-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-gray-900">
              {filteredFoods.length.toLocaleString()}
            </div>
            <div className="text-xs text-gray-500">Showing</div>
          </div>
          <div className="bg-gray-50 rounded-lg p-3">
            <div className="text-2xl font-bold text-gray-900">
              {stats?.totalFoods.toLocaleString() || '-'}
            </div>
            <div className="text-xs text-gray-500">Total</div>
          </div>
        </div>
      </div>

      {/* Index Breakdown */}
      <div className="p-4 border-b border-gray-100 flex-1 overflow-auto">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Indices
        </h2>
        <div className="space-y-2">
          {ALGOLIA_INDICES.map((index) => {
            const count = stats?.byIndex[index] || 0;
            const isActive = filters.indices.includes(index);
            const percentage = stats?.totalFoods ? (count / stats.totalFoods) * 100 : 0;

            return (
              <button
                key={index}
                onClick={() => {
                  if (isActive && filters.indices.length === 1) {
                    // If it's the only active index, select all
                    setFilters({ indices: [...ALGOLIA_INDICES] });
                  } else if (isActive) {
                    // Deselect this index
                    setFilters({ indices: filters.indices.filter(i => i !== index) });
                  } else {
                    // Select only this index
                    setFilters({ indices: [index] });
                  }
                }}
                className={`w-full text-left px-3 py-2 rounded-lg transition-colors ${
                  isActive ? 'bg-gray-100' : 'hover:bg-gray-50 opacity-60'
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${indexColors[index]}`} />
                    <span className="text-sm font-medium text-gray-700">
                      {indexShortNames[index]}
                    </span>
                  </div>
                  <span className="text-sm text-gray-500">
                    {count.toLocaleString()}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-1">
                  <div
                    className={`${indexColors[index]} h-1 rounded-full transition-all`}
                    style={{ width: `${percentage}%` }}
                  />
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Quick Stats */}
      <div className="p-4 border-b border-gray-100">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Data Quality
        </h2>
        <div className="space-y-2">
          <div className="flex items-center justify-between px-3 py-2 bg-green-50 rounded-lg">
            <span className="text-sm text-green-700">Verified</span>
            <span className="text-sm font-medium text-green-700">
              {stats?.verified.toLocaleString() || 0}
            </span>
          </div>
          <button
            onClick={() => setFilters({ hasIssues: !filters.hasIssues })}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-lg transition-colors ${
              filters.hasIssues ? 'bg-red-100' : 'bg-red-50 hover:bg-red-100'
            }`}
          >
            <span className="text-sm text-red-700">With Issues</span>
            <span className="text-sm font-medium text-red-700">
              {issueCount.toLocaleString()}
            </span>
          </button>
          <div className="flex items-center justify-between px-3 py-2 bg-yellow-50 rounded-lg">
            <span className="text-sm text-yellow-700">Duplicates</span>
            <span className="text-sm font-medium text-yellow-700">
              {duplicateGroups.length}
            </span>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="p-4">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Actions
        </h2>
        <div className="space-y-2">
          <button
            onClick={onDetectDuplicates}
            disabled={isDetectingDuplicates}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-50"
          >
            {isDetectingDuplicates ? (
              <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
            ) : (
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            )}
            <span>Detect Duplicates</span>
          </button>

          <button
            onClick={onLookupOFF}
            className={`w-full flex items-center gap-2 px-3 py-2 text-sm rounded-lg transition-colors ${
              selectedFoodIds.length > 0
                ? 'text-primary-700 bg-primary-50 hover:bg-primary-100'
                : 'text-gray-700 bg-gray-50 hover:bg-gray-100'
            }`}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <span>
              {selectedFoodIds.length > 0
                ? `Check UK Status (${selectedFoodIds.length})`
                : 'OpenFoodFacts Lookup'}
            </span>
          </button>

          <button
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            <span>Add New Food</span>
          </button>

          <button
            onClick={onImageProcessing}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-primary-700 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span>Image Processing</span>
          </button>

          <button
            onClick={onGoogleScraper}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
            </svg>
            <span>Google Image Scraper</span>
          </button>

          <button
            onClick={onReports}
            className={`w-full flex items-center justify-between px-3 py-2 text-sm rounded-lg transition-colors ${
              pendingReportsCount > 0
                ? 'text-orange-700 bg-orange-50 hover:bg-orange-100'
                : 'text-gray-700 bg-gray-50 hover:bg-gray-100'
            }`}
          >
            <div className="flex items-center gap-2">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <span>User Reports</span>
            </div>
            {pendingReportsCount > 0 && (
              <span className="flex items-center justify-center min-w-[20px] h-5 px-1.5 text-xs font-bold text-white bg-orange-500 rounded-full">
                {pendingReportsCount > 99 ? '99+' : pendingReportsCount}
              </span>
            )}
          </button>

          <button
            onClick={onAnalytics}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-cyan-700 bg-cyan-50 hover:bg-cyan-100 rounded-lg transition-colors font-semibold"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            <span>Analytics</span>
          </button>

          <button
            onClick={onMasterBuilder}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-green-700 bg-green-50 hover:bg-green-100 rounded-lg transition-colors font-semibold"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
            </svg>
            <span>Master Builder</span>
          </button>

          <button
            onClick={onFoodCategorizer}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors font-semibold"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
            </svg>
            <span>Food Categorizer</span>
          </button>
        </div>
      </div>
    </aside>
  );
};

export default Sidebar;
