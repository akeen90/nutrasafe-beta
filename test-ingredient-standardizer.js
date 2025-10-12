const axios = require('axios');

async function testStandardizer() {
  const testIngredients = [
    "wheat flour (wheat flour)",
    "calcium carbonate",
    "iron",
    "niacin",
    "thiamin)",
    "cream (milk)",
    "carrots",
    "tomato purée",
    "butter (milk)",
    "concentrated grape must)",
    "chicken liver",
    "cornflour",
    "beef stock (yeast extract)",
    "beef bone stock",
    "molasses",
    "dried onions",
    "sunflower oil",
    "black pepper",
    "garlic purée",
    "oregano",
    "parsley",
    "black pepper",
    "ground nutmeg",
    "ground star anise",
    "including cereals containing gluten",
    "nuts",
    "sesame",
    "pork (6%)",
    "onions",
    "celery",
    "balsamic vinegar of Modena (wine vinegar",
    "rapeseed oil"
  ];

  try {
    console.log('🧪 Testing ingredient standardization...');
    console.log(`📥 Input: ${testIngredients.length} ingredients\n`);

    const response = await axios.post(
      'https://us-central1-nutrasafe-705c7.cloudfunctions.net/standardizeIngredients',
      {
        data: {
          ingredients: testIngredients
        }
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Response received:');
    console.log(JSON.stringify(response.data, null, 2));

    if (response.data.result?.standardizedIngredients) {
      console.log('\n📤 Output ingredients:');
      response.data.result.standardizedIngredients.forEach((ing, i) => {
        console.log(`  ${i + 1}. ${ing}`);
      });
    }

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testStandardizer();
