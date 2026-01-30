/**
 * Analytics Service
 * Fetches analytics data from Firebase Cloud Functions
 */

import { httpsCallable } from 'firebase/functions';
import { getFirebaseFunctions } from './firebaseService';

const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

// Types for analytics data
export interface WebsiteAnalytics {
  totalVisitors: number;
  acceptedConsent: number;
  rejectedConsent: number;
  consentRate: number;
  visitorsByDay: { date: string; count: number }[];
  visitorsByPage: { page: string; count: number }[];
  topReferrers: { referrer: string; count: number }[];
  deviceBreakdown: { device: string; count: number }[];
  generatedAt: string;
}

export interface AppUserAnalytics {
  totalUsers: number;
  activeUsers: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  recentlyActiveUsers: number;
  totalScans: number;
  totalSearches: number;
  totalFoodsLogged: number;
  totalReactionsLogged: number;
  avgScansPerUser: string | number;
  avgSearchesPerUser: string | number;
  topAllergens: { allergen: string; count: number }[];
  userGrowthData: { date: string; newUsers: number }[];
  generatedAt: string;
}

export interface DatabaseAnalytics {
  totalFoods: number;
  humanVerifiedFoods: number;
  aiVerifiedFoods: number;
  unverifiedFoods: number;
  dataCompleteness: number;
  foodsWithIngredients: number;
  foodsWithNutrition: number;
  pendingVerifications: number;
  topBrands: { brand: string; count: number }[];
  topCategories: { category: string; count: number }[];
  nutritionGrades: Record<string, number>;
  generatedAt: string;
}

export interface OverviewStats {
  totalFoods: number;
  humanVerifiedFoods: number;
  aiVerifiedFoods: number;
  unverifiedFoods: number;
  foodsWithIngredients: number;
  foodsWithNutrition: number;
  dataCompleteness: number;
  pendingVerifications: number;
  generatedAt: string;
}

export interface AnalyticsData {
  topBrands: { brand: string; count: number }[];
  topCategories: { category: string; count: number }[];
  nutritionGrades: Record<string, number>;
  userGrowthData: { date: string; users: number }[];
  totalFoodsAnalyzed: number;
  averageNutritionScore: number;
  generatedAt: string;
}

/**
 * Get overview statistics (public endpoint)
 */
export async function getOverviewStats(): Promise<OverviewStats> {
  const response = await fetch(`${API_BASE}/getOverviewStats`);
  const result = await response.json();

  if (!result.success) {
    throw new Error(result.error || 'Failed to get overview stats');
  }

  return result.stats;
}

/**
 * Get analytics data (public endpoint)
 */
export async function getAnalyticsData(): Promise<AnalyticsData> {
  const response = await fetch(`${API_BASE}/getAnalyticsData`);
  const result = await response.json();

  if (!result.success) {
    throw new Error(result.error || 'Failed to get analytics data');
  }

  return result.analytics;
}

/**
 * Get user analytics (requires admin authentication)
 */
export async function getUserAnalytics(): Promise<AppUserAnalytics> {
  console.log('getUserAnalytics: Starting...');
  const functions = getFirebaseFunctions();
  const getUserAnalyticsFn = httpsCallable(functions, 'getUserAnalytics');

  try {
    console.log('getUserAnalytics: Calling function...');
    const result = await getUserAnalyticsFn({});
    console.log('getUserAnalytics: Got result:', result);
    const data = result.data as { success: boolean; analytics: AppUserAnalytics; error?: string };

    if (!data.success) {
      console.error('getUserAnalytics: Failed:', data.error);
      throw new Error(data.error || 'Failed to get user analytics');
    }

    console.log('getUserAnalytics: Success!', data.analytics);
    return data.analytics;
  } catch (error) {
    console.error('getUserAnalytics: Error:', error);
    throw error;
  }
}

// GA4 Analytics types
export interface GA4Analytics {
  summary: {
    activeUsers: number;
    newUsers: number;
    totalUsers: number;
    sessions: number;
    engagedSessions: number;
    avgSessionDuration: number;
    avgSessionDurationFormatted: string;
    screenViews: number;
    totalEvents: number;
    engagementRate: number;
  };
  dailyUsers: { date: string; activeUsers: number; newUsers: number }[];
  topEvents: { event: string; count: number }[];
  topScreens: { screen: string; views: number }[];
  engagementByDay: { day: string; activeUsers: number; sessions: number }[];
  dateRange: { start: string; end: string };
  generatedAt: string;
}

export interface GA4ConfigStatus {
  configured: boolean;
  propertyId: string | null;
  instructions?: {
    step1: string;
    step2: string;
    step3: string;
    step4: string;
  };
}

/**
 * Get real GA4 analytics data (requires admin authentication)
 */
export async function getGA4Analytics(): Promise<GA4Analytics> {
  console.log('getGA4Analytics: Starting...');
  const functions = getFirebaseFunctions();
  const getGA4AnalyticsFn = httpsCallable(functions, 'getGA4Analytics');

  try {
    console.log('getGA4Analytics: Calling function...');
    const result = await getGA4AnalyticsFn({});
    console.log('getGA4Analytics: Got result:', result);
    const data = result.data as {
      success: boolean;
      analytics?: GA4Analytics;
      error?: string;
      setupInstructions?: Record<string, string>;
      help?: string;
    };

    if (!data.success) {
      console.error('getGA4Analytics: Failed:', data.error);
      const errorMsg = data.error || 'Failed to get GA4 analytics';
      if (data.setupInstructions) {
        throw new Error(`${errorMsg}\n\nSetup: ${JSON.stringify(data.setupInstructions, null, 2)}`);
      }
      throw new Error(errorMsg);
    }

    console.log('getGA4Analytics: Success!', data.analytics);
    return data.analytics!;
  } catch (error) {
    console.error('getGA4Analytics: Error:', error);
    throw error;
  }
}

/**
 * Check GA4 configuration status
 */
export async function checkGA4Config(): Promise<GA4ConfigStatus> {
  const functions = getFirebaseFunctions();
  const checkGA4ConfigFn = httpsCallable(functions, 'checkGA4Config');

  try {
    const result = await checkGA4ConfigFn({});
    return result.data as GA4ConfigStatus;
  } catch (error) {
    console.error('checkGA4Config: Error:', error);
    throw error;
  }
}

/**
 * Get website analytics (public endpoint)
 */
export async function getWebsiteAnalytics(): Promise<WebsiteAnalytics> {
  const response = await fetch(`${API_BASE}/getWebsiteAnalytics`);
  const result = await response.json();

  if (!result.success) {
    throw new Error(result.error || 'Failed to get website analytics');
  }

  return result.analytics;
}

/**
 * Get all analytics data at once
 */
export async function getAllAnalytics(): Promise<{
  overview: OverviewStats;
  analytics: AnalyticsData;
  users: AppUserAnalytics | null;
  website: WebsiteAnalytics | null;
}> {
  // Fetch public endpoints in parallel
  const [overview, analytics] = await Promise.all([
    getOverviewStats(),
    getAnalyticsData(),
  ]);

  // Try to fetch authenticated endpoints
  let users: AppUserAnalytics | null = null;
  let website: WebsiteAnalytics | null = null;

  try {
    users = await getUserAnalytics();
  } catch (error) {
    console.warn('Could not fetch user analytics (may need auth):', error);
  }

  try {
    website = await getWebsiteAnalytics();
  } catch (error) {
    console.warn('Could not fetch website analytics:', error);
  }

  return { overview, analytics, users, website };
}
