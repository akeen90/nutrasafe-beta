import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {algoliasearch} from 'algoliasearch';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const getAlgoliaAdminKey = () => functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || '';

/**
 * Upload food image to Firebase Storage and update Algolia
 * Accepts JSON with imageUrl (URL to fetch), index, and objectID
 */
export const uploadFoodImage = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      const { imageUrl, index, objectID } = req.body;

      if (!imageUrl || !index || !objectID) {
        res.status(400).json({ error: 'Missing required fields: imageUrl, index, objectID' });
        return;
      }

      // Fetch the image
      const imageResponse = await fetch(imageUrl);
      if (!imageResponse.ok) {
        throw new Error('Failed to fetch image');
      }

      const imageBuffer = Buffer.from(await imageResponse.arrayBuffer());

      // Upload to Firebase Storage
      const bucket = admin.storage().bucket();
      const fileName = `food-images/${index}/${objectID}.jpg`;
      const file = bucket.file(fileName);

      await file.save(imageBuffer, {
        metadata: {
          contentType: 'image/jpeg',
        },
      });

      await file.makePublic();

      const firebaseImageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      // Update Algolia (v5 API - client IS the index)
      const adminKey = getAlgoliaAdminKey();
      if (!adminKey) {
        throw new Error('Algolia admin key not configured');
      }

      const algoliaClient = algoliasearch(ALGOLIA_APP_ID, adminKey);
      await algoliaClient.partialUpdateObject({
        indexName: index,
        objectID,
        attributesToUpdate: {
          imageUrl: firebaseImageUrl,
        },
      });

      res.status(200).json({
        success: true,
        imageUrl: firebaseImageUrl,
        message: 'Image uploaded successfully',
      });
    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({
        error: 'Upload failed',
        details: error instanceof Error ? error.message : String(error),
      });
    }
  });

/**
 * Batch upload food images (placeholder for future)
 */
export const batchUploadFoodImages = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    res.status(501).json({ error: 'Not implemented yet' });
  });
