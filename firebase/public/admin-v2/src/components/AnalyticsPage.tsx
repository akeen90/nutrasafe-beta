/**
 * Analytics Dashboard Page
 * Comprehensive analytics for Website, App Users, and Food Database
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
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
  getGA4Analytics,
  WebsiteAnalytics,
  AppUserAnalytics,
  OverviewStats,
  AnalyticsData,
  GA4Analytics,
} from '../services/analyticsService';
import { useGridStore } from '../store';
import { useAuth, SignInForm, UserBadge } from './AuthProvider';

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

  // Auth state
  const { user } = useAuth();

  // Data states
  const [websiteData, setWebsiteData] = useState<WebsiteAnalytics | null>(null);
  const [appUserData, setAppUserData] = useState<AppUserAnalytics | null>(null);
  const [ga4Data, setGa4Data] = useState<GA4Analytics | null>(null);
  const [overviewStats, setOverviewStats] = useState<OverviewStats | null>(null);
  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(null);
  const [appUserError, setAppUserError] = useState<string | null>(null);
  const [ga4Error, setGa4Error] = useState<string | null>(null);

  // Get index stats from store
  const { stats } = useGridStore();

  // Fetch all data
  const fetchData = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      console.log('fetchData called, user:', user?.email);

      // Build list of promises - only include user analytics if signed in
      const promises: Promise<any>[] = [
        getWebsiteAnalytics(),
        getOverviewStats(),
        getAnalyticsData(),
      ];

      // Only fetch user analytics and GA4 if authenticated
      if (user) {
        console.log('Adding getUserAnalytics and getGA4Analytics to promises...');
        promises.push(getUserAnalytics());
        promises.push(getGA4Analytics());
      } else {
        console.log('No user, skipping getUserAnalytics and getGA4Analytics');
      }

      const results = await Promise.allSettled(promises);

      // Process results
      if (results[0].status === 'fulfilled') {
        setWebsiteData(results[0].value);
      } else {
        console.warn('Website analytics failed:', results[0].reason);
      }

      if (results[1].status === 'fulfilled') {
        setOverviewStats(results[1].value);
      } else {
        console.warn('Overview stats failed:', results[1].reason);
      }

      if (results[2].status === 'fulfilled') {
        setAnalyticsData(results[2].value);
      } else {
        console.warn('Analytics data failed:', results[2].reason);
      }

      // User analytics (only if user is signed in)
      if (user && results[3]) {
        if (results[3].status === 'fulfilled') {
          setAppUserData(results[3].value);
          setAppUserError(null);
        } else {
          const errorMsg = results[3].reason?.message || results[3].reason || 'Unknown error';
          console.error('User analytics failed:', errorMsg);
          setAppUserData(null);
          setAppUserError(String(errorMsg));
        }
      } else if (!user) {
        setAppUserData(null);
        setAppUserError(null);
      }

      // GA4 analytics (only if user is signed in)
      if (user && results[4]) {
        if (results[4].status === 'fulfilled') {
          setGa4Data(results[4].value);
          setGa4Error(null);
        } else {
          const errorMsg = results[4].reason?.message || results[4].reason || 'Unknown error';
          console.error('GA4 analytics failed:', errorMsg);
          setGa4Data(null);
          setGa4Error(String(errorMsg));
        }
      } else if (!user) {
        setGa4Data(null);
        setGa4Error(null);
      }

      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch analytics');
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  // Initial fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Refetch when user signs in (to get user analytics and GA4)
  useEffect(() => {
    console.log('Auth state:', { user: user?.email, appUserData: !!appUserData, ga4Data: !!ga4Data, isLoading, appUserError });
    if (user && !appUserData && !ga4Data && !isLoading) {
      console.log('User signed in, fetching user analytics and GA4...');
      fetchData();
    }
  }, [user, appUserData, ga4Data, isLoading, fetchData, appUserError]);

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

  // App Users Tab - Real GA4 Analytics
  const renderAppTab = () => {
    // Show sign-in form if not authenticated
    if (!user) {
      return (
        <div className="flex flex-col items-center justify-center py-12">
          <SignInForm onSuccess={() => {
            console.log('Sign in success, will refetch...');
            // Let the useEffect handle the refetch when user state updates
          }} />
        </div>
      );
    }

    // Show loading if authenticated but no data yet
    if (!ga4Data && !appUserData && isLoading) {
      return (
        <div className="text-center py-12 text-gray-500">
          <svg className="w-12 h-12 mx-auto mb-4 text-gray-400 animate-spin" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
          </svg>
          <p>Loading analytics...</p>
          <p className="text-sm mt-1">Fetching data from Google Analytics 4</p>
        </div>
      );
    }

    // Show GA4 setup instructions if GA4 is not configured
    if (ga4Error && ga4Error.includes('not configured')) {
      return (
        <div className="max-w-2xl mx-auto py-12">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <div className="flex items-start gap-4">
              <svg className="w-8 h-8 text-yellow-500 flex-shrink-0 mt-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div>
                <h3 className="font-semibold text-yellow-800 text-lg mb-2">GA4 Setup Required</h3>
                <p className="text-yellow-700 mb-4">To see real app analytics, you need to configure Google Analytics 4:</p>
                <ol className="list-decimal list-inside space-y-2 text-yellow-700 text-sm">
                  <li>Go to <strong>Google Analytics &gt; Admin &gt; Property Settings</strong></li>
                  <li>Copy the <strong>Property ID</strong> (numeric, e.g., 123456789)</li>
                  <li>Run: <code className="bg-yellow-100 px-2 py-0.5 rounded font-mono text-xs">firebase functions:config:set ga4.property_id="YOUR_PROPERTY_ID"</code></li>
                  <li>Run: <code className="bg-yellow-100 px-2 py-0.5 rounded font-mono text-xs">firebase deploy --only functions</code></li>
                  <li>In GA4 &gt; Admin &gt; Property Access Management, grant your Firebase service account <strong>Viewer</strong> role</li>
                </ol>
              </div>
            </div>
          </div>

          {/* Fallback to Firestore user data */}
          {appUserData && (
            <div className="mt-8">
              <h3 className="text-lg font-semibold text-gray-700 mb-4">Firestore User Data (Fallback)</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <MetricCard title="Total Users" value={appUserData.totalUsers} color="info" />
                <MetricCard title="Active (7 days)" value={appUserData.recentlyActiveUsers} color="success" />
                <MetricCard title="New Today" value={appUserData.newUsersToday} />
                <MetricCard title="New This Week" value={appUserData.newUsersThisWeek} />
              </div>
            </div>
          )}
        </div>
      );
    }

    // Show error if GA4 fetch failed for another reason
    if (!ga4Data && !isLoading && ga4Error) {
      return (
        <div className="text-center py-12 text-gray-500">
          <svg className="w-12 h-12 mx-auto mb-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <p className="font-medium text-gray-700 mb-2">Failed to load GA4 analytics</p>
          <p className="text-sm mb-2">Signed in as: {user.email}</p>
          <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4 max-w-md mx-auto text-left">
            <p className="text-sm text-red-700 font-mono break-all whitespace-pre-wrap">{ga4Error}</p>
          </div>
          <button
            onClick={fetchData}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Retry Loading Analytics
          </button>
        </div>
      );
    }

    // Show GA4 Analytics
    if (ga4Data) {
      return (
        <div className="space-y-6">
          {/* Date Range Banner */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm text-blue-700">
            📊 Showing data from <strong>{ga4Data.dateRange.start}</strong> to <strong>{ga4Data.dateRange.end}</strong>
            <span className="ml-2 text-blue-500">(Last 30 days)</span>
          </div>

          {/* Key Metrics */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard
              title="Active Users"
              value={ga4Data.summary.activeUsers}
              subtitle="Last 30 days"
              color="info"
            />
            <MetricCard
              title="New Users"
              value={ga4Data.summary.newUsers}
              subtitle="Last 30 days"
              color="success"
            />
            <MetricCard
              title="Sessions"
              value={ga4Data.summary.sessions}
              subtitle={`${ga4Data.summary.engagementRate}% engaged`}
            />
            <MetricCard
              title="Avg Session"
              value={ga4Data.summary.avgSessionDurationFormatted}
              subtitle="Duration"
            />
          </div>

          {/* Engagement Metrics */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard
              title="Screen Views"
              value={ga4Data.summary.screenViews}
            />
            <MetricCard
              title="Total Events"
              value={ga4Data.summary.totalEvents}
            />
            <MetricCard
              title="Engaged Sessions"
              value={ga4Data.summary.engagedSessions}
              color="success"
            />
            <MetricCard
              title="Engagement Rate"
              value={`${ga4Data.summary.engagementRate}%`}
              color={ga4Data.summary.engagementRate >= 50 ? 'success' : ga4Data.summary.engagementRate >= 30 ? 'warning' : 'danger'}
            />
          </div>

          {/* Daily Users Trend */}
          <ChartCard title="Daily Active Users (Last 30 Days)">
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={ga4Data.dailyUsers}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(date) => {
                    const d = date.toString();
                    if (d.length === 8) {
                      return `${d.slice(6, 8)}/${d.slice(4, 6)}`;
                    }
                    return d;
                  }}
                  stroke="#9ca3af"
                  fontSize={12}
                />
                <YAxis stroke="#9ca3af" fontSize={12} />
                <Tooltip
                  labelFormatter={(date) => {
                    const d = date.toString();
                    if (d.length === 8) {
                      return `${d.slice(6, 8)}/${d.slice(4, 6)}/${d.slice(0, 4)}`;
                    }
                    return d;
                  }}
                  contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="activeUsers"
                  name="Active Users"
                  stroke="#2563eb"
                  fill="#3b82f6"
                  fillOpacity={0.2}
                />
                <Area
                  type="monotone"
                  dataKey="newUsers"
                  name="New Users"
                  stroke="#22c55e"
                  fill="#22c55e"
                  fillOpacity={0.2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </ChartCard>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Top Events */}
            <ChartCard title="Top Events">
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={ga4Data.topEvents.slice(0, 10)} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis type="number" stroke="#9ca3af" fontSize={12} />
                  <YAxis
                    dataKey="event"
                    type="category"
                    width={140}
                    stroke="#9ca3af"
                    fontSize={11}
                    tickFormatter={(event) => event.length > 20 ? event.substring(0, 20) + '...' : event}
                  />
                  <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                  <Bar dataKey="count" name="Event Count" fill="#8b5cf6" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>

            {/* Top Screens */}
            <ChartCard title="Top Screens">
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={ga4Data.topScreens} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis type="number" stroke="#9ca3af" fontSize={12} />
                  <YAxis
                    dataKey="screen"
                    type="category"
                    width={140}
                    stroke="#9ca3af"
                    fontSize={11}
                    tickFormatter={(screen) => screen.length > 20 ? screen.substring(0, 20) + '...' : screen}
                  />
                  <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                  <Bar dataKey="views" name="Screen Views" fill="#22c55e" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </div>

          {/* Engagement by Day of Week */}
          <ChartCard title="Engagement by Day of Week">
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={ga4Data.engagementByDay}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="day" stroke="#9ca3af" fontSize={12} />
                <YAxis stroke="#9ca3af" fontSize={12} />
                <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                <Legend />
                <Bar dataKey="activeUsers" name="Active Users" fill="#2563eb" radius={[4, 4, 0, 0]} />
                <Bar dataKey="sessions" name="Sessions" fill="#06b6d4" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          {/* Firestore User Data (additional info) */}
          {appUserData && (
            <>
              <div className="border-t border-gray-200 pt-6 mt-6">
                <h3 className="text-lg font-semibold text-gray-700 mb-4">📱 App-Specific Metrics (from Firestore)</h3>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <MetricCard
                  title="Registered Users"
                  value={appUserData.totalUsers}
                  subtitle="In Firestore"
                />
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
            </>
          )}
        </div>
      );
    }

    // Fallback to Firestore data only
    if (appUserData) {
      return (
        <div className="space-y-6">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 text-sm text-yellow-700">
            ⚠️ GA4 analytics unavailable. Showing Firestore user data only.
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard title="Total Users" value={appUserData.totalUsers} color="info" />
            <MetricCard title="Active (7 days)" value={appUserData.recentlyActiveUsers} color="success" />
            <MetricCard title="New Today" value={appUserData.newUsersToday} />
            <MetricCard title="New This Week" value={appUserData.newUsersThisWeek} />
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard title="Total Scans" value={appUserData.totalScans} subtitle={`${appUserData.avgScansPerUser} avg/user`} />
            <MetricCard title="Total Searches" value={appUserData.totalSearches} subtitle={`${appUserData.avgSearchesPerUser} avg/user`} />
            <MetricCard title="Foods Logged" value={appUserData.totalFoodsLogged} />
            <MetricCard title="Reactions Logged" value={appUserData.totalReactionsLogged} />
          </div>
        </div>
      );
    }

    return (
      <div className="text-center py-12 text-gray-500">
        <p>No analytics data available</p>
        <button
          onClick={fetchData}
          className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          Retry Loading
        </button>
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
            {/* Auth status badge */}
            <UserBadge />

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
