/**
 * Serving Types Editor Component
 * Allows managing multiple serving options per food with a default selection
 */

import React, { useState, useCallback } from 'react';

export interface ServingType {
  id: string;
  name: string;        // e.g., "1 slice", "1 cup", "100g"
  servingSize: number; // Size in grams or ml
  unit: 'g' | 'ml';    // Unit type
  isDefault: boolean;  // Is this the default serving shown to users
}

interface ServingTypesEditorProps {
  servingTypes: ServingType[];
  onChange: (servingTypes: ServingType[]) => void;
  className?: string;
}

// Generate unique ID
const generateId = () => `serving_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

// Common serving presets
const SERVING_PRESETS = [
  { name: '100g', servingSize: 100, unit: 'g' as const },
  { name: '1 serving (30g)', servingSize: 30, unit: 'g' as const },
  { name: '1 cup (240ml)', servingSize: 240, unit: 'ml' as const },
  { name: '1 tablespoon (15g)', servingSize: 15, unit: 'g' as const },
  { name: '1 teaspoon (5g)', servingSize: 5, unit: 'g' as const },
  { name: '1 piece', servingSize: 0, unit: 'g' as const },
  { name: '1 can (330ml)', servingSize: 330, unit: 'ml' as const },
  { name: '1 bottle (500ml)', servingSize: 500, unit: 'ml' as const },
  { name: '1 slice', servingSize: 0, unit: 'g' as const },
  { name: '1 portion', servingSize: 0, unit: 'g' as const },
];

export const ServingTypesEditor: React.FC<ServingTypesEditorProps> = ({
  servingTypes,
  onChange,
  className = '',
}) => {
  const [showPresets, setShowPresets] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // Add a new serving type
  const handleAdd = useCallback(() => {
    const newServing: ServingType = {
      id: generateId(),
      name: '',
      servingSize: 100,
      unit: 'g',
      isDefault: servingTypes.length === 0, // First one is default
    };
    onChange([...servingTypes, newServing]);
    setEditingId(newServing.id);
  }, [servingTypes, onChange]);

  // Add from preset
  const handleAddPreset = useCallback((preset: typeof SERVING_PRESETS[0]) => {
    const newServing: ServingType = {
      id: generateId(),
      name: preset.name,
      servingSize: preset.servingSize,
      unit: preset.unit,
      isDefault: servingTypes.length === 0,
    };
    onChange([...servingTypes, newServing]);
    setShowPresets(false);
  }, [servingTypes, onChange]);

  // Update a serving type
  const handleUpdate = useCallback((id: string, updates: Partial<ServingType>) => {
    onChange(
      servingTypes.map(s => (s.id === id ? { ...s, ...updates } : s))
    );
  }, [servingTypes, onChange]);

  // Remove a serving type
  const handleRemove = useCallback((id: string) => {
    const updated = servingTypes.filter(s => s.id !== id);
    // If we removed the default, make the first one default
    if (updated.length > 0 && !updated.some(s => s.isDefault)) {
      updated[0].isDefault = true;
    }
    onChange(updated);
  }, [servingTypes, onChange]);

  // Set as default
  const handleSetDefault = useCallback((id: string) => {
    onChange(
      servingTypes.map(s => ({ ...s, isDefault: s.id === id }))
    );
  }, [servingTypes, onChange]);

  // Move serving up/down
  const handleMove = useCallback((id: string, direction: 'up' | 'down') => {
    const index = servingTypes.findIndex(s => s.id === id);
    if (index === -1) return;

    const newIndex = direction === 'up' ? index - 1 : index + 1;
    if (newIndex < 0 || newIndex >= servingTypes.length) return;

    const updated = [...servingTypes];
    [updated[index], updated[newIndex]] = [updated[newIndex], updated[index]];
    onChange(updated);
  }, [servingTypes, onChange]);

  return (
    <div className={`space-y-3 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <label className="block text-xs font-medium text-gray-500">
          Serving Options ({servingTypes.length})
        </label>
        <div className="flex gap-2">
          <div className="relative">
            <button
              type="button"
              onClick={() => setShowPresets(!showPresets)}
              className="px-2 py-1 text-xs text-blue-600 hover:bg-blue-50 rounded transition-colors"
            >
              + Add Preset
            </button>
            {showPresets && (
              <div className="absolute right-0 top-full mt-1 w-48 bg-white border border-gray-200 rounded-lg shadow-lg z-10 max-h-64 overflow-auto">
                {SERVING_PRESETS.map((preset, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => handleAddPreset(preset)}
                    className="w-full px-3 py-2 text-left text-sm hover:bg-gray-50 flex items-center justify-between"
                  >
                    <span>{preset.name}</span>
                    <span className="text-gray-400 text-xs">
                      {preset.servingSize > 0 ? `${preset.servingSize}${preset.unit}` : 'custom'}
                    </span>
                  </button>
                ))}
              </div>
            )}
          </div>
          <button
            type="button"
            onClick={handleAdd}
            className="px-2 py-1 text-xs text-green-600 hover:bg-green-50 rounded transition-colors"
          >
            + Custom
          </button>
        </div>
      </div>

      {/* Serving types list */}
      {servingTypes.length === 0 ? (
        <div className="text-center py-6 bg-gray-50 rounded-lg border border-dashed border-gray-200">
          <svg className="w-8 h-8 mx-auto text-gray-300 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          <p className="text-sm text-gray-500">No serving types defined</p>
          <p className="text-xs text-gray-400 mt-1">Add serving options for users to choose from</p>
        </div>
      ) : (
        <div className="space-y-2">
          {servingTypes.map((serving, index) => (
            <div
              key={serving.id}
              className={`relative p-3 rounded-lg border transition-all ${
                serving.isDefault
                  ? 'bg-blue-50 border-blue-200'
                  : 'bg-white border-gray-200 hover:border-gray-300'
              }`}
            >
              {/* Default badge */}
              {serving.isDefault && (
                <span className="absolute -top-2 left-3 px-2 py-0.5 bg-blue-500 text-white text-[10px] font-medium rounded">
                  DEFAULT
                </span>
              )}

              <div className="flex items-start gap-3">
                {/* Reorder buttons */}
                <div className="flex flex-col gap-0.5 pt-1">
                  <button
                    type="button"
                    onClick={() => handleMove(serving.id, 'up')}
                    disabled={index === 0}
                    className="p-0.5 text-gray-400 hover:text-gray-600 disabled:opacity-30 disabled:cursor-not-allowed"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
                    </svg>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleMove(serving.id, 'down')}
                    disabled={index === servingTypes.length - 1}
                    className="p-0.5 text-gray-400 hover:text-gray-600 disabled:opacity-30 disabled:cursor-not-allowed"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                </div>

                {/* Serving details */}
                <div className="flex-1 grid grid-cols-3 gap-2">
                  {/* Name */}
                  <div className="col-span-3 sm:col-span-1">
                    <label className="block text-[10px] text-gray-400 mb-0.5">Name</label>
                    <input
                      type="text"
                      value={serving.name}
                      onChange={(e) => handleUpdate(serving.id, { name: e.target.value })}
                      placeholder="e.g., 1 slice"
                      className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                      onFocus={() => setEditingId(serving.id)}
                      onBlur={() => setEditingId(null)}
                      autoFocus={editingId === serving.id && !serving.name}
                    />
                  </div>

                  {/* Size */}
                  <div>
                    <label className="block text-[10px] text-gray-400 mb-0.5">Size</label>
                    <input
                      type="number"
                      value={serving.servingSize || ''}
                      onChange={(e) => handleUpdate(serving.id, { servingSize: parseFloat(e.target.value) || 0 })}
                      placeholder="100"
                      min="0"
                      step="0.1"
                      className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                    />
                  </div>

                  {/* Unit */}
                  <div>
                    <label className="block text-[10px] text-gray-400 mb-0.5">Unit</label>
                    <select
                      value={serving.unit}
                      onChange={(e) => handleUpdate(serving.id, { unit: e.target.value as 'g' | 'ml' })}
                      className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white"
                    >
                      <option value="g">g (grams)</option>
                      <option value="ml">ml (milliliters)</option>
                    </select>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 pt-4">
                  {!serving.isDefault && (
                    <button
                      type="button"
                      onClick={() => handleSetDefault(serving.id)}
                      className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
                      title="Set as default"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                      </svg>
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => handleRemove(serving.id)}
                    className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                    title="Remove"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Help text */}
      <p className="text-xs text-gray-400">
        The default serving will be shown first when users add this food. Other options appear in the serving selector.
      </p>
    </div>
  );
};

export default ServingTypesEditor;
