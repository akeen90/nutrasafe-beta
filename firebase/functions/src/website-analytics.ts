import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Parse device type from user agent string
 */
function parseDeviceType(userAgent: string): string {
  if (!userAgent) return 'Unknown';

  const ua = userAgent.toLowerCase();

  if (ua.includes('mobile') || ua.includes('android') || ua.includes('iphone')) {
    return 'Mobile';
  } else if (ua.includes('tablet') || ua.includes('ipad')) {
    return 'Tablet';
  } else if (ua.includes('bot') || ua.includes('crawler') || ua.includes('spider')) {
    return 'Bot';
  } else {
    return 'Desktop';
  }
}

/**
 * Get website analytics from cookie_consents collection
 */
export const getWebsiteAnalytics = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    console.log('Getting website analytics...');

    const db = admin.firestore();

    // Get all cookie consent records
    const consentsSnapshot = await db.collection('cookie_consents').get();

    // Initialize counters
    const totalVisitors = consentsSnapshot.size;
    let acceptedConsent = 0;
    let rejectedConsent = 0;
    const pageCount: Record<string, number> = {};
    const referrerCount: Record<string, number> = {};
    const dailyCount: Record<string, number> = {};
    const deviceCount: Record<string, number> = {};

    // Process each consent record
    consentsSnapshot.docs.forEach(doc => {
      const data = doc.data();

      // Count consent choices
      const choice = data.choice;
      if (choice === 'accepted') {
        acceptedConsent++;
      } else if (choice === 'rejected') {
        rejectedConsent++;
      }

      // Count by page
      const page = data.page || '/';
      pageCount[page] = (pageCount[page] || 0) + 1;

      // Count by referrer
      const referrer = data.referrer || 'direct';
      // Clean up referrer - extract domain
      let cleanReferrer = referrer;
      try {
        if (referrer !== 'direct' && referrer.startsWith('http')) {
          const url = new URL(referrer);
          cleanReferrer = url.hostname;
        }
      } catch {
        cleanReferrer = referrer;
      }
      referrerCount[cleanReferrer] = (referrerCount[cleanReferrer] || 0) + 1;

      // Count by day
      const timestamp = data.timestamp;
      if (timestamp) {
        let date: string;
        if (typeof timestamp === 'string') {
          date = timestamp.split('T')[0];
        } else if (timestamp.toDate) {
          date = timestamp.toDate().toISOString().split('T')[0];
        } else {
          date = new Date(timestamp).toISOString().split('T')[0];
        }
        dailyCount[date] = (dailyCount[date] || 0) + 1;
      }

      // Count by device type
      const userAgent = data.userAgent || '';
      const deviceType = parseDeviceType(userAgent);
      deviceCount[deviceType] = (deviceCount[deviceType] || 0) + 1;
    });

    // Calculate consent rate
    const consentRate = totalVisitors > 0
      ? Math.round((acceptedConsent / totalVisitors) * 100 * 10) / 10
      : 0;

    // Sort and format page data (top 10)
    const visitorsByPage = Object.entries(pageCount)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([page, count]) => ({ page, count }));

    // Sort and format referrer data (top 10)
    const topReferrers = Object.entries(referrerCount)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([referrer, count]) => ({ referrer, count }));

    // Sort and format daily data (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const visitorsByDay = Object.entries(dailyCount)
      .filter(([date]) => new Date(date) >= thirtyDaysAgo)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, count]) => ({ date, count }));

    // Fill in missing days with zeros
    const filledVisitorsByDay: { date: string; count: number }[] = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      const existing = visitorsByDay.find(d => d.date === dateStr);
      filledVisitorsByDay.push({
        date: dateStr,
        count: existing ? existing.count : 0
      });
    }

    // Format device breakdown
    const deviceBreakdown = Object.entries(deviceCount)
      .sort(([, a], [, b]) => b - a)
      .map(([device, count]) => ({ device, count }));

    const analytics = {
      totalVisitors,
      acceptedConsent,
      rejectedConsent,
      consentRate,
      visitorsByDay: filledVisitorsByDay,
      visitorsByPage,
      topReferrers,
      deviceBreakdown,
      generatedAt: new Date().toISOString()
    };

    console.log(`Website analytics generated - Total visitors: ${totalVisitors}, Consent rate: ${consentRate}%`);

    res.json({
      success: true,
      analytics
    });

  } catch (error) {
    console.error('Error getting website analytics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get website analytics'
    });
  }
});
