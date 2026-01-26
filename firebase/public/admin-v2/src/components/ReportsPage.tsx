/**
 * Reports Page
 * Review and manage user-submitted food reports/corrections
 */

import React, { useState, useEffect, useCallback } from 'react';

// Types
interface FoodReport {
  id: string;
  foodId: string;
  foodName: string;
  brandName?: string;
  barcode?: string;
  reportType: string;
  description: string;
  status: 'pending' | 'in_progress' | 'resolved' | 'dismissed';
  userId?: string;
  createdAt: string;
  sourceIndex?: string;
  food?: {
    id?: string;
    objectID?: string;
    name?: string;
    brand?: string;
    barcode?: string;
    calories?: number;
    protein?: number;
    carbs?: number;
    fat?: number;
    fiber?: number;
    sugar?: number;
    salt?: number;
    sodium?: number;
    saturatedFat?: number;
    servingDescription?: string;
    servingSizeG?: number;
    servingUnit?: string;
    category?: string;
    ingredients?: string | string[];
    imageUrl?: string;
    _sourceIndex?: string;
    sourceIndex?: string;
  };
  suggestedCorrections?: {
    foodName?: string;
    brandName?: string;
    barcode?: string;
    servingSize?: string;
    ingredients?: string;
    nutrition?: {
      calories?: number;
      protein?: number;
      carbohydrates?: number;
      fat?: number;
      fiber?: number;
      sugar?: number;
      salt?: number;
      saturatedFat?: number;
    };
  };
}

interface EditableFood {
  name: string;
  brandName: string;
  barcode: string;
  servingDescription: string;
  servingSizeG: string;
  servingUnit: string;
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
}

// API base URL
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

export const ReportsPage: React.FC<{ onBack: () => void }> = ({ onBack }) => {
  const [reports, setReports] = useState<FoodReport[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'in_progress' | 'resolved' | 'dismissed'>('pending');
  const [selectedReport, setSelectedReport] = useState<FoodReport | null>(null);
  const [selectedReportIds, setSelectedReportIds] = useState<Set<string>>(new Set());
  const [editableFood, setEditableFood] = useState<EditableFood | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [isApplyingAI, setIsApplyingAI] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  // Show toast notification
  const showToast = (message: string, type: 'success' | 'error' | 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Load reports from API
  const loadReports = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE}/getUserReports`);
      const result = await response.json();
      if (result.success) {
        setReports(result.reports || []);
      } else {
        showToast('Error loading reports', 'error');
      }
    } catch (error) {
      console.error('Error loading reports:', error);
      showToast('Error loading reports', 'error');
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Initial load
  useEffect(() => {
    loadReports();
  }, [loadReports]);

  // Filter reports
  const filteredReports = reports.filter(r => {
    if (filter === 'all') return true;
    return r.status === filter;
  });

  // Status counts
  const statusCounts = {
    all: reports.length,
    pending: reports.filter(r => r.status === 'pending').length,
    in_progress: reports.filter(r => r.status === 'in_progress').length,
    resolved: reports.filter(r => r.status === 'resolved').length,
    dismissed: reports.filter(r => r.status === 'dismissed').length,
  };

  // Open report detail panel
  const openReport = (report: FoodReport) => {
    setSelectedReport(report);
    const food = report.food || {};
    setEditableFood({
      name: food.name || report.foodName || '',
      brandName: food.brand || report.brandName || '',
      barcode: food.barcode || report.barcode || '',
      servingDescription: food.servingDescription || '',
      servingSizeG: food.servingSizeG?.toString() || '',
      servingUnit: food.servingUnit || 'g',
      category: food.category || '',
      ingredients: Array.isArray(food.ingredients) ? food.ingredients.join(', ') : (food.ingredients || ''),
      calories: food.calories?.toString() || '',
      protein: food.protein?.toString() || '',
      carbs: food.carbs?.toString() || '',
      fat: food.fat?.toString() || '',
      fiber: food.fiber?.toString() || '',
      sugar: food.sugar?.toString() || '',
      salt: food.salt?.toString() || '',
      saturatedFat: food.saturatedFat?.toString() || '',
    });
  };

  // Close detail panel
  const closeReport = () => {
    setSelectedReport(null);
    setEditableFood(null);
  };

  // Apply AI suggestions
  const applyAISuggestions = async () => {
    if (!selectedReport || !editableFood) return;

    setIsApplyingAI(true);
    try {
      const name = editableFood.name;
      const brand = editableFood.brandName;

      const response = await fetch(`${API_BASE}/aiAnalyzeFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, brand }),
      });

      const result = await response.json();
      if (result.success && result.data) {
        const { suggestions, nutrition } = result.data;

        setEditableFood(prev => {
          if (!prev) return prev;
          return {
            ...prev,
            ...(suggestions?.foodName && { name: suggestions.foodName }),
            ...(suggestions?.brandName && { brandName: suggestions.brandName }),
            ...(suggestions?.barcode && { barcode: suggestions.barcode }),
            ...(suggestions?.servingSize && { servingDescription: suggestions.servingSize }),
            ...(suggestions?.ingredients && { ingredients: Array.isArray(suggestions.ingredients) ? suggestions.ingredients.join(', ') : suggestions.ingredients }),
            ...(nutrition?.calories !== undefined && { calories: nutrition.calories.toString() }),
            ...(nutrition?.protein !== undefined && { protein: nutrition.protein.toString() }),
            ...(nutrition?.carbohydrates !== undefined && { carbs: nutrition.carbohydrates.toString() }),
            ...(nutrition?.fat !== undefined && { fat: nutrition.fat.toString() }),
            ...(nutrition?.fiber !== undefined && { fiber: nutrition.fiber.toString() }),
            ...(nutrition?.sugar !== undefined && { sugar: nutrition.sugar.toString() }),
            ...(nutrition?.salt !== undefined && { salt: nutrition.salt.toString() }),
            ...(nutrition?.saturatedFat !== undefined && { saturatedFat: nutrition.saturatedFat.toString() }),
          };
        });

        showToast('AI suggestions applied', 'success');
      } else {
        showToast('No AI suggestions available', 'info');
      }
    } catch (error) {
      console.error('Error getting AI suggestions:', error);
      showToast('Error getting AI suggestions', 'error');
    } finally {
      setIsApplyingAI(false);
    }
  };

  // Save food changes
  const saveFood = async (resolveReport: boolean = false) => {
    if (!selectedReport || !editableFood) return;

    setIsSaving(true);
    try {
      const foodId = selectedReport.food?.id || selectedReport.food?.objectID || selectedReport.foodId;
      const foodIndex = selectedReport.food?._sourceIndex || selectedReport.sourceIndex || 'uk_foods_cleaned';

      const payload = {
        foodId,
        indexName: foodIndex,
        updates: {
          foodName: editableFood.name,
          brandName: editableFood.brandName,
          barcode: editableFood.barcode,
          servingSize: editableFood.servingDescription,
          servingSizeG: parseFloat(editableFood.servingSizeG) || null,
          servingUnit: editableFood.servingUnit,
          category: editableFood.category,
          ingredients: editableFood.ingredients.split(',').map(i => i.trim()).filter(i => i),
          nutrition: {
            calories: parseFloat(editableFood.calories) || null,
            protein: parseFloat(editableFood.protein) || null,
            carbs: parseFloat(editableFood.carbs) || null,
            fat: parseFloat(editableFood.fat) || null,
            fiber: parseFloat(editableFood.fiber) || null,
            sugar: parseFloat(editableFood.sugar) || null,
            salt: parseFloat(editableFood.salt) || null,
            sodium: Math.round((parseFloat(editableFood.salt) || 0) * 1000 / 2.5) || null,
            saturatedFat: parseFloat(editableFood.saturatedFat) || null,
          },
        },
      };

      const response = await fetch(`${API_BASE}/adminSaveFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const result = await response.json();
      if (result.success) {
        showToast('Food saved successfully', 'success');

        if (resolveReport) {
          await updateReportStatus(selectedReport.id, 'resolved');
          closeReport();
        }
      } else {
        showToast(result.error || 'Error saving food', 'error');
      }
    } catch (error) {
      console.error('Error saving food:', error);
      showToast('Error saving food', 'error');
    } finally {
      setIsSaving(false);
    }
  };

  // Update report status
  const updateReportStatus = async (reportId: string, status: FoodReport['status']) => {
    try {
      const response = await fetch(`${API_BASE}/updateUserReport`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reportId, status }),
      });

      const result = await response.json();
      if (result.success) {
        setReports(prev => prev.map(r => r.id === reportId ? { ...r, status } : r));
        showToast('Report updated', 'success');
      } else {
        showToast('Error updating report', 'error');
      }
    } catch (error) {
      console.error('Error updating report:', error);
      showToast('Error updating report', 'error');
    }
  };

  // Dismiss report
  const dismissReport = async () => {
    if (!selectedReport) return;
    await updateReportStatus(selectedReport.id, 'dismissed');
    closeReport();
  };

  // Delete report
  const deleteReport = async (reportId: string) => {
    if (!confirm('Delete this report? This cannot be undone.')) return;

    try {
      const response = await fetch(`${API_BASE}/deleteUserReport`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reportId }),
      });

      const result = await response.json();
      if (result.success) {
        setReports(prev => prev.filter(r => r.id !== reportId));
        if (selectedReport?.id === reportId) closeReport();
        showToast('Report deleted', 'success');
      } else {
        showToast('Error deleting report', 'error');
      }
    } catch (error) {
      console.error('Error deleting report:', error);
      showToast('Error deleting report', 'error');
    }
  };

  // Delete reported food
  const deleteReportedFood = async () => {
    if (!selectedReport) return;
    if (!confirm('Delete this food from the database? This cannot be undone.')) return;

    try {
      const foodId = selectedReport.food?.id || selectedReport.food?.objectID || selectedReport.foodId;
      const indexName = selectedReport.food?._sourceIndex || selectedReport.sourceIndex || 'uk_foods_cleaned';

      const response = await fetch(`${API_BASE}/deleteFood`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ foodId, indexName }),
      });

      const result = await response.json();
      if (result.success) {
        await updateReportStatus(selectedReport.id, 'resolved');
        closeReport();
        showToast('Food deleted and report resolved', 'success');
      } else {
        showToast(result.error || 'Error deleting food', 'error');
      }
    } catch (error) {
      console.error('Error deleting food:', error);
      showToast('Error deleting food', 'error');
    }
  };

  // Toggle report selection
  const toggleSelection = (reportId: string) => {
    setSelectedReportIds(prev => {
      const next = new Set(prev);
      if (next.has(reportId)) {
        next.delete(reportId);
      } else {
        next.add(reportId);
      }
      return next;
    });
  };

  // Select/deselect all
  const toggleSelectAll = () => {
    if (selectedReportIds.size === filteredReports.length) {
      setSelectedReportIds(new Set());
    } else {
      setSelectedReportIds(new Set(filteredReports.map(r => r.id)));
    }
  };

  // Bulk delete
  const bulkDelete = async () => {
    if (selectedReportIds.size === 0) return;
    if (!confirm(`Delete ${selectedReportIds.size} report(s)? This cannot be undone.`)) return;

    let deleted = 0;
    for (const id of selectedReportIds) {
      try {
        const response = await fetch(`${API_BASE}/deleteUserReport`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ reportId: id }),
        });
        const result = await response.json();
        if (result.success) {
          deleted++;
          setReports(prev => prev.filter(r => r.id !== id));
        }
      } catch (error) {
        console.error('Error deleting report:', id, error);
      }
    }

    setSelectedReportIds(new Set());
    showToast(`Deleted ${deleted} reports`, 'success');
  };

  // Format date
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  };

  // Status colors
  const statusColors: Record<FoodReport['status'], string> = {
    pending: 'bg-yellow-100 text-yellow-800',
    in_progress: 'bg-blue-100 text-blue-800',
    resolved: 'bg-green-100 text-green-800',
    dismissed: 'bg-gray-100 text-gray-600',
  };

  const statusLabels: Record<FoodReport['status'], string> = {
    pending: 'Pending',
    in_progress: 'In Progress',
    resolved: 'Resolved',
    dismissed: 'Dismissed',
  };

  return (
    <div className="h-full flex flex-col bg-gray-50">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg ${
          toast.type === 'success' ? 'bg-green-500 text-white' :
          toast.type === 'error' ? 'bg-red-500 text-white' :
          'bg-blue-500 text-white'
        }`}>
          {toast.message}
        </div>
      )}

      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={onBack} className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <div>
              <h1 className="text-xl font-semibold text-gray-900">User Reports</h1>
              <p className="text-sm text-gray-500">Review and resolve user-submitted food corrections</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={loadReports}
              disabled={isLoading}
              className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              <svg className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Refresh
            </button>

            {selectedReportIds.size > 0 && (
              <button
                onClick={bulkDelete}
                className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-red-600 hover:bg-red-700 rounded-lg"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete ({selectedReportIds.size})
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="bg-white border-b border-gray-200 px-6">
        <div className="flex items-center justify-between">
          <div className="flex gap-1">
            {(['all', 'pending', 'in_progress', 'resolved', 'dismissed'] as const).map(status => (
              <button
                key={status}
                onClick={() => setFilter(status)}
                className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  filter === status ? 'border-primary-600 text-primary-600' : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                {status === 'all' ? 'All' : status === 'in_progress' ? 'In Progress' : status.charAt(0).toUpperCase() + status.slice(1)}
                {' '}
                <span className={`inline-flex items-center justify-center px-2 py-0.5 rounded-full text-xs ${
                  filter === status ? 'bg-primary-100 text-primary-700' : 'bg-gray-100 text-gray-600'
                }`}>
                  {statusCounts[status]}
                </span>
              </button>
            ))}
          </div>

          {filteredReports.length > 0 && (
            <label className="flex items-center gap-2 text-sm text-gray-600 cursor-pointer">
              <input
                type="checkbox"
                checked={selectedReportIds.size === filteredReports.length && filteredReports.length > 0}
                onChange={toggleSelectAll}
                className="w-4 h-4 text-primary-600 rounded"
              />
              Select all
            </label>
          )}
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Reports list */}
        <div className={`flex-1 overflow-auto p-6 transition-all ${selectedReport ? 'w-1/2' : 'w-full'}`}>
          {isLoading ? (
            <div className="flex items-center justify-center h-64">
              <div className="flex flex-col items-center gap-3">
                <svg className="w-8 h-8 animate-spin text-primary-600" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                <span className="text-gray-500">Loading reports...</span>
              </div>
            </div>
          ) : filteredReports.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-64 text-gray-500">
              <svg className="w-16 h-16 mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-lg font-medium">No reports found</p>
              <p className="text-sm">No {filter === 'all' ? '' : filter} reports to display</p>
            </div>
          ) : (
            <div className="grid gap-3">
              {filteredReports.map(report => (
                <div
                  key={report.id}
                  className={`bg-white rounded-xl border p-4 transition-all cursor-pointer hover:shadow-md ${
                    selectedReport?.id === report.id ? 'border-primary-500 ring-2 ring-primary-100' : 'border-gray-200'
                  }`}
                  onClick={() => openReport(report)}
                >
                  <div className="flex items-start gap-3">
                    {/* Checkbox */}
                    <input
                      type="checkbox"
                      checked={selectedReportIds.has(report.id)}
                      onChange={(e) => {
                        e.stopPropagation();
                        toggleSelection(report.id);
                      }}
                      onClick={(e) => e.stopPropagation()}
                      className="mt-1 w-4 h-4 text-primary-600 rounded"
                    />

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <h3 className="font-semibold text-gray-900 truncate">
                            {report.foodName || 'Unknown Food'}
                          </h3>
                          {report.brandName && (
                            <p className="text-sm text-gray-500">{report.brandName}</p>
                          )}
                        </div>
                        <span className={`flex-shrink-0 px-2.5 py-1 rounded-full text-xs font-medium ${statusColors[report.status]}`}>
                          {statusLabels[report.status]}
                        </span>
                      </div>

                      <div className="mt-2 flex items-center gap-3 text-xs text-gray-500 flex-wrap">
                        <span className="flex items-center gap-1">
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                          </svg>
                          {report.reportType || 'General'}
                        </span>
                        <span className="flex items-center gap-1">
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          {formatDate(report.createdAt)}
                        </span>
                        {report.barcode && (
                          <span className="font-mono">{report.barcode}</span>
                        )}
                        {(report.food?._sourceIndex || report.sourceIndex) && (
                          <span className="flex items-center gap-1 px-2 py-0.5 bg-blue-50 text-blue-700 rounded font-medium">
                            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
                            </svg>
                            {report.food?._sourceIndex || report.sourceIndex}
                          </span>
                        )}
                      </div>

                      <p className="mt-2 text-sm text-gray-600 line-clamp-2">
                        {report.description || 'No description provided.'}
                      </p>
                    </div>
                  </div>

                  {/* Quick actions */}
                  <div className="mt-3 flex items-center gap-2 pt-3 border-t border-gray-100">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        openReport(report);
                      }}
                      className="flex-1 px-3 py-1.5 text-xs font-medium text-primary-700 bg-primary-50 hover:bg-primary-100 rounded-lg transition-colors"
                    >
                      Review
                    </button>
                    {report.status === 'pending' && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          updateReportStatus(report.id, 'dismissed');
                        }}
                        className="px-3 py-1.5 text-xs font-medium text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                      >
                        Dismiss
                      </button>
                    )}
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteReport(report.id);
                      }}
                      className="px-3 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Detail panel */}
        {selectedReport && editableFood && (
          <div className="w-1/2 border-l border-gray-200 bg-white overflow-auto">
            <div className="p-6">
              {/* Panel header */}
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">Review Report</h2>
                  <p className="text-sm text-gray-500">Edit and verify food information</p>
                </div>
                <button
                  onClick={closeReport}
                  className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Report info */}
              <div className="mb-6 p-4 bg-yellow-50 rounded-xl border border-yellow-100">
                <div className="flex items-start gap-3">
                  <svg className="w-5 h-5 text-yellow-600 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <p className="font-medium text-yellow-800">{selectedReport.reportType || 'General Report'}</p>
                      {(selectedReport.food?._sourceIndex || selectedReport.sourceIndex) && (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium">
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
                          </svg>
                          {selectedReport.food?._sourceIndex || selectedReport.sourceIndex}
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-yellow-700 mt-1">{selectedReport.description || 'No description provided.'}</p>
                    <p className="text-xs text-yellow-600 mt-2">Reported {formatDate(selectedReport.createdAt)}</p>
                  </div>
                </div>
              </div>

              {/* AI Suggestions button */}
              <button
                onClick={applyAISuggestions}
                disabled={isApplyingAI}
                className="w-full mb-6 flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-xl transition-colors disabled:opacity-50"
              >
                {isApplyingAI ? (
                  <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                )}
                {isApplyingAI ? 'Analyzing...' : 'Apply AI Suggestions'}
              </button>

              {/* Food form */}
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Food Name</label>
                    <input
                      type="text"
                      value={editableFood.name}
                      onChange={(e) => setEditableFood({ ...editableFood, name: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Brand Name</label>
                    <input
                      type="text"
                      value={editableFood.brandName}
                      onChange={(e) => setEditableFood({ ...editableFood, brandName: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Barcode</label>
                    <input
                      type="text"
                      value={editableFood.barcode}
                      onChange={(e) => setEditableFood({ ...editableFood, barcode: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Category</label>
                    <input
                      type="text"
                      value={editableFood.category}
                      onChange={(e) => setEditableFood({ ...editableFood, category: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Serving Size</label>
                    <input
                      type="text"
                      value={editableFood.servingDescription}
                      onChange={(e) => setEditableFood({ ...editableFood, servingDescription: e.target.value })}
                      placeholder="e.g., 1 slice"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Size (g/ml)</label>
                    <input
                      type="number"
                      value={editableFood.servingSizeG}
                      onChange={(e) => setEditableFood({ ...editableFood, servingSizeG: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">Unit</label>
                    <select
                      value={editableFood.servingUnit}
                      onChange={(e) => setEditableFood({ ...editableFood, servingUnit: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                    >
                      <option value="g">g</option>
                      <option value="ml">ml</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Ingredients</label>
                  <textarea
                    value={editableFood.ingredients}
                    onChange={(e) => setEditableFood({ ...editableFood, ingredients: e.target.value })}
                    rows={3}
                    placeholder="Enter ingredients separated by commas..."
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                  />
                </div>

                {/* Nutrition */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2">Nutrition (per 100g)</label>
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
                            value={editableFood[key as keyof EditableFood]}
                            onChange={(e) => setEditableFood({ ...editableFood, [key]: e.target.value })}
                            className="w-full px-2 py-1.5 pr-6 border border-gray-300 rounded text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                          />
                          <span className="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-gray-400">{unit}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="mt-8 pt-6 border-t border-gray-200 space-y-3">
                <div className="flex gap-3">
                  <button
                    onClick={() => saveFood(true)}
                    disabled={isSaving}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 rounded-xl transition-colors disabled:opacity-50"
                  >
                    {isSaving ? (
                      <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                      </svg>
                    ) : (
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                    Save & Resolve
                  </button>
                  <button
                    onClick={() => saveFood(false)}
                    disabled={isSaving}
                    className="px-4 py-3 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors disabled:opacity-50"
                  >
                    Save Only
                  </button>
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={dismissReport}
                    className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-xl transition-colors"
                  >
                    Dismiss Report
                  </button>
                  <button
                    onClick={deleteReportedFood}
                    className="px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-50 rounded-xl transition-colors"
                  >
                    Delete Food
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportsPage;
