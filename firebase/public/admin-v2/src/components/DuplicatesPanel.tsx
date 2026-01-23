/**
 * Duplicates Panel Component
 * Shows detected duplicate groups with merge/dismiss actions
 */

import React, { useState } from 'react';
import { useGridStore } from '../store';
import { mergeDuplicates } from '../utils/duplicateDetection';
import { DuplicateGroup, UnifiedFood } from '../types';

interface DuplicatesPanelProps {
  onClose: () => void;
}

export const DuplicatesPanel: React.FC<DuplicatesPanelProps> = ({ onClose }) => {
  const { duplicateGroups, setDuplicateGroups, getFoodById, updateFood } = useGridStore();
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null);
  const [merging, setMerging] = useState<string | null>(null);

  const handleMerge = async (group: DuplicateGroup) => {
    const masterFood = getFoodById(group.masterFoodId);
    if (!masterFood) return;

    const duplicateFoods = group.duplicateIds
      .map(id => getFoodById(id))
      .filter((f): f is UnifiedFood => f !== undefined);

    if (duplicateFoods.length === 0) return;

    setMerging(group.id);

    try {
      // Merge the data
      const merged = mergeDuplicates(masterFood, duplicateFoods);

      // Update the master food with merged data
      updateFood(masterFood._id, {
        barcodes: merged.barcodes,
        barcode: merged.barcode,
        imageUrl: merged.imageUrl,
        ingredientsText: merged.ingredientsText,
        ingredients: merged.ingredients,
      });

      // Mark duplicates as deleted (they'll be hidden from view)
      duplicateFoods.forEach(dup => {
        updateFood(dup._id, { _isDeleted: true } as any);
      });

      // Remove this group from the list
      setDuplicateGroups(duplicateGroups.filter(g => g.id !== group.id));

      console.log(`Merged ${duplicateFoods.length} duplicates into ${masterFood.name}`);
    } catch (error) {
      console.error('Error merging duplicates:', error);
      alert('Failed to merge duplicates');
    } finally {
      setMerging(null);
    }
  };

  const handleDismiss = (group: DuplicateGroup) => {
    setDuplicateGroups(duplicateGroups.filter(g => g.id !== group.id));
  };

  const handleDismissAll = () => {
    if (confirm('Dismiss all duplicate groups? This cannot be undone.')) {
      setDuplicateGroups([]);
    }
  };

  if (duplicateGroups.length === 0) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl p-6">
          <div className="text-center py-8">
            <svg className="w-16 h-16 mx-auto text-green-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">No Duplicates Found</h3>
            <p className="text-gray-500 mb-6">Your database looks clean!</p>
            <button
              onClick={onClose}
              className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">Duplicate Detection</h2>
            <p className="text-sm text-gray-500">
              Found {duplicateGroups.length} potential duplicate group{duplicateGroups.length !== 1 ? 's' : ''}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={handleDismissAll}
              className="px-3 py-1.5 text-sm text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-lg"
            >
              Dismiss All
            </button>
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

        {/* Duplicate Groups List */}
        <div className="flex-1 overflow-y-auto divide-y divide-gray-200">
          {duplicateGroups.map((group) => {
            const masterFood = getFoodById(group.masterFoodId);
            const duplicateFoods = group.duplicateIds
              .map(id => getFoodById(id))
              .filter((f): f is UnifiedFood => f !== undefined);

            if (!masterFood) return null;

            const isExpanded = expandedGroup === group.id;
            const isMerging = merging === group.id;

            return (
              <div key={group.id} className="p-4">
                {/* Group Header */}
                <div className="flex items-start gap-4">
                  {/* Master Food Image */}
                  <div className="flex-shrink-0">
                    {masterFood.imageUrl ? (
                      <img src={masterFood.imageUrl} alt="" className="w-16 h-16 object-cover rounded border border-gray-200" />
                    ) : (
                      <div className="w-16 h-16 bg-gray-100 rounded border border-gray-200 flex items-center justify-center text-gray-400 text-xs">
                        No img
                      </div>
                    )}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h4 className="font-medium text-gray-900">{masterFood.name}</h4>
                        {masterFood.brandName && (
                          <p className="text-sm text-gray-500">{masterFood.brandName}</p>
                        )}
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded">
                            Master: {masterFood._sourceIndex}
                          </span>
                          <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded">
                            {duplicateFoods.length} duplicate{duplicateFoods.length !== 1 ? 's' : ''}
                          </span>
                        </div>
                      </div>

                      {/* Match Score */}
                      <div className="text-right">
                        <div className={`text-lg font-bold ${
                          group.matchScore >= 80 ? 'text-red-600' :
                          group.matchScore >= 50 ? 'text-yellow-600' :
                          'text-gray-600'
                        }`}>
                          {group.matchScore}%
                        </div>
                        <div className="text-xs text-gray-400">match</div>
                      </div>
                    </div>

                    {/* Match Reasons */}
                    <div className="mt-2 flex flex-wrap gap-1">
                      {group.matchReasons.slice(0, isExpanded ? undefined : 2).map((reason, idx) => (
                        <span key={idx} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded">
                          {reason}
                        </span>
                      ))}
                      {!isExpanded && group.matchReasons.length > 2 && (
                        <span className="text-xs text-gray-400">
                          +{group.matchReasons.length - 2} more
                        </span>
                      )}
                    </div>

                    {/* Expand/Collapse */}
                    <button
                      onClick={() => setExpandedGroup(isExpanded ? null : group.id)}
                      className="mt-2 text-xs text-primary-600 hover:underline"
                    >
                      {isExpanded ? 'Hide details' : 'Show details'}
                    </button>

                    {/* Expanded Details */}
                    {isExpanded && (
                      <div className="mt-3 space-y-2">
                        <div className="text-xs font-medium text-gray-500 uppercase">Duplicates:</div>
                        {duplicateFoods.map((dup) => (
                          <div key={dup._id} className="flex items-center gap-3 p-2 bg-gray-50 rounded">
                            {dup.imageUrl ? (
                              <img src={dup.imageUrl} alt="" className="w-10 h-10 object-cover rounded" />
                            ) : (
                              <div className="w-10 h-10 bg-gray-200 rounded flex items-center justify-center text-gray-400 text-xs">
                                -
                              </div>
                            )}
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-gray-700 truncate">{dup.name}</p>
                              <p className="text-xs text-gray-500">
                                {dup._sourceIndex} • {dup.barcode || 'No barcode'}
                              </p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex flex-col gap-2 flex-shrink-0">
                    <button
                      onClick={() => handleMerge(group)}
                      disabled={isMerging}
                      className="px-3 py-1.5 text-xs bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 whitespace-nowrap"
                    >
                      {isMerging ? (
                        <span className="flex items-center gap-1">
                          <svg className="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                          </svg>
                          Merging
                        </span>
                      ) : (
                        'Merge'
                      )}
                    </button>
                    <button
                      onClick={() => handleDismiss(group)}
                      className="px-3 py-1.5 text-xs bg-gray-100 text-gray-600 rounded hover:bg-gray-200 whitespace-nowrap"
                    >
                      Dismiss
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-500">
              <span className="font-medium text-red-600">{duplicateGroups.filter(g => g.matchScore >= 80).length}</span> high confidence •
              <span className="font-medium text-yellow-600 ml-1">{duplicateGroups.filter(g => g.matchScore >= 50 && g.matchScore < 80).length}</span> medium •
              <span className="font-medium text-gray-600 ml-1">{duplicateGroups.filter(g => g.matchScore < 50).length}</span> low
            </div>
            <button
              onClick={onClose}
              className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
            >
              Done
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DuplicatesPanel;
