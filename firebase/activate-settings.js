#!/usr/bin/env node

// Activate Algolia Search Improvements
// This script calls the configureAlgoliaIndices cloud function

const https = require('https');

console.log('🚀 Activating Algolia Search Improvements...\n');

const options = {
  hostname: 'us-central1-nutrasafe-705c7.cloudfunctions.net',
  port: 443,
  path: '/configureAlgoliaIndices',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': 2
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const result = JSON.parse(data);
      console.log('✅ Configuration Result:\n');
      console.log(JSON.stringify(result, null, 2));
      console.log('\n📝 Next Steps:');
      console.log('1. Test search in your iOS app:');
      console.log('   - Search for "apple" - should show "Apple" before "Applewood"');
      console.log('   - Search for "costa" - should show "Costa Coffee"');
      console.log('2. All future food syncs will automatically use the new ranking\n');
    } catch (error) {
      console.error('❌ Error parsing response:', error);
      console.log('Raw response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error calling function:', error);
  process.exit(1);
});

// Send empty data object
req.write('{}');
req.end();
