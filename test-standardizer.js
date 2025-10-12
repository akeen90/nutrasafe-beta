const axios = require('axios');

const testIngredients = [
  "wheat flour (wheat flour)",
  "calcium carbonate",
  "iron",
  "including cereals containing gluten",
  "nuts",
  "sesame"
];

axios.post(
  'https://us-central1-nutrasafe-705c7.cloudfunctions.net/standardizeIngredients',
  { data: { ingredients: testIngredients } }
).then(response => {
  console.log('Success:', JSON.stringify(response.data, null, 2));
}).catch(error => {
  console.error('Error:', error.response ? error.response.data : error.message);
});
