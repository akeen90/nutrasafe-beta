/**
 * Analytics Dashboard Page
 * Comprehensive analytics for Website, App Users, and Food Database
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import {
  getOverviewStats,
  getAnalyticsData,
  getUserAnalytics,
  getWebsiteAnalytics,
  WebsiteAnalytics,
  AppUserAnalytics,
  OverviewStats,
  AnalyticsData,
} from '../services/analyticsService';
import { useGridStore } from '../store';

interface AnalyticsPageProps {
  onBack: () => void;
}

type TabType = 'website' | 'app' | 'database';

// Chart color palette
const COLORS = ['#2563eb', '#8b5cf6', '#22c55e', '#f59e0b', '#ef4444', '#06b6d4', '#ec4899', '#14b8a6', '#f97316', '#6366f1'];

// Metric Card Component
const MetricCard: React.FC<{
  title: string;
  value: string | number;
  subtitle?: string;
  trend?: { value: number; isPositive: boolean };
  color?: 'default' | 'success' | 'warning' | 'danger' | 'info';
}> = ({ title, value, subtitle, trend, color = 'default' }) => {
  const colorClasses = {
    default: 'text-gray-900',
    success: 'text-green-600',
    warning: 'text-yellow-600',
    danger: 'text-red-600',
    info: 'text-blue-600',
  };

  return (
    <div className="bg-white rounded-lg shadow p-4">
      <div className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">
        {title}
      </div>
      <div className={`text-3xl font-bold ${colorClasses[color]}`}>
        {typeof value === 'number' ? value.toLocaleString() : value}
      </div>
      {subtitle && (
        <div className="text-sm text-gray-500 mt-1">{subtitle}</div>
      )}
      {trend && (
        <div className={`text-sm mt-1 ${trend.isPositive ? 'text-green-600' : 'text-red-600'}`}>
          {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}% vs last period
        </div>
      )}
    </div>
  );
};

// Chart Card Component
const ChartCard: React.FC<{
  title: string;
  children: React.ReactNode;
  className?: string;
}> = ({ title, children, className = '' }) => (
  <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
    <div className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-4">
      {title}
    </div>
    {children}
  </div>
);

// Loading Skeleton
const Skeleton: React.FC<{ className?: string }> = ({ className = '' }) => (
  <div className={`animate-pulse bg-gray-200 rounded ${className}`} />
);

export const AnalyticsPage: React.FC<AnalyticsPageProps> = ({ onBack }) => {
  const [activeTab, setActiveTab] = useState<TabType>('website');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(false);

  // Data states
  const [websiteData, setWebsiteData] = useState<WebsiteAnalytics | null>(null);
  const [appUserData, setAppUserData] = useState<AppUserAnalytics | null>(null);
  const [overviewStats, setOverviewStats] = useState<OverviewStats | null>(null);
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);

  // Get index stats from store
  const { stats } = useGridStore();

  // Fetch all data
  const fetchData = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Fetch all data in parallel
      const results = await Promise.allSettled([
        getWebsiteAnalytics(),
        getUserAnalytics(),
        getOverviewStats(),
        getAnalyticsData(),
      ]);

      // Process results
      if (results[0].status === 'fulfilled') {
        setWebsiteData(results[0].value);
      } else {
        console.warn('Website analytics failed:', results[0].reason);
      }

      if (results[1].status === 'fulfilled') {
        setAppUserData(results[1].value);
      } else {
        console.warn('User analytics failed:', results[1].reason);
      }

      if (results[2].status === 'fulfilled') {
        setOverviewStats(results[2].value);
      } else {
        console.warn('Overview stats failed:', results[2].reason);
      }

      if (results[3].status === 'fulfilled') {
        setAnalyticsData(results[3].value);
      } else {
        console.warn('Analytics data failed:', results[3].reason);
      }

      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch analytics');
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Initial fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Auto refresh
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, [autoRefresh, fetchData]);

  // Tab buttons
  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    {
      id: 'website',
      label: 'Website',
      icon: (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
        </svg>
      ),
    },
    {
      id: 'app',
      label: 'App Users',
      icon: (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
    },
    {
      id: 'database',
      label: 'Database',
      icon: (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
        </svg>
      ),
    },
  ];

  // Website Analytics Tab
  const renderWebsiteTab = () => {
    if (!websiteData) {
      return (
        <div className="text-center py-12 text-gray-500">
          <svg className="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <p>Website analytics not available</p>
          <p className="text-sm mt-1">Make sure the getWebsiteAnalytics Cloud Function is deployed</p>
        </div>
      );
    }

    return (
      <div className="space-y-6">
        {/* Top Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard
            title="Total Visitors"
            value={websiteData.totalVisitors}
            subtitle="All time"
          />
          <MetricCard
            title="Consent Rate"
            value={`${websiteData.consentRate}%`}
            subtitle={`${websiteData.acceptedConsent} accepted`}
            color={websiteData.consentRate >= 70 ? 'success' : websiteData.consentRate >= 50 ? 'warning' : 'danger'}
          />
          <MetricCard
            title="Accepted"
            value={websiteData.acceptedConsent}
            color="success"
          />
          <MetricCard
            title="Rejected"
            value={websiteData.rejectedConsent}
            color="danger"
          />
        </div>

        {/* Visitors Over Time */}
        <ChartCard title="Daily Visitors (Last 30 Days)" className="col-span-2">
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={websiteData.visitorsByDay}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis
                dataKey="date"
                tickFormatter={(date) => new Date(date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                stroke="#9ca3af"
                fontSize={12}
              />
              <YAxis stroke="#9ca3af" fontSize={12} />
              <Tooltip
                labelFormatter={(date) => new Date(date).toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' })}
                contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
              />
              <Area
                type="monotone"
                dataKey="count"
                name="Visitors"
                stroke="#2563eb"
                fill="#3b82f6"
                fillOpacity={0.2}
              />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Top Pages */}
          <ChartCard title="Top Pages">
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={websiteData.visitorsByPage} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" stroke="#9ca3af" fontSize={12} />
                <YAxis
                  dataKey="page"
                  type="category"
                  width={120}
                  stroke="#9ca3af"
                  fontSize={11}
                  tickFormatter={(page) => page.length > 20 ? page.substring(0, 20) + '...' : page}
                />
                <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                <Bar dataKey="count" name="Visitors" fill="#2563eb" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          {/* Device Breakdown */}
          <ChartCard title="Device Types">
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={websiteData.deviceBreakdown}
                  dataKey="count"
                  nameKey="device"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ name, percent }) => `${name} ${((percent || 0) * 100).toFixed(0)}%`}
                  labelLine={false}
                >
                  {websiteData.deviceBreakdown.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* Top Referrers */}
        <ChartCard title="Top Referrers">
          <div className="space-y-2">
            {websiteData.topReferrers.map((referrer, index) => (
              <div key={referrer.referrer} className="flex items-center gap-3">
                <div className="w-6 text-center text-sm font-medium text-gray-400">
                  {index + 1}
                </div>
                <div className="flex-1 bg-gray-100 rounded-full h-6 relative overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${(referrer.count / websiteData.topReferrers[0].count) * 100}%`,
                      backgroundColor: COLORS[index % COLORS.length],
                    }}
                  />
                  <span className="absolute inset-0 flex items-center px-3 text-sm font-medium text-gray-700">
                    {referrer.referrer}
                  </span>
                </div>
                <div className="w-16 text-right text-sm font-medium text-gray-600">
                  {referrer.count}
                </div>
              </div>
            ))}
          </div>
        </ChartCard>
      </div>
    );
  };

  // App Users Tab
  const renderAppTab = () => {
    if (!appUserData) {
      return (
        <div className="text-center py-12 text-gray-500">
          <svg className="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
          <p>App user analytics requires authentication</p>
          <p className="text-sm mt-1">Sign in with an admin account to view user data</p>
        </div>
      );
    }

    return (
      <div className="space-y-6">
        {/* User Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard
            title="Total Users"
            value={appUserData.totalUsers}
            color="info"
          />
          <MetricCard
            title="Active (7 days)"
            value={appUserData.recentlyActiveUsers}
            subtitle={`${appUserData.totalUsers > 0 ? Math.round((appUserData.recentlyActiveUsers / appUserData.totalUsers) * 100) : 0}% of total`}
            color="success"
          />
          <MetricCard
            title="New Today"
            value={appUserData.newUsersToday}
            color={appUserData.newUsersToday > 0 ? 'success' : 'default'}
          />
          <MetricCard
            title="New This Week"
            value={appUserData.newUsersThisWeek}
            color={appUserData.newUsersThisWeek > 0 ? 'success' : 'default'}
          />
        </div>

        {/* User Growth Chart */}
        <ChartCard title="User Growth (Last 30 Days)">
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={appUserData.userGrowthData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis
                dataKey="date"
                tickFormatter={(date) => new Date(date).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                stroke="#9ca3af"
                fontSize={12}
              />
              <YAxis stroke="#9ca3af" fontSize={12} />
              <Tooltip
                labelFormatter={(date) => new Date(date).toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' })}
                contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
              />
              <Line
                type="monotone"
                dataKey="newUsers"
                name="New Users"
                stroke="#22c55e"
                strokeWidth={2}
                dot={{ r: 3 }}
                activeDot={{ r: 5 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Engagement Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard
            title="Total Scans"
            value={appUserData.totalScans}
            subtitle={`${appUserData.avgScansPerUser} avg/user`}
          />
          <MetricCard
            title="Total Searches"
            value={appUserData.totalSearches}
            subtitle={`${appUserData.avgSearchesPerUser} avg/user`}
          />
          <MetricCard
            title="Foods Logged"
            value={appUserData.totalFoodsLogged}
          />
          <MetricCard
            title="Reactions Logged"
            value={appUserData.totalReactionsLogged}
          />
        </div>

        {/* Top Allergens */}
        {appUserData.topAllergens.length > 0 && (
          <ChartCard title="Top Tracked Allergens">
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={appUserData.topAllergens}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis
                  dataKey="allergen"
                  stroke="#9ca3af"
                  fontSize={12}
                  angle={-45}
                  textAnchor="end"
                  height={80}
                />
                <YAxis stroke="#9ca3af" fontSize={12} />
                <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                <Bar dataKey="count" name="Users" fill="#ef4444" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        )}
      </div>
    );
  };

  // Database Tab
  const renderDatabaseTab = () => {
    return (
      <div className="space-y-6">
        {/* Overview Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard
            title="Total Foods"
            value={overviewStats?.totalFoods ?? stats?.totalFoods ?? 0}
            color="info"
          />
          <MetricCard
            title="Verified"
            value={(overviewStats?.humanVerifiedFoods ?? 0) + (overviewStats?.aiVerifiedFoods ?? 0)}
            subtitle={`${overviewStats?.humanVerifiedFoods ?? 0} human, ${overviewStats?.aiVerifiedFoods ?? 0} AI`}
            color="success"
          />
          <MetricCard
            title="Unverified"
            value={overviewStats?.unverifiedFoods ?? 0}
            color={overviewStats?.unverifiedFoods ?? 0 > 100 ? 'warning' : 'default'}
          />
          <MetricCard
            title="Data Completeness"
            value={`${overviewStats?.dataCompleteness ?? 0}%`}
            color={
              (overviewStats?.dataCompleteness ?? 0) >= 80
                ? 'success'
                : (overviewStats?.dataCompleteness ?? 0) >= 50
                ? 'warning'
                : 'danger'
            }
          />
        </div>

        {/* Data Quality */}
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <MetricCard
            title="With Ingredients"
            value={overviewStats?.foodsWithIngredients ?? 0}
            subtitle={`${overviewStats?.totalFoods ? Math.round((overviewStats.foodsWithIngredients / overviewStats.totalFoods) * 100) : 0}% of total`}
          />
          <MetricCard
            title="With Nutrition"
            value={overviewStats?.foodsWithNutrition ?? 0}
            subtitle={`${overviewStats?.totalFoods ? Math.round((overviewStats.foodsWithNutrition / overviewStats.totalFoods) * 100) : 0}% of total`}
          />
          <MetricCard
            title="Pending Verification"
            value={overviewStats?.pendingVerifications ?? 0}
            color={overviewStats?.pendingVerifications ?? 0 > 50 ? 'warning' : 'default'}
          />
        </div>

        {analyticsData && (
          <>
            {/* Top Brands & Categories */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <ChartCard title="Top Brands">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={analyticsData.topBrands} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis type="number" stroke="#9ca3af" fontSize={12} />
                    <YAxis
                      dataKey="brand"
                      type="category"
                      width={100}
                      stroke="#9ca3af"
                      fontSize={11}
                      tickFormatter={(brand) => brand.length > 15 ? brand.substring(0, 15) + '...' : brand}
                    />
                    <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                    <Bar dataKey="count" name="Products" fill="#8b5cf6" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartCard>

              <ChartCard title="Top Categories">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={analyticsData.topCategories} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis type="number" stroke="#9ca3af" fontSize={12} />
                    <YAxis
                      dataKey="category"
                      type="category"
                      width={100}
                      stroke="#9ca3af"
                      fontSize={11}
                      tickFormatter={(cat) => cat.length > 15 ? cat.substring(0, 15) + '...' : cat}
                    />
                    <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                    <Bar dataKey="count" name="Products" fill="#22c55e" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </ChartCard>
            </div>

            {/* Nutrition Grades Distribution */}
            {analyticsData.nutritionGrades && Object.keys(analyticsData.nutritionGrades).length > 0 && (
              <ChartCard title="Nutrition Grades Distribution">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart
                    data={Object.entries(analyticsData.nutritionGrades)
                      .map(([grade, count]) => ({ grade, count }))
                      .sort((a, b) => {
                        const order = ['A+', 'A', 'B', 'C', 'D', 'E', 'F'];
                        return order.indexOf(a.grade) - order.indexOf(b.grade);
                      })}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="grade" stroke="#9ca3af" fontSize={12} />
                    <YAxis stroke="#9ca3af" fontSize={12} />
                    <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                    <Bar dataKey="count" name="Foods" radius={[4, 4, 0, 0]}>
                      {Object.entries(analyticsData.nutritionGrades).map(([grade], index) => {
                        const gradeColors: Record<string, string> = {
                          'A+': '#22c55e',
                          'A': '#4ade80',
                          'B': '#a3e635',
                          'C': '#fbbf24',
                          'D': '#fb923c',
                          'E': '#f87171',
                          'F': '#ef4444',
                        };
                        return <Cell key={`cell-${index}`} fill={gradeColors[grade] || COLORS[index % COLORS.length]} />;
                      })}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </ChartCard>
            )}
          </>
        )}

        {/* Index Distribution */}
        {stats?.byIndex && (
          <ChartCard title="Index Distribution">
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={Object.entries(stats.byIndex)
                    .filter(([_, count]) => count > 0)
                    .map(([index, count]) => ({
                      name: index.replace(/_/g, ' ').replace(/foods?/gi, '').trim() || index,
                      value: count,
                    }))}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={({ name, percent }) => `${name} ${((percent || 0) * 100).toFixed(0)}%`}
                  labelLine={true}
                >
                  {Object.entries(stats.byIndex)
                    .filter(([_, count]) => count > 0)
                    .map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                </Pie>
                <Tooltip
                  formatter={(value) => typeof value === 'number' ? value.toLocaleString() : value}
                  contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>
        )}
      </div>
    );
  };

  return (
    <div className="h-full flex flex-col bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={onBack}
              className="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
              <span>Back</span>
            </button>
            <h1 className="text-xl font-bold text-gray-900">Analytics Dashboard</h1>
          </div>

          <div className="flex items-center gap-4">
            {lastUpdated && (
              <span className="text-sm text-gray-500">
                Updated {lastUpdated.toLocaleTimeString()}
              </span>
            )}

            <label className="flex items-center gap-2 text-sm text-gray-600 cursor-pointer">
              <input
                type="checkbox"
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              Auto-refresh
            </label>

            <button
              onClick={fetchData}
              disabled={isLoading}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
            >
              {isLoading ? (
                <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
              ) : (
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              )}
              <span>Refresh</span>
            </button>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white border-b border-gray-200 px-6">
        <div className="flex gap-1 py-2">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === tab.id
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              {tab.icon}
              <span>{tab.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-6">
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <span>{error}</span>
            </div>
          </div>
        )}

        {isLoading && !websiteData && !appUserData && !overviewStats ? (
          <div className="space-y-6">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="bg-white rounded-lg shadow p-4">
                  <Skeleton className="h-4 w-20 mb-2" />
                  <Skeleton className="h-8 w-24" />
                </div>
              ))}
            </div>
            <div className="bg-white rounded-lg shadow p-4">
              <Skeleton className="h-4 w-32 mb-4" />
              <Skeleton className="h-64 w-full" />
            </div>
          </div>
        ) : (
          <>
            {activeTab === 'website' && renderWebsiteTab()}
            {activeTab === 'app' && renderAppTab()}
            {activeTab === 'database' && renderDatabaseTab()}
          </>
        )}
      </div>
    </div>
  );
};

export default AnalyticsPage;
