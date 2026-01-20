"use strict";
/**
 * Tesco Database Builder
 *
 * Systematically scans the Tesco product catalog via the Tesco8 API
 * and builds a comprehensive food database with full nutrition data.
 *
 * Features:
 * - Alphabetical search through A-Z + common food terms
 * - Category-based browsing
 * - Progress tracking with resume capability
 * - Rate limiting to respect API limits
 * - Stores to Firestore "tescoProducts" collection
 * - Syncs to Algolia "tesco_products" index
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupTescoDatabase = exports.syncTescoToAlgolia = exports.configureTescoAlgoliaIndex = exports.getTescoDatabaseStats = exports.resetTescoDatabase = exports.scheduledTescoBuild = exports.stopTescoBuild = exports.pauseTescoBuild = exports.startTescoBuild = exports.getTescoBuildProgress = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const algoliasearch_1 = require("algoliasearch");
// Initialize Firebase Admin if not already
if (!admin.apps.length) {
    admin.initializeApp();
}
// Tesco8 API Configuration
const TESCO8_API_KEY = functions.config().rapidapi?.key || '7e61162448msh2832ba8d19f26cep1e55c3jsn5242e6c6d761';
const TESCO8_HOST = 'tesco8.p.rapidapi.com';
// Helper to remove undefined values from objects (Firestore doesn't accept undefined)
function removeUndefined(obj) {
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
        if (value !== undefined) {
            if (value && typeof value === 'object' && !Array.isArray(value)) {
                result[key] = removeUndefined(value);
            }
            else {
                result[key] = value;
            }
        }
    }
    return result;
}
// Algolia Configuration
const ALGOLIA_APP_ID = functions.config().algolia?.app_id || 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.admin_key;
const TESCO_INDEX_NAME = 'tesco_products';
// Tesco food categories - comprehensive list for maximum product coverage
// Strategy: Popular categories first (Snacks → Everyday → Staples → Fresh → Frozen)
const SEARCH_TERMS = [
    // ============ 1. SNACKS & CONFECTIONERY (Most Popular) ============
    'Chocolate', 'Milk Chocolate', 'Dark Chocolate', 'White Chocolate',
    'Cadbury', 'Cadbury Dairy Milk', 'Galaxy', 'Lindt', 'Ferrero Rocher', 'Toblerone',
    'Kit Kat', 'Twix', 'Mars', 'Snickers', 'Bounty', 'Milky Way', 'Maltesers',
    'Wispa', 'Flake', 'Crunchie', 'Double Decker', 'Boost', 'Picnic', 'Twirl',
    'Aero', 'Yorkie', 'Dairy Milk', 'Fruit And Nut', 'Whole Nut',
    'Sweets', 'Haribo', 'Wine Gums', 'Fruit Pastilles', 'Jelly Babies', 'Gummy Bears',
    'Mints', 'Polo', 'Tic Tac', 'Extra', 'Trebor',
    'Crisps', 'Walkers', 'Walkers Crisps', 'Pringles', 'Kettle Chips', 'Sensations',
    'Doritos', 'Wotsits', 'Quavers', 'Monster Munch', 'Skips', 'Hula Hoops',
    'Ready Salted', 'Cheese And Onion', 'Salt And Vinegar', 'Prawn Cocktail',
    'Popcorn', 'Butterkist', 'Propercorn', 'Sweet Popcorn', 'Salted Popcorn',
    'Nuts', 'Peanuts', 'Cashews', 'Almonds', 'Walnuts', 'Pistachios', 'Mixed Nuts',
    'Biscuits', 'Digestives', 'Rich Tea', 'Hobnobs', 'Custard Creams', 'Bourbons',
    'Jammie Dodgers', 'Oreos', 'Maryland Cookies', 'Shortbread',
    'McVities', 'Jacobs', 'Foxs',
    'Crackers', 'Cream Crackers', 'Ritz', 'Jacobs Crackers', 'Oatcakes', 'Rice Cakes',
    'Cereal Bars', 'Nakd', 'Kind', 'Nature Valley', 'Belvita', 'Tracker', 'Nutri Grain',
    'Protein Bars', 'Grenade', 'Fulfil', 'Carb Killa',
    // ============ 2. EVERYDAY - CEREALS & BREAKFAST ============
    'Cereals', 'Cornflakes', 'Kelloggs', 'Weetabix', 'Shredded Wheat', 'Bran Flakes',
    'Crunchy Nut', 'Special K', 'Frosties', 'Coco Pops', 'Rice Krispies', 'Cheerios',
    'Shreddies', 'Muesli', 'Granola', 'Porridge', 'Porridge Oats', 'Ready Brek',
    'Quaker Oats', 'Alpen', 'Jordans',
    'Pancake Mix', 'Syrup', 'Maple Syrup', 'Golden Syrup',
    'Jam', 'Marmalade', 'Strawberry Jam', 'Raspberry Jam', 'Apricot Jam',
    'Honey', 'Manuka Honey', 'Clear Honey', 'Set Honey',
    'Peanut Butter', 'Nutella', 'Chocolate Spread', 'Biscoff Spread', 'Marmite',
    // ============ 2. EVERYDAY - PASTA RICE NOODLES ============
    'Pasta', 'Spaghetti', 'Penne', 'Fusilli', 'Tagliatelle', 'Linguine', 'Macaroni',
    'Lasagne Sheets', 'Ravioli', 'Tortellini', 'Fresh Pasta',
    'Rice', 'Basmati Rice', 'Long Grain Rice', 'Brown Rice', 'Jasmine Rice', 'Risotto Rice',
    'Wild Rice', 'Microwave Rice', 'Uncle Bens', 'Tilda',
    'Noodles', 'Egg Noodles', 'Rice Noodles', 'Udon Noodles', 'Ramen Noodles',
    'Pot Noodle', 'Super Noodles', 'Instant Noodles',
    'Couscous', 'Bulgur Wheat', 'Quinoa', 'Pearl Barley', 'Lentils',
    // ============ 2. EVERYDAY - SAUCES & CONDIMENTS ============
    'Ketchup', 'Heinz Ketchup', 'Tomato Ketchup',
    'Mayonnaise', 'Hellmanns', 'Salad Cream',
    'Mustard', 'English Mustard', 'Dijon Mustard', 'Wholegrain Mustard',
    'Brown Sauce', 'HP Sauce', 'BBQ Sauce', 'Hot Sauce', 'Sriracha', 'Tabasco',
    'Soy Sauce', 'Sweet Chilli Sauce', 'Hoisin Sauce', 'Teriyaki Sauce', 'Fish Sauce',
    'Worcestershire Sauce', 'Mint Sauce', 'Horseradish', 'Tartare Sauce',
    'Cooking Sauces', 'Pasta Sauce', 'Dolmio', 'Loyd Grossman', 'Homepride',
    'Curry Sauce', 'Korma Sauce', 'Tikka Masala', 'Madras Sauce', 'Jalfrezi',
    'Pataks', 'Sharwoods',
    'Pesto', 'Red Pesto', 'Green Pesto',
    'Stir Fry Sauce', 'Sweet And Sour', 'Black Bean Sauce', 'Oyster Sauce',
    'Salsa', 'Guacamole', 'Hummus', 'Tzatziki',
    // ============ 2. EVERYDAY - DRINKS ============
    'Water', 'Still Water', 'Sparkling Water', 'Mineral Water', 'Evian', 'Volvic',
    'Juice', 'Orange Juice', 'Apple Juice', 'Tropical Juice', 'Cranberry Juice',
    'Tropicana', 'Innocent', 'Ribena', 'Capri Sun',
    'Squash', 'Robinsons', 'Vimto', 'Blackcurrant Squash', 'Orange Squash',
    'Fizzy Drinks', 'Coca Cola', 'Pepsi', 'Fanta', 'Sprite', 'Lemonade',
    'Lucozade', 'Red Bull', 'Monster Energy',
    'Tea', 'PG Tips', 'Yorkshire Tea', 'Tetley', 'Twinings', 'Green Tea', 'Herbal Tea',
    'Coffee', 'Instant Coffee', 'Nescafe', 'Kenco', 'Douwe Egberts', 'Coffee Pods',
    'Hot Chocolate', 'Cadbury Hot Chocolate', 'Options Hot Chocolate',
    // ============ 2. EVERYDAY - TINNED & CANNED ============
    'Tinned Tomatoes', 'Chopped Tomatoes', 'Plum Tomatoes', 'Passata', 'Tomato Puree',
    'Baked Beans', 'Heinz Beans', 'Branston Beans',
    'Tinned Vegetables', 'Tinned Sweetcorn', 'Tinned Peas', 'Tinned Carrots',
    'Tinned Fruit', 'Tinned Peaches', 'Tinned Pineapple', 'Fruit Cocktail',
    'Tinned Fish', 'Tinned Tuna', 'Tinned Salmon', 'Tinned Sardines', 'Tinned Mackerel',
    'Tinned Meat', 'Corned Beef', 'Spam', 'Hot Dogs',
    'Tinned Soup', 'Heinz Soup', 'Baxters Soup', 'Campbell Soup',
    'Tinned Pasta', 'Spaghetti Hoops', 'Ravioli',
    'Coconut Milk Tinned', 'Evaporated Milk', 'Condensed Milk',
    'Kidney Beans', 'Chickpeas', 'Black Beans', 'Butter Beans', 'Cannellini Beans',
    'Baked Beans With Sausages', 'Chilli Con Carne',
    // ============ 3. STAPLES - DAIRY & EGGS ============
    'Milk', 'Semi Skimmed Milk', 'Whole Milk', 'Skimmed Milk', 'Oat Milk', 'Almond Milk',
    'Soya Milk', 'Coconut Milk', 'Lactose Free Milk', 'Organic Milk',
    'Butter', 'Salted Butter', 'Unsalted Butter', 'Spreadable Butter', 'Margarine',
    'Eggs', 'Free Range Eggs', 'Organic Eggs', 'Large Eggs', 'Medium Eggs',
    'Cheese', 'Cheddar', 'Cheddar Cheese', 'Mature Cheddar', 'Mild Cheddar', 'Extra Mature Cheddar',
    'Mozzarella', 'Parmesan', 'Brie', 'Camembert', 'Stilton', 'Feta', 'Halloumi',
    'Gouda', 'Edam', 'Red Leicester', 'Double Gloucester', 'Wensleydale', 'Goats Cheese',
    'Cream Cheese', 'Philadelphia', 'Cottage Cheese', 'Ricotta', 'Mascarpone',
    'Grated Cheese', 'Cheese Slices', 'Cheese Strings', 'Babybel', 'Laughing Cow',
    'Yogurt', 'Greek Yogurt', 'Natural Yogurt', 'Fruit Yogurt', 'Yoghurt Drinks',
    'Muller', 'Activia', 'Danone', 'Yeo Valley', 'Alpro Yogurt', 'Skyr',
    'Cream', 'Double Cream', 'Single Cream', 'Whipping Cream', 'Clotted Cream', 'Soured Cream',
    'Custard', 'Creme Fraiche',
    'Dairy Free', 'Dairy Alternatives', 'Vegan Cheese', 'Vegan Yogurt', 'Vegan Butter',
    // ============ 3. STAPLES - BAKERY ============
    'Bread', 'White Bread', 'Brown Bread', 'Wholemeal Bread', 'Seeded Bread', 'Sourdough',
    'Bread Rolls', 'Baguette', 'Ciabatta', 'Focaccia', 'Naan Bread', 'Pitta Bread',
    'Wraps', 'Tortilla Wraps', 'Flatbreads', 'Chapati', 'Roti',
    'Bagels', 'Croissants', 'Pain Au Chocolat', 'Brioche', 'Danish Pastries',
    'Crumpets', 'English Muffins', 'Teacakes', 'Hot Cross Buns', 'Scones', 'Fruit Loaf',
    'Pancakes', 'Scotch Pancakes', 'Waffles', 'Crepes',
    'Doughnuts', 'Cookies', 'Muffins', 'Cupcakes', 'Brownies', 'Flapjacks',
    'Cakes', 'Birthday Cake', 'Celebration Cake', 'Victoria Sponge', 'Chocolate Cake',
    'Carrot Cake', 'Lemon Drizzle', 'Coffee Cake', 'Cheesecake', 'Trifle',
    'Pastries', 'Sausage Rolls', 'Pork Pies', 'Scotch Eggs', 'Cornish Pasties',
    'Pies', 'Steak Pie', 'Chicken Pie', 'Meat Pie', 'Quiche', 'Quiche Lorraine',
    'Tarts', 'Fruit Tart', 'Custard Tart', 'Bakewell Tart', 'Treacle Tart',
    'Gluten Free Bread', 'Gluten Free Bakery',
    // ============ 4. FRESH FOOD - PRODUCE ============
    'Fresh Fruit',
    'Apples', 'Bananas', 'Oranges', 'Grapes', 'Strawberries', 'Blueberries', 'Raspberries',
    'Blackberries', 'Cherries', 'Pears', 'Plums', 'Peaches', 'Nectarines', 'Mangoes',
    'Pineapples', 'Melons', 'Watermelon', 'Kiwi', 'Avocados', 'Lemons', 'Limes',
    'Grapefruit', 'Pomegranate', 'Figs', 'Dates', 'Passion Fruit', 'Papaya', 'Coconut',
    'Fresh Vegetables',
    'Potatoes', 'Carrots', 'Onions', 'Tomatoes', 'Peppers', 'Cucumber', 'Lettuce',
    'Broccoli', 'Cauliflower', 'Cabbage', 'Spinach', 'Kale', 'Courgettes', 'Aubergine',
    'Mushrooms', 'Sweetcorn', 'Peas', 'Green Beans', 'Asparagus', 'Leeks', 'Celery',
    'Spring Onions', 'Garlic', 'Ginger', 'Beetroot', 'Parsnips', 'Swede', 'Turnips',
    'Sweet Potatoes', 'Butternut Squash', 'Radishes', 'Rocket', 'Watercress', 'Pak Choi',
    'Fresh Salad', 'Coleslaw', 'Mixed Salad', 'Caesar Salad', 'Prepared Vegetables',
    'Fresh Herbs', 'Basil', 'Coriander', 'Parsley', 'Mint', 'Rosemary', 'Thyme', 'Chives',
    // ============ 4. FRESH - MEAT & POULTRY ============
    'Fresh Meat', 'Beef', 'Beef Mince', 'Minced Beef', 'Steak', 'Sirloin Steak', 'Ribeye Steak',
    'Fillet Steak', 'Rump Steak', 'Beef Joint', 'Roasting Joint', 'Beef Burgers',
    'Pork', 'Pork Chops', 'Pork Loin', 'Pork Mince', 'Pork Joint', 'Pork Belly', 'Gammon',
    'Lamb', 'Lamb Chops', 'Lamb Mince', 'Lamb Joint', 'Lamb Leg', 'Lamb Shoulder',
    'Chicken', 'Chicken Breast', 'Chicken Thighs', 'Chicken Drumsticks', 'Chicken Wings',
    'Whole Chicken', 'Roast Chicken', 'Chicken Mince', 'Chicken Fillets', 'Chicken Kievs',
    'Turkey', 'Turkey Mince', 'Turkey Breast', 'Turkey Steaks',
    'Duck', 'Duck Breast', 'Duck Legs',
    'Sausages', 'Pork Sausages', 'Beef Sausages', 'Chicken Sausages', 'Cumberland Sausages',
    'Bacon', 'Streaky Bacon', 'Back Bacon', 'Smoked Bacon', 'Unsmoked Bacon', 'Bacon Rashers',
    'Ham', 'Sliced Ham', 'Cooked Ham', 'Parma Ham', 'Serrano Ham',
    'Cooked Meats', 'Sliced Meats', 'Deli Meats', 'Chorizo', 'Salami', 'Pepperoni',
    'Pastrami', 'Corned Beef', 'Roast Beef', 'Turkey Slices', 'Chicken Slices',
    // ============ 4. FRESH - FISH & SEAFOOD ============
    'Fresh Fish', 'Salmon', 'Salmon Fillets', 'Smoked Salmon', 'Cod', 'Cod Fillets',
    'Haddock', 'Smoked Haddock', 'Sea Bass', 'Trout', 'Mackerel', 'Smoked Mackerel',
    'Tuna Steaks', 'Plaice', 'Sole', 'Bream', 'Tilapia', 'Pollock', 'Coley',
    'Prawns', 'King Prawns', 'Tiger Prawns', 'Cooked Prawns', 'Raw Prawns',
    'Shrimp', 'Crab', 'Crab Sticks', 'Lobster', 'Mussels', 'Scallops', 'Squid', 'Calamari',
    'Fish Fingers', 'Fish Cakes', 'Breaded Fish', 'Battered Fish', 'Fish Pie Mix',
    // ============ 5. FROZEN FOOD ============
    'Frozen Vegetables', 'Frozen Peas', 'Frozen Sweetcorn', 'Frozen Mixed Vegetables',
    'Frozen Broccoli', 'Frozen Spinach', 'Frozen Carrots', 'Frozen Green Beans',
    'Frozen Chips', 'Oven Chips', 'Frozen Roast Potatoes', 'Frozen Mash', 'Frozen Wedges',
    'Frozen Fish', 'Frozen Salmon', 'Frozen Cod', 'Frozen Haddock', 'Frozen Fish Fingers',
    'Frozen Prawns', 'Frozen Seafood',
    'Frozen Meat', 'Frozen Chicken', 'Frozen Burgers', 'Frozen Sausages', 'Frozen Meatballs',
    'Frozen Pizza', 'Frozen Garlic Bread', 'Frozen Naan',
    'Frozen Ready Meals', 'Frozen Lasagne', 'Frozen Curry', 'Frozen Chinese',
    'Frozen Yorkshire Puddings', 'Frozen Stuffing', 'Frozen Gravy',
    'Frozen Pastry', 'Puff Pastry', 'Shortcrust Pastry', 'Filo Pastry',
    'Frozen Fruit', 'Frozen Berries', 'Frozen Mango', 'Frozen Banana',
    'Ice Cream', 'Ben Jerrys', 'Haagen Dazs', 'Magnum', 'Cornetto', 'Viennetta',
    'Ice Lollies', 'Fab', 'Twister', 'Calippo', 'Solero', 'Mini Milk',
    'Frozen Desserts', 'Frozen Cheesecake', 'Frozen Gateau', 'Frozen Profiteroles',
    // ============ COOKING & INGREDIENTS ============
    'Cooking Oil', 'Olive Oil', 'Vegetable Oil', 'Sunflower Oil', 'Coconut Oil', 'Rapeseed Oil',
    'Vinegar', 'Balsamic Vinegar', 'White Wine Vinegar', 'Cider Vinegar', 'Malt Vinegar',
    'Salt', 'Sea Salt', 'Rock Salt', 'Table Salt', 'Lo Salt',
    'Pepper', 'Black Pepper', 'White Pepper', 'Mixed Peppercorns',
    'Herbs Spices', 'Paprika', 'Cumin', 'Coriander Spice', 'Turmeric', 'Cinnamon', 'Nutmeg',
    'Chilli Powder', 'Curry Powder', 'Garam Masala', 'Mixed Herbs', 'Italian Herbs',
    'Stock', 'Stock Cubes', 'Chicken Stock', 'Beef Stock', 'Vegetable Stock', 'Oxo',
    'Gravy', 'Gravy Granules', 'Bisto',
    'Flour', 'Plain Flour', 'Self Raising Flour', 'Strong Bread Flour', 'Wholemeal Flour',
    'Sugar', 'Caster Sugar', 'Icing Sugar', 'Brown Sugar', 'Demerara Sugar',
    'Baking Powder', 'Bicarbonate Soda', 'Yeast', 'Cornflour', 'Cocoa Powder',
    'Vanilla Extract', 'Food Colouring', 'Chocolate Chips', 'Sprinkles',
    // ============ PASTA RICE NOODLES ============
    'Pasta', 'Spaghetti', 'Penne', 'Fusilli', 'Tagliatelle', 'Linguine', 'Macaroni',
    'Lasagne Sheets', 'Ravioli', 'Tortellini', 'Fresh Pasta',
    'Rice', 'Basmati Rice', 'Long Grain Rice', 'Brown Rice', 'Jasmine Rice', 'Risotto Rice',
    'Wild Rice', 'Microwave Rice', 'Uncle Bens', 'Tilda',
    'Noodles', 'Egg Noodles', 'Rice Noodles', 'Udon Noodles', 'Ramen Noodles',
    'Pot Noodle', 'Super Noodles', 'Instant Noodles',
    'Couscous', 'Bulgur Wheat', 'Quinoa', 'Pearl Barley', 'Lentils',
    // ============ SAUCES & CONDIMENTS ============
    'Ketchup', 'Heinz Ketchup', 'Tomato Ketchup',
    'Mayonnaise', 'Hellmanns', 'Salad Cream',
    'Mustard', 'English Mustard', 'Dijon Mustard', 'Wholegrain Mustard',
    'Brown Sauce', 'HP Sauce', 'BBQ Sauce', 'Hot Sauce', 'Sriracha', 'Tabasco',
    'Soy Sauce', 'Sweet Chilli Sauce', 'Hoisin Sauce', 'Teriyaki Sauce', 'Fish Sauce',
    'Worcestershire Sauce', 'Mint Sauce', 'Horseradish', 'Tartare Sauce',
    'Cooking Sauces', 'Pasta Sauce', 'Dolmio', 'Loyd Grossman', 'Homepride',
    'Curry Sauce', 'Korma Sauce', 'Tikka Masala', 'Madras Sauce', 'Jalfrezi',
    'Pataks', 'Sharwoods',
    'Pesto', 'Red Pesto', 'Green Pesto',
    'Stir Fry Sauce', 'Sweet And Sour', 'Black Bean Sauce', 'Oyster Sauce',
    'Salsa', 'Guacamole', 'Hummus', 'Tzatziki',
    // ============ TINNED & CANNED ============
    'Tinned Tomatoes', 'Chopped Tomatoes', 'Plum Tomatoes', 'Passata', 'Tomato Puree',
    'Baked Beans', 'Heinz Beans', 'Branston Beans',
    'Tinned Vegetables', 'Tinned Sweetcorn', 'Tinned Peas', 'Tinned Carrots',
    'Tinned Fruit', 'Tinned Peaches', 'Tinned Pineapple', 'Fruit Cocktail',
    'Tinned Fish', 'Tinned Tuna', 'Tinned Salmon', 'Tinned Sardines', 'Tinned Mackerel',
    'Tinned Meat', 'Corned Beef', 'Spam', 'Hot Dogs',
    'Tinned Soup', 'Heinz Soup', 'Baxters Soup', 'Campbell Soup',
    'Tinned Pasta', 'Spaghetti Hoops', 'Ravioli',
    'Coconut Milk Tinned', 'Evaporated Milk', 'Condensed Milk',
    'Kidney Beans', 'Chickpeas', 'Black Beans', 'Butter Beans', 'Cannellini Beans',
    'Baked Beans With Sausages', 'Chilli Con Carne',
    // ============ DRINKS ============
    'Water', 'Still Water', 'Sparkling Water', 'Mineral Water', 'Evian', 'Volvic',
    'Juice', 'Orange Juice', 'Apple Juice', 'Tropical Juice', 'Cranberry Juice',
    'Tropicana', 'Innocent', 'Ribena', 'Capri Sun',
    'Squash', 'Robinsons', 'Vimto', 'Blackcurrant Squash', 'Orange Squash',
    'Fizzy Drinks', 'Coca Cola', 'Pepsi', 'Fanta', 'Sprite', 'Lemonade',
    'Lucozade', 'Red Bull', 'Monster Energy',
    'Tea', 'PG Tips', 'Yorkshire Tea', 'Tetley', 'Twinings', 'Green Tea', 'Herbal Tea',
    'Coffee', 'Instant Coffee', 'Nescafe', 'Kenco', 'Douwe Egberts', 'Coffee Pods',
    'Hot Chocolate', 'Cadbury Hot Chocolate', 'Options Hot Chocolate',
    // ============ READY MEALS & CONVENIENCE ============
    'Ready Meals', 'Microwave Meals', 'Meal Deal',
    'Sandwiches', 'Wraps', 'Meal Pots', 'Sushi',
    'Soup', 'Fresh Soup', 'Chunky Soup',
    'Pizza', 'Fresh Pizza', 'Takeaway Pizza', 'Chicago Town', 'Goodfellas', 'Dr Oetker',
    'Curry', 'Indian Meal', 'Chinese Meal', 'Thai Meal', 'Italian Meal',
    'Roast Dinner', 'Sunday Roast',
    'Kids Meals', 'Lunchbox', 'School Dinners',
    // ============ WORLD FOODS ============
    'Chinese', 'Chinese Food', 'Stir Fry', 'Spring Rolls', 'Prawn Crackers', 'Duck Pancakes',
    'Indian', 'Indian Food', 'Naan', 'Poppadoms', 'Onion Bhaji', 'Samosa',
    'Thai', 'Thai Food', 'Thai Curry', 'Pad Thai',
    'Mexican', 'Mexican Food', 'Fajita', 'Taco', 'Enchilada', 'Burrito',
    'Italian', 'Italian Food', 'Risotto', 'Gnocchi', 'Bruschetta',
    'Japanese', 'Japanese Food', 'Sushi Rice', 'Miso Soup', 'Edamame',
    'Polish', 'Polish Food', 'Pierogi',
    'Greek', 'Greek Food', 'Feta Salad',
    'Middle Eastern', 'Falafel', 'Shawarma',
    // ============ FREE FROM & SPECIAL DIETS ============
    'Free From', 'Gluten Free', 'Dairy Free Foods', 'Lactose Free', 'Vegan',
    'Vegetarian', 'Plant Based', 'Meat Free', 'Quorn', 'Linda McCartney',
    'Beyond Meat', 'This Isnt', 'Vivera',
    'Organic', 'Organic Food', 'Organic Vegetables', 'Organic Meat',
    'Low Fat', 'Low Calorie', 'Low Sugar', 'Sugar Free', 'Diet', 'Light',
    'High Protein', 'Protein', 'High Fibre',
    'Halal', 'Halal Food', 'Halal Meat', 'Halal Chicken',
    'Kosher',
    // ============ BABY & TODDLER ============
    'Baby Food', 'Baby Puree', 'Ella Kitchen', 'Cow Gate', 'Aptamil',
    'Baby Milk', 'Formula Milk', 'Follow On Milk',
    'Baby Snacks', 'Baby Biscuits', 'Baby Rice Cakes',
    'Toddler Food', 'Toddler Meals',
    // ============ MAJOR BRANDS ============
    'Tesco Finest', 'Tesco Organic', 'Tesco Free From', 'Tesco Plant Chef',
    'Wicked Kitchen', 'Hearty Food Co', 'Graze',
    'Heinz', 'Kelloggs', 'Nestle', 'Kraft', 'Unilever', 'Mars',
    'Birds Eye', 'McCain', 'Aunt Bessies',
    'Muller', 'Yoplait',
    'Warburtons', 'Hovis', 'Kingsmill',
    'Cathedral City', 'Pilgrims Choice',
    'Richmond', 'Mattessons',
    // ============ CHILLED DESSERTS ============
    'Chilled Desserts', 'Mousse', 'Chocolate Mousse', 'Panna Cotta', 'Rice Pudding',
    'Tiramisu', 'Creme Brulee', 'Pots', 'Chocolate Pot', 'Dessert Pots', 'Gu',
    // ============ DELI & ANTIPASTI ============
    'Deli', 'Antipasti', 'Olives', 'Stuffed Olives', 'Sun Dried Tomatoes',
    'Stuffed Peppers', 'Marinated', 'Artichokes', 'Capers', 'Anchovies',
    // ============ PICKLES & PRESERVES ============
    'Pickles', 'Gherkins', 'Pickled Onions', 'Pickled Beetroot', 'Sauerkraut',
    'Chutney', 'Mango Chutney', 'Relish', 'Piccalilli', 'Branston Pickle',
    // ============ MORE WORLD FOODS ============
    'Korean', 'Korean Food', 'Kimchi', 'Gochujang', 'Korean BBQ',
    'Vietnamese', 'Pho', 'Vietnamese Food',
    'Caribbean', 'Jerk', 'Jerk Chicken', 'Plantain', 'Ackee',
    'African', 'Jollof', 'African Food',
    // ============ OFFAL & SPECIALTY MEATS ============
    'Liver', 'Chicken Liver', 'Lambs Liver', 'Kidney', 'Heart',
    'Black Pudding', 'White Pudding', 'Haggis', 'Tripe',
    'Venison', 'Rabbit', 'Goat', 'Pheasant', 'Partridge',
    // ============ DRIED FRUITS & TRAIL MIX ============
    'Dried Fruit', 'Raisins', 'Sultanas', 'Currants', 'Dried Apricots',
    'Dried Mango', 'Dried Cranberries', 'Prunes', 'Trail Mix', 'Fruit And Nut Mix',
    // ============ MEAL KITS & BUNDLES ============
    'Meal Kit', 'Recipe Box', 'Dinner Kit', 'Cook Kit', 'Meal Bundle',
    // ============ TESCO OWN BRAND RANGES ============
    'Tesco', 'Tesco Everyday Value', 'Tesco Clubcard', 'Tesco Meal Deal',
    'Exclusively At Tesco', 'Tesco Ingredients',
    // ============ SEASONAL ============
    'Christmas Food', 'Christmas Dinner', 'Turkey Crown', 'Mince Pies', 'Christmas Pudding',
    'Easter', 'Easter Eggs', 'Hot Cross Buns', 'Simnel Cake',
    'BBQ', 'BBQ Food', 'Summer Food', 'Picnic', 'Party Food',
    'Halloween', 'Bonfire Night',
    // ============ BREAKFAST EXTRAS ============
    'Hash Browns', 'Potato Waffles', 'Beans On Toast', 'Full English',
    'Kippers', 'Smoked Kippers', 'Kedgeree',
    // ============ BROAD CATCH-ALL TERMS ============
    'Groceries', 'Food', 'Fresh Food', 'Chilled', 'Chilled Food',
    'Ambient', 'Cupboard', 'Essentials', 'Basics', 'Everyday',
    'Weekly Shop', 'Big Shop', 'Top Up',
    // ============ GENERIC CATEGORY TERMS (to capture all products in category) ============
    // These single-word generic terms should return many products per search
    'Fruit', 'Vegetables', 'Salad', 'Herbs',
    'Dairy', 'Milk', 'Cheese', 'Yogurt', 'Butter', 'Eggs', 'Cream',
    'Meat', 'Beef', 'Pork', 'Lamb', 'Chicken', 'Turkey', 'Sausages', 'Bacon', 'Ham',
    'Fish', 'Seafood', 'Prawns', 'Salmon',
    'Bread', 'Bakery', 'Rolls', 'Cakes', 'Pastries', 'Pies',
    'Frozen', 'Ice Cream', 'Frozen Meals', 'Frozen Vegetables', 'Frozen Meat',
    'Chocolate', 'Sweets', 'Crisps', 'Snacks', 'Biscuits', 'Cookies', 'Crackers', 'Nuts',
    'Cereals', 'Breakfast', 'Porridge', 'Muesli', 'Granola',
    'Pasta', 'Rice', 'Noodles', 'Grains',
    'Sauces', 'Condiments', 'Ketchup', 'Mayonnaise', 'Dressings',
    'Tinned', 'Canned', 'Beans', 'Soup',
    'Drinks', 'Water', 'Juice', 'Squash', 'Fizzy', 'Tea', 'Coffee',
    'Ready Meals', 'Sandwiches', 'Pizza', 'Curry',
    'Vegan', 'Vegetarian', 'Gluten Free', 'Organic', 'Free From',
    'Baby', 'Toddler',
    'Spreads', 'Jams', 'Honey',
    'Oil', 'Vinegar', 'Seasonings', 'Spices',
    'Desserts', 'Puddings', 'Trifle', 'Mousse',
    'Dips', 'Hummus', 'Salsa',
    'Stuffing', 'Gravy', 'Stock',
    'World Food', 'Chinese', 'Indian', 'Mexican', 'Italian', 'Thai',
    'Party', 'Entertaining', 'Nibbles',
    // ============ ALPHABETICAL CATCH-ALL (A-Z single letters) ============
    // These catch products not found by category searches
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
];
// Helper: Parse numeric value from string
function parseNumber(value) {
    if (value === undefined || value === null)
        return undefined;
    if (typeof value === 'number')
        return value;
    const cleaned = value.replace(/[^\d.]/g, '');
    const num = parseFloat(cleaned);
    return isNaN(num) ? undefined : num;
}
// Helper: Identify allergens from text
function identifyAllergens(text) {
    const allergenList = [
        'milk', 'egg', 'peanut', 'tree nut', 'wheat', 'soy', 'fish',
        'shellfish', 'sesame', 'gluten', 'celery', 'mustard', 'lupin',
        'mollusc', 'sulphite', 'sulphur dioxide', 'crustacean'
    ];
    const textStr = Array.isArray(text) ? text.join(' ') : text;
    const lowerText = textStr.toLowerCase();
    return allergenList.filter(allergen => lowerText.includes(allergen));
}
// Helper: Check if product has valid nutrition
// STRICT: Must have calories - protein/carbs alone isn't enough
function hasValidNutrition(nutrition) {
    if (!nutrition)
        return false;
    // MUST have calories (energyKcal) - this is the primary requirement
    if (!nutrition.energyKcal || nutrition.energyKcal <= 0)
        return false;
    // Sanity check: calories should be realistic (0-900 kcal per 100g, max is pure fat)
    if (nutrition.energyKcal > 950)
        return false;
    return true;
}
// Helper: Check if product is valid for saving (has required fields)
function isValidProduct(product, requireIngredients = false) {
    // Must have a title/name
    if (!product.title || product.title.trim().length === 0) {
        return { valid: false, reason: 'Missing title' };
    }
    // Must have an ID
    if (!product.id) {
        return { valid: false, reason: 'Missing ID' };
    }
    // Must have valid calories
    if (!product.nutrition?.energyKcal || product.nutrition.energyKcal <= 0) {
        return { valid: false, reason: 'Missing or invalid calories' };
    }
    // Calories sanity check
    if (product.nutrition.energyKcal > 950) {
        return { valid: false, reason: `Calories too high: ${product.nutrition.energyKcal}` };
    }
    // Must have ingredients (if required) - minimum 10 characters to filter out garbage
    if (requireIngredients && (!product.ingredients || product.ingredients.trim().length < 10)) {
        return { valid: false, reason: 'Missing or insufficient ingredients' };
    }
    return { valid: true };
}
// Helper: Count non-zero nutrition fields
function countNutritionFields(nutrition) {
    if (!nutrition)
        return 0;
    let count = 0;
    if (nutrition.energyKcal)
        count++;
    if (nutrition.energyKj)
        count++;
    if (nutrition.fat)
        count++;
    if (nutrition.saturates)
        count++;
    if (nutrition.carbohydrate)
        count++;
    if (nutrition.sugars)
        count++;
    if (nutrition.fibre)
        count++;
    if (nutrition.protein)
        count++;
    if (nutrition.salt)
        count++;
    return count;
}
// Helper: Check if new product has more complete data than existing
function isMoreComplete(newProduct, existingData) {
    const newNutritionCount = countNutritionFields(newProduct.nutrition);
    const existingNutritionCount = countNutritionFields(existingData.nutrition);
    // New has more nutrition fields
    if (newNutritionCount > existingNutritionCount)
        return true;
    // New has ingredients but existing doesn't
    if (newProduct.ingredients && !existingData.ingredients)
        return true;
    // New has allergens but existing doesn't
    if (newProduct.allergens?.length && !existingData.allergens?.length)
        return true;
    return false;
}
// Helper: Strip HTML tags and clean ingredients text
function cleanIngredients(text) {
    if (!text)
        return '';
    let str = Array.isArray(text) ? text.join(', ') : text;
    // Remove HTML tags like <p>, <strong>, </strong>, etc.
    str = str.replace(/<[^>]*>/g, '');
    // Remove "INGREDIENTS:" prefix if present
    str = str.replace(/^INGREDIENTS:\s*/i, '');
    // Clean up whitespace
    str = str.replace(/\s+/g, ' ').trim();
    return str;
}
// Helper: Sleep function
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
/**
 * Token Bucket Rate Limiter - allows burst while maintaining average rate
 * Much more efficient than fixed delays - only waits when actually needed
 */
class RateLimiter {
    constructor(requestsPerSecond, burstCapacity = requestsPerSecond) {
        this.maxTokens = burstCapacity;
        this.tokens = burstCapacity;
        this.refillRate = requestsPerSecond / 1000;
        this.lastRefill = Date.now();
    }
    refillTokens() {
        const now = Date.now();
        const elapsed = now - this.lastRefill;
        this.tokens = Math.min(this.maxTokens, this.tokens + elapsed * this.refillRate);
        this.lastRefill = now;
    }
    async acquire() {
        this.refillTokens();
        if (this.tokens >= 1) {
            this.tokens -= 1;
            return;
        }
        // Calculate wait time needed to get 1 token
        const waitTime = Math.ceil((1 - this.tokens) / this.refillRate);
        await sleep(waitTime);
        return this.acquire();
    }
    async execute(fn) {
        await this.acquire();
        return fn();
    }
}
// 3 req/s with burst of 3 (conservative to preserve API quota)
const apiRateLimiter = new RateLimiter(3, 3);
// Parallel batch processing constants
const PARALLEL_BATCH_SIZE = 3; // Process 3 products concurrently (matches rate limit)
/**
 * Process product IDs in parallel batches with rate limiting
 * Returns results for all products (success or error)
 */
async function processProductBatch(productIds) {
    const results = [];
    for (let i = 0; i < productIds.length; i += PARALLEL_BATCH_SIZE) {
        const batch = productIds.slice(i, i + PARALLEL_BATCH_SIZE);
        const batchPromises = batch.map(async (productId) => {
            try {
                const { product, error } = await apiRateLimiter.execute(() => getProductDetails(productId));
                return { productId, product, error };
            }
            catch (err) {
                return { productId, product: null, error: err.message };
            }
        });
        const batchResults = await Promise.allSettled(batchPromises);
        for (const result of batchResults) {
            if (result.status === 'fulfilled') {
                results.push(result.value);
            }
            else {
                // Promise rejected - shouldn't happen but handle it
                results.push({ productId: 'unknown', product: null, error: result.reason?.message || 'Unknown error' });
            }
        }
    }
    return results;
}
// OPTIMIZED: Batch check which product IDs already exist in Firestore
async function batchCheckExisting(tescoCollection, productIds) {
    const existingMap = new Map();
    // Firestore getAll can handle up to 100 documents at once
    const chunks = [];
    for (let i = 0; i < productIds.length; i += 100) {
        chunks.push(productIds.slice(i, i + 100));
    }
    for (const chunk of chunks) {
        const refs = chunk.map(id => tescoCollection.doc(id));
        const docs = await admin.firestore().getAll(...refs);
        docs.forEach((doc, index) => {
            if (doc.exists) {
                existingMap.set(chunk[index], doc.data());
            }
        });
    }
    return existingMap;
}
// Parse serving size string to extract numeric value in grams/ml
function parseServingSizeToGrams(servingSize) {
    if (!servingSize)
        return 100;
    // Match patterns like "330ml", "100g", "1 serving (50g)", "per 100g"
    const match = servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml|grams?|millilitre?s?)/i);
    if (match) {
        return parseFloat(match[1]);
    }
    // Default to 100g if we can't parse
    return 100;
}
// OPTIMIZED: Prepare Algolia object from product
function prepareAlgoliaObject(product) {
    const servingSizeStr = product.servingSize || 'per 100g';
    const servingSizeG = parseServingSizeToGrams(product.servingSize);
    return {
        objectID: product.id,
        name: product.title,
        foodName: product.title,
        brandName: product.brand,
        brand: product.brand,
        barcode: product.gtin,
        gtin: product.gtin,
        calories: product.nutrition?.energyKcal || 0,
        protein: product.nutrition?.protein || 0,
        carbs: product.nutrition?.carbohydrate || 0,
        fat: product.nutrition?.fat || 0,
        saturates: product.nutrition?.saturates || 0,
        sugar: product.nutrition?.sugars || 0,
        sugars: product.nutrition?.sugars || 0,
        fiber: product.nutrition?.fibre || 0,
        fibre: product.nutrition?.fibre || 0,
        salt: product.nutrition?.salt || 0,
        sodium: product.nutrition?.salt ? product.nutrition.salt * 400 : 0,
        ingredients: product.ingredients || '',
        servingSize: servingSizeStr,
        servingDescription: servingSizeStr, // iOS app expects this key
        servingSizeG: servingSizeG, // Parse actual serving size
        category: product.category || '',
        imageUrl: product.imageUrl || '',
        source: 'Tesco',
        verified: true,
        isVerified: true,
        allergens: product.allergens || []
    };
}
// Helper: Retry with exponential backoff
async function retryWithBackoff(fn, maxRetries = 3, baseDelay = 500, // Reduced from 2000ms - API supports 5 req/s
operationName = 'operation') {
    let lastError;
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        }
        catch (error) {
            lastError = error;
            const statusCode = error.response?.status;
            // If rate limited (429), wait longer and retry
            if (statusCode === 429 && attempt < maxRetries) {
                const delay = baseDelay * Math.pow(2, attempt); // Exponential backoff: 2s, 4s, 8s
                console.log(`Rate limited on ${operationName}, waiting ${delay}ms before retry ${attempt + 1}/${maxRetries}...`);
                await sleep(delay);
                continue;
            }
            // For other errors, only retry once
            if (attempt < 1) {
                console.log(`Error in ${operationName}: ${error.message}, retrying once...`);
                await sleep(1000);
                continue;
            }
            throw error;
        }
    }
    throw lastError;
}
/**
 * Search Tesco products by keyword
 */
async function searchTescoProducts(query, page = 0) {
    return retryWithBackoff(async () => {
        const response = await axios_1.default.get(`https://${TESCO8_HOST}/product-search-by-keyword`, {
            params: {
                query,
                page: page.toString()
            },
            headers: {
                'x-rapidapi-host': TESCO8_HOST,
                'x-rapidapi-key': TESCO8_API_KEY
            },
            timeout: 15000
        });
        if (!response.data?.success) {
            return { products: [], totalPages: 0 };
        }
        const products = response.data?.data?.products || [];
        const pagination = response.data?.data?.pagination || {};
        const totalPages = pagination.totalPages || 1;
        return { products, totalPages };
    }, 3, 1000, `search "${query}" page ${page}`); // Reduced from 3000ms
}
async function getProductDetails(productId) {
    try {
        console.log(`Fetching product details for: ${productId}`);
        const response = await retryWithBackoff(async () => {
            return axios_1.default.get(`https://${TESCO8_HOST}/product-details`, {
                params: { productId },
                headers: {
                    'x-rapidapi-host': TESCO8_HOST,
                    'x-rapidapi-key': TESCO8_API_KEY
                },
                timeout: 15000
            });
        }, 3, 1000, `product details ${productId}`); // Reduced from 3000ms
        // Debug logging
        console.log(`Product ${productId} response status: ${response.status}`);
        console.log(`Product ${productId} response success: ${response.data?.success}`);
        console.log(`Product ${productId} response keys: ${JSON.stringify(Object.keys(response.data || {}))}`);
        if (!response.data?.success) {
            const errorMsg = `API returned success=false for ${productId}. Response: ${JSON.stringify(response.data).substring(0, 200)}`;
            console.error(errorMsg);
            return { product: null, error: errorMsg };
        }
        if (!response.data?.data?.results?.[0]?.data?.product) {
            const errorMsg = `No product data in response for ${productId}. Structure: data.data=${!!response.data?.data}, results=${JSON.stringify(response.data?.data?.results?.length || 0)}`;
            console.error(errorMsg);
            return { product: null, error: errorMsg };
        }
        const productData = response.data.data.results[0].data.product;
        const details = productData.details || {};
        // Check if this is a food item (filter out non-food products)
        const category = (productData.superDepartment || productData.department || '').toLowerCase();
        const title = (productData.title || '').toLowerCase();
        const brand = (productData.brand || '').toLowerCase();
        // Non-food categories
        const NON_FOOD_CATEGORIES = [
            'household', 'cleaning', 'laundry', 'pet', 'health', 'beauty',
            'toiletries', 'baby', 'nappies', 'home', 'garden', 'diy',
            'electrical', 'stationery', 'clothing', 'toys', 'seasonal',
            'battery', 'batteries'
        ];
        // Non-food brands (products from these brands are never food)
        const NON_FOOD_BRANDS = [
            'duracell', 'energizer', 'panasonic', 'varta', // Batteries
            'oral-b', 'oral b', 'colgate', 'sensodyne', 'aquafresh', 'listerine', // Oral care
            'dove', 'lynx', 'sure', 'nivea', 'garnier', 'loreal', "l'oreal", // Personal care
            'andrex', 'cushelle', 'kleenex', 'plenty', // Toilet/tissue
            'fairy', 'persil', 'ariel', 'bold', 'daz', 'surf', 'comfort', // Cleaning/laundry
            'dettol', 'domestos', 'flash', 'cillit bang', 'mr muscle', // Disinfectant/cleaning
            'nurofen', 'paracetamol', 'ibuprofen', 'calpol', 'lemsip', // Medicine
            'pampers', 'huggies', // Baby care
            'whiskas', 'felix', 'pedigree', 'iams', 'purina' // Pet food
        ];
        // Non-food keywords in title
        const NON_FOOD_KEYWORDS = [
            'battery', 'batteries', 'charger',
            'toothpaste', 'toothbrush', 'mouthwash', 'dental', 'floss',
            'shampoo', 'conditioner', 'soap', 'shower gel', 'body wash',
            'deodorant', 'antiperspirant', 'moisturiser', 'moisturizer',
            'toilet roll', 'toilet tissue', 'kitchen roll', 'tissues',
            'washing liquid', 'laundry', 'dishwasher', 'washing up',
            'bleach', 'disinfectant', 'cleaner', 'polish',
            'painkiller', 'tablet', 'capsule', 'medicine',
            'nappies', 'nappy', 'diaper', 'baby wipe',
            'cat food', 'dog food', 'pet food', 'pet treats',
            'light bulb', 'lightbulb', 'extension lead', 'plug'
        ];
        // Check category
        if (NON_FOOD_CATEGORIES.some(nf => category.includes(nf))) {
            console.log(`Skipping non-food product: ${productData.title} (category: ${category})`);
            return { product: null, error: `Non-food item: ${category}` };
        }
        // Check brand
        if (NON_FOOD_BRANDS.some(nfb => brand.includes(nfb))) {
            console.log(`Skipping non-food brand: ${productData.title} (brand: ${productData.brand})`);
            return { product: null, error: `Non-food brand: ${productData.brand}` };
        }
        // Check title keywords
        if (NON_FOOD_KEYWORDS.some(nfk => title.includes(nfk))) {
            console.log(`Skipping non-food product: ${productData.title} (title keyword match)`);
            return { product: null, error: `Non-food keyword in title` };
        }
        // Parse nutrition
        const nutrition = {};
        const nutritionItems = details.nutritionInfo || [];
        let servingSize;
        // Log the full details object structure to understand available fields
        console.log(`Product ${productId} details keys: ${JSON.stringify(Object.keys(details))}`);
        if (nutritionItems.length > 0) {
            console.log(`Product ${productId} nutrition item sample: ${JSON.stringify(nutritionItems[0])}`);
        }
        for (const item of nutritionItems) {
            const name = item.name?.toLowerCase() || '';
            const value = item.perComp || ''; // per 100g column
            // Energy - handles multiple formats:
            // 1. "Energy Content (KCAL)" with value "360"
            // 2. "Energy" with value "360kcal"
            // 3. "Energy" with value "1506kJ/360kcal" (slash-separated, kJ first then kcal)
            // 4. "Energy" with value "360kcal/1506kJ" (slash-separated, kcal first then kJ)
            if (name.includes('energy') || (name === '-' && value.includes('kcal'))) {
                // Check if name contains (KCAL) or (KJ) - indicates the value is just a number
                if (name.includes('(kcal)') || name.includes('kcal)')) {
                    // Value is just the number, e.g., "360"
                    nutrition.energyKcal = parseNumber(value);
                }
                else if (name.includes('(kj)') || name.includes('kj)')) {
                    // Value is just the number for kJ
                    nutrition.energyKj = parseNumber(value);
                }
                else {
                    // Value contains units - MUST extract with regex to avoid concatenation issues
                    // e.g., "1506kJ/360kcal" should give kcal=360, NOT kcal=1506360
                    // Extract kcal value - look for number immediately before 'kcal'
                    const kcalMatch = value.match(/(\d+(?:\.\d+)?)\s*kcal/i);
                    if (kcalMatch) {
                        nutrition.energyKcal = parseFloat(kcalMatch[1]);
                    }
                    // Extract kJ value - look for number immediately before 'kJ'
                    const kjMatch = value.match(/(\d+(?:\.\d+)?)\s*kJ/i);
                    if (kjMatch) {
                        nutrition.energyKj = parseFloat(kjMatch[1]);
                    }
                    // ONLY fall back to plain number parsing if NO unit found AND value doesn't contain a slash
                    // This prevents "1506kJ/360kcal" from being parsed as 1506360
                    if (!kcalMatch && !kjMatch && !value.includes('/') && !name.includes('kj')) {
                        const plainNum = parseNumber(value) || 0;
                        // Sanity check: calories per 100g should be under 1000 (pure fat is ~900)
                        if (plainNum > 0 && plainNum < 1000) {
                            nutrition.energyKcal = plainNum;
                        }
                    }
                }
                // Fat - handles "Fat", "Total Fat", "Total Fat (g)" etc. but NOT saturated fat
            }
            else if ((name === 'fat' || name.includes('total fat') || (name.startsWith('fat') && !name.includes('saturate'))) && !name.includes('saturate')) {
                nutrition.fat = parseNumber(value);
            }
            else if (name.includes('saturate')) {
                nutrition.saturates = parseNumber(value);
            }
            else if ((name.includes('carbohydrate') || name.includes('carbs') || name.includes('total carbohydrate')) && !name.includes('sugar')) {
                nutrition.carbohydrate = parseNumber(value);
            }
            else if (name.includes('sugar')) {
                nutrition.sugars = parseNumber(value);
            }
            else if (name.includes('fibre') || name.includes('fiber') || name.includes('dietary fiber')) {
                nutrition.fibre = parseNumber(value);
            }
            else if (name.includes('protein')) {
                nutrition.protein = parseNumber(value);
            }
            else if (name.includes('salt') || name.includes('sodium')) {
                // Handle sodium conversion if needed (sodium to salt = sodium * 2.5)
                if (name.includes('sodium') && !name.includes('salt')) {
                    const sodiumMg = parseNumber(value) || 0;
                    // If value is in mg (typically >100), convert to g then to salt
                    if (sodiumMg > 10) {
                        nutrition.salt = (sodiumMg / 1000) * 2.5;
                    }
                    else if (sodiumMg > 0) {
                        // Already in grams
                        nutrition.salt = sodiumMg * 2.5;
                    }
                }
                else {
                    nutrition.salt = parseNumber(value);
                }
            }
            // Extract serving size from perServing column value or header
            // Try multiple patterns - Tesco uses various formats
            if (!servingSize) {
                // Check perServing column value for patterns like "30g", "Per 30g serving", etc.
                const perServingValue = item.perServing || '';
                if (perServingValue) {
                    // Try direct number match first (e.g., "30g" or "50ml")
                    let servingMatch = perServingValue.match(/^(\d+(?:\.\d+)?)\s*(g|ml)$/i);
                    if (!servingMatch) {
                        // Try "Per Xg" or "Per X g" format
                        servingMatch = perServingValue.match(/per\s+(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    }
                    if (!servingMatch) {
                        // Try "Xg serving" format
                        servingMatch = perServingValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)\s*serving/i);
                    }
                    if (!servingMatch) {
                        // Try any number with g/ml
                        servingMatch = perServingValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    }
                    if (servingMatch) {
                        servingSize = `${servingMatch[1]}${servingMatch[2].toLowerCase()}`;
                        console.log(`Found serving size from perServing: ${servingSize} (original: ${perServingValue})`);
                    }
                }
            }
        }
        // Try to get serving size from nutrition table header or servingSize field
        if (!servingSize && details.servingSize) {
            const match = details.servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.servingSize: ${servingSize}`);
            }
        }
        // Look for serving size in typical serving info
        if (!servingSize && details.typicalServingSize) {
            const match = details.typicalServingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.typicalServingSize: ${servingSize}`);
            }
        }
        // Check for servingHeader field (some products have this)
        if (!servingSize && details.servingHeader) {
            const match = details.servingHeader.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.servingHeader: ${servingSize}`);
            }
        }
        // Check unitOfMeasure or portionSize fields
        if (!servingSize && details.portionSize) {
            const match = details.portionSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.portionSize: ${servingSize}`);
            }
        }
        // Check product-level serving info
        if (!servingSize && productData.servingSize) {
            const match = productData.servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from productData.servingSize: ${servingSize}`);
            }
        }
        // Last resort: try to infer from the nutrition table structure itself
        // Sometimes the column header contains "Per serving (Xg)"
        if (!servingSize && details.nutritionInfo?.length > 0) {
            // Check for perServingHeader or columnHeaders
            const firstItem = details.nutritionInfo[0];
            for (const key of Object.keys(firstItem || {})) {
                if (key.toLowerCase().includes('serving') && !key.toLowerCase().includes('percomp')) {
                    const headerValue = String(firstItem[key] || '');
                    const match = headerValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    if (match) {
                        servingSize = `${match[1]}${match[2].toLowerCase()}`;
                        console.log(`Found serving size from nutrition header field '${key}': ${servingSize}`);
                        break;
                    }
                }
            }
        }
        // Default to 100g if no serving size found (it's per 100g anyway)
        if (!servingSize) {
            servingSize = '100g';
            console.log(`No serving size found for ${productId}, defaulting to 100g`);
        }
        // CRITICAL: Skip products without ingredients AND without nutrition
        // Real food products ALWAYS have either ingredients or nutritional info
        // Non-food items (batteries, toiletries) have neither
        const hasIngredients = details.ingredients &&
            (Array.isArray(details.ingredients) ? details.ingredients.length > 0 : details.ingredients.trim().length > 0);
        const hasNutritionData = hasValidNutrition(nutrition);
        if (!hasIngredients && !hasNutritionData) {
            console.log(`Skipping non-food product: ${productData.title} (no ingredients and no nutrition data)`);
            return { product: null, error: 'Non-food item: no ingredients or nutrition' };
        }
        // Build product object
        const product = {
            id: productData.id || productId,
            tpnb: productData.tpnb || '',
            gtin: productData.gtin || '',
            title: productData.title || '',
            brand: productData.brandName || 'Tesco',
            description: Array.isArray(productData.description)
                ? productData.description.join(' ')
                : productData.description,
            imageUrl: productData.defaultImageUrl,
            price: productData.price?.actual,
            unitPrice: productData.price?.unitPrice,
            nutrition,
            ingredients: cleanIngredients(details.ingredients),
            allergens: details.allergenInfo ? identifyAllergens(details.allergenInfo) : [],
            servingSize,
            category: productData.superDepartment || productData.department,
            importedAt: new Date().toISOString(),
            source: 'tesco8_api'
        };
        return { product };
    }
    catch (error) {
        console.error(`Details error for product ${productId}:`, error.message);
        return { product: null, error: `Exception: ${error.message}` };
    }
}
/**
 * Get current build progress
 */
exports.getTescoBuildProgress = functions.https.onCall(async (_data, context) => {
    // Verify admin
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const progressDoc = await db.collection('system').doc('tescoBuildProgress').get();
    if (!progressDoc.exists) {
        return {
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            currentPage: 0,
            maxPages: 5,
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: '',
            lastUpdated: '',
            errorMessages: [],
            recentlyFoundProducts: []
        };
    }
    return progressDoc.data();
});
/**
 * Start or resume the Tesco database build
 */
exports.startTescoBuild = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (data, context) => {
    // Verify admin
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');
    const tescoCollection = db.collection('tescoProducts');
    // Get current progress
    const progressDoc = await progressRef.get();
    let progress = progressDoc.exists
        ? progressDoc.data()
        : {
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            currentPage: 5, // Start at page 5 (continuing from previous run)
            maxPages: 10, // Go up to page 9 (pages 5-9)
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: new Date().toISOString(),
            lastUpdated: new Date().toISOString(),
            errorMessages: [],
            recentlyFoundProducts: []
        };
    // Ensure currentPage and maxPages exist for older progress docs
    if (progress.currentPage === undefined)
        progress.currentPage = 5;
    if (progress.maxPages === undefined)
        progress.maxPages = 10;
    // Log current status for debugging
    console.log(`[START] Current status: ${progress.status}, currentTermIndex: ${progress.currentTermIndex}/${SEARCH_TERMS.length}, lastUpdated: ${progress.lastUpdated}`);
    // Check if already running - but handle stale 'running' status
    // Cloud Functions timeout after 540 seconds (9 mins) without updating status
    // If lastUpdated is more than 10 minutes old, the function has timed out
    if (progress.status === 'running') {
        const lastUpdated = new Date(progress.lastUpdated).getTime();
        const now = Date.now();
        const staleCutoff = 10 * 60 * 1000; // 10 minutes
        if (now - lastUpdated < staleCutoff) {
            // Recently updated - actually still running
            console.log(`[START] Build already running (last updated ${Math.round((now - lastUpdated) / 1000)}s ago). Returning.`);
            return {
                success: false,
                message: 'Build already in progress',
                progress
            };
        }
        else {
            // Stale 'running' status - function timed out without updating
            console.log(`[START] Detected stale 'running' status (last updated ${Math.round((now - lastUpdated) / 60000)} mins ago). Resuming build...`);
            // Fall through to allow restart
        }
    }
    // Option to reset - check this FIRST before the completed check
    if (data?.reset) {
        console.log(`[START] Reset requested - restarting build from beginning`);
        progress = {
            status: 'running',
            currentTermIndex: 0,
            currentTerm: SEARCH_TERMS[0],
            totalTerms: SEARCH_TERMS.length,
            currentPage: 5, // Start at page 5 (continuing from previous run)
            maxPages: 10, // Go up to page 9 (pages 5-9)
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: new Date().toISOString(),
            lastUpdated: new Date().toISOString(),
            errorMessages: [],
            recentlyFoundProducts: []
        };
    }
    else if (progress.status === 'completed') {
        // Only block if completed AND not requesting reset
        console.log(`[START] Build already completed. Use reset=true to restart.`);
        return {
            success: false,
            message: 'Build already completed. Use reset to restart.',
            progress
        };
    }
    else {
        progress.status = 'running';
        progress.lastUpdated = new Date().toISOString();
    }
    await progressRef.set(progress);
    // Initialize Algolia
    let algoliaClient = null;
    if (ALGOLIA_ADMIN_KEY) {
        algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    }
    const seenProductIds = new Set();
    const ALGOLIA_BATCH_SIZE = 100; // Batch Algolia writes for efficiency
    let algoliaBatch = [];
    // Helper to flush Algolia batch
    const flushAlgoliaBatch = async () => {
        if (algoliaBatch.length > 0 && algoliaClient) {
            try {
                await algoliaClient.saveObjects({
                    indexName: TESCO_INDEX_NAME,
                    objects: algoliaBatch
                });
                console.log(`[ALGOLIA] Flushed ${algoliaBatch.length} objects`);
            }
            catch (e) {
                console.error(`[ALGOLIA] Batch error: ${e.message}`);
            }
            algoliaBatch = [];
        }
    };
    try {
        // Process search terms from where we left off - 5 PAGES PER TERM
        // This approach: Pages 0-4 of term 0, then pages 0-4 of term 1, etc.
        console.log(`[LOOP] Starting from term index ${progress.currentTermIndex} page ${progress.currentPage} (${SEARCH_TERMS[progress.currentTermIndex] || 'END'})`);
        for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
            const term = SEARCH_TERMS[termIndex];
            progress.currentTermIndex = termIndex;
            progress.currentTerm = term;
            // Process multiple pages for this term (from currentPage to maxPages-1)
            const startPage = (termIndex === progress.currentTermIndex) ? progress.currentPage : 0;
            for (let page = startPage; page < progress.maxPages; page++) {
                progress.currentPage = page;
                progress.lastUpdated = new Date().toISOString();
                await progressRef.update({ ...progress });
                console.log(`[SEARCH] "${term}" page ${page + 1}/${progress.maxPages} (term ${termIndex + 1}/${SEARCH_TERMS.length})`);
                try {
                    // Search for this term at this page
                    const { products, totalPages } = await searchTescoProducts(term, page);
                    // Skip if this page doesn't exist for this term
                    if (page >= totalPages) {
                        console.log(`[SEARCH] Term "${term}" only has ${totalPages} pages, done with this term`);
                        break; // Move to next term
                    }
                    // OPTIMIZED: Batch check which products already exist
                    const newProductIds = products.filter(p => !seenProductIds.has(p.id)).map(p => p.id);
                    newProductIds.forEach(id => seenProductIds.add(id));
                    progress.productsFound += newProductIds.length;
                    // Batch read existing documents
                    const existingMap = await batchCheckExisting(tescoCollection, newProductIds);
                    // OPTIMIZED: Fetch product details in parallel batches with rate limiting
                    // Filter to only IDs that need fetching (not in existingMap or need update check)
                    const idsToFetch = newProductIds.filter(id => {
                        const existing = existingMap.get(id);
                        // Fetch if not existing, or if we need to check for more complete data
                        return !existing || true; // Always fetch to check for completeness
                    });
                    console.log(`[BATCH] Fetching ${idsToFetch.length} products in parallel batches`);
                    const batchResults = await processProductBatch(idsToFetch);
                    // Process batch results
                    for (const { productId, product, error: detailsError } of batchResults) {
                        if (detailsError) {
                            progress.errors++;
                            progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                            if (progress.errorMessages.length > 50) {
                                progress.errorMessages = progress.errorMessages.slice(-50);
                            }
                            continue;
                        }
                        const existingData = existingMap.get(productId);
                        // Check if existing and if new data is more complete
                        if (existingData && product) {
                            if (!isMoreComplete(product, existingData)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            // New data is more complete - will update below
                            console.log(`Updating ${product.id} with more complete data`);
                        }
                        else if (existingData) {
                            progress.duplicatesSkipped++;
                            continue;
                        }
                        if (product) {
                            // STRICT VALIDATION: Must have title, ID, and valid calories
                            const validation = isValidProduct(product);
                            if (!validation.valid) {
                                console.log(`Skipping invalid product: ${product.title?.substring(0, 40)} - ${validation.reason}`);
                                progress.errors++;
                                progress.errorMessages.push(`Invalid product: ${validation.reason} - ${product.title?.substring(0, 30)}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue;
                            }
                            progress.productsWithNutrition++;
                            // Save to Firestore with error handling (set will create or update)
                            try {
                                await tescoCollection.doc(product.id).set(removeUndefined(product));
                                progress.productsSaved++;
                                progress.lastProductSavedAt = new Date().toISOString(); // Track for stall detection
                                console.log(`Saved product: ${product.id} - ${product.title?.substring(0, 40)} (${product.nutrition?.energyKcal} kcal)`);
                                // Track this product in recentlyFoundProducts
                                if (!progress.recentlyFoundProducts) {
                                    progress.recentlyFoundProducts = [];
                                }
                                progress.recentlyFoundProducts.push({
                                    id: product.id,
                                    title: product.title || 'Unknown',
                                    brand: product.brand,
                                    hasNutrition: hasValidNutrition(product.nutrition),
                                    savedAt: new Date().toISOString()
                                });
                                // Keep only last 30 products
                                if (progress.recentlyFoundProducts.length > 30) {
                                    progress.recentlyFoundProducts = progress.recentlyFoundProducts.slice(-30);
                                }
                            }
                            catch (firestoreError) {
                                console.error(`Firestore save error for ${product.id}:`, firestoreError.message);
                                progress.errors++;
                                progress.errorMessages.push(`Firestore save failed: ${firestoreError.message}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue; // Skip Algolia sync if Firestore failed
                            }
                            // OPTIMIZED: Add to Algolia batch instead of individual writes
                            algoliaBatch.push(prepareAlgoliaObject(product));
                            if (algoliaBatch.length >= ALGOLIA_BATCH_SIZE) {
                                await flushAlgoliaBatch();
                            }
                        }
                    }
                    // No sleep() needed - rate limiter handles timing
                    // Flush Algolia batch after each page
                    await flushAlgoliaBatch();
                    // Update progress after each page
                    progress.lastUpdated = new Date().toISOString();
                    await progressRef.update({ ...progress });
                }
                catch (searchError) {
                    progress.errors++;
                    progress.errorMessages.push(`Term "${term}" page ${page}: ${searchError.message}`);
                    if (progress.errorMessages.length > 50) {
                        progress.errorMessages = progress.errorMessages.slice(-50);
                    }
                    console.error(`Error searching "${term}" page ${page}:`, searchError.message);
                    // Rate limit on error - wait before continuing
                    if (searchError.response?.status === 429) {
                        console.log('Rate limited - waiting 10 seconds before next page');
                        await sleep(10000);
                    }
                    else {
                        // Short delay for other errors
                        await sleep(500);
                    }
                }
                // Check for pause request
                const currentProgress = await progressRef.get();
                if (currentProgress.data()?.status === 'paused') {
                    console.log('Build paused by user');
                    return {
                        success: true,
                        message: 'Build paused',
                        progress: currentProgress.data()
                    };
                }
            } // End page loop
            // Reset page to 0 for next term
            progress.currentPage = 0;
        } // End term loop
        // Final flush of any remaining Algolia objects
        await flushAlgoliaBatch();
        // Mark as completed
        console.log(`[COMPLETE] All ${SEARCH_TERMS.length} search terms processed.`);
        progress.status = 'completed';
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
        return {
            success: true,
            message: 'Build completed',
            progress
        };
    }
    catch (error) {
        console.error(`[ERROR] Fatal error: ${error.message}`, error.stack);
        progress.status = 'error';
        progress.errorMessages.push(`Fatal: ${error.message}`);
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
        throw new functions.https.HttpsError('internal', `Build failed: ${error.message}`);
    }
});
/**
 * Pause the Tesco database build
 */
exports.pauseTescoBuild = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');
    await progressRef.update({
        status: 'paused',
        lastUpdated: new Date().toISOString()
    });
    return { success: true, message: 'Build paused' };
});
/**
 * STOP the Tesco database build completely (not just pause)
 * This sets status to 'idle' so scheduled function won't restart it
 */
exports.stopTescoBuild = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');
    await progressRef.update({
        status: 'idle',
        lastUpdated: new Date().toISOString()
    });
    return { success: true, message: 'Build stopped completely' };
});
/**
 * Scheduled function to auto-continue Tesco build every 5 minutes
 * This keeps the build running continuously until all products are imported
 */
exports.scheduledTescoBuild = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .pubsub
    .schedule('every 5 minutes')
    .onRun(async () => {
    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');
    const tescoCollection = db.collection('tescoProducts');
    // Get current progress
    const progressDoc = await progressRef.get();
    let progress = progressDoc.exists
        ? progressDoc.data()
        : {
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            currentPage: 0,
            maxPages: 5,
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: new Date().toISOString(),
            lastUpdated: new Date().toISOString(),
            errorMessages: [],
            recentlyFoundProducts: []
        };
    // Ensure currentPage and maxPages exist for older progress docs
    if (progress.currentPage === undefined)
        progress.currentPage = 5;
    if (progress.maxPages === undefined)
        progress.maxPages = 10;
    console.log(`[SCHEDULED] Status: ${progress.status}, Page: ${progress.currentPage}/${progress.maxPages}, Term: ${progress.currentTermIndex}/${progress.totalTerms}`);
    // Only run if status is 'running' (started via admin UI)
    // Don't run if paused, completed, or idle
    if (progress.status !== 'running') {
        console.log(`[SCHEDULED] Build status is '${progress.status}', not continuing.`);
        return null;
    }
    // ============ STALL DETECTION & AUTO-RESTART ============
    // Check if we've stalled (no product saved in last 2 minutes)
    const STALL_THRESHOLD_MS = 2 * 60 * 1000; // 2 minutes
    const AUTO_RESTART_DELAY_MS = 30 * 1000; // 30 seconds
    const now = Date.now();
    const lastProductTime = progress.lastProductSavedAt
        ? new Date(progress.lastProductSavedAt).getTime()
        : new Date(progress.lastUpdated).getTime();
    const timeSinceLastProduct = now - lastProductTime;
    if (timeSinceLastProduct > STALL_THRESHOLD_MS) {
        console.log(`[SCHEDULED] ⚠️ STALL DETECTED! No product saved for ${Math.round(timeSinceLastProduct / 1000)}s`);
        console.log(`[SCHEDULED] 🔄 Auto-restarting: pausing, waiting 30s, then resuming...`);
        // Update progress to show we're auto-restarting
        progress.autoRestartCount = (progress.autoRestartCount || 0) + 1;
        progress.lastAutoRestart = new Date().toISOString();
        progress.errorMessages.push(`Auto-restart #${progress.autoRestartCount} at ${progress.lastAutoRestart} - stalled for ${Math.round(timeSinceLastProduct / 1000)}s`);
        if (progress.errorMessages.length > 50) {
            progress.errorMessages = progress.errorMessages.slice(-50);
        }
        // Step 1: Pause
        progress.status = 'paused';
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
        console.log(`[SCHEDULED] ⏸️ Paused. Waiting ${AUTO_RESTART_DELAY_MS / 1000}s before restart...`);
        // Step 2: Wait 30 seconds
        await new Promise(resolve => setTimeout(resolve, AUTO_RESTART_DELAY_MS));
        // Step 3: Resume
        progress.status = 'running';
        progress.lastUpdated = new Date().toISOString();
        progress.lastProductSavedAt = new Date().toISOString(); // Reset the timer
        await progressRef.update({ ...progress });
        console.log(`[SCHEDULED] ▶️ Resumed after auto-restart #${progress.autoRestartCount}`);
    }
    // ============ END STALL DETECTION ============
    // Check if already completed (all terms done)
    if (progress.currentTermIndex >= SEARCH_TERMS.length) {
        console.log(`[SCHEDULED] All ${SEARCH_TERMS.length} terms completed, marking as completed.`);
        progress.status = 'completed';
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
        return null;
    }
    // Update lastUpdated to show we're still active
    progress.lastUpdated = new Date().toISOString();
    await progressRef.update({ ...progress });
    // Initialize Algolia
    let algoliaClient = null;
    if (ALGOLIA_ADMIN_KEY) {
        algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    }
    const seenProductIds = new Set();
    const ALGOLIA_BATCH_SIZE = 100;
    let algoliaBatch = [];
    // Helper to flush Algolia batch
    const flushAlgoliaBatch = async () => {
        if (algoliaBatch.length > 0 && algoliaClient) {
            try {
                await algoliaClient.saveObjects({
                    indexName: TESCO_INDEX_NAME,
                    objects: algoliaBatch
                });
                console.log(`[SCHEDULED] Flushed ${algoliaBatch.length} items to Algolia`);
            }
            catch (e) {
                console.error(`[SCHEDULED] Algolia batch error: ${e.message}`);
            }
            algoliaBatch = [];
        }
    };
    try {
        // Process search terms from where we left off - 5 PAGES PER TERM
        // This approach: Pages 0-4 of term 0, then pages 0-4 of term 1, etc.
        console.log(`[SCHEDULED] Starting from term index ${progress.currentTermIndex} page ${progress.currentPage}`);
        for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
            const term = SEARCH_TERMS[termIndex];
            progress.currentTermIndex = termIndex;
            progress.currentTerm = term;
            // Process multiple pages for this term (from currentPage to maxPages-1)
            const startPage = (termIndex === progress.currentTermIndex) ? progress.currentPage : 0;
            for (let page = startPage; page < progress.maxPages; page++) {
                progress.currentPage = page;
                progress.lastUpdated = new Date().toISOString();
                await progressRef.update({ ...progress });
                console.log(`[SCHEDULED] "${term}" page ${page + 1}/${progress.maxPages} (term ${termIndex + 1}/${SEARCH_TERMS.length})`);
                try {
                    // Search for this term at this page
                    const { products, totalPages } = await searchTescoProducts(term, page);
                    // Skip if this page doesn't exist for this term
                    if (page >= totalPages) {
                        console.log(`[SCHEDULED] Term "${term}" only has ${totalPages} pages, done with this term`);
                        break; // Move to next term
                    }
                    // OPTIMIZED: Filter out already seen products first
                    const newProducts = products.filter(p => {
                        if (seenProductIds.has(p.id)) {
                            progress.duplicatesSkipped++;
                            return false;
                        }
                        seenProductIds.add(p.id);
                        progress.productsFound++;
                        return true;
                    });
                    // OPTIMIZED: Batch check which products already exist in Firestore
                    const newProductIds = newProducts.map(p => p.id);
                    const existingMap = await batchCheckExisting(tescoCollection, newProductIds);
                    // OPTIMIZED: Fetch product details in parallel batches with rate limiting
                    if (newProductIds.length > 0) {
                        console.log(`[SCHEDULED] Fetching ${newProductIds.length} products in parallel batches`);
                        const batchResults = await processProductBatch(newProductIds);
                        for (const { productId, product, error: detailsError } of batchResults) {
                            if (detailsError) {
                                progress.errors++;
                                progress.errorMessages.push(`Details: ${detailsError}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue;
                            }
                            // Check if existing and if new data is more complete
                            const existingData = existingMap.get(productId);
                            if (existingData && product) {
                                if (!isMoreComplete(product, existingData)) {
                                    progress.duplicatesSkipped++;
                                    continue;
                                }
                                console.log(`[SCHEDULED] Updating ${product.id} with more complete data`);
                            }
                            else if (existingData) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            if (product) {
                                // STRICT VALIDATION: Must have title, ID, and valid calories
                                const validation = isValidProduct(product);
                                if (!validation.valid) {
                                    console.log(`[SCHEDULED] Skipping invalid: ${product.title?.substring(0, 30)} - ${validation.reason}`);
                                    continue;
                                }
                                progress.productsWithNutrition++;
                                try {
                                    await tescoCollection.doc(product.id).set(removeUndefined(product));
                                    progress.productsSaved++;
                                    progress.lastProductSavedAt = new Date().toISOString(); // Track for stall detection
                                    console.log(`[SCHEDULED] Saved: ${product.title?.substring(0, 30)} (${product.nutrition?.energyKcal} kcal)`);
                                    // OPTIMIZED: Add to Algolia batch instead of individual writes
                                    algoliaBatch.push(prepareAlgoliaObject(product));
                                    if (algoliaBatch.length >= ALGOLIA_BATCH_SIZE) {
                                        await flushAlgoliaBatch();
                                    }
                                }
                                catch (e) {
                                    progress.errors++;
                                }
                            }
                        }
                    }
                    // No sleep() needed - rate limiter handles timing
                    // Update progress after processing this page
                    progress.lastUpdated = new Date().toISOString();
                    await progressRef.update({ ...progress });
                    // Flush any remaining Algolia items after processing page
                    await flushAlgoliaBatch();
                }
                catch (searchError) {
                    progress.errors++;
                    if (searchError.response?.status === 429) {
                        await sleep(10000);
                    }
                }
                // Check for pause
                const currentProgress = await progressRef.get();
                if (currentProgress.data()?.status === 'paused') {
                    console.log('[SCHEDULED] Build paused');
                    // Flush remaining Algolia items before pausing
                    await flushAlgoliaBatch();
                    return null;
                }
            } // End page loop
            // Reset page to 0 for next term
            progress.currentPage = 0;
        } // End term loop
        // Flush any remaining Algolia items
        await flushAlgoliaBatch();
        // All terms are done - mark as completed
        progress.status = 'completed';
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
        console.log(`[SCHEDULED] All ${SEARCH_TERMS.length} terms completed!`);
    }
    catch (error) {
        console.error(`[SCHEDULED] Error: ${error.message}`);
        progress.errorMessages.push(`Scheduled: ${error.message}`);
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({ ...progress });
    }
    return null;
});
/**
 * Reset the Tesco database (delete all and start fresh)
 */
exports.resetTescoDatabase = functions
    .runWith({ timeoutSeconds: 300, memory: '512MB' })
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const tescoCollection = db.collection('tescoProducts');
    // Delete all documents in batches
    const batchSize = 500;
    let deleted = 0;
    while (true) {
        const snapshot = await tescoCollection.limit(batchSize).get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        deleted += snapshot.size;
        console.log(`Deleted ${deleted} Tesco products`);
    }
    // Reset progress
    await db.collection('system').doc('tescoBuildProgress').set({
        status: 'idle',
        currentTermIndex: 0,
        currentTerm: '',
        totalTerms: SEARCH_TERMS.length,
        productsFound: 0,
        productsWithNutrition: 0,
        productsSaved: 0,
        duplicatesSkipped: 0,
        errors: 0,
        startedAt: '',
        lastUpdated: new Date().toISOString(),
        errorMessages: []
    });
    // Clear Algolia index
    if (ALGOLIA_ADMIN_KEY) {
        try {
            const algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
            await algoliaClient.clearObjects({ indexName: TESCO_INDEX_NAME });
            console.log('Cleared Algolia index');
        }
        catch (error) {
            console.error('Algolia clear error:', error.message);
        }
    }
    return {
        success: true,
        message: `Reset complete. Deleted ${deleted} products.`,
        deletedCount: deleted
    };
});
/**
 * Get stats about the Tesco database
 */
exports.getTescoDatabaseStats = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const tescoCollection = db.collection('tescoProducts');
    // Get count using aggregation
    const snapshot = await tescoCollection.count().get();
    const totalProducts = snapshot.data().count;
    // Get sample products with nutrition
    const withNutritionSnapshot = await tescoCollection
        .where('nutrition.energyKcal', '>', 0)
        .limit(1)
        .get();
    // Get recent imports
    const recentSnapshot = await tescoCollection
        .orderBy('importedAt', 'desc')
        .limit(5)
        .get();
    const recentProducts = recentSnapshot.docs.map(doc => ({
        id: doc.id,
        title: doc.data().title,
        brand: doc.data().brand,
        hasNutrition: hasValidNutrition(doc.data().nutrition),
        importedAt: doc.data().importedAt
    }));
    return {
        totalProducts,
        hasNutritionEstimate: !withNutritionSnapshot.empty,
        recentProducts,
        collectionName: 'tescoProducts',
        algoliaIndex: TESCO_INDEX_NAME
    };
});
/**
 * Configure Algolia index settings for Tesco products
 * Sets searchable attributes, ranking rules, etc.
 */
exports.configureTescoAlgoliaIndex = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    if (!ALGOLIA_ADMIN_KEY) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }
    const algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    try {
        await algoliaClient.setSettings({
            indexName: TESCO_INDEX_NAME,
            indexSettings: {
                // Searchable attributes - configured for Tesco product fields
                searchableAttributes: [
                    'unordered(foodName)', // Product name (title)
                    'unordered(brandName)', // Brand name
                    'barcode', // Barcode (GTIN)
                    'unordered(ingredients)', // Ingredients text
                    'unordered(category)' // Product category
                ],
                // Custom ranking
                customRanking: [
                    'desc(calories)', // Products with nutrition data rank higher
                    'asc(foodName)' // Alphabetical for ties
                ],
                // Ranking criteria
                ranking: [
                    'typo',
                    'words',
                    'filters',
                    'proximity',
                    'attribute',
                    'exact',
                    'custom'
                ],
                // Typo tolerance
                minWordSizefor1Typo: 3,
                minWordSizefor2Typos: 6,
                typoTolerance: true,
                // Query settings
                exactOnSingleWordQuery: 'word',
                removeWordsIfNoResults: 'allOptional',
                queryType: 'prefixLast',
                // Language handling
                ignorePlurals: ['en'],
                removeStopWords: ['en'],
                // Highlighting
                attributesToHighlight: ['foodName', 'brandName'],
                highlightPreTag: '<em>',
                highlightPostTag: '</em>',
                // Attributes to retrieve
                attributesToRetrieve: [
                    'objectID',
                    'foodName',
                    'brandName',
                    'barcode',
                    'calories',
                    'protein',
                    'carbs',
                    'fat',
                    'sugar',
                    'fiber',
                    'salt',
                    'ingredients',
                    'servingSize',
                    'category',
                    'imageUrl',
                    'source'
                ]
            }
        });
        console.log('✅ Configured Tesco Algolia index settings');
        return { success: true, message: 'Tesco Algolia index configured' };
    }
    catch (error) {
        console.error('❌ Error configuring Tesco Algolia index:', error.message);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Sync all Tesco products from Firestore to Algolia
 * Use this to re-sync if products weren't indexed during build
 */
exports.syncTescoToAlgolia = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    if (!ALGOLIA_ADMIN_KEY) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }
    const db = admin.firestore();
    const algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    try {
        // First configure the index settings
        await algoliaClient.setSettings({
            indexName: TESCO_INDEX_NAME,
            indexSettings: {
                searchableAttributes: [
                    'unordered(name)', // Admin UI uses 'name'
                    'unordered(foodName)',
                    'unordered(brandName)',
                    'barcode',
                    'gtin',
                    'unordered(ingredients)',
                    'unordered(category)'
                ],
                customRanking: ['desc(calories)', 'asc(name)'],
                typoTolerance: true,
                minWordSizefor1Typo: 3,
                minWordSizefor2Typos: 6
            }
        });
        console.log('✅ Index settings configured');
        // Get all Tesco products from Firestore
        const tescoCollection = db.collection('tescoProducts');
        let synced = 0;
        let errors = 0;
        const batchSize = 100;
        let lastDoc = null;
        while (true) {
            let query = tescoCollection.orderBy('importedAt', 'desc').limit(batchSize);
            if (lastDoc) {
                query = query.startAfter(lastDoc);
            }
            const snapshot = await query.get();
            if (snapshot.empty) {
                break;
            }
            // Prepare batch for Algolia with full field mapping
            const objects = snapshot.docs.map(doc => {
                const data = doc.data();
                const nutrition = data.nutrition || {};
                return {
                    objectID: doc.id,
                    name: data.title || '', // Admin UI uses 'name'
                    foodName: data.title || '',
                    brandName: data.brand || 'Tesco',
                    brand: data.brand || 'Tesco',
                    barcode: data.gtin || '',
                    gtin: data.gtin || '',
                    calories: nutrition.energyKcal || 0,
                    protein: nutrition.protein || 0,
                    carbs: nutrition.carbohydrate || 0,
                    fat: nutrition.fat || 0,
                    saturates: nutrition.saturates || 0,
                    sugar: nutrition.sugars || 0,
                    sugars: nutrition.sugars || 0,
                    fiber: nutrition.fibre || 0,
                    fibre: nutrition.fibre || 0,
                    salt: nutrition.salt || 0,
                    sodium: nutrition.salt ? nutrition.salt * 400 : 0,
                    ingredients: data.ingredients || '',
                    servingSize: data.servingSize || 'per 100g',
                    servingSizeG: 100,
                    category: data.category || '',
                    imageUrl: data.imageUrl || '',
                    source: 'Tesco',
                    verified: true,
                    isVerified: true,
                    allergens: data.allergens || []
                };
            });
            // Save batch to Algolia
            try {
                await algoliaClient.saveObjects({
                    indexName: TESCO_INDEX_NAME,
                    objects: objects
                });
                synced += objects.length;
                console.log(`Synced ${synced} products to Algolia...`);
            }
            catch (algoliaError) {
                console.error('Algolia batch save error:', algoliaError.message);
                errors += objects.length;
            }
            lastDoc = snapshot.docs[snapshot.docs.length - 1];
            // Small delay to avoid overwhelming Algolia
            await sleep(100);
        }
        return {
            success: true,
            message: `Synced ${synced} Tesco products to Algolia`,
            synced,
            errors
        };
    }
    catch (error) {
        console.error('❌ Error syncing Tesco to Algolia:', error.message);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Clean up existing Tesco database - removes HTML tags from ingredients,
 * validates nutrition data, and removes invalid products
 */
exports.cleanupTescoDatabase = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const db = admin.firestore();
    const tescoCollection = db.collection('tescoProducts');
    const dryRun = data?.dryRun === true; // Pass dryRun: true to preview without changes
    let processed = 0;
    let cleaned = 0;
    let deleted = 0;
    let invalidCalories = 0;
    let htmlCleaned = 0;
    const errors = [];
    const batchSize = 100;
    let lastDoc = null;
    // Initialize Algolia for sync
    let algoliaClient = null;
    if (ALGOLIA_ADMIN_KEY && !dryRun) {
        algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    }
    console.log(`Starting Tesco database cleanup... (dryRun: ${dryRun})`);
    while (true) {
        let query = tescoCollection.orderBy('importedAt').limit(batchSize);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        if (snapshot.empty) {
            break;
        }
        for (const doc of snapshot.docs) {
            processed++;
            const data = doc.data();
            const updates = {};
            let needsDelete = false;
            let needsUpdate = false;
            // 1. Check for valid title
            if (!data.title || data.title.trim().length === 0) {
                needsDelete = true;
                errors.push(`${doc.id}: Missing title`);
            }
            // 2. Check for valid calories
            const calories = data.nutrition?.energyKcal;
            if (!calories || calories <= 0 || calories > 950) {
                needsDelete = true;
                invalidCalories++;
                if (calories > 950) {
                    errors.push(`${doc.id}: Invalid calories (${calories})`);
                }
                else {
                    errors.push(`${doc.id}: Missing calories`);
                }
            }
            // 3. Clean HTML from ingredients
            if (data.ingredients && typeof data.ingredients === 'string') {
                const hasHtml = /<[^>]+>/.test(data.ingredients);
                if (hasHtml) {
                    const cleanedIngredients = cleanIngredients(data.ingredients);
                    updates['ingredients'] = cleanedIngredients;
                    needsUpdate = true;
                    htmlCleaned++;
                    console.log(`Cleaning HTML from ${doc.id}: "${data.ingredients.substring(0, 50)}..." → "${cleanedIngredients.substring(0, 50)}..."`);
                }
            }
            // Apply changes
            if (needsDelete) {
                deleted++;
                if (!dryRun) {
                    await doc.ref.delete();
                    // Also delete from Algolia
                    if (algoliaClient) {
                        try {
                            await algoliaClient.deleteObject({ indexName: TESCO_INDEX_NAME, objectID: doc.id });
                        }
                        catch (e) {
                            // Ignore Algolia delete errors
                        }
                    }
                }
            }
            else if (needsUpdate) {
                cleaned++;
                if (!dryRun) {
                    await doc.ref.update(updates);
                    // Also update in Algolia
                    if (algoliaClient) {
                        try {
                            await algoliaClient.partialUpdateObject({
                                indexName: TESCO_INDEX_NAME,
                                objectID: doc.id,
                                attributesToUpdate: { ingredients: updates['ingredients'] }
                            });
                        }
                        catch (e) {
                            // Ignore Algolia update errors
                        }
                    }
                }
            }
        }
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (processed % 500 === 0) {
            console.log(`Processed ${processed} products... (cleaned: ${cleaned}, deleted: ${deleted})`);
        }
        // Small delay to avoid overwhelming Firestore
        await sleep(50);
    }
    const result = {
        success: true,
        dryRun,
        processed,
        cleaned,
        deleted,
        invalidCalories,
        htmlCleaned,
        errors: errors.slice(0, 100), // Only return first 100 errors
        message: dryRun
            ? `DRY RUN: Would clean ${cleaned} products and delete ${deleted} invalid products`
            : `Cleaned ${cleaned} products and deleted ${deleted} invalid products`
    };
    console.log(`Cleanup complete: ${JSON.stringify({ ...result, errors: `${errors.length} total` })}`);
    return result;
});
//# sourceMappingURL=tesco-database-builder.js.map