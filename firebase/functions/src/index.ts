import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import * as cors from 'cors';

admin.initializeApp();

const corsHandler = cors({origin: true});

interface FatSecretTokenResponse {
  access_token: string;
  expires_in: number;
  token_type: string;
}

interface FoodSearchResponse {
  foods?: {
    food?: Array<{
      food_id: string;
      food_name: string;
      brand_name?: string;
      food_type: string;
      food_url?: string;
    }>;
    max_results?: string;
    page_number?: string;
    total_results?: string;
  };
}

interface FoodDetailsResponse {
  food: {
    food_id: string;
    food_name: string;
    brand_name?: string;
    servings: {
      serving: Array<{
        calories?: string;
        carbohydrate?: string;
        fat?: string;
        fiber?: string;
        protein?: string;
        sodium?: string;
        sugar?: string;
        serving_description: string;
      }>;
    };
  };
}

let cachedToken: string | null = null;
let tokenExpiry: Date | null = null;

const FATSECRET_CLIENT_ID = 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = '9b2fa211700749fa98ac5dd243602189';
const FATSECRET_AUTH_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';

async function getFatSecretToken(): Promise<string> {
  if (cachedToken && tokenExpiry && tokenExpiry > new Date()) {
    return cachedToken;
  }

  const credentials = Buffer.from(`${FATSECRET_CLIENT_ID}:${FATSECRET_CLIENT_SECRET}`).toString('base64');
  
  try {
    console.log('Requesting FatSecret token...');
    const response = await axios.post(
      FATSECRET_AUTH_URL,
      'grant_type=client_credentials',
      {
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        timeout: 10000
      }
    );

    const tokenData: FatSecretTokenResponse = response.data;
    cachedToken = tokenData.access_token;
    tokenExpiry = new Date(Date.now() + (tokenData.expires_in - 60) * 1000); // 60 second buffer

    console.log('FatSecret token obtained successfully');
    return cachedToken;
  } catch (error: any) {
    console.error('Error getting FatSecret token:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', `Failed to authenticate with FatSecret API: ${error.message}`);
  }
}

export const searchFoods = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const {query, maxResults = '50'} = req.body;

      if (!query) {
        res.status(400).json({error: 'Query parameter is required'});
        return;
      }

      const token = await getFatSecretToken();

      const response = await axios.get(FATSECRET_API_URL, {
        params: {
          method: 'foods.search',
          search_expression: query,
          format: 'json',
          max_results: maxResults,
        },
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const searchData: FoodSearchResponse = response.data;

      if (!searchData.foods?.food) {
        res.json({foods: []});
        return;
      }

      const foods = searchData.foods.food.map(food => ({
        id: food.food_id,
        name: food.food_name,
        brand: food.brand_name || null,
        calories: 0, // Will be populated by getFoodDetails
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
      }));

      // Track the search event for analytics
      try {
        await admin.firestore().collection('analytics_events').add({
          eventType: 'food_search',
          userId: 'anonymous',
          metadata: { 
            query, 
            resultsCount: foods.length,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          date: new Date().toISOString().split('T')[0],
        });

        // Update daily stats
        const today = new Date().toISOString().split('T')[0];
        const dailyStatsRef = admin.firestore().collection('daily_stats').doc(today);
        await dailyStatsRef.set({
          date: today,
          food_search_count: admin.firestore.FieldValue.increment(1),
          total_events: admin.firestore.FieldValue.increment(1),
          last_updated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      } catch (analyticsError) {
        console.log('Analytics tracking failed:', analyticsError);
        // Don't fail the main request if analytics fail
      }

      res.json({foods});
    } catch (error) {
      console.error('Error searching foods:', error);
      res.status(500).json({error: 'Failed to search foods'});
    }
  });
});

export const getFoodDetails = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const {foodId} = req.body;

      if (!foodId) {
        res.status(400).json({error: 'Food ID parameter is required'});
        return;
      }

      const token = await getFatSecretToken();

      const response = await axios.get(FATSECRET_API_URL, {
        params: {
          method: 'food.get.v2',
          food_id: foodId,
          format: 'json',
        },
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const foodData: FoodDetailsResponse = response.data;
      const food = foodData.food;
      const serving = food.servings.serving[0];

      if (!serving) {
        res.status(404).json({error: 'No serving information found'});
        return;
      }

      const result = {
        id: food.food_id,
        name: food.food_name,
        brand: food.brand_name || null,
        calories: parseFloat(serving.calories || '0'),
        protein: parseFloat(serving.protein || '0'),
        carbs: parseFloat(serving.carbohydrate || '0'),
        fat: parseFloat(serving.fat || '0'),
        fiber: parseFloat(serving.fiber || '0'),
        sugar: parseFloat(serving.sugar || '0'),
        sodium: parseFloat(serving.sodium || '0'),
      };

      // Track the food details event for analytics
      try {
        await admin.firestore().collection('analytics_events').add({
          eventType: 'food_details',
          userId: 'anonymous',
          metadata: { 
            foodId,
            foodName: result.name,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          date: new Date().toISOString().split('T')[0],
        });

        // Update daily stats
        const today = new Date().toISOString().split('T')[0];
        const dailyStatsRef = admin.firestore().collection('daily_stats').doc(today);
        await dailyStatsRef.set({
          date: today,
          food_details_count: admin.firestore.FieldValue.increment(1),
          total_events: admin.firestore.FieldValue.increment(1),
          last_updated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      } catch (analyticsError) {
        console.log('Analytics tracking failed:', analyticsError);
        // Don't fail the main request if analytics fail
      }

      res.json(result);
    } catch (error) {
      console.error('Error getting food details:', error);
      res.status(500).json({error: 'Failed to get food details'});
    }
  });
});

// Health check endpoint
export const healthCheck = functions.https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'nutrasafe-functions'
    });
  });
});

// IP check endpoint - shows what IP Firebase Functions uses for outbound requests
export const checkIP = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    try {
      // Make a request to an IP detection service
      const ipResponse = await axios.get('https://api.ipify.org?format=json', {
        timeout: 5000
      });
      
      res.json({
        outboundIP: ipResponse.data.ip,
        timestamp: new Date().toISOString(),
        service: 'nutrasafe-functions',
        region: 'us-central1'
      });
    } catch (error: any) {
      console.error('Error checking IP:', error.message);
      res.status(500).json({
        error: 'Failed to check IP',
        message: error.message
      });
    }
  });
});

// Analytics Functions
export const trackEvent = functions.https.onCall(async (data, context) => {
  try {
    const { eventType, userId, metadata } = data;
    
    if (!eventType) {
      throw new functions.https.HttpsError('invalid-argument', 'Event type is required');
    }

    const eventData = {
      eventType,
      userId: userId || context.auth?.uid || 'anonymous',
      metadata: metadata || {},
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      date: new Date().toISOString().split('T')[0], // YYYY-MM-DD for easy querying
    };

    await admin.firestore().collection('analytics_events').add(eventData);
    
    // Update daily stats
    const dailyStatsRef = admin.firestore()
      .collection('daily_stats')
      .doc(eventData.date);
    
    await dailyStatsRef.set({
      date: eventData.date,
      [`${eventType}_count`]: admin.firestore.FieldValue.increment(1),
      total_events: admin.firestore.FieldValue.increment(1),
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true, eventId: eventData };
  } catch (error: any) {
    console.error('Error tracking event:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const getAnalytics = functions.https.onCall(async (data, context) => {
  try {
    // Check if user is admin (you might want to implement proper admin checking)
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { period = '30', type = 'overview' } = data;
    const daysAgo = parseInt(period);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysAgo);
    
    if (type === 'overview') {
      // Get total users from Firebase Authentication
      const listUsersResult = await admin.auth().listUsers();
      const totalUsers = listUsersResult.users.length;

      // Get active users (users with events in last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const activeUsersSnapshot = await admin.firestore()
        .collection('analytics_events')
        .where('timestamp', '>=', thirtyDaysAgo)
        .get();
      
      const activeUserIds = new Set();
      activeUsersSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.userId && data.userId !== 'anonymous') {
          activeUserIds.add(data.userId);
        }
      });

      // Get API calls today
      const today = new Date().toISOString().split('T')[0];
      const todayStatsDoc = await admin.firestore()
        .collection('daily_stats')
        .doc(today)
        .get();
      
      const todayStats = todayStatsDoc.data() || {};
      const apiCallsToday = (todayStats.food_search_count || 0) + (todayStats.food_details_count || 0);

      return {
        totalUsers,
        activeUsers: activeUserIds.size,
        apiCallsToday,
        systemUptime: '99.9%'
      };
    }
    
    if (type === 'daily') {
      const dailyStatsSnapshot = await admin.firestore()
        .collection('daily_stats')
        .where('date', '>=', startDate.toISOString().split('T')[0])
        .orderBy('date', 'asc')
        .get();

      const dailyData: any[] = [];
      dailyStatsSnapshot.forEach(doc => {
        dailyData.push({ id: doc.id, ...doc.data() });
      });

      return dailyData;
    }

    return {};
  } catch (error: any) {
    console.error('Error getting analytics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const getUserStats = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    // Get all Firebase Authentication users
    const listUsersResult = await admin.auth().listUsers(100);
    const users: any[] = [];

    for (const userRecord of listUsersResult.users) {
      // Get additional user data from Firestore if it exists
      let firestoreData: any = {};
      try {
        const firestoreDoc = await admin.firestore().collection('users').doc(userRecord.uid).get();
        if (firestoreDoc.exists) {
          firestoreData = firestoreDoc.data() || {};
        }
      } catch (error) {
        // Firestore data doesn't exist, that's ok
      }

      // Get last activity from analytics
      let lastActive = 'Never';
      try {
        const lastActivitySnapshot = await admin.firestore()
          .collection('analytics_events')
          .where('userId', '==', userRecord.uid)
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();

        if (!lastActivitySnapshot.empty) {
          const lastActivity = lastActivitySnapshot.docs[0].data();
          const timestamp = lastActivity.timestamp.toDate();
          lastActive = timestamp.toLocaleDateString();
        }
      } catch (error) {
        // No analytics data yet
      }

      users.push({
        id: userRecord.uid,
        email: userRecord.email || 'Unknown',
        name: userRecord.displayName || firestoreData.name || 'Unknown User',
        status: userRecord.disabled ? 'inactive' : 'active',
        plan: firestoreData.plan || 'Basic',
        lastActive,
        createdAt: userRecord.metadata.creationTime,
        emailVerified: userRecord.emailVerified
      });
    }

    return users;
  } catch (error: any) {
    console.error('Error getting user stats:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// User Management Functions
export const createUser = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { email, name, plan = 'Basic', password = 'tempPassword123!' } = data;
    
    if (!email || !name) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and name are required');
    }

    // Create the Firebase Authentication user
    const userRecord = await admin.auth().createUser({
      email,
      displayName: name,
      password,
      emailVerified: false,
    });

    // Create additional user data in Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      name,
      plan,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, userId: userRecord.uid, message: 'User created successfully. Password: tempPassword123!' };
  } catch (error: any) {
    console.error('Error creating user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const updateUser = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { userId, updates } = data;
    
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
    }

    // Check if user exists in Firebase Auth
    try {
      await admin.auth().getUser(userId);
    } catch (error) {
      throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
    }

    // Update Firebase Auth user if name is being updated
    if (updates.name) {
      await admin.auth().updateUser(userId, {
        displayName: updates.name,
      });
    }

    // Update Firestore user data
    await admin.firestore().collection('users').doc(userId).set({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true };
  } catch (error: any) {
    console.error('Error updating user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const deleteUser = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { userId } = data;
    
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
    }

    // Check if user exists in Firebase Auth
    try {
      await admin.auth().getUser(userId);
    } catch (error) {
      throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
    }

    // Delete user from Firebase Authentication
    await admin.auth().deleteUser(userId);

    // Delete user data from Firestore
    try {
      await admin.firestore().collection('users').doc(userId).delete();
    } catch (error) {
      console.log('No Firestore data to delete for user:', userId);
    }

    return { success: true };
  } catch (error: any) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to manually add current admin as user
export const addAdminAsUser = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const adminEmail = context.auth.token.email || 'admin@nutrasafe.com';
    const adminName = context.auth.token.name || 'Admin User';
    
    // Check if admin user already exists
    const existingUsers = await admin.firestore()
      .collection('users')
      .where('email', '==', adminEmail)
      .get();

    if (!existingUsers.empty) {
      return { success: true, message: 'Admin user already exists' };
    }

    // Create admin user
    const userRef = admin.firestore().collection('users').doc(context.auth.uid);
    await userRef.set({
      email: adminEmail,
      name: adminName,
      plan: 'Admin',
      status: 'active',
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'Admin user created successfully' };
  } catch (error: any) {
    console.error('Error adding admin as user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});