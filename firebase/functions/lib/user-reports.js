"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserReport = exports.updateUserReport = exports.getUserReports = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
/**
 * Cloud Function to fetch user reports for Database Manager
 * Uses Admin SDK to bypass Firestore rules
 */
exports.getUserReports = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const db = admin.firestore();
        // Get optional status filter from query params
        const statusFilter = req.query.status;
        let query = db.collection('userReports')
            .orderBy('reportedAt', 'desc')
            .limit(100);
        if (statusFilter && ['pending', 'in_progress', 'resolved', 'dismissed'].includes(statusFilter)) {
            query = db.collection('userReports')
                .where('status', '==', statusFilter)
                .orderBy('reportedAt', 'desc')
                .limit(100);
        }
        const snapshot = await query.get();
        const reports = snapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                // Convert Firestore Timestamp to ISO string
                reportedAt: data.reportedAt?.toDate?.()?.toISOString() || null,
                resolvedAt: data.resolvedAt?.toDate?.()?.toISOString() || null
            };
        });
        // Count pending reports
        const pendingCount = reports.filter(r => r.status === 'pending').length;
        res.status(200).json({
            success: true,
            reports,
            pendingCount,
            total: reports.length
        });
    }
    catch (error) {
        console.error('❌ Error fetching user reports:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch reports'
        });
    }
});
/**
 * Cloud Function to update report status
 */
exports.updateUserReport = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, PATCH, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { reportId, status, notes } = req.body;
        if (!reportId) {
            res.status(400).json({ success: false, error: 'Report ID is required' });
            return;
        }
        if (!status || !['pending', 'in_progress', 'resolved', 'dismissed'].includes(status)) {
            res.status(400).json({ success: false, error: 'Valid status is required' });
            return;
        }
        const db = admin.firestore();
        const updateData = {
            status,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        if (status === 'resolved' || status === 'dismissed') {
            updateData.resolvedAt = admin.firestore.FieldValue.serverTimestamp();
        }
        if (notes) {
            updateData.notes = notes;
        }
        await db.collection('userReports').doc(reportId).update(updateData);
        res.status(200).json({
            success: true,
            message: 'Report updated successfully'
        });
    }
    catch (error) {
        console.error('❌ Error updating report:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update report'
        });
    }
});
/**
 * Cloud Function to delete a report
 */
exports.deleteUserReport = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const { reportId } = req.body;
        if (!reportId) {
            res.status(400).json({ success: false, error: 'Report ID is required' });
            return;
        }
        const db = admin.firestore();
        await db.collection('userReports').doc(reportId).delete();
        res.status(200).json({
            success: true,
            message: 'Report deleted successfully'
        });
    }
    catch (error) {
        console.error('❌ Error deleting report:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete report'
        });
    }
});
//# sourceMappingURL=user-reports.js.map