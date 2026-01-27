/**
 * Main App Component
 * NutraSafe Food Database Manager
 */

import React, { useEffect, useState, useCallback } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { FoodGrid, Header, Sidebar, LoadingOverlay, OFFLookupModal, DuplicatesPanel, ImageProcessingPage, GoogleImageScraperPage, ReportsPage, MasterDatabaseBuilderPage, AnalyticsPage } from './components';
import { FoodCategorizerPage } from './components/FoodCategorizerPage';
import { useGridStore } from './store';
import { searchAllIndices, getIndexStats } from './services/algoliaService';
import { batchUpdateFoods, batchDeleteFoods, moveFoodsBetweenIndices, initializeFirebase } from './services/firebaseService';
import { detectDuplicates } from './utils/duplicateDetection';
import { ALGOLIA_INDICES, DatabaseStats } from './types';

// Initialize React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

// Initialize Firebase
initializeFirebase();

const AppContent: React.FC = () => {
  const {
    setFoods,
    setLoading,
    setLoadingProgress,
    setStats,
    setDuplicateGroups,
    getDirtyFoods,
    clearDirty,
    foods,
    isLoading,
    loadingMessage,
    loadingProgress,
    selectedFoodIds,
    getFoodById,
    deselectAll,
    setFoodReportIds,
  } = useGridStore();

  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isMoving, setIsMoving] = useState(false);
  const [isDetectingDuplicates, setIsDetectingDuplicates] = useState(false);
  const [showOFFModal, setShowOFFModal] = useState(false);
  const [showDuplicatesPanel, setShowDuplicatesPanel] = useState(false);
  const [currentView, setCurrentView] = useState<'grid' | 'image-processing' | 'google-scraper' | 'reports' | 'master-builder' | 'food-categorizer' | 'analytics'>('grid');
  const [pendingReportsCount, setPendingReportsCount] = useState(0);

  // Load pending reports count and food report IDs
  useEffect(() => {
    const loadReportsCount = async () => {
      try {
        const response = await fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/getUserReports');
        const result = await response.json();
        if (result.success) {
          const reports = result.reports || [];
          const pending = reports.filter((r: { status: string }) => r.status === 'pending').length;
          setPendingReportsCount(pending);

          // Extract unique food IDs from all reports
          const reportFoodIds = new Set<string>();
          reports.forEach((report: { foodId?: string; food?: { id?: string; objectID?: string } }) => {
            const foodId = report.food?.id || report.food?.objectID || report.foodId;
            if (foodId) reportFoodIds.add(foodId);
          });
          setFoodReportIds(reportFoodIds);
        }
      } catch (error) {
        console.error('Error loading reports count:', error);
      }
    };
    loadReportsCount();
  }, [setFoodReportIds]);

  // Load initial data
  const hasLoadedRef = React.useRef(false);

  const loadData = useCallback(async () => {
    if (hasLoadedRef.current) return; // Prevent multiple loads
    hasLoadedRef.current = true;
    setLoading(true, 'Loading food database...');
    setLoadingProgress(0);

    try {
      console.log('Starting data load...');

      // Get index stats first
      setLoading(true, 'Getting index stats...');
      const stats = await getIndexStats();
      console.log('Index stats:', stats);

      let totalFoods = 0;
      const byIndex: Record<string, number> = {};

      ALGOLIA_INDICES.forEach((index) => {
        byIndex[index] = stats[index]?.entries || 0;
        totalFoods += byIndex[index];
      });

      setLoadingProgress(10);
      console.log(`Total foods across indices: ${totalFoods}`);

      // Load foods from all indices (10 per index for faster initial load)
      setLoading(true, 'Loading foods from indices...');
      const { foods: allFoods } = await searchAllIndices('', [...ALGOLIA_INDICES], {
        hitsPerPage: 10,
      });

      console.log(`Loaded ${allFoods.length} foods`);
      setLoadingProgress(80);

      // Update stats
      const dbStats: DatabaseStats = {
        totalFoods,
        byIndex: byIndex as Record<typeof ALGOLIA_INDICES[number], number>,
        verified: allFoods.filter(f => f.isVerified).length,
        unverified: allFoods.filter(f => !f.isVerified).length,
        withIssues: allFoods.filter(f => f._reviewFlags.length > 0).length,
        duplicateGroups: 0,
        lastUpdated: new Date(),
      };

      setStats(dbStats);
      setFoods(allFoods);

      setLoadingProgress(100);
      console.log('Data load complete');
    } catch (error) {
      console.error('Error loading data:', error);
      alert(`Error loading data: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      setLoading(false);
    }
  }, [setLoading, setLoadingProgress, setStats, setFoods]);

  // Initial load (run once on mount)
  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Save dirty foods
  const handleSave = useCallback(async () => {
    const dirtyFoods = getDirtyFoods();
    if (dirtyFoods.length === 0) return;

    setIsSaving(true);

    try {
      const updates = dirtyFoods.map(food => ({
        food,
        updates: {
          name: food.name,
          brandName: food.brandName,
          barcode: food.barcode,
          ingredientsText: food.ingredientsText,
          calories: food.calories,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          saturatedFat: food.saturatedFat,
          fiber: food.fiber,
          sugar: food.sugar,
          sodium: food.sodium,
          salt: food.salt,
          servingDescription: food.servingDescription,
          servingSizeG: food.servingSizeG,
          isPerUnit: food.isPerUnit,
        },
      }));

      const result = await batchUpdateFoods(updates);

      if (result.success > 0) {
        clearDirty();
        console.log(`Saved ${result.success} foods`);
      }

      if (result.failed > 0) {
        console.error(`Failed to save ${result.failed} foods:`, result.errors);
        alert(`Failed to save ${result.failed} foods. Check console for details.`);
      }
    } catch (error) {
      console.error('Error saving:', error);
      alert('Error saving changes. Please try again.');
    } finally {
      setIsSaving(false);
    }
  }, [getDirtyFoods, clearDirty]);

  // Delete selected foods
  const handleDeleteSelected = useCallback(async () => {
    if (selectedFoodIds.length === 0) return;

    const confirmDelete = window.confirm(
      `Are you sure you want to delete ${selectedFoodIds.length} food(s)? This action cannot be undone.`
    );

    if (!confirmDelete) return;

    setIsDeleting(true);

    try {
      // Get the full food objects for selected IDs
      const foodsToDelete = selectedFoodIds
        .map(id => getFoodById(id))
        .filter((food): food is NonNullable<typeof food> => food !== undefined);

      if (foodsToDelete.length === 0) {
        alert('No foods found to delete.');
        return;
      }

      const result = await batchDeleteFoods(foodsToDelete);

      if (result.success > 0) {
        // Remove deleted foods from the local state
        const deletedIds = new Set(foodsToDelete.map(f => f._id));
        const remainingFoods = foods.filter(f => !deletedIds.has(f._id));
        setFoods(remainingFoods);
        deselectAll();
        console.log(`Deleted ${result.success} foods`);
      }

      if (result.failed > 0) {
        console.error(`Failed to delete ${result.failed} foods:`, result.errors);
        alert(`Failed to delete ${result.failed} foods. Check console for details.`);
      }
    } catch (error) {
      console.error('Error deleting:', error);
      alert('Error deleting foods. Please try again.');
    } finally {
      setIsDeleting(false);
    }
  }, [selectedFoodIds, getFoodById, foods, setFoods, deselectAll]);

  // Move selected foods to a different index
  const handleMoveSelected = useCallback(async (toIndex: string) => {
    if (selectedFoodIds.length === 0) return;

    const confirmMove = window.confirm(
      `Move ${selectedFoodIds.length} food(s) to ${toIndex}? This will remove them from their current index.`
    );

    if (!confirmMove) return;

    setIsMoving(true);

    try {
      // Get the full food objects for selected IDs
      const foodsToMove = selectedFoodIds
        .map(id => getFoodById(id))
        .filter((food): food is NonNullable<typeof food> => food !== undefined);

      if (foodsToMove.length === 0) {
        alert('No foods found to move.');
        return;
      }

      console.log(`Moving ${foodsToMove.length} foods to ${toIndex}`);
      const result = await moveFoodsBetweenIndices(foodsToMove, toIndex);

      if (result.success > 0) {
        console.log(`✅ Moved ${result.success} foods to ${toIndex}`);
        // Reload data to reflect the move
        await loadData();
        deselectAll();
        alert(`Successfully moved ${result.success} food(s) to ${toIndex}!`);
      }

      if (result.failed > 0) {
        console.error(`Failed to move ${result.failed} foods:`, result.errors);
        alert(`Failed to move ${result.failed} foods. Check console for details.`);
      }
    } catch (error) {
      console.error('Error moving:', error);
      alert('Error moving foods. Please try again.');
    } finally {
      setIsMoving(false);
    }
  }, [selectedFoodIds, getFoodById, deselectAll, loadData]);

  // Detect duplicates
  const handleDetectDuplicates = useCallback(async () => {
    setIsDetectingDuplicates(true);

    try {
      const duplicates = detectDuplicates(foods, {
        minScore: 30,
        maxGroups: 500,
      });

      setDuplicateGroups(duplicates);
      console.log(`Found ${duplicates.length} duplicate groups`);

      // Show the duplicates panel after detection
      setShowDuplicatesPanel(true);
    } catch (error) {
      console.error('Error detecting duplicates:', error);
    } finally {
      setIsDetectingDuplicates(false);
    }
  }, [foods, setDuplicateGroups]);

  // OpenFoodFacts lookup
  const handleLookupOFF = useCallback(() => {
    setShowOFFModal(true);
  }, []);

  // Show image processing page
  if (currentView === 'image-processing') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <ImageProcessingPage onBack={() => setCurrentView('grid')} />
      </div>
    );
  }

  // Show Google image scraper page
  if (currentView === 'google-scraper') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <GoogleImageScraperPage onBack={() => setCurrentView('grid')} />
      </div>
    );
  }

  // Show reports page
  if (currentView === 'reports') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <ReportsPage onBack={() => {
          setCurrentView('grid');
          // Refresh count and food report IDs when returning from reports
          fetch('https://us-central1-nutrasafe-705c7.cloudfunctions.net/getUserReports')
            .then(r => r.json())
            .then(result => {
              if (result.success) {
                const reports = result.reports || [];
                const pending = reports.filter((r: { status: string }) => r.status === 'pending').length;
                setPendingReportsCount(pending);

                // Extract unique food IDs from all reports
                const reportFoodIds = new Set<string>();
                reports.forEach((report: { foodId?: string; food?: { id?: string; objectID?: string } }) => {
                  const foodId = report.food?.id || report.food?.objectID || report.foodId;
                  if (foodId) reportFoodIds.add(foodId);
                });
                setFoodReportIds(reportFoodIds);
              }
            })
            .catch(() => {});
        }} />
      </div>
    );
  }

  // Show master database builder page
  if (currentView === 'master-builder') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <MasterDatabaseBuilderPage onBack={() => setCurrentView('grid')} />
      </div>
    );
  }

  // Show food categorizer page
  if (currentView === 'food-categorizer') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <FoodCategorizerPage onBack={() => setCurrentView('grid')} />
      </div>
    );
  }

  // Show analytics page
  if (currentView === 'analytics') {
    return (
      <div className="h-screen flex flex-col bg-gray-50">
        <AnalyticsPage onBack={() => setCurrentView('grid')} />
      </div>
    );
  }

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      {/* Header */}
      <Header
        onSave={handleSave}
        onRefresh={loadData}
        onDeleteSelected={handleDeleteSelected}
        onMoveSelected={handleMoveSelected}
        onReports={() => setCurrentView('reports')}
        pendingReportsCount={pendingReportsCount}
        isSaving={isSaving}
        isDeleting={isDeleting}
        isMoving={isMoving}
      />

      {/* Main content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar */}
        <Sidebar
          onDetectDuplicates={handleDetectDuplicates}
          onLookupOFF={handleLookupOFF}
          onImageProcessing={() => setCurrentView('image-processing')}
          onGoogleScraper={() => setCurrentView('google-scraper')}
          onReports={() => setCurrentView('reports')}
          onMasterBuilder={() => setCurrentView('master-builder')}
          onFoodCategorizer={() => setCurrentView('food-categorizer')}
          onAnalytics={() => setCurrentView('analytics')}
          isDetectingDuplicates={isDetectingDuplicates}
          pendingReportsCount={pendingReportsCount}
        />

        {/* Grid */}
        <main className="flex-1 overflow-hidden">
          <FoodGrid />
        </main>
      </div>

      {/* Loading overlay */}
      {isLoading && (
        <LoadingOverlay
          message={loadingMessage}
          progress={loadingProgress}
        />
      )}

      {/* OpenFoodFacts lookup modal */}
      {showOFFModal && (
        <OFFLookupModal
          onClose={() => setShowOFFModal(false)}
          onImport={() => {
            // Reload data to show the new food
            loadData();
            setShowOFFModal(false);
            console.log('Imported food from OpenFoodFacts');
          }}
          selectedFoods={selectedFoodIds
            .map(id => getFoodById(id))
            .filter((f): f is NonNullable<typeof f> => f !== undefined)}
        />
      )}

      {/* Duplicates panel */}
      {showDuplicatesPanel && (
        <DuplicatesPanel onClose={() => setShowDuplicatesPanel(false)} />
      )}
    </div>
  );
};

const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <AppContent />
    </QueryClientProvider>
  );
};

export default App;
