import * as functions from 'firebase-functions';

export const testCors = functions.https.onRequest((req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    console.log('OPTIONS request received');
    res.status(200).send();
    return;
  }

  console.log(`Test CORS function called with method: ${req.method}`);
  
  res.json({
    success: true,
    message: 'CORS test successful!',
    method: req.method,
    timestamp: new Date().toISOString()
  });
});