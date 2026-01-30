/**
 * GA4 Analytics Integration
 * Fetches real analytics data from Google Analytics 4 Data API
 */

import * as functions from 'firebase-functions';
import { BetaAnalyticsDataClient } from '@google-analytics/data';

// Initialize the Analytics Data API client
// Uses Application Default Credentials (Firebase service account)
const analyticsDataClient = new BetaAnalyticsDataClient();

// GA4 Property ID - Set via Firebase config:
// firebase functions:config:set ga4.property_id="YOUR_PROPERTY_ID"
// Find it in: Google Analytics > Admin > Property Settings > Property ID

/**
 * Get real GA4 analytics data
 * Requires the Firebase service account to have "Viewer" role on the GA4 property
 */
export const getGA4Analytics = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  // Check admin access
  const OWNER_EMAILS = ['aaronmkeen@gmail.com', 'aaron@nutrasafe.co.uk'];
  const userEmail = context.auth.token.email?.toLowerCase();
  if (!userEmail || !OWNER_EMAILS.includes(userEmail)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  try {
    // Get GA4 property ID from config
    const config = functions.config();
    const propertyId = config.ga4?.property_id;

    if (!propertyId) {
      console.error('GA4 property ID not configured');
      return {
        success: false,
        error: 'GA4 not configured. Run: firebase functions:config:set ga4.property_id="YOUR_PROPERTY_ID"',
        setupInstructions: {
          step1: 'Go to Google Analytics > Admin > Property Settings',
          step2: 'Copy the Property ID (numeric)',
          step3: 'Run: firebase functions:config:set ga4.property_id="YOUR_PROPERTY_ID"',
          step4: 'Run: firebase deploy --only functions',
          step5: 'Grant Firebase service account "Viewer" role on GA4 property'
        }
      };
    }

    console.log(`Fetching GA4 analytics for property: ${propertyId}`);

    // Get date range (last 30 days)
    const today = new Date();
    const thirtyDaysAgo = new Date(today);
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const formatDate = (d: Date) => d.toISOString().split('T')[0];

    // Fetch multiple reports in parallel
    const [
      activeUsersReport,
      dailyUsersReport,
      eventsReport,
      screenViewsReport,
      engagementReport
    ] = await Promise.all([
      // Active users summary
      analyticsDataClient.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{ startDate: '30daysAgo', endDate: 'today' }],
        metrics: [
          { name: 'activeUsers' },
          { name: 'newUsers' },
          { name: 'totalUsers' },
          { name: 'sessions' },
          { name: 'engagedSessions' },
          { name: 'averageSessionDuration' },
          { name: 'screenPageViews' },
          { name: 'eventCount' }
        ]
      }),

      // Daily active users trend
      analyticsDataClient.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{ startDate: '30daysAgo', endDate: 'today' }],
        dimensions: [{ name: 'date' }],
        metrics: [
          { name: 'activeUsers' },
          { name: 'newUsers' }
        ],
        orderBys: [{ dimension: { dimensionName: 'date' } }]
      }),

      // Top events
      analyticsDataClient.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{ startDate: '30daysAgo', endDate: 'today' }],
        dimensions: [{ name: 'eventName' }],
        metrics: [{ name: 'eventCount' }],
        orderBys: [{ metric: { metricName: 'eventCount' }, desc: true }],
        limit: 15
      }),

      // Top screens
      analyticsDataClient.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{ startDate: '30daysAgo', endDate: 'today' }],
        dimensions: [{ name: 'screenName' }],
        metrics: [{ name: 'screenPageViews' }],
        orderBys: [{ metric: { metricName: 'screenPageViews' }, desc: true }],
        limit: 10
      }),

      // User engagement by day of week
      analyticsDataClient.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{ startDate: '30daysAgo', endDate: 'today' }],
        dimensions: [{ name: 'dayOfWeek' }],
        metrics: [
          { name: 'activeUsers' },
          { name: 'sessions' }
        ]
      })
    ]);

    // Parse active users summary
    const summaryRow = activeUsersReport[0]?.rows?.[0];
    const summary = {
      activeUsers: parseInt(summaryRow?.metricValues?.[0]?.value || '0'),
      newUsers: parseInt(summaryRow?.metricValues?.[1]?.value || '0'),
      totalUsers: parseInt(summaryRow?.metricValues?.[2]?.value || '0'),
      sessions: parseInt(summaryRow?.metricValues?.[3]?.value || '0'),
      engagedSessions: parseInt(summaryRow?.metricValues?.[4]?.value || '0'),
      avgSessionDuration: parseFloat(summaryRow?.metricValues?.[5]?.value || '0'),
      screenViews: parseInt(summaryRow?.metricValues?.[6]?.value || '0'),
      totalEvents: parseInt(summaryRow?.metricValues?.[7]?.value || '0')
    };

    // Parse daily users trend
    const dailyUsers = (dailyUsersReport[0]?.rows || []).map(row => ({
      date: row.dimensionValues?.[0]?.value || '',
      activeUsers: parseInt(row.metricValues?.[0]?.value || '0'),
      newUsers: parseInt(row.metricValues?.[1]?.value || '0')
    }));

    // Parse top events
    const topEvents = (eventsReport[0]?.rows || []).map(row => ({
      event: row.dimensionValues?.[0]?.value || '',
      count: parseInt(row.metricValues?.[0]?.value || '0')
    }));

    // Parse top screens
    const topScreens = (screenViewsReport[0]?.rows || []).map(row => ({
      screen: row.dimensionValues?.[0]?.value || '',
      views: parseInt(row.metricValues?.[0]?.value || '0')
    }));

    // Parse engagement by day of week
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const engagementByDay = (engagementReport[0]?.rows || []).map(row => ({
      day: dayNames[parseInt(row.dimensionValues?.[0]?.value || '0')] || 'Unknown',
      activeUsers: parseInt(row.metricValues?.[0]?.value || '0'),
      sessions: parseInt(row.metricValues?.[1]?.value || '0')
    }));

    // Calculate engagement rate
    const engagementRate = summary.sessions > 0
      ? Math.round((summary.engagedSessions / summary.sessions) * 100)
      : 0;

    const analytics = {
      summary: {
        ...summary,
        engagementRate,
        avgSessionDurationFormatted: formatDuration(summary.avgSessionDuration)
      },
      dailyUsers,
      topEvents,
      topScreens,
      engagementByDay,
      dateRange: {
        start: formatDate(thirtyDaysAgo),
        end: formatDate(today)
      },
      generatedAt: new Date().toISOString()
    };

    console.log('GA4 analytics fetched successfully');

    return {
      success: true,
      analytics
    };

  } catch (error: any) {
    console.error('Error fetching GA4 analytics:', error);

    // Provide helpful error messages
    let errorMessage = error.message || 'Unknown error';
    let helpText = '';

    if (error.code === 7 || errorMessage.includes('permission')) {
      helpText = 'Grant the Firebase service account "Viewer" role on your GA4 property. Go to GA4 > Admin > Property Access Management.';
    } else if (errorMessage.includes('not found') || error.code === 5) {
      helpText = 'Check that your GA4 property ID is correct.';
    }

    return {
      success: false,
      error: errorMessage,
      help: helpText
    };
  }
});

/**
 * Format duration in seconds to human readable string
 */
function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${Math.round(seconds)}s`;
  } else if (seconds < 3600) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.round(seconds % 60);
    return `${mins}m ${secs}s`;
  } else {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${mins}m`;
  }
}

/**
 * Check GA4 configuration status
 */
export const checkGA4Config = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const config = functions.config();
  const propertyId = config.ga4?.property_id;

  return {
    configured: !!propertyId,
    propertyId: propertyId ? `${propertyId.substring(0, 4)}...` : null,
    instructions: !propertyId ? {
      step1: 'Find your GA4 Property ID in Google Analytics > Admin > Property Settings',
      step2: 'Run: firebase functions:config:set ga4.property_id="YOUR_NUMERIC_PROPERTY_ID"',
      step3: 'Run: firebase deploy --only functions',
      step4: 'In GA4 Admin > Property Access Management, add your Firebase service account email with "Viewer" role'
    } : null
  };
});
