/**
 * Food Categories with Default Serving Sizes
 * Used for AI categorization to improve serving size suggestions in the app
 */

export interface FoodCategory {
  id: string;
  name: string;
  description: string;
  defaultServingSize: number; // in grams or ml
  servingUnit: 'g' | 'ml';
  servingDescription: string;
  keywords: string[]; // Help AI recognize this category
}

export const FOOD_CATEGORIES: FoodCategory[] = [
  // === BEVERAGES ===
  {
    id: 'canned_drink',
    name: 'Canned Drink',
    description: 'Soft drinks, energy drinks in cans',
    defaultServingSize: 330,
    servingUnit: 'ml',
    servingDescription: 'per 330ml can',
    keywords: ['cola', 'fanta', 'sprite', 'energy drink', 'red bull', 'monster', 'lucozade', 'dr pepper', 'irn bru', 'tango', 'lilt', 'vimto']
  },
  {
    id: 'bottled_drink_small',
    name: 'Small Bottled Drink',
    description: 'Small plastic/glass bottles',
    defaultServingSize: 500,
    servingUnit: 'ml',
    servingDescription: 'per 500ml bottle',
    keywords: ['water bottle', 'small bottle', 'sports drink', 'lucozade sport', 'powerade']
  },
  {
    id: 'bottled_drink_large',
    name: 'Large Bottled Drink',
    description: 'Large plastic bottles',
    defaultServingSize: 250,
    servingUnit: 'ml',
    servingDescription: 'per 250ml glass',
    keywords: ['2 litre', '1.5 litre', 'family bottle', 'sharing bottle']
  },
  {
    id: 'carton_juice',
    name: 'Juice Carton',
    description: 'Juice boxes and cartons',
    defaultServingSize: 200,
    servingUnit: 'ml',
    servingDescription: 'per 200ml carton',
    keywords: ['juice box', 'ribena', 'capri sun', 'fruit shoot', 'tropicana', 'innocent', 'smoothie']
  },
  {
    id: 'beer_can',
    name: 'Beer Can',
    description: 'Standard beer/lager cans',
    defaultServingSize: 440,
    servingUnit: 'ml',
    servingDescription: 'per 440ml can',
    keywords: ['lager', 'beer', 'ale', 'carling', 'foster', 'stella', 'budweiser', 'heineken', 'peroni', 'corona']
  },
  {
    id: 'beer_bottle',
    name: 'Beer Bottle',
    description: 'Bottled beers',
    defaultServingSize: 330,
    servingUnit: 'ml',
    servingDescription: 'per 330ml bottle',
    keywords: ['craft beer', 'bottle beer', 'beer bottle']
  },
  {
    id: 'cider_can',
    name: 'Cider Can',
    description: 'Canned cider',
    defaultServingSize: 500,
    servingUnit: 'ml',
    servingDescription: 'per 500ml can',
    keywords: ['cider', 'strongbow', 'magners', 'kopparberg', 'bulmers', 'thatchers']
  },
  {
    id: 'wine_glass',
    name: 'Wine',
    description: 'Wine by the glass',
    defaultServingSize: 175,
    servingUnit: 'ml',
    servingDescription: 'per 175ml glass',
    keywords: ['wine', 'red wine', 'white wine', 'rose', 'prosecco', 'champagne']
  },
  {
    id: 'spirits',
    name: 'Spirits',
    description: 'Vodka, gin, whisky etc.',
    defaultServingSize: 25,
    servingUnit: 'ml',
    servingDescription: 'per 25ml measure',
    keywords: ['vodka', 'gin', 'whisky', 'rum', 'brandy', 'tequila', 'bourbon', 'scotch']
  },
  {
    id: 'hot_drink',
    name: 'Hot Drink',
    description: 'Tea, coffee, hot chocolate',
    defaultServingSize: 250,
    servingUnit: 'ml',
    servingDescription: 'per 250ml cup',
    keywords: ['coffee', 'tea', 'hot chocolate', 'latte', 'cappuccino', 'espresso', 'americano']
  },
  {
    id: 'milk_carton',
    name: 'Milk',
    description: 'Milk cartons/bottles',
    defaultServingSize: 200,
    servingUnit: 'ml',
    servingDescription: 'per 200ml glass',
    keywords: ['milk', 'semi skimmed', 'skimmed milk', 'whole milk', 'oat milk', 'almond milk', 'soy milk']
  },

  // === SNACKS & CONFECTIONERY ===
  {
    id: 'chocolate_bar',
    name: 'Chocolate Bar',
    description: 'Standard chocolate bars',
    defaultServingSize: 45,
    servingUnit: 'g',
    servingDescription: 'per bar',
    keywords: ['mars', 'snickers', 'twix', 'bounty', 'milky way', 'kit kat', 'dairy milk', 'galaxy', 'aero', 'wispa', 'crunchie', 'double decker', 'boost', 'yorkie']
  },
  {
    id: 'chocolate_bar_large',
    name: 'Large Chocolate Bar',
    description: 'Sharing/large format chocolate',
    defaultServingSize: 25,
    servingUnit: 'g',
    servingDescription: 'per 25g portion',
    keywords: ['sharing bar', 'family bar', 'giant bar', 'chocolate sharing']
  },
  {
    id: 'crisps_single',
    name: 'Crisps Packet',
    description: 'Single serve crisp packets',
    defaultServingSize: 25,
    servingUnit: 'g',
    servingDescription: 'per 25g bag',
    keywords: ['crisps', 'walkers', 'mccoys', 'kettle chips', 'pringles', 'doritos', 'sensations', 'quavers', 'wotsits', 'monster munch', 'skips', 'frazzles', 'hula hoops']
  },
  {
    id: 'crisps_sharing',
    name: 'Sharing Crisps',
    description: 'Large sharing bags',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per 30g portion',
    keywords: ['sharing bag', 'party size', 'grab bag', 'family pack crisps']
  },
  {
    id: 'biscuits',
    name: 'Biscuits',
    description: 'Individual biscuits/cookies',
    defaultServingSize: 25,
    servingUnit: 'g',
    servingDescription: 'per 2 biscuits',
    keywords: ['biscuit', 'digestive', 'hobnob', 'custard cream', 'bourbon', 'jammie dodger', 'rich tea', 'cookie', 'maryland', 'oreo', 'shortbread', 'jaffa cake']
  },
  {
    id: 'cereal_bar',
    name: 'Cereal/Snack Bar',
    description: 'Breakfast/cereal bars',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per bar',
    keywords: ['cereal bar', 'nutri-grain', 'belvita', 'nature valley', 'tracker', 'flapjack', 'nakd', 'trek', 'kind bar', 'protein bar']
  },
  {
    id: 'sweets_bag',
    name: 'Bag of Sweets',
    description: 'Confectionery bags',
    defaultServingSize: 40,
    servingUnit: 'g',
    servingDescription: 'per 40g portion',
    keywords: ['haribo', 'jelly babies', 'wine gums', 'fruit pastilles', 'starburst', 'skittles', 'fruit gums', 'pick n mix', 'dolly mixture', 'percy pig']
  },
  {
    id: 'nuts_pack',
    name: 'Nuts/Trail Mix',
    description: 'Nut packets and trail mixes',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per 30g handful',
    keywords: ['peanuts', 'cashews', 'almonds', 'mixed nuts', 'trail mix', 'pistachios', 'walnuts', 'brazils', 'macadamia']
  },
  {
    id: 'dried_fruit',
    name: 'Dried Fruit',
    description: 'Raisins, dried apricots etc.',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per 30g portion',
    keywords: ['raisins', 'sultanas', 'dried apricot', 'dried mango', 'cranberries', 'dates', 'figs', 'prunes']
  },
  {
    id: 'ice_cream_tub',
    name: 'Ice Cream',
    description: 'Ice cream tubs',
    defaultServingSize: 75,
    servingUnit: 'g',
    servingDescription: 'per scoop',
    keywords: ['ice cream', 'ben jerry', 'haagen dazs', 'magnum', 'cornetto', 'solero', 'fab', 'viennetta']
  },
  {
    id: 'ice_lolly',
    name: 'Ice Lolly',
    description: 'Individual ice lollies',
    defaultServingSize: 70,
    servingUnit: 'g',
    servingDescription: 'per lolly',
    keywords: ['ice lolly', 'calippo', 'twister', 'fruit pastille lolly', 'feast', 'solero']
  },

  // === BREAD & BAKERY ===
  {
    id: 'sliced_bread',
    name: 'Sliced Bread',
    description: 'Sandwich bread slices',
    defaultServingSize: 36,
    servingUnit: 'g',
    servingDescription: 'per slice',
    keywords: ['bread', 'hovis', 'warburtons', 'kingsmill', 'white bread', 'brown bread', 'wholemeal', 'sourdough', 'seeded loaf']
  },
  {
    id: 'bread_roll',
    name: 'Bread Roll',
    description: 'Individual rolls/baps',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per roll',
    keywords: ['roll', 'bap', 'bun', 'ciabatta', 'brioche', 'bagel', 'english muffin', 'crumpet', 'teacake']
  },
  {
    id: 'wrap_tortilla',
    name: 'Wrap/Tortilla',
    description: 'Wraps and tortillas',
    defaultServingSize: 62,
    servingUnit: 'g',
    servingDescription: 'per wrap',
    keywords: ['wrap', 'tortilla', 'mission wrap', 'old el paso', 'flatbread', 'pitta', 'naan']
  },
  {
    id: 'croissant',
    name: 'Croissant/Pastry',
    description: 'Pastries and croissants',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per pastry',
    keywords: ['croissant', 'pain au chocolat', 'danish', 'pastry', 'cinnamon swirl', 'pain au raisin']
  },
  {
    id: 'muffin_cake',
    name: 'Muffin/Cake',
    description: 'Muffins and individual cakes',
    defaultServingSize: 85,
    servingUnit: 'g',
    servingDescription: 'per muffin',
    keywords: ['muffin', 'cupcake', 'fairy cake', 'brownie', 'flapjack', 'slice', 'traybake']
  },
  {
    id: 'pasty_pie',
    name: 'Pasty/Pie',
    description: 'Cornish pasties, pies, sausage rolls',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per pasty/pie',
    keywords: ['pasty', 'cornish pasty', 'pork pie', 'sausage roll', 'steak bake', 'greggs', 'meat pie', 'chicken pie', 'cheese pastry']
  },
  {
    id: 'doughnut',
    name: 'Doughnut',
    description: 'Ring or filled doughnuts',
    defaultServingSize: 70,
    servingUnit: 'g',
    servingDescription: 'per doughnut',
    keywords: ['doughnut', 'donut', 'ring doughnut', 'jam doughnut', 'krispy kreme', 'glazed donut']
  },
  {
    id: 'scone',
    name: 'Scone',
    description: 'Plain or fruit scones',
    defaultServingSize: 70,
    servingUnit: 'g',
    servingDescription: 'per scone',
    keywords: ['scone', 'fruit scone', 'cheese scone', 'cream tea']
  },

  // === MEALS & MAIN DISHES ===
  {
    id: 'ready_meal',
    name: 'Ready Meal',
    description: 'Microwave/oven ready meals',
    defaultServingSize: 400,
    servingUnit: 'g',
    servingDescription: 'per meal',
    keywords: ['ready meal', 'microwave meal', 'lasagne', 'cottage pie', 'curry', 'tikka masala', 'korma', 'sweet and sour', 'shepherd pie', 'frozen meal', 'ping meal']
  },
  {
    id: 'pizza_whole',
    name: 'Pizza (Whole)',
    description: 'Whole pizza',
    defaultServingSize: 125,
    servingUnit: 'g',
    servingDescription: 'per slice (1/4)',
    keywords: ['pizza', 'margherita', 'pepperoni pizza', 'hawaiian', 'meat feast', 'dr oetker', 'chicago town', 'goodfella']
  },
  {
    id: 'pizza_slice',
    name: 'Pizza Slice',
    description: 'Individual pizza slices',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per slice',
    keywords: ['pizza slice', 'takeaway pizza', 'dominos', 'pizza hut', 'papa johns']
  },
  {
    id: 'sandwich_prepacked',
    name: 'Pre-packed Sandwich',
    description: 'Shop-bought sandwiches',
    defaultServingSize: 200,
    servingUnit: 'g',
    servingDescription: 'per sandwich',
    keywords: ['sandwich', 'meal deal', 'boots sandwich', 'tesco sandwich', 'blt', 'club sandwich', 'wrap', 'baguette']
  },
  {
    id: 'soup_can',
    name: 'Tinned Soup',
    description: 'Canned soups',
    defaultServingSize: 400,
    servingUnit: 'g',
    servingDescription: 'per can',
    keywords: ['soup', 'heinz soup', 'tomato soup', 'chicken soup', 'cream of mushroom', 'minestrone', 'lentil soup']
  },
  {
    id: 'soup_carton',
    name: 'Fresh Soup',
    description: 'Fresh soup cartons',
    defaultServingSize: 300,
    servingUnit: 'ml',
    servingDescription: 'per 300ml serving',
    keywords: ['fresh soup', 'new covent garden', 'glorious soup', 'cully fitch']
  },
  {
    id: 'pot_noodle',
    name: 'Instant Noodles/Pot',
    description: 'Pot noodles and instant noodles',
    defaultServingSize: 90,
    servingUnit: 'g',
    servingDescription: 'per pot (dry weight)',
    keywords: ['pot noodle', 'super noodles', 'instant noodles', 'cup noodle', 'ramen']
  },
  {
    id: 'pasta_meal',
    name: 'Pasta Pot/Meal',
    description: 'Ready pasta meals',
    defaultServingSize: 300,
    servingUnit: 'g',
    servingDescription: 'per pot',
    keywords: ['pasta pot', 'pasta salad', 'mug shot', 'pot pasta', 'pasta n sauce']
  },
  {
    id: 'burrito_wrap',
    name: 'Burrito/Filled Wrap',
    description: 'Burritos and filled wraps',
    defaultServingSize: 350,
    servingUnit: 'g',
    servingDescription: 'per burrito',
    keywords: ['burrito', 'filled wrap', 'chicken wrap', 'fajita', 'quesadilla']
  },

  // === MEAT & PROTEIN ===
  {
    id: 'raw_chicken',
    name: 'Raw Chicken',
    description: 'Raw chicken portions',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per breast/portion',
    keywords: ['chicken breast', 'chicken thigh', 'chicken leg', 'raw chicken', 'chicken fillet', 'chicken drumstick']
  },
  {
    id: 'raw_beef',
    name: 'Raw Beef',
    description: 'Raw beef cuts',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['beef steak', 'sirloin', 'ribeye', 'fillet steak', 'rump steak', 'beef mince', 'raw beef', 'braising steak']
  },
  {
    id: 'raw_pork',
    name: 'Raw Pork',
    description: 'Raw pork cuts',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per chop/portion',
    keywords: ['pork chop', 'pork loin', 'pork fillet', 'raw pork', 'pork belly', 'pork shoulder', 'gammon']
  },
  {
    id: 'raw_lamb',
    name: 'Raw Lamb',
    description: 'Raw lamb cuts',
    defaultServingSize: 150,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['lamb chop', 'lamb leg', 'lamb shoulder', 'lamb mince', 'raw lamb', 'rack of lamb']
  },
  {
    id: 'mince',
    name: 'Mince',
    description: 'Raw minced meat',
    defaultServingSize: 125,
    servingUnit: 'g',
    servingDescription: 'per 125g portion',
    keywords: ['beef mince', 'lamb mince', 'pork mince', 'turkey mince', 'chicken mince', 'quorn mince']
  },
  {
    id: 'sausages',
    name: 'Sausages',
    description: 'Raw/cooked sausages',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per sausage',
    keywords: ['sausage', 'pork sausage', 'cumberland', 'lincolnshire', 'chipolata', 'richmond', 'walls sausage']
  },
  {
    id: 'bacon',
    name: 'Bacon',
    description: 'Bacon rashers',
    defaultServingSize: 25,
    servingUnit: 'g',
    servingDescription: 'per rasher',
    keywords: ['bacon', 'streaky bacon', 'back bacon', 'smoked bacon', 'unsmoked bacon', 'bacon rashers']
  },
  {
    id: 'ham_sliced',
    name: 'Sliced Ham/Deli Meat',
    description: 'Pre-sliced deli meats',
    defaultServingSize: 35,
    servingUnit: 'g',
    servingDescription: 'per 2 slices',
    keywords: ['ham', 'sliced ham', 'turkey slices', 'chicken slices', 'pastrami', 'salami', 'chorizo', 'deli meat', 'cooked meat']
  },
  {
    id: 'fish_fillet',
    name: 'Fish Fillet',
    description: 'Fresh fish fillets',
    defaultServingSize: 140,
    servingUnit: 'g',
    servingDescription: 'per fillet',
    keywords: ['salmon fillet', 'cod fillet', 'haddock', 'sea bass', 'trout', 'mackerel', 'tuna steak', 'fish fillet']
  },
  {
    id: 'fish_fingers',
    name: 'Fish Fingers',
    description: 'Breaded fish fingers',
    defaultServingSize: 28,
    servingUnit: 'g',
    servingDescription: 'per finger',
    keywords: ['fish finger', 'birds eye', 'captain birds eye', 'cod fish finger']
  },
  {
    id: 'prawns',
    name: 'Prawns/Seafood',
    description: 'Prawns and shellfish',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per 100g portion',
    keywords: ['prawns', 'king prawns', 'shrimp', 'mussels', 'scallops', 'squid', 'calamari', 'crab', 'lobster']
  },
  {
    id: 'canned_fish',
    name: 'Tinned Fish',
    description: 'Canned tuna, salmon etc.',
    defaultServingSize: 120,
    servingUnit: 'g',
    servingDescription: 'per tin (drained)',
    keywords: ['tinned tuna', 'canned salmon', 'sardines', 'mackerel tin', 'pilchards', 'john west']
  },
  {
    id: 'eggs',
    name: 'Eggs',
    description: 'Whole eggs',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per medium egg',
    keywords: ['egg', 'eggs', 'free range egg', 'medium egg', 'large egg', 'chicken egg']
  },
  {
    id: 'tofu_tempeh',
    name: 'Tofu/Tempeh',
    description: 'Plant-based protein blocks',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per 100g portion',
    keywords: ['tofu', 'tempeh', 'firm tofu', 'silken tofu', 'smoked tofu']
  },

  // === DAIRY & ALTERNATIVES ===
  {
    id: 'cheese_block',
    name: 'Cheese Block',
    description: 'Hard cheese blocks',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per 30g portion',
    keywords: ['cheddar', 'cheese', 'red leicester', 'double gloucester', 'stilton', 'mature cheddar', 'mild cheddar', 'cheese block']
  },
  {
    id: 'cheese_sliced',
    name: 'Sliced Cheese',
    description: 'Pre-sliced cheese',
    defaultServingSize: 20,
    servingUnit: 'g',
    servingDescription: 'per slice',
    keywords: ['cheese slices', 'processed cheese', 'burger cheese', 'american cheese', 'emmental slices']
  },
  {
    id: 'cheese_spread',
    name: 'Cheese Spread',
    description: 'Soft/spreadable cheese',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['philadelphia', 'cream cheese', 'laughing cow', 'dairylea', 'cheese spread', 'soft cheese', 'boursin']
  },
  {
    id: 'yogurt_pot',
    name: 'Yogurt Pot',
    description: 'Individual yogurt pots',
    defaultServingSize: 125,
    servingUnit: 'g',
    servingDescription: 'per pot',
    keywords: ['yogurt', 'yoghurt', 'muller', 'activia', 'danone', 'onken', 'yeo valley', 'greek yogurt', 'natural yogurt']
  },
  {
    id: 'yogurt_drink',
    name: 'Yogurt Drink',
    description: 'Drinkable yogurts',
    defaultServingSize: 100,
    servingUnit: 'ml',
    servingDescription: 'per bottle',
    keywords: ['actimel', 'yakult', 'benecol', 'cholesterol drink', 'probiotic drink']
  },
  {
    id: 'butter_spread',
    name: 'Butter/Spread',
    description: 'Butter and spreads',
    defaultServingSize: 10,
    servingUnit: 'g',
    servingDescription: 'per serving (1 tsp)',
    keywords: ['butter', 'lurpak', 'anchor', 'flora', 'country life', 'margarine', 'spread', 'i cant believe', 'clover']
  },
  {
    id: 'cream',
    name: 'Cream',
    description: 'Single/double cream',
    defaultServingSize: 30,
    servingUnit: 'ml',
    servingDescription: 'per tablespoon',
    keywords: ['single cream', 'double cream', 'whipping cream', 'clotted cream', 'soured cream', 'creme fraiche']
  },

  // === FRUIT & VEGETABLES ===
  {
    id: 'fresh_fruit_whole',
    name: 'Whole Fresh Fruit',
    description: 'Whole pieces of fruit',
    defaultServingSize: 120,
    servingUnit: 'g',
    servingDescription: 'per fruit',
    keywords: ['apple', 'banana', 'orange', 'pear', 'peach', 'nectarine', 'plum', 'mango', 'kiwi', 'satsuma', 'clementine']
  },
  {
    id: 'fresh_fruit_portion',
    name: 'Fresh Fruit Portion',
    description: 'Cut/prepared fruit',
    defaultServingSize: 80,
    servingUnit: 'g',
    servingDescription: 'per 80g portion (1 of 5-a-day)',
    keywords: ['grapes', 'strawberries', 'blueberries', 'raspberries', 'melon', 'pineapple', 'watermelon', 'fruit salad', 'mixed berries']
  },
  {
    id: 'vegetables_fresh',
    name: 'Fresh Vegetables',
    description: 'Raw/uncooked vegetables',
    defaultServingSize: 80,
    servingUnit: 'g',
    servingDescription: 'per 80g portion (1 of 5-a-day)',
    keywords: ['carrot', 'broccoli', 'cauliflower', 'peas', 'beans', 'sweetcorn', 'spinach', 'lettuce', 'tomato', 'cucumber', 'pepper', 'courgette', 'aubergine', 'mushroom', 'onion']
  },
  {
    id: 'salad_bag',
    name: 'Bagged Salad',
    description: 'Pre-washed salad bags',
    defaultServingSize: 50,
    servingUnit: 'g',
    servingDescription: 'per handful',
    keywords: ['salad bag', 'rocket', 'mixed leaves', 'baby spinach', 'iceberg', 'watercress', 'coleslaw']
  },
  {
    id: 'potato_whole',
    name: 'Potato',
    description: 'Whole potatoes',
    defaultServingSize: 175,
    servingUnit: 'g',
    servingDescription: 'per medium potato',
    keywords: ['potato', 'baking potato', 'jacket potato', 'new potato', 'maris piper', 'king edward', 'sweet potato']
  },
  {
    id: 'tinned_vegetables',
    name: 'Tinned Vegetables',
    description: 'Canned vegetables',
    defaultServingSize: 80,
    servingUnit: 'g',
    servingDescription: 'per 80g portion',
    keywords: ['tinned peas', 'tinned sweetcorn', 'tinned carrots', 'canned vegetables', 'mushy peas']
  },
  {
    id: 'frozen_vegetables',
    name: 'Frozen Vegetables',
    description: 'Frozen veg bags',
    defaultServingSize: 80,
    servingUnit: 'g',
    servingDescription: 'per 80g portion',
    keywords: ['frozen peas', 'frozen sweetcorn', 'frozen broccoli', 'frozen mixed veg', 'birds eye vegetables']
  },
  {
    id: 'chips_frozen',
    name: 'Frozen Chips',
    description: 'Oven chips and fries',
    defaultServingSize: 165,
    servingUnit: 'g',
    servingDescription: 'per serving',
    keywords: ['oven chips', 'frozen chips', 'mccain', 'fries', 'wedges', 'crinkle cut', 'chunky chips']
  },
  {
    id: 'baked_beans',
    name: 'Baked Beans',
    description: 'Tinned baked beans',
    defaultServingSize: 207,
    servingUnit: 'g',
    servingDescription: 'per half can',
    keywords: ['baked beans', 'heinz beans', 'branston beans', 'beans on toast']
  },
  {
    id: 'hummus_dip',
    name: 'Hummus/Dips',
    description: 'Hummus and dips',
    defaultServingSize: 50,
    servingUnit: 'g',
    servingDescription: 'per 50g portion',
    keywords: ['hummus', 'guacamole', 'tzatziki', 'salsa', 'sour cream dip', 'taramasalata']
  },

  // === CEREALS & BREAKFAST ===
  {
    id: 'cereal_box',
    name: 'Breakfast Cereal',
    description: 'Boxed cereals',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per 30g serving',
    keywords: ['cereal', 'weetabix', 'shreddies', 'cheerios', 'corn flakes', 'rice krispies', 'crunchy nut', 'special k', 'granola', 'muesli', 'porridge oats', 'bran flakes', 'frosties']
  },
  {
    id: 'porridge_sachet',
    name: 'Instant Porridge',
    description: 'Instant porridge sachets',
    defaultServingSize: 36,
    servingUnit: 'g',
    servingDescription: 'per sachet',
    keywords: ['instant porridge', 'oat so simple', 'quaker oats', 'ready brek', 'porridge pot']
  },

  // === PASTA, RICE & GRAINS ===
  {
    id: 'pasta_dried',
    name: 'Dried Pasta',
    description: 'Uncooked pasta',
    defaultServingSize: 75,
    servingUnit: 'g',
    servingDescription: 'per 75g (dry)',
    keywords: ['pasta', 'spaghetti', 'penne', 'fusilli', 'tagliatelle', 'linguine', 'macaroni', 'lasagne sheets', 'farfalle']
  },
  {
    id: 'rice_dried',
    name: 'Dried Rice',
    description: 'Uncooked rice',
    defaultServingSize: 75,
    servingUnit: 'g',
    servingDescription: 'per 75g (dry)',
    keywords: ['rice', 'basmati', 'long grain', 'jasmine rice', 'brown rice', 'risotto rice', 'arborio']
  },
  {
    id: 'rice_microwave',
    name: 'Microwave Rice',
    description: 'Ready-to-heat rice pouches',
    defaultServingSize: 125,
    servingUnit: 'g',
    servingDescription: 'per half pouch',
    keywords: ['uncle bens', 'tilda', 'microwave rice', 'rice pouch', 'pilau rice']
  },
  {
    id: 'noodles_dried',
    name: 'Dried Noodles',
    description: 'Uncooked noodles',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per 60g nest',
    keywords: ['egg noodles', 'rice noodles', 'udon', 'ramen noodles', 'vermicelli', 'noodle nest']
  },
  {
    id: 'couscous',
    name: 'Couscous/Quinoa',
    description: 'Dried grains',
    defaultServingSize: 60,
    servingUnit: 'g',
    servingDescription: 'per 60g (dry)',
    keywords: ['couscous', 'quinoa', 'bulgur wheat', 'pearl barley', 'freekeh']
  },

  // === CONDIMENTS & SAUCES ===
  {
    id: 'sauce_bottle',
    name: 'Sauce/Condiment',
    description: 'Ketchup, mayo, BBQ etc.',
    defaultServingSize: 15,
    servingUnit: 'g',
    servingDescription: 'per tablespoon',
    keywords: ['ketchup', 'mayonnaise', 'bbq sauce', 'brown sauce', 'hp sauce', 'salad cream', 'mustard', 'sriracha', 'hot sauce', 'heinz ketchup', 'hellmans']
  },
  {
    id: 'cooking_sauce',
    name: 'Cooking Sauce',
    description: 'Pasta sauces, curry sauces',
    defaultServingSize: 125,
    servingUnit: 'g',
    servingDescription: 'per quarter jar',
    keywords: ['pasta sauce', 'dolmio', 'loyd grossman', 'curry sauce', 'tikka masala sauce', 'korma sauce', 'pesto', 'tomato sauce', 'stir fry sauce']
  },
  {
    id: 'gravy',
    name: 'Gravy',
    description: 'Gravy granules/powder',
    defaultServingSize: 50,
    servingUnit: 'ml',
    servingDescription: 'per 50ml ladle',
    keywords: ['gravy', 'bisto', 'oxo', 'gravy granules', 'beef gravy', 'chicken gravy']
  },
  {
    id: 'oil',
    name: 'Cooking Oil',
    description: 'Olive oil, vegetable oil etc.',
    defaultServingSize: 15,
    servingUnit: 'ml',
    servingDescription: 'per tablespoon',
    keywords: ['olive oil', 'vegetable oil', 'sunflower oil', 'rapeseed oil', 'coconut oil', 'sesame oil']
  },
  {
    id: 'jam_spread',
    name: 'Jam/Sweet Spreads',
    description: 'Jams, honey, chocolate spread',
    defaultServingSize: 15,
    servingUnit: 'g',
    servingDescription: 'per tablespoon',
    keywords: ['jam', 'marmalade', 'honey', 'nutella', 'chocolate spread', 'peanut butter', 'marmite', 'lemon curd', 'biscoff spread']
  },
  {
    id: 'sugar',
    name: 'Sugar',
    description: 'Granulated/caster sugar',
    defaultServingSize: 4,
    servingUnit: 'g',
    servingDescription: 'per teaspoon',
    keywords: ['sugar', 'white sugar', 'brown sugar', 'demerara', 'caster sugar', 'icing sugar']
  },

  // === TAKEAWAY & FAST FOOD ===
  {
    id: 'burger',
    name: 'Burger',
    description: 'Fast food burgers',
    defaultServingSize: 250,
    servingUnit: 'g',
    servingDescription: 'per burger',
    keywords: ['burger', 'big mac', 'whopper', 'quarter pounder', 'cheeseburger', 'mcdonalds', 'burger king', 'five guys']
  },
  {
    id: 'fried_chicken',
    name: 'Fried Chicken',
    description: 'KFC-style pieces',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per piece',
    keywords: ['fried chicken', 'kfc', 'chicken piece', 'chicken wing', 'chicken strip', 'popcorn chicken', 'chicken bucket']
  },
  {
    id: 'chips_takeaway',
    name: 'Takeaway Chips',
    description: 'Fish shop/takeaway chips',
    defaultServingSize: 200,
    servingUnit: 'g',
    servingDescription: 'per regular portion',
    keywords: ['chip shop chips', 'takeaway chips', 'chunky chips', 'fish shop chips']
  },
  {
    id: 'fish_battered',
    name: 'Battered Fish',
    description: 'Fish & chips style fish',
    defaultServingSize: 200,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['battered fish', 'fish and chips', 'cod in batter', 'haddock in batter', 'chip shop fish']
  },
  {
    id: 'kebab',
    name: 'Kebab',
    description: 'Doner/shish kebabs',
    defaultServingSize: 300,
    servingUnit: 'g',
    servingDescription: 'per kebab',
    keywords: ['doner kebab', 'shish kebab', 'chicken kebab', 'lamb kebab', 'kebab meat']
  },
  {
    id: 'chinese_dish',
    name: 'Chinese Takeaway',
    description: 'Chinese main dishes',
    defaultServingSize: 350,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['sweet and sour', 'chow mein', 'kung po', 'crispy duck', 'fried rice', 'egg fried rice', 'spring roll', 'prawn crackers']
  },
  {
    id: 'indian_dish',
    name: 'Indian Takeaway',
    description: 'Indian curry dishes',
    defaultServingSize: 350,
    servingUnit: 'g',
    servingDescription: 'per portion',
    keywords: ['chicken tikka masala', 'korma', 'balti', 'bhuna', 'jalfrezi', 'vindaloo', 'biryani', 'samosa', 'onion bhaji', 'pakora', 'naan bread', 'poppadom']
  },
  {
    id: 'sushi',
    name: 'Sushi',
    description: 'Sushi pieces/packs',
    defaultServingSize: 25,
    servingUnit: 'g',
    servingDescription: 'per piece',
    keywords: ['sushi', 'nigiri', 'maki', 'california roll', 'sashimi', 'wasabi', 'itsu', 'yo sushi']
  },

  // === MISCELLANEOUS ===
  {
    id: 'protein_powder',
    name: 'Protein Powder',
    description: 'Protein shake powder',
    defaultServingSize: 30,
    servingUnit: 'g',
    servingDescription: 'per scoop',
    keywords: ['protein powder', 'whey protein', 'myprotein', 'bulk', 'protein shake', 'mass gainer', 'casein']
  },
  {
    id: 'baby_food',
    name: 'Baby Food',
    description: 'Baby food pouches/jars',
    defaultServingSize: 120,
    servingUnit: 'g',
    servingDescription: 'per pouch/jar',
    keywords: ['baby food', 'ella kitchen', 'cow and gate', 'aptamil', 'hipp', 'baby puree']
  },
  {
    id: 'pet_food',
    name: 'Pet Food',
    description: 'Dog/cat food (not for human consumption)',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per serving',
    keywords: ['dog food', 'cat food', 'whiskas', 'felix', 'pedigree', 'bakers', 'iams']
  },
  {
    id: 'flour',
    name: 'Flour',
    description: 'Cooking flour',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per 100g',
    keywords: ['flour', 'plain flour', 'self raising', 'bread flour', 'wholemeal flour', 'cornflour']
  },
  {
    id: 'supplement',
    name: 'Vitamin/Supplement',
    description: 'Vitamin pills and supplements',
    defaultServingSize: 1,
    servingUnit: 'g',
    servingDescription: 'per tablet',
    keywords: ['vitamin', 'supplement', 'multivitamin', 'cod liver oil', 'omega 3', 'vitamin d', 'vitamin c', 'iron supplement', 'centrum']
  },
  {
    id: 'unknown',
    name: 'Other/Unknown',
    description: 'Could not categorize',
    defaultServingSize: 100,
    servingUnit: 'g',
    servingDescription: 'per 100g',
    keywords: []
  }
];

/**
 * Get category by ID
 */
export function getCategoryById(categoryId: string): FoodCategory | undefined {
  return FOOD_CATEGORIES.find(cat => cat.id === categoryId);
}

/**
 * Get all category IDs for AI prompt
 */
export function getCategoryIds(): string[] {
  return FOOD_CATEGORIES.map(cat => cat.id);
}

/**
 * Get category descriptions for AI prompt
 */
export function getCategoryDescriptions(): string {
  return FOOD_CATEGORIES
    .filter(cat => cat.id !== 'unknown')
    .map(cat => `- ${cat.id}: ${cat.name} - ${cat.description} (e.g., ${cat.keywords.slice(0, 3).join(', ')})`)
    .join('\n');
}

/**
 * Get serving size info for a category
 */
export function getServingSizeForCategory(categoryId: string): { size: number; unit: 'g' | 'ml'; description: string } | null {
  const category = getCategoryById(categoryId);
  if (!category) return null;

  return {
    size: category.defaultServingSize,
    unit: category.servingUnit,
    description: category.servingDescription
  };
}
