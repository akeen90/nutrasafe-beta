/**
 * Upload Food Image Function
 * Uploads processed food images to Firebase Storage and updates the food document
 */

import * as functions from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const bucket = admin.storage().bucket();

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const algoliaAdminKey = defineSecret('ALGOLIA_ADMIN_API_KEY');

// Map Algolia index names to Firestore collection names
const INDEX_TO_COLLECTION: Record<string, string | null> = {
  'uk_foods_cleaned': null,
  'fast_foods_database': null,
  'generic_database': null,
  'foods': 'foods',
  'verified_foods': 'verifiedFoods',
  'manual_foods': 'manualFoods',
  'user_added': 'userAdded',
  'ai_enhanced': 'aiEnhanced',
  'ai_manually_added': 'aiManuallyAdded',
  'tesco_products': 'tescoProducts',  // Fixed: was 'tesco_products', should be 'tescoProducts'
};

/**
 * Upload a processed food image to Firebase Storage and update the database
 */
export const uploadFoodImage = functions
  .runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 120,
    memory: '512MB'
  })
  .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(200).send();
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ success: false, error: 'Method not allowed' });
      return;
    }

    try {
      const { foodId, imageData, sourceIndex, objectID } = req.body;

      if (!foodId && !objectID) {
        res.status(400).json({ success: false, error: 'foodId or objectID is required' });
        return;
      }

      if (!imageData) {
        res.status(400).json({ success: false, error: 'imageData is required' });
        return;
      }

      // Extract base64 data from data URL
      const matches = imageData.match(/^data:image\/(\w+);base64,(.+)$/);
      if (!matches) {
        res.status(400).json({ success: false, error: 'Invalid image data format' });
        return;
      }

      const imageFormat = matches[1]; // png, jpeg, etc.
      const base64Data = matches[2];
      const imageBuffer = Buffer.from(base64Data, 'base64');

      // Generate file path
      const identifier = foodId || objectID;
      const filePath = `food-images/cleaned/${identifier}.${imageFormat}`;

      // Upload to Firebase Storage
      const file = bucket.file(filePath);
      await file.save(imageBuffer, {
        metadata: {
          contentType: `image/${imageFormat}`,
          cacheControl: 'public, max-age=31536000', // Cache for 1 year
        },
      });

      // Make the file publicly accessible
      await file.makePublic();

      // Get the public URL
      const imageUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

      console.log(`Uploaded image for ${identifier}: ${imageUrl}`);

      // Update the database
      let updated = false;

      // If sourceIndex is provided, try to update the right place
      if (sourceIndex) {
        const collection = INDEX_TO_COLLECTION[sourceIndex];

        if (collection) {
          // Has Firestore backing - update Firestore (will auto-sync to Algolia)
          const docRef = db.collection(collection).doc(identifier);
          const doc = await docRef.get();

          if (doc.exists) {
            await docRef.update({
              imageUrl: imageUrl,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            updated = true;
            console.log(`Updated Firestore: ${collection}/${identifier}`);
          }
        } else {
          // Algolia-only index - update directly in Algolia
          const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

          await client.partialUpdateObject({
            indexName: sourceIndex,
            objectID: identifier,
            attributesToUpdate: {
              imageUrl: imageUrl,
            },
            createIfNotExists: false,
          });

          updated = true;
          console.log(`Updated Algolia: ${sourceIndex}/${identifier}`);
        }
      }

      // If not updated via sourceIndex, try to find the food in Firestore collections
      if (!updated) {
        for (const [, collectionName] of Object.entries(INDEX_TO_COLLECTION)) {
          if (!collectionName) continue;

          const docRef = db.collection(collectionName).doc(identifier);
          const doc = await docRef.get();

          if (doc.exists) {
            await docRef.update({
              imageUrl: imageUrl,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            updated = true;
            console.log(`Found and updated in Firestore: ${collectionName}/${identifier}`);
            break;
          }
        }
      }

      res.status(200).json({
        success: true,
        imageUrl: imageUrl,
        updated: updated,
      });

    } catch (error) {
      console.error('Error uploading food image:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });

/**
 * Batch upload food images
 * For processing multiple images at once
 */
export const batchUploadFoodImages = functions
  .runWith({
    secrets: [algoliaAdminKey],
    timeoutSeconds: 540, // 9 minutes
    memory: '1GB'
  })
  .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(200).send();
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ success: false, error: 'Method not allowed' });
      return;
    }

    try {
      const { images } = req.body;

      if (!images || !Array.isArray(images)) {
        res.status(400).json({ success: false, error: 'images array is required' });
        return;
      }

      const results: { foodId: string; success: boolean; imageUrl?: string; error?: string }[] = [];
      const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

      for (const image of images) {
        try {
          const { foodId, imageData, sourceIndex } = image;

          if (!foodId || !imageData) {
            results.push({ foodId: foodId || 'unknown', success: false, error: 'Missing foodId or imageData' });
            continue;
          }

          // Extract base64 data
          const matches = imageData.match(/^data:image\/(\w+);base64,(.+)$/);
          if (!matches) {
            results.push({ foodId, success: false, error: 'Invalid image format' });
            continue;
          }

          const imageFormat = matches[1];
          const base64Data = matches[2];
          const imageBuffer = Buffer.from(base64Data, 'base64');

          // Upload to Storage
          const filePath = `food-images/cleaned/${foodId}.${imageFormat}`;
          const file = bucket.file(filePath);
          await file.save(imageBuffer, {
            metadata: {
              contentType: `image/${imageFormat}`,
              cacheControl: 'public, max-age=31536000',
            },
          });
          await file.makePublic();

          const imageUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

          // Update database
          const collection = sourceIndex ? INDEX_TO_COLLECTION[sourceIndex] : null;

          if (collection) {
            await db.collection(collection).doc(foodId).update({
              imageUrl: imageUrl,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else if (sourceIndex) {
            await client.partialUpdateObject({
              indexName: sourceIndex,
              objectID: foodId,
              attributesToUpdate: { imageUrl: imageUrl },
              createIfNotExists: false,
            });
          }

          results.push({ foodId, success: true, imageUrl });

        } catch (error) {
          results.push({
            foodId: image.foodId || 'unknown',
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error',
          });
        }
      }

      const successCount = results.filter(r => r.success).length;
      const failCount = results.filter(r => !r.success).length;

      res.status(200).json({
        success: true,
        total: images.length,
        succeeded: successCount,
        failed: failCount,
        results,
      });

    } catch (error) {
      console.error('Error in batch upload:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
