/**
 * Food Detail Modal Component
 * Full-featured food editing modal with serving types management
 */

import React, { useState, useCallback } from 'react';
import { ServingTypesEditor, ServingType } from './ServingTypesEditor';
import { UnifiedFood } from '../types';

// Cloud Function for saving
const FUNCTIONS_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

interface FoodDetailModalProps {
  food: UnifiedFood;
  onClose: () => void;
  onSaved: (updatedFood: UnifiedFood) => void;
}

interface EditableFields {
  name: string;
  brandName: string;
  barcode: string;
  servingDescription: string;
  servingSizeG: string;
  servingUnit: 'g' | 'ml';
  servingTypes: ServingType[];
  category: string;
  ingredients: string;
  calories: string;
  protein: string;
  carbs: string;
  fat: string;
  fiber: string;
  sugar: string;
  salt: string;
  saturatedFat: string;
  imageUrl: string;
  isPerUnit: boolean;
}

export const FoodDetailModal: React.FC<FoodDetailModalProps> = ({
  food,
  onClose,
  onSaved,
}) => {
  const [isSaving, setIsSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Parse existing serving types
  const parseServingTypes = useCallback((): ServingType[] => {
    const unit = food.suggestedServingUnit === 'ml' ? 'ml' : 'g';

    // Try servingTypes field first (new format)
    if (food.servingTypes && Array.isArray(food.servingTypes)) {
      return (food.servingTypes as any[]).map((st, idx) => ({
        id: st.id || `serving_${idx}_${Date.now()}`,
        name: st.name || '',
        servingSize: st.servingSize || st.serving_g || 0,
        unit: st.unit || unit,
        isDefault: st.isDefault || idx === 0,
      }));
    }

    // Fall back to portions (iOS format)
    if (food.portions && Array.isArray(food.portions)) {
      return (food.portions as any[]).map((p, idx) => ({
        id: `portion_${idx}_${Date.now()}`,
        name: p.name || '',
        servingSize: p.serving_g || 0,
        unit: unit,
        isDefault: idx === 0,
      }));
    }

    // Create default from existing fields
    if (food.servingDescription || food.servingSizeG) {
      return [{
        id: `default_${Date.now()}`,
        name: food.servingDescription || `${food.servingSizeG || 100}${unit}`,
        servingSize: food.servingSizeG || 100,
        unit: unit,
        isDefault: true,
      }];
    }

    return [];
  }, [food]);

  const [fields, setFields] = useState<EditableFields>(() => ({
    name: food.name || '',
    brandName: food.brandName || '',
    barcode: food.barcode || '',
    servingDescription: food.servingDescription || '',
    servingSizeG: food.servingSizeG?.toString() || '',
    servingUnit: food.suggestedServingUnit === 'ml' ? 'ml' : 'g',
    servingTypes: parseServingTypes(),
    category: food.category || '',
    ingredients: food.ingredientsText || (Array.isArray(food.ingredients) ? food.ingredients.join(', ') : food.ingredients || ''),
    calories: food.calories?.toString() || '',
    protein: food.protein?.toString() || '',
    carbs: food.carbs?.toString() || '',
    fat: food.fat?.toString() || '',
    fiber: food.fiber?.toString() || '',
    sugar: food.sugar?.toString() || '',
    salt: food.salt?.toString() || '',
    saturatedFat: food.saturatedFat?.toString() || '',
    imageUrl: food.imageUrl || '',
    isPerUnit: food.isPerUnit || false,
  }));

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Handle serving types change
  const handleServingTypesChange = useCallback((servingTypes: ServingType[]) => {
    const defaultServing = servingTypes.find(s => s.isDefault) || servingTypes[0];
    setFields(prev => ({
      ...prev,
      servingTypes,
      servingDescription: defaultServing?.name || prev.servingDescription,
      servingSizeG: defaultServing?.servingSize?.toString() || prev.servingSizeG,
      servingUnit: defaultServing?.unit || prev.servingUnit,
    }));
  }, []);

  // Save handler
  const handleSave = useCallback(async () => {
    setIsSaving(true);

    try {
      const defaultServing = fields.servingTypes.find(s => s.isDefault) || fields.servingTypes[0];

      // Prepare serving types for save
      const servingTypesPayload = fields.servingTypes.length > 0 ? fields.servingTypes.map(st => ({
        id: st.id,
        name: st.name,
        servingSize: st.servingSize,
        unit: st.unit,
        isDefault: st.isDefault,
      })) : null;

      // Also create portions for iOS compatibility
      const portionsPayload = fields.servingTypes.length > 0 ? fields.servingTypes.map(st => ({
        name: st.name,
        serving_g: st.servingSize,
        calories: 0,
      })) : null;

      const payload = {
        foodId: food.objectID,
        indexName: food._sourceIndex,
        updates: {
          foodName: fields.name,
          brandName: fields.brandName,
          barcode: fields.barcode,
          servingSize: defaultServing?.name || fields.servingDescription,
          servingSizeG: defaultServing?.servingSize || parseFloat(fields.servingSizeG) || null,
          servingUnit: defaultServing?.unit || fields.servingUnit,
          suggestedServingUnit: defaultServing?.unit || fields.servingUnit,
          suggestedServingSize: defaultServing?.servingSize || null,
          suggestedServingDescription: defaultServing?.name || null,
          servingTypes: servingTypesPayload,
          portions: portionsPayload,
          category: fields.category,
          ingredients: fields.ingredients.split(',').map(i => i.trim()).filter(i => i),
          imageUrl: fields.imageUrl || null,
          isPerUnit: fields.isPerUnit,
          nutrition: {
            calories: parseFloat(fields.calories) || null,
            protein: parseFloat(fields.protein) || null,
            carbs: parseFloat(fields.carbs) || null,
            fat: parseFloat(fields.fat) || null,
            fiber: parseFloat(fields.fiber) || null,
            sugar: parseFloat(fields.sugar) || null,
            salt: parseFloat(fields.salt) || null,
            sodium: Math.round((parseFloat(fields.salt) || 0) * 1000 / 2.5) || null,
            saturatedFat: parseFloat(fields.saturatedFat) || null,
          },
        },
      };

      console.log('💾 SAVING FOOD:', payload);

      const response = await fetch(`${FUNCTIONS_BASE}/adminSaveFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const result = await response.json();

      if (result.success) {
        showToast('Food saved successfully', 'success');
        // Return updated food object
        const updatedFood: UnifiedFood = {
          ...food,
          name: fields.name,
          brandName: fields.brandName || null,
          barcode: fields.barcode || null,
          servingDescription: defaultServing?.name || fields.servingDescription || null,
          servingSizeG: defaultServing?.servingSize || parseFloat(fields.servingSizeG) || null,
          suggestedServingUnit: defaultServing?.unit || fields.servingUnit,
          suggestedServingSize: defaultServing?.servingSize || null,
          suggestedServingDescription: defaultServing?.name || null,
          servingTypes: servingTypesPayload,
          portions: portionsPayload,
          category: fields.category || null,
          calories: parseFloat(fields.calories) || 0,
          protein: parseFloat(fields.protein) || 0,
          carbs: parseFloat(fields.carbs) || 0,
          fat: parseFloat(fields.fat) || 0,
          fiber: parseFloat(fields.fiber) || 0,
          sugar: parseFloat(fields.sugar) || 0,
          salt: parseFloat(fields.salt) || 0,
          saturatedFat: parseFloat(fields.saturatedFat) || null,
          imageUrl: fields.imageUrl || null,
          isPerUnit: fields.isPerUnit,
        };
        onSaved(updatedFood);
        setTimeout(onClose, 1000);
      } else {
        showToast(result.error || 'Error saving food', 'error');
      }
    } catch (error) {
      console.error('Error saving food:', error);
      showToast('Error saving food', 'error');
    } finally {
      setIsSaving(false);
    }
  }, [food, fields, onClose, onSaved]);

  return (
    <div
      className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-[60] px-4 py-3 rounded-lg shadow-lg ${
          toast.type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
        }`}>
          {toast.message}
        </div>
      )}

      <div
        className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-gradient-to-r from-blue-50 to-indigo-50">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Edit Food</h2>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-700 rounded">
                {food._sourceIndex}
              </span>
              {food.objectID && (
                <span className="text-xs text-gray-400 font-mono">{food.objectID}</span>
              )}
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-white/50 rounded-lg transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto p-6">
          <div className="space-y-6">
            {/* Basic Info */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Food Name</label>
                <input
                  type="text"
                  value={fields.name}
                  onChange={e => setFields({ ...fields, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Brand</label>
                <input
                  type="text"
                  value={fields.brandName}
                  onChange={e => setFields({ ...fields, brandName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Barcode</label>
                <input
                  type="text"
                  value={fields.barcode}
                  onChange={e => setFields({ ...fields, barcode: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Category</label>
                <input
                  type="text"
                  value={fields.category}
                  onChange={e => setFields({ ...fields, category: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Nutrition Type</label>
                <select
                  value={fields.isPerUnit ? 'unit' : '100g'}
                  onChange={e => setFields({ ...fields, isPerUnit: e.target.value === 'unit' })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
                >
                  <option value="100g">Per 100g/ml</option>
                  <option value="unit">Per Unit</option>
                </select>
              </div>
            </div>

            {/* Image URL */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Image URL</label>
              <div className="flex gap-2">
                <input
                  type="url"
                  value={fields.imageUrl}
                  onChange={e => setFields({ ...fields, imageUrl: e.target.value })}
                  placeholder="https://example.com/image.jpg"
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
                {fields.imageUrl && (
                  <img
                    src={fields.imageUrl}
                    alt=""
                    className="w-10 h-10 object-cover rounded border border-gray-200"
                    onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                )}
              </div>
            </div>

            {/* Serving Types Section */}
            <div className="p-4 bg-indigo-50 rounded-xl border border-indigo-100">
              <div className="flex items-center gap-2 mb-3">
                <svg className="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
                </svg>
                <h3 className="font-medium text-indigo-900">Serving Options</h3>
              </div>
              <ServingTypesEditor
                servingTypes={fields.servingTypes}
                onChange={handleServingTypesChange}
              />
            </div>

            {/* Ingredients */}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Ingredients</label>
              <textarea
                value={fields.ingredients}
                onChange={e => setFields({ ...fields, ingredients: e.target.value })}
                rows={2}
                placeholder="Enter ingredients separated by commas..."
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            {/* Nutrition */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="block text-xs font-medium text-gray-500">
                  Nutrition {fields.isPerUnit ? '(per unit)' : `(per 100${fields.servingUnit})`}
                </label>
                <span className={`px-2 py-0.5 text-[10px] font-bold rounded-full ${
                  fields.servingUnit === 'g' ? 'bg-gray-100 text-gray-600' : 'bg-blue-100 text-blue-600'
                }`}>
                  {fields.servingUnit.toUpperCase()} MODE
                </span>
              </div>
              <div className="grid grid-cols-4 gap-3">
                {[
                  { key: 'calories', label: 'Calories', unit: 'kcal' },
                  { key: 'protein', label: 'Protein', unit: 'g' },
                  { key: 'carbs', label: 'Carbs', unit: 'g' },
                  { key: 'fat', label: 'Fat', unit: 'g' },
                  { key: 'saturatedFat', label: 'Sat Fat', unit: 'g' },
                  { key: 'fiber', label: 'Fibre', unit: 'g' },
                  { key: 'sugar', label: 'Sugar', unit: 'g' },
                  { key: 'salt', label: 'Salt', unit: 'g' },
                ].map(({ key, label, unit }) => (
                  <div key={key}>
                    <label className="block text-[10px] text-gray-400 mb-1">{label}</label>
                    <div className="relative">
                      <input
                        type="number"
                        step="0.1"
                        value={fields[key as keyof EditableFields] as string}
                        onChange={e => setFields({ ...fields, [key]: e.target.value })}
                        className="w-full px-2 py-1.5 pr-7 border border-gray-300 rounded text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      />
                      <span className="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-gray-400">{unit}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-end gap-3 bg-gray-50">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={isSaving}
            className={`px-4 py-2 text-sm font-medium text-white rounded-lg transition-colors flex items-center gap-2 ${
              isSaving ? 'bg-blue-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700'
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
                Save Changes
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default FoodDetailModal;
