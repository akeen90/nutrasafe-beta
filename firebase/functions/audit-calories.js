// Comprehensive calorie audit and fix script
const { algoliasearch } = require('algoliasearch');
const client = algoliasearch('WK0TIF84M2', 'd7334de1f8cb66eaba016ad9b2ded473');

// Expected calorie ranges per 100g for different food types
const CALORIE_RULES = {
  // Vegetables (non-starchy) - should be LOW
  vegetables: {
    keywords: ['broccoli', 'spinach', 'lettuce', 'kale', 'cabbage', 'celery', 'cucumber',
               'courgette', 'zucchini', 'asparagus', 'green bean', 'cauliflower', 'pepper',
               'tomato', 'mushroom', 'onion', 'leek', 'carrot', 'beetroot', 'radish',
               'aubergine', 'eggplant', 'pea', 'mange', 'sugar snap', 'runner bean'],
    maxCal100g: 80,
    minCal100g: 5,
    excludeKeywords: ['chips', 'crisp', 'fried', 'tempura', 'batter', 'cheese', 'cream',
                      'gratin', 'pie', 'quiche', 'soup', 'sauce', 'dip', 'hummus']
  },
  // Fruits - moderate calories
  fruits: {
    keywords: ['apple', 'banana', 'orange', 'grape', 'strawberry', 'blueberry', 'raspberry',
               'mango', 'pineapple', 'melon', 'watermelon', 'kiwi', 'pear', 'peach', 'plum',
               'cherry', 'apricot', 'nectarine', 'grapefruit', 'lemon', 'lime', 'papaya',
               'passion fruit', 'pomegranate', 'fig', 'date', 'clementine', 'satsuma', 'tangerine'],
    maxCal100g: 120,
    minCal100g: 15,
    excludeKeywords: ['juice', 'dried', 'candy', 'sweet', 'jam', 'jelly', 'pie', 'cake',
                      'tart', 'crumble', 'yogurt', 'smoothie', 'bar', 'snack']
  },
  // Leafy greens - very low
  leafyGreens: {
    keywords: ['lettuce', 'spinach', 'kale', 'rocket', 'arugula', 'watercress', 'chard',
               'collard', 'romaine', 'iceberg', 'mixed leaves', 'salad leaves'],
    maxCal100g: 35,
    minCal100g: 5,
    excludeKeywords: ['dressed', 'caesar', 'coleslaw', 'potato salad']
  },
  // Plain cooked grains
  cookedGrains: {
    keywords: ['rice boiled', 'rice cooked', 'pasta boiled', 'pasta cooked', 'quinoa cooked',
               'couscous cooked', 'bulgur cooked', 'noodles boiled'],
    maxCal100g: 180,
    minCal100g: 80,
    excludeKeywords: ['fried', 'pilau', 'biryani', 'risotto', 'paella']
  },
  // Plain chicken breast
  leanPoultry: {
    keywords: ['chicken breast', 'turkey breast'],
    maxCal100g: 200,
    minCal100g: 100,
    excludeKeywords: ['fried', 'breaded', 'kiev', 'korma', 'tikka', 'butter', 'cream', 'pie', 'nugget']
  },
  // Eggs
  eggs: {
    keywords: ['egg boiled', 'egg poached', 'egg raw', 'boiled egg', 'poached egg'],
    maxCal100g: 180,
    minCal100g: 130,
    excludeKeywords: ['fried', 'scrambled', 'omelette', 'benedict', 'scotch']
  }
};

async function auditIndex(indexName) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`AUDITING: ${indexName}`);
  console.log('='.repeat(60));

  const issues = [];

  // Search for each category
  for (const [category, rules] of Object.entries(CALORIE_RULES)) {
    for (const keyword of rules.keywords) {
      try {
        const results = await client.searchSingleIndex({
          indexName,
          searchParams: {
            query: keyword,
            hitsPerPage: 100,
            attributesToRetrieve: ['objectID', 'name', 'brandName', 'calories', 'servingSizeG', 'servingSize', 'category']
          }
        });

        for (const hit of results.hits) {
          const nameLower = (hit.name || '').toLowerCase();

          // Skip if contains exclude keywords
          if (rules.excludeKeywords.some(ex => nameLower.includes(ex))) continue;

          // Must contain the keyword
          if (!nameLower.includes(keyword.toLowerCase())) continue;

          // Calculate cal/100g
          const servingG = hit.servingSizeG || 100;
          const cal100g = Math.round((hit.calories / servingG) * 100);

          // Check if outside acceptable range
          if (cal100g > rules.maxCal100g || cal100g < rules.minCal100g) {
            issues.push({
              objectID: hit.objectID,
              name: hit.name,
              brand: hit.brandName || 'Generic',
              calories: hit.calories,
              servingSizeG: servingG,
              cal100g: cal100g,
              category: category,
              expectedMax: rules.maxCal100g,
              expectedMin: rules.minCal100g,
              issue: cal100g > rules.maxCal100g ? 'TOO HIGH' : 'TOO LOW'
            });
          }
        }
      } catch (e) {
        // Ignore search errors
      }
    }
  }

  // Deduplicate by objectID
  const uniqueIssues = [...new Map(issues.map(i => [i.objectID, i])).values()];

  if (uniqueIssues.length === 0) {
    console.log('✅ No issues found!');
    return [];
  }

  console.log(`\n❌ Found ${uniqueIssues.length} problematic items:\n`);

  for (const issue of uniqueIssues) {
    console.log(`${issue.issue}: ${issue.name} (${issue.brand})`);
    console.log(`   ${issue.cal100g} cal/100g (expected ${issue.expectedMin}-${issue.expectedMax})`);
    console.log(`   Raw: ${issue.calories} cal per ${issue.servingSizeG}g`);
    console.log(`   ID: ${issue.objectID}`);
    console.log('');
  }

  return uniqueIssues.map(i => ({ ...i, indexName }));
}

async function main() {
  console.log('🔍 COMPREHENSIVE CALORIE AUDIT');
  console.log('Finding items with unrealistic calorie values...\n');

  const indices = ['uk_foods_cleaned', 'foods', 'generic_database'];
  let allIssues = [];

  for (const indexName of indices) {
    const issues = await auditIndex(indexName);
    allIssues = allIssues.concat(issues);
  }

  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total problematic items: ${allIssues.length}`);

  // Group by issue type
  const tooHigh = allIssues.filter(i => i.issue === 'TOO HIGH');
  const tooLow = allIssues.filter(i => i.issue === 'TOO LOW');

  console.log(`  - Too high: ${tooHigh.length}`);
  console.log(`  - Too low: ${tooLow.length}`);

  // Output as JSON for fixing
  if (allIssues.length > 0) {
    console.log('\n📝 Issues saved to: calorie_issues.json');
    require('fs').writeFileSync(
      '/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/functions/calorie_issues.json',
      JSON.stringify(allIssues, null, 2)
    );
  }
}

main().catch(console.error);
