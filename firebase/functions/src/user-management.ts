import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Get all users with pagination
export const getUsers = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    console.log('Getting users list...');

    const db = admin.firestore();
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;
    
    // Get users from Firestore
    const usersSnapshot = await db.collection('users')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .offset(offset)
      .get();
    
    // Also get total count
    const totalSnapshot = await db.collection('users').get();
    const totalUsers = totalSnapshot.size;

    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Convert Firestore timestamps to ISO strings
      createdAt: doc.data().createdAt ? doc.data().createdAt.toDate().toISOString() : null,
      lastLogin: doc.data().lastLogin ? doc.data().lastLogin.toDate().toISOString() : null,
      lastActivity: doc.data().lastActivity ? doc.data().lastActivity.toDate().toISOString() : null
    }));

    console.log(`Found ${users.length} users (${totalUsers} total)`);

    res.json({
      success: true,
      users,
      totalUsers,
      hasMore: offset + users.length < totalUsers
    });

  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
});

// Add new user
export const addUser = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const {
      email,
      displayName,
      phoneNumber,
      role = 'user',
      allergens = [],
      preferences = {}
    } = req.body;

    if (!email) {
      res.status(400).json({ error: 'Email is required' });
      return;
    }

    console.log(`Adding new user: ${email}`);

    const db = admin.firestore();
    const userRef = db.collection('users').doc();
    
    const userData = {
      email,
      displayName: displayName || '',
      phoneNumber: phoneNumber || '',
      role,
      allergens,
      preferences,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
      lastActivity: null,
      // App usage stats
      totalScans: 0,
      totalSearches: 0,
      foodsLogged: 0,
      reactionsLogged: 0
    };

    await userRef.set(userData);

    res.json({
      success: true,
      message: 'User added successfully',
      userId: userRef.id,
      user: {
        id: userRef.id,
        ...userData,
        createdAt: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error adding user:', error);
    res.status(500).json({ error: 'Failed to add user' });
  }
});

// Update user
export const updateUser = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { userId, ...updateData } = req.body;

    if (!userId) {
      res.status(400).json({ error: 'User ID is required' });
      return;
    }

    console.log(`Updating user: ${userId}`);

    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);
    
    // Remove fields that shouldn't be updated directly
    const { createdAt, ...safeUpdateData } = updateData;
    
    await userRef.update({
      ...safeUpdateData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({
      success: true,
      message: 'User updated successfully',
      userId
    });

  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Delete users (batch operation)
export const deleteUsers = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { userIds } = req.body;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      res.status(400).json({ error: 'User IDs array is required' });
      return;
    }

    console.log(`Deleting users: ${userIds.join(', ')}`);

    const db = admin.firestore();
    const batch = db.batch();
    
    for (const userId of userIds) {
      const userRef = db.collection('users').doc(userId);
      batch.delete(userRef);
    }

    await batch.commit();

    res.json({
      success: true,
      message: `Successfully deleted ${userIds.length} user(s)`,
      deletedIds: userIds
    });

  } catch (error) {
    console.error('Error deleting users:', error);
    res.status(500).json({ error: 'Failed to delete users' });
  }
});

// Get user analytics
export const getUserAnalytics = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    console.log('Getting user analytics...');

    const db = admin.firestore();
    
    // Get all users for analysis
    const usersSnapshot = await db.collection('users').get();
    const users = usersSnapshot.docs.map(doc => doc.data());

    // Calculate analytics
    const totalUsers = users.length;
    const activeUsers = users.filter(user => user.isActive).length;
    
    // Date calculations
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    // Users by activity
    const newUsersToday = users.filter(user => {
      const createdAt = user.createdAt ? user.createdAt.toDate() : null;
      return createdAt && createdAt > oneDayAgo;
    }).length;

    const newUsersThisWeek = users.filter(user => {
      const createdAt = user.createdAt ? user.createdAt.toDate() : null;
      return createdAt && createdAt > oneWeekAgo;
    }).length;

    const recentlyActiveUsers = users.filter(user => {
      const lastActivity = user.lastActivity ? user.lastActivity.toDate() : null;
      return lastActivity && lastActivity > oneWeekAgo;
    }).length;

    // App usage stats
    const totalScans = users.reduce((sum, user) => sum + (user.totalScans || 0), 0);
    const totalSearches = users.reduce((sum, user) => sum + (user.totalSearches || 0), 0);
    const totalFoodsLogged = users.reduce((sum, user) => sum + (user.foodsLogged || 0), 0);
    const totalReactionsLogged = users.reduce((sum, user) => sum + (user.reactionsLogged || 0), 0);

    // Most common allergens
    const allergenCounts: { [key: string]: number } = {};
    users.forEach(user => {
      if (user.allergens && Array.isArray(user.allergens)) {
        user.allergens.forEach((allergen: string) => {
          allergenCounts[allergen] = (allergenCounts[allergen] || 0) + 1;
        });
      }
    });

    const topAllergens = Object.entries(allergenCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([allergen, count]) => ({ allergen, count }));

    // User growth data (30 days)
    const userGrowthData = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      
      const usersOnDate = users.filter(user => {
        const createdAt = user.createdAt ? user.createdAt.toDate() : null;
        return createdAt && createdAt.toDateString() === date.toDateString();
      }).length;
      
      userGrowthData.push({
        date: dateStr,
        newUsers: usersOnDate
      });
    }

    const analytics = {
      // User statistics
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsersThisWeek,
      recentlyActiveUsers,
      
      // App usage
      totalScans,
      totalSearches,
      totalFoodsLogged,
      totalReactionsLogged,
      
      // Insights
      topAllergens,
      userGrowthData,
      
      // Averages
      avgScansPerUser: totalUsers > 0 ? (totalScans / totalUsers).toFixed(1) : 0,
      avgSearchesPerUser: totalUsers > 0 ? (totalSearches / totalUsers).toFixed(1) : 0,
      
      generatedAt: new Date().toISOString()
    };

    console.log(`User analytics generated - Total: ${totalUsers}, Active: ${activeUsers}`);

    res.json({
      success: true,
      analytics
    });

  } catch (error) {
    console.error('Error getting user analytics:', error);
    res.status(500).json({ error: 'Failed to get user analytics' });
  }
});