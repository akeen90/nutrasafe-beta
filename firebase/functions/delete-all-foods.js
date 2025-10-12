#!/usr/bin/env node

/**
 * Delete ALL foods from Firebase
 */

const https = require('https');

const FIREBASE_FUNCTION_URL = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net/replaceAllFoods';

async function deleteAll() {
  return new Promise((resolve, reject) => {
    console.log('🗑️  Deleting ALL foods from Firebase...\n');

    // Send empty foods array with deleteFirst=true to just delete everything
    const postData = JSON.stringify({ foods: [], deleteFirst: true });

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(FIREBASE_FUNCTION_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(data);
          console.log(`✅ Deletion complete!`);
          console.log(`   Deleted: ${result.deleted} foods`);
          console.log(`   Database is now empty.\n`);
          resolve(result.deleted);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function main() {
  try {
    const deleted = await deleteAll();

    if (deleted === 0) {
      console.log('⚠️  No foods found - database was already empty.\n');
    }

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error:', error);
    process.exit(1);
  }
}

main();
