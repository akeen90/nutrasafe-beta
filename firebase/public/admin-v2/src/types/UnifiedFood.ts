/**
 * Unified Food Data Model
 * Merges all 10 Algolia indices into a single normalized format
 */

// All Algolia index names
export const ALGOLIA_INDICES = [
  'verified_foods',
  'foods',
  'manual_foods',
  'user_added',
  'ai_enhanced',
  'ai_manually_added',
  'tesco_products',
  'uk_foods_cleaned',
  'fast_foods_database',
  'generic_database',
  'consumer_foods',
] as const;

export type AlgoliaIndexName = typeof ALGOLIA_INDICES[number];

// Mapping from Algolia index to Firestore collection (null = Algolia-only)
export const INDEX_TO_COLLECTION: Record<AlgoliaIndexName, string | null> = {
  'verified_foods': 'verifiedFoods',
  'foods': 'foods',
  'manual_foods': 'manualFoods',
  'user_added': 'userAdded',
  'ai_enhanced': 'aiEnhanced',
  'ai_manually_added': 'aiManuallyAdded',
  'tesco_products': 'tescoProducts',
  'uk_foods_cleaned': null,        // Algolia-only
  'fast_foods_database': null,     // Algolia-only
  'generic_database': null,        // Algolia-only
  'consumer_foods': 'consumer_foods',
};

// Indices that have no Firestore backing (Algolia-only)
export const ALGOLIA_ONLY_INDICES: AlgoliaIndexName[] = [
  'uk_foods_cleaned',
  'fast_foods_database',
  'generic_database',
];

// Review flags for data quality issues
export type ReviewFlagType =
  | 'missing_nutrition'
  | 'missing_name'
  | 'implausible_calories'
  | 'implausible_macros'
  | 'non_uk'
  | 'duplicate_candidate'
  | 'low_confidence'
  | 'missing_barcode'
  | 'missing_ingredients';

export interface ReviewFlag {
  type: ReviewFlagType;
  severity: 'error' | 'warning' | 'info';
  message: string;
}

// Unified food interface (all 10 indices merged)
export interface UnifiedFood {
  // Identity
  _id: string;                    // Compound: `${sourceIndex}:${objectID}`
  objectID: string;               // Original Algolia objectID
  _sourceIndex: AlgoliaIndexName; // Which Algolia index this came from
  _firestoreCollection: string | null;
  _hasFirestoreBacking: boolean;

  // Core fields
  name: string;
  brandName: string | null;
  barcode: string | null;
  barcodes: string[];             // Some foods have multiple barcodes
  ingredients: string[];
  ingredientsText: string | null;

  // Nutrition (per 100g)
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  saturatedFat: number | null;
  fiber: number;
  sugar: number;
  sodium: number;
  salt: number | null;

  // Serving
  servingDescription: string | null;
  servingSizeG: number | null;
  isPerUnit: boolean;

  // Verification
  isVerified: boolean;
  verifiedBy: string | null;
  verifiedAt: Date | null;

  // Image
  imageUrl: string | null;
  dontShowImage?: boolean;        // Flag to hide image in UI

  // Metadata
  category: string | null;
  source: string | null;
  createdAt: Date | null;
  updatedAt: Date | null;

  // Computed (for grid display and filtering)
  _confidenceScore: number;
  _reviewFlags: ReviewFlag[];
  _duplicateCandidates: string[];
  _isDirty: boolean;              // Has unsaved changes
  _isDeleted: boolean;            // Marked for deletion
}

// Partial update for editing
export type UnifiedFoodUpdate = Partial<Omit<UnifiedFood, '_id' | '_sourceIndex' | '_firestoreCollection' | '_hasFirestoreBacking'>>;

// Grid column configuration
export interface ColumnConfig {
  field: keyof UnifiedFood | string;
  headerName: string;
  width?: number;
  editable?: boolean;
  pinned?: 'left' | 'right';
  cellRenderer?: string;
  valueFormatter?: (params: { value: unknown }) => string;
  filter?: boolean | string;
  sortable?: boolean;
}

// Duplicate detection result
export interface DuplicateGroup {
  id: string;
  masterFoodId: string;           // The "best" version to keep
  duplicateIds: string[];         // Other foods that may be duplicates
  matchScore: number;             // 0-100 confidence
  matchReasons: string[];         // Why these were flagged as duplicates
}

// Search/filter state
export interface FilterState {
  searchQuery: string;
  indices: AlgoliaIndexName[];
  verified: 'all' | 'verified' | 'unverified';
  hasIssues: boolean;
  hasDuplicates: boolean;
  hasBarcode: boolean;
  zeroCalories: boolean;
  hasReport: boolean; // Filter to show only foods with user reports
}

// Statistics for the dashboard
export interface DatabaseStats {
  totalFoods: number;
  byIndex: Record<AlgoliaIndexName, number>;
  verified: number;
  unverified: number;
  withIssues: number;
  duplicateGroups: number;
  lastUpdated: Date;
}
