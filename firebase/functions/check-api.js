const axios = require('axios');

const TESCO8_API_KEY = '7e61162448msh2832ba8d19f26cep1e55c3jsn5242e6c6d761';
const TESCO8_HOST = 'tesco8.p.rapidapi.com';

async function checkProduct() {
    const productId = '326056633'; // Bob's Red Mill Pancake
    
    try {
        const response = await axios.get(
            `https://${TESCO8_HOST}/product-details`,
            {
                params: { productId },
                headers: {
                    'x-rapidapi-host': TESCO8_HOST,
                    'x-rapidapi-key': TESCO8_API_KEY
                },
                timeout: 15000
            }
        );

        const productData = response.data.data.results[0].data.product;
        const details = productData.details || {};
        
        console.log('=== RAW NUTRITION INFO ===');
        console.log(JSON.stringify(details.nutritionInfo, null, 2));
        
        console.log('\n=== GUIDELINE DAILY AMOUNT ===');
        console.log(JSON.stringify(details.guidelineDailyAmount, null, 2));
        
        console.log('\n=== OTHER NUTRITION ===');
        console.log(JSON.stringify(details.otherNutritionInformation, null, 2));
        
    } catch (error) {
        console.error('Error:', error.message);
    }
    
    process.exit(0);
}

checkProduct();
