import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import algoliasearch from 'algoliasearch';
import * as busboy from 'busboy';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.key || '';
const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

/**
 * Upload food image to Firebase Storage and update Algolia
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
      const bb = busboy({ headers: req.headers });
      const tmpdir = os.tmpdir();

      const fields: Record<string, string> = {};
      const uploads: Record<string, string> = {};

      bb.on('field', (name: string, val: string) => {
        fields[name] = val;
      });

      bb.on('file', (name: string, file: NodeJS.ReadableStream, info: busboy.FileInfo) => {
        const { filename } = info;
        const filepath = path.join(tmpdir, filename);
        uploads[name] = filepath;
        file.pipe(fs.createWriteStream(filepath));
      });

      bb.on('finish', async () => {
        try {
          const { index, objectID } = fields;
          const filePath = uploads['file'];

          if (!index || !objectID || !filePath) {
            res.status(400).json({ error: 'Missing required fields' });
            return;
          }

          const bucket = admin.storage().bucket();
          const fileName = `food-images/${index}/${objectID}.jpg`;

          await bucket.upload(filePath, {
            destination: fileName,
            metadata: { contentType: 'image/jpeg' },
          });

          await bucket.file(fileName).makePublic();

          const imageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

          const algoliaIndex = client.initIndex(index);
          await algoliaIndex.partialUpdateObject({ objectID, imageUrl });

          fs.unlinkSync(filePath);

          res.status(200).json({ success: true, imageUrl });
        } catch (error) {
          console.error('Upload error:', error);
          res.status(500).json({ error: 'Upload failed' });
        }
      });

      req.pipe(bb);
    } catch (error) {
      console.error('Request error:', error);
      res.status(500).json({ error: 'Request processing failed' });
    }
  });
