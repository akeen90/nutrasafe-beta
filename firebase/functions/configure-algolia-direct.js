#!/usr/bin/env node

/**
 * Direct Algolia Index Configuration Script
 * This applies custom ranking settings to fix search ranking issues
 */

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.env.ALGOLIA_ADMIN_API_KEY || process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('❌ Error: ALGOLIA_ADMIN_API_KEY not provided');
  console.log('\nUsage:');
  console.log('  ALGOLIA_ADMIN_API_KEY=your_key node configure-algolia-direct.js');
  console.log('  OR');
  console.log('  node configure-algolia-direct.js YOUR_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

const indices = [
  'verified_foods',
  'foods',
  'manual_foods',
  'user_added',
  'ai_enhanced',
  'ai_manually_added',
];

const indexSettings = {
  // Searchable attributes with priority ordering
  searchableAttributes: [
    'name',        // Highest priority - product name
    'brandName',   // Second - brand name
    'barcode',     // Third - exact barcode match
    'ingredients', // Lowest - ingredient text
  ],

  // Custom ranking attributes for tie-breaking
  customRanking: [
    'desc(isGeneric)',  // Boost generic/raw foods
    'asc(nameLength)',  // Prefer shorter names
    'desc(verified)',   // Verified foods rank higher
    'desc(score)',      // Nutrition score
  ],

  // Ranking criteria - controls the overall ranking formula
  ranking: [
    'typo',       // Typo tolerance
    'words',      // Number of matched query words
    'filters',    // Applied filters
    'proximity',  // Proximity of matched words
    'attribute',  // Searchable attribute order
    'exact',      // Exact matches boost (critical for "apple" vs "applewood")
    'custom',     // Custom ranking attributes above
  ],

  // Typo tolerance settings - more lenient like leading nutrition apps
  minWordSizefor1Typo: 3,  // Allow 1 typo for words 3+ chars
  minWordSizefor2Typos: 7, // Allow 2 typos for words 7+ chars
  typoTolerance: true,     // Enable full typo tolerance

  // Exact matching settings
  exactOnSingleWordQuery: 'word', // Boost exact word matches on single-word queries

  // Query word handling
  removeWordsIfNoResults: 'allOptional', // Make all words optional if no results

  // Prefix matching - allows partial word searches
  queryType: 'prefixLast', // Enable prefix search on last word (e.g., "las" finds "lasagne")

  // Advanced settings
  attributeForDistinct: 'name', // Deduplicate by name
  distinct: true,               // Enable deduplication
  removeStopWords: ['en'],      // Remove English stop words

  // Alternative words/synonyms for common food variations
  alternativesAsExact: ['ignorePlurals', 'singleWordSynonym'],

  // Ignore plurals
  ignorePlurals: ['en'],

  // Highlighting for UI display
  attributesToHighlight: ['name', 'brandName'],
  highlightPreTag: '<em>',
  highlightPostTag: '</em>',
};

async function configureIndex(indexName) {
  try {
    console.log(`⚙️  Configuring index: ${indexName}...`);

    await client.setSettings({
      indexName,
      indexSettings,
    });

    console.log(`✅ Successfully configured: ${indexName}`);
    return { index: indexName, status: 'success' };
  } catch (error) {
    console.error(`❌ Failed to configure ${indexName}:`, error.message);
    return { index: indexName, status: 'failed', error: error.message };
  }
}

async function main() {
  console.log('🚀 Starting Algolia Index Configuration...\n');
  console.log('Enhanced search features like leading nutrition apps:');
  console.log('  ✓ Intelligent typo tolerance (lasagne/lasagna)');
  console.log('  ✓ Prefix matching ("las" finds "lasagne")');
  console.log('  ✓ Plural handling (apple/apples)');
  console.log('  ✓ Brand + product matching ("charlie bigham lasagne")');
  console.log('  ✓ Exact matches prioritized\n');

  const results = [];

  for (const indexName of indices) {
    const result = await configureIndex(indexName);
    results.push(result);
  }

  console.log('\n📊 Configuration Results:');
  console.log('═'.repeat(50));

  const successful = results.filter(r => r.status === 'success');
  const failed = results.filter(r => r.status === 'failed');

  successful.forEach(r => console.log(`✅ ${r.index}`));
  failed.forEach(r => console.log(`❌ ${r.index}: ${r.error}`));

  console.log('═'.repeat(50));
  console.log(`\n✅ Success: ${successful.length}/${indices.length}`);
  console.log(`❌ Failed: ${failed.length}/${indices.length}\n`);

  if (successful.length === indices.length) {
    console.log('🎉 All indices configured successfully!');
    console.log('\n📝 Test these search improvements in your iOS app:');
    console.log('   ✓ "lasagne" → finds Charlie Bigham\'s Lasagne');
    console.log('   ✓ "las" → prefix matches lasagne products');
    console.log('   ✓ "apple" → shows "Apple" before "Applewood"');
    console.log('   ✓ "costa" → finds Costa Coffee');
    console.log('   ✓ "apples" → finds "apple" products (plural handling)');
    console.log('\n🚀 Smart search is now active!\n');
  } else {
    console.log('⚠️  Some indices failed to configure.');
    console.log('Please check the errors above.\n');
    process.exit(1);
  }
}

main().catch(error => {
  console.error('💥 Fatal error:', error);
  process.exit(1);
});
