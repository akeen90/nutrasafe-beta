/**
 * Filter Tesco Images
 * Uses Vision AI to detect overlay text/freshness labels and filter images
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const cors = require('cors')({ origin: true });

interface ImageAnalysis {
  imageUrl: string;
  hasOverlayText: boolean;
  detectedText: string[];
  confidence: number;
  flags: string[];
  shouldKeep: boolean;
}

// Patterns that indicate overlay/marketing text
const OVERLAY_PATTERNS = [
  /\d+\s*days?/i,           // "5 days", "3 day"
  /use\s*by/i,              // "use by"
  /best\s*before/i,         // "best before"
  /display\s*until/i,       // "display until"
  /fresh(ness)?/i,          // "fresh", "freshness"
  /\d+\/\d+\/\d+/,          // dates like "25/01/26"
  /£\s*\d+/,                // prices like "£5"
  /save\s*£/i,              // "save £"
  /offer/i,                 // "offer"
  /deal/i,                  // "deal"
  /new/i,                   // "new"
  /limited/i,               // "limited"
  /organic\s*badge/i,       // "organic" badge
  /free\s*from/i,           // "free from"
];

/**
 * Analyze image for overlay text using Vision AI
 */
async function analyzeImage(imageUrl: string): Promise<ImageAnalysis> {
  const flags: string[] = [];
  const detectedText: string[] = [];
  let hasOverlayText = false;
  let confidence = 100; // Start assuming clean

  try {
    // Use Google Cloud Vision API
    const vision = require('@google-cloud/vision');
    const client = new vision.ImageAnnotatorClient();

    // Detect text in image
    const [result] = await client.textDetection(imageUrl);
    const detections = result.textAnnotations;

    if (detections && detections.length > 0) {
      // First detection is full text, rest are individual words
      const fullText = detections[0].description || '';
      detectedText.push(fullText);

      // Check for overlay patterns
      for (const pattern of OVERLAY_PATTERNS) {
        const matches = fullText.match(pattern);
        if (matches) {
          hasOverlayText = true;
          confidence -= 30;
          flags.push(`Overlay text: "${matches[0]}"`);
        }
      }

      // Check text density - too much text = likely marketing
      const wordCount = fullText.split(/\s+/).filter((w: string) => w.length > 0).length;
      if (wordCount > 10) {
        hasOverlayText = true;
        confidence -= 20;
        flags.push(`High text density: ${wordCount} words`);
      }

      // Check for date-like numbers
      const numberMatches = fullText.match(/\d+/g);
      if (numberMatches && numberMatches.length > 3) {
        confidence -= 15;
        flags.push(`Multiple numbers detected (${numberMatches.length})`);
      }
    }

    // Optionally check for label detection (detect objects/scenes)
    const [labelResult] = await client.labelDetection(imageUrl);
    const labels = labelResult.labelAnnotations || [];

    // Look for marketing/display indicators
    const marketingLabels = ['shelf', 'display', 'signage', 'banner', 'promotion'];
    for (const label of labels) {
      if (marketingLabels.some(ml => label.description.toLowerCase().includes(ml))) {
        confidence -= 10;
        flags.push(`Marketing indicator: ${label.description}`);
      }
    }

  } catch (error: any) {
    console.error('Vision API error:', error.message);
    flags.push(`Analysis error: ${error.message}`);
  }

  // Decide if we should keep the image
  const shouldKeep = confidence >= 50 && !hasOverlayText;

  return {
    imageUrl,
    hasOverlayText,
    detectedText,
    confidence,
    flags,
    shouldKeep,
  };
}

/**
 * Filter Tesco images in a collection
 */
export const filterTescoImages = functions.runWith({
  timeoutSeconds: 540,
  memory: '2GB'
}).https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { collection = 'tesco_products', batchSize = 100, dryRun = true } = req.body;

      const db = admin.firestore();
      const snapshot = await db.collection(collection).limit(batchSize).get();

      const results: ImageAnalysis[] = [];
      const toUpdate: any[] = [];

      console.log(`Analyzing ${snapshot.size} products from ${collection}...`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const imageUrl = data.imageUrl || data.image || null;

        if (!imageUrl) {
          continue;
        }

        // Analyze image
        const analysis = await analyzeImage(imageUrl);
        results.push(analysis);

        // Mark for update if needed
        if (!analysis.shouldKeep && !dryRun) {
          toUpdate.push({
            docId: doc.id,
            flaggedImage: imageUrl,
            flags: analysis.flags,
          });
        }

        console.log(`${doc.id}: ${analysis.shouldKeep ? 'KEEP' : 'REJECT'} (${analysis.confidence}%) - ${analysis.flags.join(', ')}`);
      }

      // Update Firestore if not dry run
      if (!dryRun && toUpdate.length > 0) {
        const batch = db.batch();
        for (const update of toUpdate) {
          const docRef = db.collection(collection).doc(update.docId);
          batch.update(docRef, {
            imageQuality: 'flagged',
            imageFlags: update.flags,
            flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        console.log(`Updated ${toUpdate.length} products with flagged images`);
      }

      res.json({
        success: true,
        analyzed: results.length,
        kept: results.filter(r => r.shouldKeep).length,
        rejected: results.filter(r => !r.shouldKeep).length,
        dryRun,
        results,
      });

    } catch (error: any) {
      console.error('Filter Tesco images error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * Get stats on image quality across a collection
 */
export const getTescoImageStats = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { collection = 'tesco_products' } = req.query;

      const db = admin.firestore();
      const snapshot = await db.collection(collection as string).get();

      let totalProducts = 0;
      let hasImage = 0;
      let flagged = 0;
      let clean = 0;

      snapshot.forEach(doc => {
        totalProducts++;
        const data = doc.data();

        if (data.imageUrl || data.image) {
          hasImage++;

          if (data.imageQuality === 'flagged') {
            flagged++;
          } else {
            clean++;
          }
        }
      });

      res.json({
        success: true,
        collection,
        totalProducts,
        hasImage,
        flagged,
        clean,
        noImage: totalProducts - hasImage,
        flaggedPercentage: hasImage > 0 ? Math.round((flagged / hasImage) * 100) : 0,
      });

    } catch (error: any) {
      console.error('Get image stats error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});
