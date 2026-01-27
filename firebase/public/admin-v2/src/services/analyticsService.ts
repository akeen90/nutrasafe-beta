/**
 * Analytics Service
 * Fetches analytics data from Firebase Cloud Functions
 */

import { getFunctions, httpsCallable } from 'firebase/functions';

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
  const functions = getFunctions();
  const getUserAnalyticsFn = httpsCallable(functions, 'getUserAnalytics');

  const result = await getUserAnalyticsFn({});
  const data = result.data as { success: boolean; analytics: AppUserAnalytics; error?: string };

  if (!data.success) {
    throw new Error(data.error || 'Failed to get user analytics');
  }

  return data.analytics;
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
