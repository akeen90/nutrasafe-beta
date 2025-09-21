"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.detectLiveText = void 0;
const functions = require("firebase-functions");
const vision_1 = require("@google-cloud/vision");
const cors = require("cors");
const corsHandler = cors({ origin: true });
const vision = new vision_1.ImageAnnotatorClient();
exports.detectLiveText = functions.https.onRequest(async (req, res) => {
    corsHandler(req, res, async () => {
        try {
            if (req.method !== 'POST') {
                res.status(405).json({ success: false, error: 'Method not allowed' });
                return;
            }
            const { imageData, sessionId, scanType } = req.body;
            if (!imageData || !sessionId) {
                res.status(400).json({
                    success: false,
                    error: 'Missing required fields: imageData, sessionId'
                });
                return;
            }
            // Convert base64 image data to buffer
            const imageBuffer = Buffer.from(imageData, 'base64');
            // Configure Vision API request based on scan type
            const request = {
                image: { content: imageBuffer },
                features: [
                    {
                        type: 'TEXT_DETECTION',
                        maxResults: 50
                    }
                ],
                imageContext: {
                    textDetectionParams: {
                        enableTextDetectionConfidenceScore: true
                    }
                }
            };
            // Call Google Cloud Vision API
            const [result] = await vision.annotateImage(request);
            const textAnnotations = result.textAnnotations || [];
            if (textAnnotations.length === 0) {
                res.json({
                    success: true,
                    text: '',
                    confidence: 0,
                    boundingBoxes: [],
                    sessionId
                });
                return;
            }
            // Extract full text (first annotation contains all detected text)
            const fullText = textAnnotations[0].description || '';
            const fullTextConfidence = textAnnotations[0].confidence || 0;
            // Extract individual text blocks with bounding boxes
            const boundingBoxes = textAnnotations.slice(1).map(annotation => {
                var _a, _b;
                return ({
                    text: annotation.description || '',
                    vertices: ((_b = (_a = annotation.boundingPoly) === null || _a === void 0 ? void 0 : _a.vertices) === null || _b === void 0 ? void 0 : _b.map(vertex => ({
                        x: vertex.x || 0,
                        y: vertex.y || 0
                    }))) || [],
                    confidence: annotation.confidence || 0
                });
            });
            // Filter text based on scan type
            let processedText = fullText;
            if (scanType === 'ingredients') {
                // For ingredients, focus on text that looks like ingredient lists
                processedText = processIngredientText(fullText);
            }
            else if (scanType === 'nutrition') {
                // For nutrition, focus on nutritional information
                processedText = processNutritionText(fullText);
            }
            const response = {
                success: true,
                text: processedText,
                confidence: fullTextConfidence,
                boundingBoxes,
                sessionId
            };
            res.json(response);
        }
        catch (error) {
            console.error('Vision API error:', error);
            res.status(500).json({
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error occurred',
                sessionId: req.body.sessionId || 'unknown'
            });
        }
    });
});
function processIngredientText(text) {
    // Clean and format ingredient text
    let processed = text
        .replace(/\n+/g, ' ') // Replace multiple newlines with space
        .replace(/\s+/g, ' ') // Replace multiple spaces with single space
        .trim();
    // Look for ingredient list patterns
    const ingredientPatterns = [
        /ingredients?[:\s]+(.+)/i,
        /contains?[:\s]+(.+)/i,
        /made with[:\s]+(.+)/i
    ];
    for (const pattern of ingredientPatterns) {
        const match = processed.match(pattern);
        if (match && match[1]) {
            processed = match[1].trim();
            break;
        }
    }
    return processed;
}
function processNutritionText(text) {
    // Clean and format nutrition text
    let processed = text
        .replace(/\n+/g, '\n') // Preserve line breaks for nutrition facts
        .replace(/\s+/g, ' ') // Replace multiple spaces with single space
        .trim();
    // Look for nutrition facts patterns
    const nutritionPatterns = [
        /nutrition facts?[:\s]*\n?(.+)/i,
        /nutritional information[:\s]*\n?(.+)/i,
        /per \d+[gml]+[:\s]*\n?(.+)/i
    ];
    for (const pattern of nutritionPatterns) {
        const match = processed.match(pattern);
        if (match && match[1]) {
            processed = match[1].trim();
            break;
        }
    }
    return processed;
}
//# sourceMappingURL=detect-live-text.js.map