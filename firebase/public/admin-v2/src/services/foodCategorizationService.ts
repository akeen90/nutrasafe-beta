/**
 * Food Categorization Service
 * AI-powered food categorization using Claude 3.5 Sonnet or GPT-4o
 *
 * Tiered serving size system:
 * - T0: Actual database serving size (if passes sanity check)
 * - T1: Category default serving size
 * - T2: Fallback to 100g
 */

// ============================================================================
// CATEGORY DEFINITIONS
// ============================================================================

export interface ServingSize {
  name: string;
  grams: number;
}

export interface FoodCategory {
  id: string;
  name: string;
  description: string;
  keywords: string[];           // Positive keywords to match
  excludeKeywords: string[];    // Keywords that should NOT match this category
  defaultServingG: number;      // T1 default serving size
  servingSizes?: ServingSize[]; // Optional small/medium/large variants
  toleranceMin: number;         // Minimum acceptable T0 serving (grams)
  toleranceMax: number;         // Maximum acceptable T0 serving (grams)
  examples: string[];           // Example products for AI context
  notExamples: string[];        // Counter-examples (things that look similar but aren't)
}

export const FOOD_CATEGORIES: FoodCategory[] = [
  // ============================================================================
  // DAIRY & ALTERNATIVES
  // ============================================================================
  {
    id: 'milk',
    name: 'Milk & Milk Alternatives',
    description: 'Liquid milk products and plant-based alternatives for drinking',
    keywords: ['milk', 'semi-skimmed', 'skimmed', 'whole milk', 'oat milk', 'almond milk', 'soy milk', 'soya milk', 'lactofree'],
    excludeKeywords: ['chocolate', 'milkshake', 'milk chocolate', 'milky bar', 'milky way', 'condensed', 'evaporated', 'powder', 'dried'],
    defaultServingG: 200,
    servingSizes: [
      { name: 'Small glass', grams: 150 },
      { name: 'Medium glass', grams: 200 },
      { name: 'Large glass', grams: 300 },
    ],
    toleranceMin: 100,
    toleranceMax: 500,
    examples: ['Whole Milk', 'Semi-Skimmed Milk', 'Oatly Oat Milk', 'Alpro Soya Milk', 'Lactofree Semi-Skimmed'],
    notExamples: ['Cadbury Dairy Milk', 'Milk Chocolate Digestives', 'Chocolate Milkshake', 'Milky Bar', 'Milky Way'],
  },
  {
    id: 'cheese',
    name: 'Cheese',
    description: 'Hard and soft cheeses',
    keywords: ['cheese', 'cheddar', 'mozzarella', 'brie', 'camembert', 'stilton', 'parmesan', 'feta', 'halloumi', 'gouda', 'edam', 'red leicester', 'wensleydale'],
    excludeKeywords: ['cheesecake', 'cheese and onion', 'cheese sandwich', 'macaroni cheese', 'cheese string'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 100,
    examples: ['Cathedral City Mature Cheddar', 'Philadelphia Cream Cheese', 'Babybel', 'Boursin', 'Grated Mozzarella'],
    notExamples: ['New York Cheesecake', 'Cheese and Onion Crisps', 'Cheese Sandwich', 'Mac and Cheese'],
  },
  {
    id: 'yoghurt',
    name: 'Yoghurt & Fromage Frais',
    description: 'Yoghurts, fromage frais, and cultured dairy desserts',
    keywords: ['yoghurt', 'yogurt', 'fromage frais', 'skyr', 'kefir', 'activia', 'muller', 'yeo valley', 'fage'],
    excludeKeywords: ['yoghurt coated', 'yogurt raisins'],
    defaultServingG: 125,
    servingSizes: [
      { name: 'Small pot', grams: 100 },
      { name: 'Standard pot', grams: 125 },
      { name: 'Large pot', grams: 150 },
    ],
    toleranceMin: 50,
    toleranceMax: 500,
    examples: ['Muller Corner', 'Activia Strawberry', 'Fage Total 0%', 'Yeo Valley Organic', 'Petits Filous'],
    notExamples: ['Yoghurt Coated Raisins', 'Yoghurt Covered Nuts'],
  },
  {
    id: 'butter_spread',
    name: 'Butter & Spreads',
    description: 'Butter, margarine, spreadable fats, and butter alternatives. Includes "Creamy and Buttery" products like Elmlea which are plant-based butter substitutes.',
    keywords: ['butter', 'margarine', 'spread', 'flora', 'lurpak', 'anchor', 'bertolli', 'clover', 'utterly butterly', 'elmlea', 'creamy and buttery', 'buttery salted', 'buttery unsalted'],
    excludeKeywords: ['peanut butter', 'almond butter', 'chocolate spread', 'jam', 'marmalade', 'marmite'],
    defaultServingG: 10,
    toleranceMin: 5,
    toleranceMax: 30,
    examples: ['Lurpak Spreadable', 'Flora Original', 'Anchor Butter', 'Clover', 'Bertolli', 'Elmlea Creamy and Buttery Salted', 'Elmlea Creamy and Buttery Unsalted'],
    notExamples: ['Peanut Butter', 'Nutella', 'Biscoff Spread', 'Marmite', 'Elmlea Double (cream alternative)', 'Elmlea Single (cream alternative)'],
  },
  {
    id: 'cream',
    name: 'Cream',
    description: 'Single, double, whipping, and clotted cream (REAL dairy cream only)',
    keywords: ['cream', 'single cream', 'double cream', 'whipping cream', 'clotted cream', 'soured cream', 'creme fraiche'],
    excludeKeywords: ['ice cream', 'cream cheese', 'cream cracker', 'cream of', 'cream liqueur', 'cream egg', 'elmlea', 'cream alternative', 'plant cream', 'creamy'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 100,
    examples: ['Rodda\'s Clotted Cream', 'Creme Fraiche', 'Soured Cream', 'Tesco Double Cream', 'Sainsbury\'s Single Cream'],
    notExamples: ['Ice Cream', 'Cream Crackers', 'Cream of Tomato Soup', 'Cream Egg', 'Irish Cream Liqueur', 'Elmlea (cream alternative)'],
  },
  {
    id: 'cream_alternatives',
    name: 'Cream Alternatives',
    description: 'Plant-based and non-dairy cream for pouring/cooking/whipping (NOT butter substitutes). Elmlea Single/Double are cream alternatives. But "Creamy and Buttery" Elmlea = butter substitute → goes in butter_spreads.',
    keywords: ['cream alternative', 'plant cream', 'vegan cream', 'oat cream', 'soy cream', 'elmlea single', 'elmlea double', 'elmlea plant'],
    excludeKeywords: ['ice cream', 'cream cheese', 'creamy and buttery', 'buttery salted', 'buttery unsalted'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 100,
    examples: ['Elmlea Double', 'Elmlea Single', 'Elmlea Plant Double', 'Oatly Oat Cream', 'Alpro Soya Cream'],
    notExamples: ['Tesco Double Cream', 'Rodda\'s Clotted Cream', 'Real dairy cream', 'Elmlea Creamy and Buttery (butter substitute)'],
  },
  {
    id: 'eggs',
    name: 'Eggs',
    description: 'Whole eggs - chicken, duck, quail',
    keywords: ['egg', 'eggs', 'free range', 'barn eggs', 'organic eggs'],
    excludeKeywords: ['egg fried rice', 'egg sandwich', 'egg mayo', 'scotch egg', 'easter egg', 'cream egg', 'creme egg'],
    defaultServingG: 60,
    servingSizes: [
      { name: 'Medium egg', grams: 50 },
      { name: 'Large egg', grams: 60 },
      { name: 'Very large egg', grams: 70 },
    ],
    toleranceMin: 35,
    toleranceMax: 100,
    examples: ['Large Free Range Eggs', 'Organic Eggs', 'Clarence Court Eggs', 'Quail Eggs'],
    notExamples: ['Scotch Egg', 'Cadbury Creme Egg', 'Easter Egg', 'Egg Fried Rice', 'Egg Mayo Sandwich'],
  },

  // ============================================================================
  // BREAD & BAKERY
  // ============================================================================
  {
    id: 'bread_sliced',
    name: 'Sliced Bread',
    description: 'Pre-sliced bread loaves - white, wholemeal, seeded',
    keywords: ['bread', 'loaf', 'sliced', 'white bread', 'wholemeal bread', 'brown bread', 'warburtons', 'hovis', 'kingsmill'],
    excludeKeywords: ['garlic bread', 'bread roll', 'bread stick', 'naan bread', 'pitta', 'flatbread', 'breadcrumbs', 'bread sauce'],
    defaultServingG: 38,
    servingSizes: [
      { name: 'Thin slice', grams: 25 },
      { name: 'Medium slice', grams: 38 },
      { name: 'Thick slice', grams: 50 },
    ],
    toleranceMin: 20,
    toleranceMax: 80,
    examples: ['Warburtons Toastie White', 'Hovis Best of Both', 'Kingsmill 50/50', 'Roberts Bakery Wholemeal'],
    notExamples: ['Garlic Bread', 'Ciabatta Roll', 'Breadsticks', 'Stuffing'],
  },
  {
    id: 'bread_rolls',
    name: 'Bread Rolls & Buns',
    description: 'Individual bread rolls, baps, buns, bagels',
    keywords: ['roll', 'bun', 'bap', 'bagel', 'brioche bun', 'ciabatta roll', 'sub roll', 'hot dog bun', 'burger bun'],
    excludeKeywords: ['sausage roll', 'spring roll', 'swiss roll', 'cinnamon roll', 'iced bun'],
    defaultServingG: 60,
    servingSizes: [
      { name: 'Small roll', grams: 45 },
      { name: 'Medium roll', grams: 60 },
      { name: 'Large roll/bagel', grams: 85 },
    ],
    toleranceMin: 30,
    toleranceMax: 120,
    examples: ['White Bread Rolls', 'Warburtons Sandwich Thins', 'New York Bagels', 'Brioche Burger Buns'],
    notExamples: ['Sausage Roll', 'Spring Roll', 'Cinnamon Roll', 'Chelsea Bun'],
  },
  {
    id: 'crumpets',
    name: 'Crumpets & English Muffins',
    description: 'Crumpets, English muffins, pikelet',
    keywords: ['crumpet', 'english muffin', 'muffin', 'pikelet'],
    excludeKeywords: ['muffin chocolate', 'blueberry muffin', 'chocolate chip muffin', 'breakfast muffin'],
    defaultServingG: 55,
    toleranceMin: 40,
    toleranceMax: 80,
    examples: ['Warburtons Crumpets', 'Kingsmill Crumpets', 'Warburtons English Muffins'],
    notExamples: ['Chocolate Muffin', 'Blueberry Muffin', 'McDonalds McMuffin'],
  },
  {
    id: 'wraps_tortillas',
    name: 'Wraps & Tortillas',
    description: 'Flour tortillas, wraps, flatbreads for filling',
    keywords: ['wrap', 'tortilla', 'flatbread', 'naan', 'pitta', 'pita', 'chapati', 'roti'],
    excludeKeywords: ['tortilla chips', 'wrap meal', 'chicken wrap'],
    defaultServingG: 60,
    servingSizes: [
      { name: 'Small wrap', grams: 40 },
      { name: 'Medium wrap', grams: 60 },
      { name: 'Large wrap', grams: 80 },
    ],
    toleranceMin: 30,
    toleranceMax: 120,
    examples: ['Old El Paso Flour Tortillas', 'Mission Deli Wraps', 'Warburtons Wraps', 'Mini Naans'],
    notExamples: ['Doritos', 'Tortilla Chips', 'Chicken Fajita Wrap Meal'],
  },
  {
    id: 'croissants_pastries',
    name: 'Croissants & Pastries',
    description: 'Croissants, pain au chocolat, danish pastries',
    keywords: ['croissant', 'pain au chocolat', 'danish', 'pastry', 'almond croissant'],
    excludeKeywords: ['pastry case', 'puff pastry', 'filo pastry', 'shortcrust'],
    defaultServingG: 60,
    toleranceMin: 40,
    toleranceMax: 120,
    examples: ['All Butter Croissant', 'Pain au Chocolat', 'Almond Croissant', 'Cinnamon Swirl'],
    notExamples: ['Jus-Rol Puff Pastry', 'Filo Pastry Sheets', 'Cornish Pasty'],
  },

  // ============================================================================
  // CEREALS & BREAKFAST
  // ============================================================================
  {
    id: 'cereal_cold',
    name: 'Breakfast Cereals (Cold)',
    description: 'Cold cereals - flakes, puffs, clusters, granola',
    keywords: ['cereal', 'cornflakes', 'weetabix', 'shreddies', 'cheerios', 'special k', 'bran flakes', 'granola', 'muesli', 'crunchy nut', 'coco pops', 'frosties', 'rice krispies', 'shredded wheat'],
    excludeKeywords: ['cereal bar'],
    defaultServingG: 40,
    servingSizes: [
      { name: 'Small bowl', grams: 30 },
      { name: 'Medium bowl', grams: 40 },
      { name: 'Large bowl', grams: 60 },
    ],
    toleranceMin: 20,
    toleranceMax: 100,
    examples: ['Kelloggs Corn Flakes', 'Weetabix', 'Nestle Shreddies', 'Jordans Granola', 'Alpen Muesli'],
    notExamples: ['Nutri-Grain Cereal Bar', 'Kelloggs Crunchy Nut Bar'],
  },
  {
    id: 'porridge_oats',
    name: 'Porridge & Oats',
    description: 'Oats, porridge, overnight oats, instant oats',
    keywords: ['oats', 'porridge', 'oatmeal', 'oat so simple', 'ready brek', 'overnight oats', 'rolled oats', 'steel cut oats'],
    excludeKeywords: ['oat milk', 'oat cake', 'flapjack'],
    defaultServingG: 40,
    toleranceMin: 25,
    toleranceMax: 80,
    examples: ['Quaker Oats', 'Oat So Simple', 'Ready Brek', 'Flahavans Porridge Oats'],
    notExamples: ['Oatly Oat Milk', 'Nairns Oatcakes', 'Oat Flapjack'],
  },

  // ============================================================================
  // MEAT & POULTRY
  // ============================================================================
  {
    id: 'chicken_breast',
    name: 'Chicken Breast',
    description: 'Raw and cooked chicken breast fillets',
    keywords: ['chicken breast', 'chicken fillet', 'mini fillets', 'chicken escalope'],
    excludeKeywords: ['chicken kiev', 'chicken nugget', 'chicken burger', 'chicken pie', 'stuffed chicken'],
    defaultServingG: 150,
    servingSizes: [
      { name: 'Small breast', grams: 120 },
      { name: 'Medium breast', grams: 150 },
      { name: 'Large breast', grams: 200 },
    ],
    toleranceMin: 80,
    toleranceMax: 300,
    examples: ['Chicken Breast Fillets', 'Chargrilled Chicken Breast', 'Chicken Mini Fillets'],
    notExamples: ['Chicken Kiev', 'Chicken Nuggets', 'KFC Chicken', 'Nandos Chicken'],
  },
  {
    id: 'chicken_thigh_drumstick',
    name: 'Chicken Thighs & Drumsticks',
    description: 'Chicken thighs and drumsticks, bone-in or boneless',
    keywords: ['chicken thigh', 'chicken drumstick', 'chicken leg', 'thigh fillet'],
    excludeKeywords: [],
    defaultServingG: 120,
    toleranceMin: 60,
    toleranceMax: 200,
    examples: ['Chicken Thigh Fillets', 'Chicken Drumsticks', 'Skin-On Chicken Thighs'],
    notExamples: ['Chicken Breast', 'Whole Chicken'],
  },
  {
    id: 'beef_mince',
    name: 'Beef Mince',
    description: 'Minced beef of various fat percentages',
    keywords: ['beef mince', 'minced beef', 'ground beef', 'lean mince', 'extra lean mince', 'steak mince'],
    excludeKeywords: ['bolognese', 'lasagne', 'chilli con carne', 'burger'],
    defaultServingG: 125,
    toleranceMin: 80,
    toleranceMax: 250,
    examples: ['Lean Beef Mince 5% Fat', 'Beef Steak Mince', 'Extra Lean Minced Beef'],
    notExamples: ['Spaghetti Bolognese', 'Beef Burgers', 'Beef Lasagne'],
  },
  {
    id: 'beef_steak',
    name: 'Beef Steak',
    description: 'Steak cuts - sirloin, ribeye, fillet, rump',
    keywords: ['steak', 'sirloin', 'ribeye', 'fillet steak', 'rump steak', 'bavette', 'onglet'],
    excludeKeywords: ['steak pie', 'steak slice', 'steak bake', 'steak mince'],
    defaultServingG: 225,
    servingSizes: [
      { name: 'Small steak', grams: 170 },
      { name: 'Medium steak', grams: 225 },
      { name: 'Large steak', grams: 300 },
    ],
    toleranceMin: 120,
    toleranceMax: 450,
    examples: ['Ribeye Steak', 'Sirloin Steak', 'Rump Steak', 'Fillet Steak'],
    notExamples: ['Steak and Kidney Pie', 'Greggs Steak Bake', 'Pukka Steak Pie'],
  },
  {
    id: 'bacon',
    name: 'Bacon',
    description: 'Streaky and back bacon, smoked and unsmoked',
    keywords: ['bacon', 'streaky bacon', 'back bacon', 'smoked bacon', 'unsmoked bacon', 'bacon rashers', 'pancetta'],
    excludeKeywords: ['bacon sandwich', 'bacon roll', 'bacon bits', 'bacon flavour'],
    defaultServingG: 60,
    toleranceMin: 25,
    toleranceMax: 150,
    examples: ['Smoked Back Bacon', 'Unsmoked Streaky Bacon', 'Thick Cut Bacon', 'Pancetta Cubes'],
    notExamples: ['Bacon Sandwich', 'Bacon Flavour Crisps', 'Turkey Bacon'],
  },
  {
    id: 'sausages',
    name: 'Sausages',
    description: 'Pork, beef, chicken, and vegetarian sausages',
    keywords: ['sausage', 'sausages', 'cumberland', 'lincolnshire', 'chipolata', 'banger'],
    excludeKeywords: ['sausage roll', 'sausage meat', 'sausage casserole', 'hot dog'],
    defaultServingG: 67,
    servingSizes: [
      { name: '1 sausage', grams: 67 },
      { name: '2 sausages', grams: 134 },
      { name: '3 sausages', grams: 200 },
    ],
    toleranceMin: 40,
    toleranceMax: 250,
    examples: ['Cumberland Sausages', 'Pork Chipolatas', 'Richmond Thick Sausages', 'Linda McCartney Sausages'],
    notExamples: ['Greggs Sausage Roll', 'Sausage Casserole', 'Toad in the Hole'],
  },
  {
    id: 'ham_sliced',
    name: 'Sliced Ham & Cooked Meats',
    description: 'Sliced ham, turkey, chicken, and deli meats',
    keywords: ['ham', 'sliced ham', 'cooked ham', 'turkey slices', 'chicken slices', 'pastrami', 'salami', 'chorizo slices', 'prosciutto'],
    excludeKeywords: ['ham sandwich', 'ham and cheese', 'gammon'],
    defaultServingG: 35,
    toleranceMin: 15,
    toleranceMax: 100,
    examples: ['Tesco Honey Roast Ham', 'Wafer Thin Turkey', 'Sliced Chicken Breast', 'Parma Ham'],
    notExamples: ['Ham and Cheese Toastie', 'Gammon Steak', 'Christmas Ham'],
  },

  // ============================================================================
  // FISH & SEAFOOD
  // ============================================================================
  {
    id: 'fish_fillets',
    name: 'Fish Fillets (Fresh)',
    description: 'Fresh fish fillets - salmon, cod, haddock, sea bass',
    keywords: ['salmon fillet', 'cod fillet', 'haddock fillet', 'sea bass', 'trout fillet', 'mackerel fillet', 'tuna steak'],
    excludeKeywords: ['fish fingers', 'fish cake', 'fish pie', 'battered fish'],
    defaultServingG: 130,
    toleranceMin: 80,
    toleranceMax: 250,
    examples: ['Salmon Fillet', 'Cod Loin', 'Sea Bass Fillets', 'Smoked Haddock'],
    notExamples: ['Birds Eye Fish Fingers', 'Fish Cakes', 'Chip Shop Fish'],
  },
  {
    id: 'tinned_fish',
    name: 'Tinned Fish',
    description: 'Canned tuna, salmon, sardines, mackerel',
    keywords: ['tinned', 'canned', 'tuna chunks', 'tuna flakes', 'sardines', 'mackerel fillets', 'salmon pink', 'salmon red'],
    excludeKeywords: [],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['John West Tuna Chunks', 'Princes Salmon', 'Sardines in Tomato Sauce', 'Mackerel in Sunflower Oil'],
    notExamples: ['Fresh Tuna Steak', 'Salmon Fillet'],
  },
  {
    id: 'prawns_seafood',
    name: 'Prawns & Seafood',
    description: 'Prawns, shrimp, mussels, squid',
    keywords: ['prawn', 'shrimp', 'king prawn', 'tiger prawn', 'mussel', 'squid', 'calamari', 'scallop', 'crab', 'lobster'],
    excludeKeywords: ['prawn cocktail', 'prawn cracker', 'seafood stick'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['King Prawns', 'Cooked Prawns', 'Mussels in Garlic', 'Squid Rings'],
    notExamples: ['Prawn Cocktail Crisps', 'Prawn Crackers', 'Seafood Sticks'],
  },

  // ============================================================================
  // READY MEALS & PREPARED FOODS
  // UK single portion ready meals are typically 350-450g
  // ============================================================================
  {
    id: 'lasagne',
    name: 'Lasagne',
    description: 'Beef lasagne, vegetable lasagne ready meals',
    keywords: ['lasagne', 'lasagna'],
    excludeKeywords: ['lasagne sheets', 'lasagne pasta'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Beef Lasagne', 'Vegetable Lasagne', 'Tesco Finest Lasagne', 'M&S Lasagne'],
    notExamples: ['Lasagne Sheets', 'Dried Lasagne Pasta'],
  },
  {
    id: 'chicken_ready_meal',
    name: 'Chicken Ready Meal',
    description: 'Chicken-based ready meals - satay, kiev, hunter\'s chicken, etc.',
    keywords: ['satay chicken', 'hunter\'s chicken', 'hunters chicken', 'chicken kiev', 'chicken dinner', 'chicken and rice', 'chicken with rice', 'roast chicken meal', 'chicken casserole ready meal', 'lemon chicken', 'teriyaki chicken', 'honey chicken', 'garlic chicken'],
    excludeKeywords: ['raw chicken', 'chicken breast', 'chicken thigh', 'chicken drumstick'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Tesco Finest Satay Chicken With Jasmine Rice', 'Chicken Kiev', 'Hunter\'s Chicken', 'Lemon & Herb Chicken'],
    notExamples: ['Raw Chicken Breast', 'Chicken Thighs', 'Fresh Chicken'],
  },
  {
    id: 'curry_ready_meal',
    name: 'Curry (Ready Meal)',
    description: 'Indian curry ready meals - tikka masala, korma, jalfrezi',
    keywords: ['curry', 'tikka masala', 'korma', 'madras', 'vindaloo', 'jalfrezi', 'balti', 'bhuna', 'rogan josh', 'butter chicken', 'biryani'],
    excludeKeywords: ['curry paste', 'curry sauce', 'curry powder', 'curry pot noodle', 'curry leaves'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Chicken Tikka Masala', 'Lamb Rogan Josh', 'Vegetable Korma', 'M&S Chicken Jalfrezi', 'Chicken Biryani'],
    notExamples: ['Patak\'s Curry Paste', 'Curry Powder', 'Pot Noodle Chicken Korma'],
  },
  {
    id: 'chinese_ready_meal',
    name: 'Chinese Ready Meal',
    description: 'Chinese takeaway style ready meals - chow mein, sweet & sour, etc.',
    keywords: ['chow mein', 'sweet and sour', 'sweet & sour', 'kung pao', 'crispy chilli', 'szechuan', 'cantonese', 'black bean', 'oyster sauce', 'egg fried rice', 'special fried rice', 'chinese chicken', 'chinese pork', 'chinese beef', 'char siu', 'hoisin'],
    excludeKeywords: ['sauce', 'paste', 'powder', 'noodles dry', 'stir fry sauce'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Chicken Chow Mein', 'Sweet & Sour Chicken', 'Beef in Black Bean Sauce', 'Special Fried Rice', 'Crispy Chilli Beef'],
    notExamples: ['Chow Mein Noodles Dry', 'Sweet & Sour Sauce', 'Hoisin Sauce'],
  },
  {
    id: 'cottage_shepherds_pie',
    name: 'Cottage Pie / Shepherd\'s Pie',
    description: 'Minced meat with mashed potato topping ready meals',
    keywords: ['cottage pie', 'shepherd pie', 'shepherds pie', "shepherd's pie", 'beef pie mash', 'lamb pie mash'],
    excludeKeywords: [],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Cottage Pie', 'Shepherd\'s Pie', 'M&S Cottage Pie', 'Tesco Shepherd\'s Pie'],
    notExamples: [],
  },
  {
    id: 'fish_pie',
    name: 'Fish Pie',
    description: 'Fish pie with mashed potato topping ready meals',
    keywords: ['fish pie', 'fisherman pie', 'fishermans pie', "fisherman's pie", 'ocean pie', 'seafood pie'],
    excludeKeywords: [],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Fish Pie', 'Fisherman\'s Pie', 'M&S Fish Pie', 'Charlie Bigham\'s Fish Pie'],
    notExamples: [],
  },
  {
    id: 'pasta_bake_ready_meal',
    name: 'Pasta Bake / Mac & Cheese',
    description: 'Pasta bake, macaroni cheese ready meals',
    keywords: ['pasta bake', 'macaroni cheese', 'mac and cheese', 'mac & cheese', 'mac n cheese', 'tuna pasta bake', 'chicken pasta bake', 'carbonara ready meal'],
    excludeKeywords: ['pasta bake sauce', 'pasta bake mix'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Macaroni Cheese', 'Tuna Pasta Bake', 'Chicken Pasta Bake', 'M&S Mac & Cheese'],
    notExamples: ['Pasta Bake Sauce', 'Dolmio Pasta Bake'],
  },
  {
    id: 'spaghetti_bolognese_ready_meal',
    name: 'Spaghetti Bolognese (Ready Meal)',
    description: 'Spaghetti bolognese, meat sauce pasta ready meals',
    keywords: ['spaghetti bolognese', 'spag bol', 'bolognaise', 'meat sauce pasta', 'beef ragu'],
    excludeKeywords: ['bolognese sauce', 'ragu sauce', 'jar'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Spaghetti Bolognese', 'Spag Bol Ready Meal', 'Beef Ragu with Pasta'],
    notExamples: ['Dolmio Bolognese Sauce', 'Ragu Sauce Jar'],
  },
  {
    id: 'chilli_con_carne_ready_meal',
    name: 'Chilli Con Carne (Ready Meal)',
    description: 'Chilli con carne ready meals with rice',
    keywords: ['chilli con carne', 'chili con carne', 'beef chilli', 'beef chili', 'chilli with rice'],
    excludeKeywords: ['chilli sauce', 'chilli powder', 'chilli flakes'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Chilli Con Carne', 'Beef Chilli with Rice', 'M&S Chilli Con Carne'],
    notExamples: ['Chilli Sauce', 'Chilli Powder', 'Chilli Con Carne Spice Mix'],
  },
  {
    id: 'roast_dinner_ready_meal',
    name: 'Roast Dinner (Ready Meal)',
    description: 'Sunday roast style ready meals with meat and veg',
    keywords: ['roast dinner', 'sunday roast', 'roast beef dinner', 'roast chicken dinner', 'roast pork dinner', 'carvery', 'roast lamb'],
    excludeKeywords: ['roast potatoes only', 'roast chicken breast raw'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 500 },
    ],
    toleranceMin: 300,
    toleranceMax: 550,
    examples: ['Roast Beef Dinner', 'Roast Chicken Dinner', 'Sunday Roast Ready Meal', 'Carvery Meal'],
    notExamples: ['Roast Potatoes', 'Raw Roast Chicken'],
  },
  {
    id: 'stew_casserole_ready_meal',
    name: 'Stew / Casserole (Ready Meal)',
    description: 'Beef stew, chicken casserole, hotpot ready meals',
    keywords: ['stew', 'casserole', 'hotpot', 'hot pot', 'lancashire hotpot', 'beef stew', 'lamb stew', 'chicken casserole', 'irish stew'],
    excludeKeywords: ['casserole mix', 'stewing steak raw', 'casserole dish'],
    defaultServingG: 400,
    servingSizes: [
      { name: 'Small portion', grams: 300 },
      { name: 'Standard portion', grams: 400 },
      { name: 'Large portion', grams: 450 },
    ],
    toleranceMin: 280,
    toleranceMax: 500,
    examples: ['Beef Stew', 'Lancashire Hotpot', 'Chicken Casserole', 'Irish Stew'],
    notExamples: ['Stewing Steak Raw', 'Casserole Mix Packet'],
  },
  {
    id: 'pizza',
    name: 'Pizza',
    description: 'Fresh, frozen, and takeaway pizzas',
    keywords: ['pizza', 'margherita', 'pepperoni pizza', 'pizza express', 'goodfellas', 'chicago town', 'dr oetker'],
    excludeKeywords: ['pizza base', 'pizza dough', 'pizza sauce', 'pizza flavour'],
    defaultServingG: 200,
    servingSizes: [
      { name: '1/4 pizza', grams: 150 },
      { name: '1/3 pizza', grams: 200 },
      { name: '1/2 pizza', grams: 300 },
    ],
    toleranceMin: 80,
    toleranceMax: 500,
    examples: ['Pepperoni Pizza', 'Margherita', 'Chicago Town Deep Dish', 'Goodfellas Thin'],
    notExamples: ['Pizza Base', 'Pizza Express Dough Balls', 'Pizza Flavour Pringles'],
  },
  {
    id: 'pie_savoury',
    name: 'Savoury Pies & Pasties',
    description: 'Meat pies, pasties, quiches',
    keywords: ['pie', 'pasty', 'pastie', 'quiche', 'pukka pie', 'fray bentos', 'steak pie', 'chicken pie', 'pork pie', 'cornish pasty'],
    excludeKeywords: ['pie filling', 'apple pie', 'cherry pie', 'banoffee pie', 'pie crust'],
    defaultServingG: 200,
    toleranceMin: 100,
    toleranceMax: 400,
    examples: ['Pukka Steak Pie', 'Cornish Pasty', 'Pork Pie', 'Quiche Lorraine', 'Chicken & Mushroom Pie'],
    notExamples: ['Apple Pie', 'Mr Kipling Pies', 'Mince Pie'],
  },
  {
    id: 'sandwich_prepared',
    name: 'Prepared Sandwiches',
    description: 'Pre-made sandwiches, meal deal sandwiches',
    keywords: ['sandwich', 'sarnie', 'blt', 'club sandwich', 'triple sandwich', 'sub'],
    excludeKeywords: ['sandwich thins', 'sandwich spread', 'sandwich pickle'],
    defaultServingG: 180,
    toleranceMin: 100,
    toleranceMax: 350,
    examples: ['BLT Sandwich', 'Chicken & Bacon Triple', 'Prawn Mayo Sandwich', 'Tesco Meal Deal Sandwich'],
    notExamples: ['Warburtons Sandwich Thins', 'Sandwich Spread', 'Branston Pickle'],
  },
  {
    id: 'soup',
    name: 'Soup',
    description: 'Tinned, fresh, and packet soups',
    keywords: ['soup', 'broth', 'chowder', 'heinz soup', 'baxters', 'covent garden'],
    excludeKeywords: ['soup mix', 'soup maker'],
    defaultServingG: 300,
    servingSizes: [
      { name: 'Cup/mug', grams: 200 },
      { name: 'Bowl', grams: 300 },
      { name: 'Large bowl', grams: 400 },
    ],
    toleranceMin: 150,
    toleranceMax: 500,
    examples: ['Heinz Tomato Soup', 'Baxters Chicken Broth', 'New Covent Garden Soup'],
    notExamples: ['Soup and Shake', 'Dried Soup Mix'],
  },

  // ============================================================================
  // PASTA & RICE
  // ============================================================================
  {
    id: 'pasta_dried',
    name: 'Pasta (Dried)',
    description: 'Dried pasta - spaghetti, penne, fusilli, etc.',
    keywords: ['pasta', 'spaghetti', 'penne', 'fusilli', 'tagliatelle', 'rigatoni', 'farfalle', 'linguine', 'macaroni', 'orzo'],
    excludeKeywords: ['pasta sauce', 'pasta bake', 'pot pasta', 'pasta salad', 'ready meal'],
    defaultServingG: 75,
    servingSizes: [
      { name: 'Small portion', grams: 60 },
      { name: 'Medium portion', grams: 75 },
      { name: 'Large portion', grams: 100 },
    ],
    toleranceMin: 40,
    toleranceMax: 150,
    examples: ['Napolina Spaghetti', 'De Cecco Penne', 'Barilla Fusilli', 'Own Brand Pasta'],
    notExamples: ['Dolmio Pasta Sauce', 'Pot Pasta', 'Pasta King'],
  },
  {
    id: 'rice_dried',
    name: 'Rice (Dried)',
    description: 'Dried rice - basmati, long grain, jasmine, risotto',
    keywords: ['rice', 'basmati', 'long grain', 'jasmine rice', 'risotto rice', 'arborio', 'wild rice', 'brown rice'],
    excludeKeywords: ['rice pudding', 'rice cake', 'rice cracker', 'microwave rice', 'rice krispies', 'fried rice'],
    defaultServingG: 75,
    servingSizes: [
      { name: 'Small portion', grams: 60 },
      { name: 'Medium portion', grams: 75 },
      { name: 'Large portion', grams: 100 },
    ],
    toleranceMin: 40,
    toleranceMax: 150,
    examples: ['Tilda Basmati Rice', 'Uncle Bens Long Grain', 'Arborio Risotto Rice'],
    notExamples: ['Rice Pudding', 'Rice Cakes', 'Egg Fried Rice', 'Ben\'s Original Microwave Rice'],
  },
  {
    id: 'rice_microwave',
    name: 'Microwave Rice (Cooked)',
    description: 'Pre-cooked microwave rice pouches',
    keywords: ['microwave rice', 'uncle bens', 'bens original', 'tilda steamed', 'express rice'],
    excludeKeywords: [],
    defaultServingG: 125,
    toleranceMin: 100,
    toleranceMax: 300,
    examples: ['Ben\'s Original Microwave Rice', 'Tilda Steamed Rice', 'Sainsburys Microwave Rice'],
    notExamples: ['Dried Rice', 'Risotto'],
  },
  {
    id: 'noodles',
    name: 'Noodles',
    description: 'Dried and fresh noodles - egg noodles, rice noodles, udon',
    keywords: ['noodle', 'egg noodle', 'rice noodle', 'udon', 'ramen', 'chow mein', 'vermicelli'],
    excludeKeywords: ['pot noodle', 'noodle pot', 'super noodles', 'instant noodles'],
    defaultServingG: 65,
    toleranceMin: 40,
    toleranceMax: 150,
    examples: ['Blue Dragon Egg Noodles', 'Rice Noodles', 'Fresh Udon', 'Straight to Wok Noodles'],
    notExamples: ['Pot Noodle', 'Super Noodles', 'Naked Noodle'],
  },
  {
    id: 'instant_noodles',
    name: 'Instant Noodles & Pot Noodles',
    description: 'Pot noodles, super noodles, instant ramen',
    keywords: ['pot noodle', 'super noodles', 'instant noodle', 'cup noodle', 'naked noodle', 'nissin', 'kabuto'],
    excludeKeywords: [],
    defaultServingG: 90,
    toleranceMin: 60,
    toleranceMax: 150,
    examples: ['Pot Noodle Chicken & Mushroom', 'Batchelors Super Noodles', 'Kabuto Ramen'],
    notExamples: ['Fresh Noodles', 'Dried Egg Noodles'],
  },

  // ============================================================================
  // FRUITS
  // ============================================================================
  {
    id: 'apple',
    name: 'Apple',
    description: 'Fresh apples - all varieties',
    keywords: ['apple', 'granny smith', 'gala', 'braeburn', 'pink lady', 'jazz apple', 'cox'],
    excludeKeywords: ['apple juice', 'apple pie', 'apple sauce', 'apple crumble', 'toffee apple', 'apple cider'],
    defaultServingG: 150,
    servingSizes: [
      { name: 'Small apple', grams: 120 },
      { name: 'Medium apple', grams: 150 },
      { name: 'Large apple', grams: 200 },
    ],
    toleranceMin: 80,
    toleranceMax: 250,
    examples: ['Pink Lady Apple', 'Gala Apple', 'Granny Smith', 'Braeburn'],
    notExamples: ['Apple Juice', 'Apple Pie', 'Dried Apple'],
  },
  {
    id: 'banana',
    name: 'Banana',
    description: 'Fresh bananas',
    keywords: ['banana', 'fairtrade banana'],
    excludeKeywords: ['banana bread', 'banana chip', 'dried banana', 'banana milkshake', 'banana split'],
    defaultServingG: 120,
    servingSizes: [
      { name: 'Small banana', grams: 90 },
      { name: 'Medium banana', grams: 120 },
      { name: 'Large banana', grams: 150 },
    ],
    toleranceMin: 60,
    toleranceMax: 200,
    examples: ['Loose Bananas', 'Fairtrade Bananas', 'Organic Bananas'],
    notExamples: ['Banana Bread', 'Banana Chips', 'Banana Milkshake'],
  },
  {
    id: 'berries',
    name: 'Berries',
    description: 'Strawberries, blueberries, raspberries, blackberries',
    keywords: ['strawberry', 'strawberries', 'blueberry', 'blueberries', 'raspberry', 'raspberries', 'blackberry', 'blackberries', 'mixed berries'],
    excludeKeywords: ['jam', 'compote', 'yoghurt', 'smoothie', 'ice cream'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Fresh Strawberries', 'Blueberries', 'Raspberries', 'Mixed Berry Pack'],
    notExamples: ['Strawberry Jam', 'Strawberry Yoghurt', 'Berry Smoothie'],
  },
  {
    id: 'citrus',
    name: 'Citrus Fruits',
    description: 'Oranges, lemons, limes, grapefruit, satsumas',
    keywords: ['orange', 'lemon', 'lime', 'grapefruit', 'satsuma', 'clementine', 'tangerine', 'mandarin'],
    excludeKeywords: ['juice', 'marmalade', 'squash', 'lemon curd', 'orange chocolate'],
    defaultServingG: 130,
    servingSizes: [
      { name: 'Small/satsuma', grams: 70 },
      { name: 'Medium orange', grams: 130 },
      { name: 'Large orange', grams: 180 },
    ],
    toleranceMin: 50,
    toleranceMax: 250,
    examples: ['Navel Oranges', 'Easy Peeler Satsumas', 'Lemons', 'Pink Grapefruit'],
    notExamples: ['Orange Juice', 'Lemon Curd', 'Terry\'s Chocolate Orange'],
  },
  {
    id: 'grapes',
    name: 'Grapes',
    description: 'Fresh grapes - red, green, black',
    keywords: ['grape', 'grapes', 'seedless grapes', 'red grapes', 'green grapes', 'black grapes'],
    excludeKeywords: ['grape juice', 'raisins', 'sultanas', 'wine'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Green Seedless Grapes', 'Red Grapes', 'Black Grapes', 'Cotton Candy Grapes'],
    notExamples: ['Raisins', 'Sultanas', 'Grape Juice'],
  },
  {
    id: 'melon',
    name: 'Melon',
    description: 'Watermelon, cantaloupe, honeydew, galia',
    keywords: ['melon', 'watermelon', 'cantaloupe', 'honeydew', 'galia'],
    excludeKeywords: [],
    defaultServingG: 150,
    toleranceMin: 80,
    toleranceMax: 300,
    examples: ['Watermelon Slices', 'Cantaloupe Melon', 'Honeydew Melon', 'Galia Melon'],
    notExamples: [],
  },
  {
    id: 'tropical_fruit',
    name: 'Tropical Fruits',
    description: 'Mango, pineapple, papaya, kiwi, passion fruit',
    keywords: ['mango', 'pineapple', 'papaya', 'kiwi', 'passion fruit', 'coconut', 'lychee', 'dragon fruit'],
    excludeKeywords: ['juice', 'dried', 'smoothie'],
    defaultServingG: 80,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Fresh Mango', 'Pineapple Chunks', 'Kiwi Fruit', 'Papaya'],
    notExamples: ['Pineapple Juice', 'Dried Mango', 'Coconut Milk'],
  },
  {
    id: 'dried_fruit',
    name: 'Dried Fruit',
    description: 'Raisins, sultanas, dates, apricots, cranberries',
    keywords: ['dried', 'raisins', 'sultanas', 'currants', 'dates', 'dried apricot', 'dried mango', 'prunes', 'cranberries', 'dried fig'],
    excludeKeywords: ['trail mix', 'fruit and nut'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 80,
    examples: ['Sun-Maid Raisins', 'Medjool Dates', 'Dried Apricots', 'Dried Cranberries'],
    notExamples: ['Fresh Dates', 'Fresh Apricots', 'Trail Mix'],
  },

  // ============================================================================
  // VEGETABLES
  // ============================================================================
  {
    id: 'potato',
    name: 'Potatoes',
    description: 'Fresh potatoes - baking, mashing, roasting',
    keywords: ['potato', 'potatoes', 'maris piper', 'king edward', 'jersey royal', 'new potato', 'baby potato', 'baking potato'],
    excludeKeywords: ['chips', 'crisps', 'mash', 'wedges', 'roast potato', 'hash brown', 'potato waffle'],
    defaultServingG: 175,
    servingSizes: [
      { name: 'Small potato', grams: 100 },
      { name: 'Medium potato', grams: 175 },
      { name: 'Large baking potato', grams: 300 },
    ],
    toleranceMin: 60,
    toleranceMax: 400,
    examples: ['Maris Piper Potatoes', 'Baking Potatoes', 'Jersey Royals', 'Baby New Potatoes'],
    notExamples: ['Oven Chips', 'Crisps', 'Mashed Potato', 'Potato Waffles'],
  },
  {
    id: 'chips_frozen',
    name: 'Chips & Wedges (Frozen/Prepared)',
    description: 'Oven chips, frozen chips, potato wedges',
    keywords: ['chips', 'oven chips', 'frozen chips', 'chunky chips', 'wedges', 'potato wedges', 'fries', 'mccain', 'aunt bessies'],
    excludeKeywords: ['fish and chips', 'chip shop', 'crisps', 'tortilla chips'],
    defaultServingG: 165,
    toleranceMin: 100,
    toleranceMax: 300,
    examples: ['McCain Oven Chips', 'Aunt Bessie\'s Homestyle Chips', 'Sweet Potato Wedges'],
    notExamples: ['Walkers Crisps', 'Doritos', 'Fish and Chips'],
  },
  {
    id: 'carrot',
    name: 'Carrots',
    description: 'Fresh carrots - whole, baby, batons',
    keywords: ['carrot', 'carrots', 'baby carrot', 'carrot batons', 'chantenay'],
    excludeKeywords: ['carrot cake', 'carrot juice', 'carrot soup'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Loose Carrots', 'Baby Carrots', 'Chantenay Carrots', 'Carrot Batons'],
    notExamples: ['Carrot Cake', 'Carrot and Coriander Soup'],
  },
  {
    id: 'broccoli',
    name: 'Broccoli',
    description: 'Fresh and frozen broccoli',
    keywords: ['broccoli', 'tenderstem', 'broccoli florets'],
    excludeKeywords: ['broccoli soup', 'broccoli cheese'],
    defaultServingG: 85,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Broccoli Florets', 'Tenderstem Broccoli', 'Frozen Broccoli'],
    notExamples: ['Broccoli and Stilton Soup', 'Broccoli Cheese Bake'],
  },
  {
    id: 'onion',
    name: 'Onions',
    description: 'Fresh onions - white, red, spring',
    keywords: ['onion', 'onions', 'red onion', 'white onion', 'spring onion', 'shallot', 'leek'],
    excludeKeywords: ['onion rings', 'onion bhaji', 'onion gravy', 'crispy onion'],
    defaultServingG: 80,
    toleranceMin: 30,
    toleranceMax: 200,
    examples: ['Brown Onions', 'Red Onions', 'Spring Onions', 'Shallots'],
    notExamples: ['Onion Rings', 'Onion Bhajis', 'Bisto Onion Gravy'],
  },
  {
    id: 'tomato',
    name: 'Tomatoes (Fresh)',
    description: 'Fresh tomatoes - cherry, plum, vine',
    keywords: ['tomato', 'tomatoes', 'cherry tomato', 'plum tomato', 'vine tomato', 'beef tomato'],
    excludeKeywords: ['tomato sauce', 'tomato soup', 'tinned tomato', 'chopped tomato', 'passata', 'ketchup', 'puree'],
    defaultServingG: 85,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Cherry Tomatoes', 'Vine Ripened Tomatoes', 'Plum Tomatoes', 'Beef Tomatoes'],
    notExamples: ['Chopped Tomatoes', 'Tomato Puree', 'Tomato Ketchup', 'Tomato Soup'],
  },
  {
    id: 'tinned_tomato',
    name: 'Tinned Tomatoes & Passata',
    description: 'Chopped, whole, and passata tomatoes',
    keywords: ['tinned tomato', 'canned tomato', 'chopped tomato', 'plum tomato tin', 'passata', 'tomato puree'],
    excludeKeywords: ['tomato soup', 'tomato sauce'],
    defaultServingG: 100,
    toleranceMin: 50,
    toleranceMax: 400,
    examples: ['Napolina Chopped Tomatoes', 'Whole Plum Tomatoes', 'Passata', 'Tomato Puree'],
    notExamples: ['Fresh Tomatoes', 'Tomato Soup', 'Dolmio Sauce'],
  },
  {
    id: 'salad_leaves',
    name: 'Salad Leaves & Lettuce',
    description: 'Lettuce, spinach, rocket, mixed leaves',
    keywords: ['lettuce', 'salad', 'rocket', 'spinach', 'watercress', 'mixed leaves', 'iceberg', 'romaine', 'cos', 'little gem'],
    excludeKeywords: ['salad dressing', 'caesar salad', 'pasta salad', 'potato salad', 'coleslaw'],
    defaultServingG: 35,
    toleranceMin: 15,
    toleranceMax: 100,
    examples: ['Iceberg Lettuce', 'Baby Spinach', 'Rocket Salad', 'Mixed Salad Leaves'],
    notExamples: ['Caesar Salad with Dressing', 'Pasta Salad', 'Coleslaw'],
  },
  {
    id: 'beans_green',
    name: 'Green Beans & Peas',
    description: 'Green beans, runner beans, peas, mange tout',
    keywords: ['green bean', 'runner bean', 'pea', 'garden pea', 'petit pois', 'mange tout', 'sugar snap', 'edamame'],
    excludeKeywords: ['baked beans', 'bean salad', 'bean chilli'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Fine Beans', 'Garden Peas', 'Mange Tout', 'Sugar Snap Peas', 'Frozen Peas'],
    notExamples: ['Heinz Baked Beans', 'Three Bean Salad'],
  },
  {
    id: 'baked_beans',
    name: 'Baked Beans',
    description: 'Tinned baked beans in tomato sauce',
    keywords: ['baked beans', 'heinz beans', 'branston beans'],
    excludeKeywords: [],
    defaultServingG: 200,
    toleranceMin: 100,
    toleranceMax: 420,
    examples: ['Heinz Baked Beans', 'Branston Baked Beans', 'Reduced Sugar Baked Beans'],
    notExamples: ['Green Beans', 'Kidney Beans', 'Bean Salad'],
  },
  {
    id: 'sweetcorn',
    name: 'Sweetcorn',
    description: 'Tinned, frozen, and fresh sweetcorn',
    keywords: ['sweetcorn', 'corn on the cob', 'corn kernels', 'baby corn'],
    excludeKeywords: ['cornflakes', 'corn chips', 'popcorn'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Green Giant Sweetcorn', 'Frozen Sweetcorn', 'Corn on the Cob', 'Baby Corn'],
    notExamples: ['Popcorn', 'Corn Flakes', 'Doritos'],
  },
  {
    id: 'mushroom',
    name: 'Mushrooms',
    description: 'Fresh and tinned mushrooms',
    keywords: ['mushroom', 'button mushroom', 'chestnut mushroom', 'portobello', 'shiitake', 'oyster mushroom'],
    excludeKeywords: ['mushroom soup', 'mushroom sauce', 'mushroom risotto'],
    defaultServingG: 65,
    toleranceMin: 30,
    toleranceMax: 200,
    examples: ['Button Mushrooms', 'Chestnut Mushrooms', 'Portobello Mushrooms', 'Sliced Mushrooms'],
    notExamples: ['Cream of Mushroom Soup', 'Mushroom Stroganoff'],
  },
  {
    id: 'pepper',
    name: 'Peppers',
    description: 'Bell peppers - red, green, yellow, orange',
    keywords: ['pepper', 'bell pepper', 'red pepper', 'green pepper', 'yellow pepper', 'mixed pepper', 'romano pepper'],
    excludeKeywords: ['pepper steak', 'black pepper', 'chilli pepper', 'pepper sauce'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Red Peppers', 'Mixed Peppers', 'Yellow Pepper', 'Romano Peppers'],
    notExamples: ['Black Pepper', 'Jalapeno Peppers', 'Pepper Steak'],
  },
  {
    id: 'cucumber',
    name: 'Cucumber',
    description: 'Fresh cucumber',
    keywords: ['cucumber', 'mini cucumber'],
    excludeKeywords: ['tzatziki', 'cucumber salad'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Whole Cucumber', 'Mini Cucumbers', 'Sliced Cucumber'],
    notExamples: ['Tzatziki Dip'],
  },
  {
    id: 'courgette',
    name: 'Courgette & Squash',
    description: 'Courgettes, butternut squash, aubergine',
    keywords: ['courgette', 'zucchini', 'butternut squash', 'squash', 'aubergine', 'eggplant'],
    excludeKeywords: ['courgette soup', 'squash soup'],
    defaultServingG: 90,
    toleranceMin: 50,
    toleranceMax: 250,
    examples: ['Courgettes', 'Butternut Squash', 'Aubergine', 'Diced Butternut'],
    notExamples: ['Butternut Squash Soup', 'Moussaka'],
  },
  {
    id: 'cabbage',
    name: 'Cabbage & Kale',
    description: 'White cabbage, red cabbage, savoy, kale',
    keywords: ['cabbage', 'white cabbage', 'red cabbage', 'savoy', 'kale', 'cavolo nero', 'spring greens'],
    excludeKeywords: ['coleslaw', 'sauerkraut'],
    defaultServingG: 90,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['White Cabbage', 'Red Cabbage', 'Savoy Cabbage', 'Curly Kale'],
    notExamples: ['Coleslaw', 'Sauerkraut'],
  },
  {
    id: 'cauliflower',
    name: 'Cauliflower',
    description: 'Fresh and frozen cauliflower',
    keywords: ['cauliflower', 'cauliflower florets', 'cauliflower rice'],
    excludeKeywords: ['cauliflower cheese', 'cauliflower soup'],
    defaultServingG: 85,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Cauliflower Florets', 'Whole Cauliflower', 'Cauliflower Rice', 'Frozen Cauliflower'],
    notExamples: ['Cauliflower Cheese', 'Cauliflower Soup'],
  },
  {
    id: 'avocado',
    name: 'Avocado',
    description: 'Fresh avocados',
    keywords: ['avocado', 'ripe avocado', 'hass avocado'],
    excludeKeywords: ['guacamole', 'avocado oil'],
    defaultServingG: 75,
    servingSizes: [
      { name: 'Half avocado', grams: 75 },
      { name: 'Whole avocado', grams: 150 },
    ],
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Ripe Avocado', 'Ripen at Home Avocado', 'Hass Avocado'],
    notExamples: ['Guacamole', 'Avocado Oil'],
  },

  // ============================================================================
  // SNACKS & CONFECTIONERY
  // ============================================================================
  {
    id: 'crisps',
    name: 'Crisps & Tortilla Chips',
    description: 'Potato crisps, tortilla chips, vegetable crisps (single bag ~25g)',
    keywords: ['crisps', 'walkers', 'pringles', 'kettle chips', 'sensations', 'tyrrells', 'doritos', 'tortilla chips', 'nachos'],
    excludeKeywords: ['oven chips', 'frozen chips', 'fish and chips'],
    defaultServingG: 25,
    toleranceMin: 15,
    toleranceMax: 50,
    examples: ['Walkers Ready Salted', 'Pringles Original', 'Doritos', 'Kettle Chips', 'Sensations'],
    notExamples: ['Oven Chips', 'McCain Chips'],
  },
  {
    id: 'popcorn',
    name: 'Popcorn',
    description: 'Ready-made and microwave popcorn',
    keywords: ['popcorn', 'butterkist', 'metcalfe', 'propercorn', 'skinny popcorn'],
    excludeKeywords: ['popcorn chicken'],
    defaultServingG: 25,
    toleranceMin: 15,
    toleranceMax: 80,
    examples: ['Butterkist Sweet Popcorn', 'Propercorn', 'Metcalfe\'s Skinny Popcorn'],
    notExamples: ['KFC Popcorn Chicken'],
  },
  {
    id: 'nuts_plain',
    name: 'Nuts (Plain & Roasted)',
    description: 'Almonds, cashews, peanuts, mixed nuts',
    keywords: ['nuts', 'almond', 'cashew', 'peanut', 'walnut', 'pistachio', 'brazil nut', 'macadamia', 'hazelnut', 'mixed nuts', 'dry roasted'],
    excludeKeywords: ['nut butter', 'chocolate nuts', 'honey roasted', 'praline'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 80,
    examples: ['KP Dry Roasted Peanuts', 'Whole Almonds', 'Cashew Nuts', 'Mixed Nuts'],
    notExamples: ['Peanut Butter', 'Snickers', 'Chocolate Brazils', 'Honey Roasted Peanuts'],
  },
  {
    id: 'chocolate_bar',
    name: 'Chocolate Bars',
    description: 'Chocolate bars, blocks, and countlines',
    keywords: ['chocolate', 'dairy milk', 'galaxy', 'cadbury', 'mars', 'snickers', 'twix', 'kitkat', 'bounty', 'maltesers', 'milky way', 'milkybar', 'aero', 'wispa', 'crunchie', 'flake', 'yorkie', 'toblerone', 'lindt'],
    excludeKeywords: ['chocolate milk', 'chocolate milkshake', 'hot chocolate', 'chocolate spread', 'chocolate cake', 'chocolate biscuit', 'chocolate ice cream', 'truffles', 'box'],
    defaultServingG: 40,
    toleranceMin: 20,
    toleranceMax: 60,
    examples: ['Cadbury Dairy Milk', 'Galaxy Smooth Milk', 'Mars Bar', 'Snickers', 'KitKat', 'Maltesers'],
    notExamples: ['Chocolate Milk', 'Hot Chocolate', 'Chocolate Spread', 'Chocolate Digestive', 'Lindt Lindor Truffles Box'],
  },
  {
    id: 'chocolate_sharing',
    name: 'Chocolate (Sharing Bags)',
    description: 'Sharing bags of small chocolates like M&Ms, Maltesers pouches',
    keywords: ['sharing bag', 'pouch', 'm&ms', 'maltesers bag', 'minstrels', 'revels', 'peanut m&m'],
    excludeKeywords: ['box', 'truffles', 'lindor', 'ferrero'],
    defaultServingG: 40,
    toleranceMin: 25,
    toleranceMax: 60,
    examples: ['M&M\'s Sharing Bag', 'Maltesers Pouch', 'Minstrels Bag', 'Revels'],
    notExamples: ['Lindt Lindor Box', 'Ferrero Rocher', 'Celebrations Tub'],
  },
  {
    id: 'chocolate_selection_box',
    name: 'Chocolate Selection Boxes',
    description: 'Selection tubs and boxes - Celebrations, Roses, Heroes, Quality Street',
    keywords: ['celebrations', 'heroes', 'roses', 'quality street', 'selection', 'tub', 'miniatures'],
    excludeKeywords: ['truffles', 'lindor', 'ferrero'],
    defaultServingG: 30,
    toleranceMin: 20,
    toleranceMax: 50,
    examples: ['Celebrations', 'Heroes', 'Quality Street', 'Cadbury Roses', 'Cadbury Miniatures'],
    notExamples: ['Lindt Lindor', 'Ferrero Rocher', 'Single Bar'],
  },
  {
    id: 'chocolate_truffles_box',
    name: 'Boxed Chocolates & Truffles',
    description: 'Premium boxed chocolates - Lindor, Ferrero Rocher, Belgian chocolates',
    keywords: ['truffles', 'lindor', 'ferrero', 'rocher', 'belgian', 'praline', 'boxed chocolate', 'gift box', 'assorted chocolate'],
    excludeKeywords: ['sharing bag', 'multipack'],
    defaultServingG: 25,
    toleranceMin: 12,
    toleranceMax: 40,
    examples: ['Lindt Lindor Truffles', 'Ferrero Rocher', 'Belgian Chocolate Selection', 'Hotel Chocolat'],
    notExamples: ['Celebrations', 'Heroes', 'Chocolate Bar', 'M&Ms'],
  },
  {
    id: 'sweets',
    name: 'Sweets & Candy',
    description: 'Boiled sweets, gummies, jellies, mints',
    keywords: ['sweet', 'candy', 'gummy', 'haribo', 'jelly baby', 'wine gums', 'fruit pastille', 'skittles', 'starburst', 'polo', 'mints', 'toffee', 'fudge', 'chews', 'bonbon'],
    excludeKeywords: ['sweet potato', 'sweetcorn', 'sweet chilli'],
    defaultServingG: 25,
    toleranceMin: 10,
    toleranceMax: 50,
    examples: ['Haribo Starmix', 'Bassetts Wine Gums', 'Rowntree\'s Fruit Pastilles', 'Skittles'],
    notExamples: ['Sweet Potato', 'Chocolate Bar'],
  },

  // ============================================================================
  // BISCUITS & CAKES
  // ============================================================================
  {
    id: 'biscuits',
    name: 'Biscuits',
    description: 'Sweet biscuits - digestives, bourbons, custard creams (2 biscuits typical)',
    keywords: ['biscuit', 'digestive', 'hobnob', 'bourbon', 'custard cream', 'rich tea', 'shortbread', 'oreo', 'maryland', 'cookie', 'jammie dodger', 'malted milk'],
    excludeKeywords: ['biscuit base', 'biscuit tin'],
    defaultServingG: 25,
    toleranceMin: 10,
    toleranceMax: 40,
    examples: ['McVitie\'s Digestives', 'Chocolate Hobnobs', 'Bourbon Creams', 'Oreos', 'Maryland Cookies'],
    notExamples: ['Cheesecake Biscuit Base'],
  },
  {
    id: 'cake',
    name: 'Cakes & Gateaux',
    description: 'Large cakes, sliced cakes, gateaux',
    keywords: ['cake', 'sponge', 'victoria sponge', 'chocolate cake', 'carrot cake', 'cheesecake', 'gateau', 'birthday cake', 'coffee cake', 'lemon drizzle'],
    excludeKeywords: ['cake mix', 'cake bar', 'jaffa cake', 'rice cake', 'fish cake', 'potato cake'],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Victoria Sponge', 'Chocolate Fudge Cake', 'Carrot Cake', 'New York Cheesecake'],
    notExamples: ['Jaffa Cakes', 'Rice Cakes', 'Cake Mix'],
  },
  {
    id: 'cake_bars',
    name: 'Cake Bars & Individual Cakes',
    description: 'Mr Kipling cakes, French Fancies, cake bars',
    keywords: ['cake bar', 'mr kipling', 'french fancy', 'fondant fancy', 'mini roll', 'swiss roll', 'jaffa cake', 'angel slice', 'bakewell', 'brownie'],
    excludeKeywords: [],
    defaultServingG: 35,
    toleranceMin: 20,
    toleranceMax: 100,
    examples: ['Mr Kipling French Fancies', 'Cadbury Mini Rolls', 'Jaffa Cakes', 'Bakewell Tart', 'Brownie'],
    notExamples: ['Whole Cake', 'Large Victoria Sponge'],
  },
  {
    id: 'muffins_sweet',
    name: 'Muffins (Sweet)',
    description: 'Chocolate chip, blueberry, and other sweet muffins',
    keywords: ['muffin chocolate', 'blueberry muffin', 'double chocolate muffin', 'banana muffin', 'lemon muffin'],
    excludeKeywords: ['english muffin'],
    defaultServingG: 100,
    toleranceMin: 60,
    toleranceMax: 180,
    examples: ['Chocolate Chip Muffin', 'Blueberry Muffin', 'Starbucks Muffin', 'Costa Muffin'],
    notExamples: ['English Muffin', 'Warburtons Muffins'],
  },
  {
    id: 'doughnuts',
    name: 'Doughnuts',
    description: 'Ring doughnuts, jam doughnuts, filled doughnuts',
    keywords: ['doughnut', 'donut', 'jam doughnut', 'ring doughnut', 'krispy kreme', 'dunkin'],
    excludeKeywords: [],
    defaultServingG: 70,
    toleranceMin: 40,
    toleranceMax: 150,
    examples: ['Krispy Kreme Original', 'Jam Doughnut', 'Ring Doughnut', 'Yum Yums'],
    notExamples: [],
  },

  // ============================================================================
  // BEVERAGES
  // ============================================================================
  {
    id: 'soft_drinks',
    name: 'Soft Drinks',
    description: 'Fizzy drinks, cola, lemonade, squash',
    keywords: ['cola', 'coke', 'pepsi', 'fanta', 'sprite', '7up', 'lemonade', 'orangeade', 'fizzy', 'soda', 'dr pepper', 'irn bru', 'lucozade', 'energy drink', 'red bull', 'monster'],
    excludeKeywords: ['diet', 'zero', 'no sugar', 'sugar free'],
    defaultServingG: 330,
    servingSizes: [
      { name: 'Small can', grams: 250 },
      { name: 'Standard can', grams: 330 },
      { name: 'Large bottle', grams: 500 },
    ],
    toleranceMin: 150,
    toleranceMax: 750,
    examples: ['Coca-Cola', 'Pepsi', 'Fanta Orange', 'Sprite', 'Lucozade Original', 'Red Bull'],
    notExamples: ['Diet Coke', 'Coke Zero', 'Pepsi Max'],
  },
  {
    id: 'soft_drinks_diet',
    name: 'Diet & Zero Soft Drinks',
    description: 'Sugar-free fizzy drinks',
    keywords: ['diet coke', 'coke zero', 'pepsi max', 'diet pepsi', 'fanta zero', 'sprite zero', 'sugar free', 'no sugar', 'zero sugar'],
    excludeKeywords: [],
    defaultServingG: 330,
    toleranceMin: 150,
    toleranceMax: 750,
    examples: ['Diet Coke', 'Coke Zero', 'Pepsi Max', 'Fanta Zero', '7Up Free'],
    notExamples: ['Regular Coca-Cola', 'Full Sugar Fanta'],
  },
  {
    id: 'fruit_juice',
    name: 'Fruit Juice',
    description: 'Orange juice, apple juice, fruit juices',
    keywords: ['juice', 'orange juice', 'apple juice', 'tropicana', 'innocent', 'pure juice', 'freshly squeezed', 'cranberry juice', 'grape juice'],
    excludeKeywords: ['squash', 'cordial', 'concentrate', 'juice drink'],
    defaultServingG: 200,
    toleranceMin: 100,
    toleranceMax: 500,
    examples: ['Tropicana Orange Juice', 'Innocent Apple Juice', 'Fresh Orange Juice', 'Cranberry Juice'],
    notExamples: ['Robinsons Squash', 'Capri Sun', 'Um Bongo'],
  },
  {
    id: 'smoothie',
    name: 'Smoothies',
    description: 'Fruit smoothies, protein smoothies',
    keywords: ['smoothie', 'innocent smoothie', 'naked juice', 'protein smoothie'],
    excludeKeywords: [],
    defaultServingG: 250,
    toleranceMin: 150,
    toleranceMax: 500,
    examples: ['Innocent Strawberry & Banana', 'Naked Green Machine', 'M&S Super Smoothie'],
    notExamples: ['Fruit Juice', 'Milkshake'],
  },
  {
    id: 'milkshake',
    name: 'Milkshakes',
    description: 'Flavoured milkshakes - chocolate, strawberry, banana',
    keywords: ['milkshake', 'frijj', 'yazoo', 'chocolate milk', 'strawberry milk', 'banana milkshake'],
    excludeKeywords: ['milkshake powder', 'milkshake mix'],
    defaultServingG: 400,
    toleranceMin: 200,
    toleranceMax: 600,
    examples: ['Frijj Chocolate Milkshake', 'Yazoo Strawberry', 'McDonald\'s Milkshake'],
    notExamples: ['Semi-Skimmed Milk', 'Milkshake Powder'],
  },
  {
    id: 'hot_drinks',
    name: 'Hot Drinks (Prepared)',
    description: 'Coffee shop drinks - lattes, cappuccinos, hot chocolates (ready to drink)',
    keywords: ['latte', 'cappuccino', 'americano', 'mocha', 'flat white', 'macchiato', 'starbucks', 'costa', 'nero'],
    excludeKeywords: ['coffee beans', 'instant coffee', 'ground coffee', 'powder', 'flakes', 'drinking chocolate', 'cocoa', 'mix', 'sachet'],
    defaultServingG: 350,
    toleranceMin: 200,
    toleranceMax: 500,
    examples: ['Starbucks Latte', 'Costa Cappuccino', 'Caffe Nero Mocha', 'Costa Hot Chocolate RTD'],
    notExamples: ['Nescafe Instant', 'Ground Coffee', 'Coffee Beans', 'Hot Chocolate Powder', 'Cadbury Drinking Chocolate', 'Galaxy Hot Chocolate Flakes'],
  },
  {
    id: 'tea_coffee_instant',
    name: 'Tea & Coffee (Instant/Dry)',
    description: 'Tea bags, instant coffee, ground coffee',
    keywords: ['tea bag', 'instant coffee', 'nescafe', 'kenco', 'pg tips', 'yorkshire tea', 'tetley', 'twinings', 'ground coffee'],
    excludeKeywords: [],
    defaultServingG: 2,
    toleranceMin: 1,
    toleranceMax: 10,
    examples: ['PG Tips Tea Bags', 'Yorkshire Tea', 'Nescafe Gold', 'Kenco Millicano'],
    notExamples: ['Costa Latte', 'Starbucks Iced Coffee'],
  },
  {
    id: 'hot_chocolate_powder',
    name: 'Hot Chocolate Powder/Mix',
    description: 'Hot chocolate powder, drinking chocolate, cocoa powder mixes',
    keywords: ['hot chocolate', 'drinking chocolate', 'cocoa', 'chocolate flakes', 'chocolate powder', 'options', 'cadbury hot chocolate', 'galaxy hot chocolate', 'ovaltine'],
    excludeKeywords: ['ready to drink', 'prepared', 'rtd', 'carton'],
    defaultServingG: 25,
    toleranceMin: 15,
    toleranceMax: 40,
    examples: ['Cadbury Drinking Chocolate', 'Galaxy Hot Chocolate', 'Options Hot Chocolate', 'Ovaltine', 'Green & Blacks Cocoa'],
    notExamples: ['Costa Hot Chocolate', 'Starbucks Hot Chocolate', 'Ready Made Hot Chocolate'],
  },
  {
    id: 'squash_cordial',
    name: 'Squash & Cordial',
    description: 'Concentrated squash and cordials (undiluted)',
    keywords: ['squash', 'cordial', 'robinsons', 'ribena', 'vimto', 'dilute', 'concentrate'],
    excludeKeywords: ['no added sugar', 'sugar free'],
    defaultServingG: 50,
    toleranceMin: 25,
    toleranceMax: 100,
    examples: ['Robinsons Orange Squash', 'Ribena', 'Vimto Cordial', 'Elderflower Cordial'],
    notExamples: ['Ready to Drink', 'Carton Drink'],
  },
  {
    id: 'alcohol_beer',
    name: 'Beer & Lager',
    description: 'Beer, lager, ale, cider',
    keywords: ['beer', 'lager', 'ale', 'cider', 'stout', 'ipa', 'pilsner', 'guinness', 'stella', 'heineken', 'carling', 'fosters', 'budweiser', 'corona', 'peroni', 'craft beer'],
    excludeKeywords: ['non alcoholic', 'alcohol free', '0%'],
    defaultServingG: 500,
    servingSizes: [
      { name: 'Half pint', grams: 284 },
      { name: 'Can/bottle', grams: 440 },
      { name: 'Pint', grams: 568 },
    ],
    toleranceMin: 250,
    toleranceMax: 700,
    examples: ['Stella Artois', 'Heineken', 'Guinness', 'Magners Cider', 'BrewDog Punk IPA'],
    notExamples: ['Heineken 0.0', 'Alcohol-Free Peroni'],
  },
  {
    id: 'alcohol_wine',
    name: 'Wine',
    description: 'Red, white, rosé, sparkling wine',
    keywords: ['wine', 'red wine', 'white wine', 'rose', 'prosecco', 'champagne', 'sauvignon', 'chardonnay', 'merlot', 'pinot', 'rioja', 'malbec'],
    excludeKeywords: ['wine gums', 'cooking wine', 'non alcoholic'],
    defaultServingG: 175,
    servingSizes: [
      { name: 'Small glass', grams: 125 },
      { name: 'Medium glass', grams: 175 },
      { name: 'Large glass', grams: 250 },
    ],
    toleranceMin: 100,
    toleranceMax: 300,
    examples: ['Sauvignon Blanc', 'Merlot', 'Prosecco', 'Pinot Grigio', 'House Red'],
    notExamples: ['Wine Gums', 'Cooking Wine'],
  },
  {
    id: 'alcohol_spirits',
    name: 'Spirits',
    description: 'Vodka, gin, rum, whisky, tequila',
    keywords: ['vodka', 'gin', 'rum', 'whisky', 'whiskey', 'tequila', 'brandy', 'bourbon', 'cognac', 'liqueur', 'baileys', 'amaretto', 'sambuca'],
    excludeKeywords: [],
    defaultServingG: 25,
    servingSizes: [
      { name: 'Single measure', grams: 25 },
      { name: 'Double measure', grams: 50 },
    ],
    toleranceMin: 20,
    toleranceMax: 100,
    examples: ['Smirnoff Vodka', 'Gordon\'s Gin', 'Captain Morgan Rum', 'Jack Daniel\'s', 'Baileys'],
    notExamples: ['Rum and Coke', 'Cocktail'],
  },

  // ============================================================================
  // SAUCES & CONDIMENTS
  // ============================================================================
  {
    id: 'ketchup_sauces',
    name: 'Ketchup & Table Sauces',
    description: 'Ketchup, brown sauce, BBQ sauce',
    keywords: ['ketchup', 'tomato ketchup', 'heinz', 'brown sauce', 'hp sauce', 'bbq sauce', 'burger sauce'],
    excludeKeywords: [],
    defaultServingG: 15,
    toleranceMin: 10,
    toleranceMax: 50,
    examples: ['Heinz Tomato Ketchup', 'HP Brown Sauce', 'Heinz BBQ Sauce', 'Nandos Sauce'],
    notExamples: ['Tomato Puree', 'Pasta Sauce'],
  },
  {
    id: 'mayonnaise',
    name: 'Mayonnaise & Salad Cream',
    description: 'Mayonnaise, salad cream, aioli',
    keywords: ['mayonnaise', 'mayo', 'hellmanns', 'salad cream', 'aioli', 'garlic mayo'],
    excludeKeywords: ['egg mayo sandwich', 'prawn mayo'],
    defaultServingG: 15,
    toleranceMin: 10,
    toleranceMax: 50,
    examples: ['Hellmann\'s Mayonnaise', 'Heinz Salad Cream', 'Garlic Aioli', 'Light Mayo'],
    notExamples: ['Egg Mayo Sandwich', 'Coleslaw'],
  },
  {
    id: 'mustard',
    name: 'Mustard',
    description: 'English mustard, Dijon, wholegrain',
    keywords: ['mustard', 'english mustard', 'dijon', 'wholegrain mustard', 'french mustard', 'colmans'],
    excludeKeywords: ['mustard powder'],
    defaultServingG: 10,
    toleranceMin: 5,
    toleranceMax: 30,
    examples: ['Colman\'s English Mustard', 'Maille Dijon', 'Wholegrain Mustard'],
    notExamples: ['Mustard Powder', 'Honey Mustard Dressing'],
  },
  {
    id: 'salad_dressing',
    name: 'Salad Dressings',
    description: 'Caesar dressing, vinaigrette, ranch',
    keywords: ['dressing', 'caesar dressing', 'vinaigrette', 'ranch', 'thousand island', 'balsamic glaze', 'french dressing'],
    excludeKeywords: ['salad cream'],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 60,
    examples: ['Newman\'s Own Caesar', 'Balsamic Vinaigrette', 'Ranch Dressing', 'Blue Cheese Dressing'],
    notExamples: ['Salad Cream', 'Mayonnaise'],
  },
  {
    id: 'cooking_sauce',
    name: 'Cooking Sauces',
    description: 'Pasta sauces, curry sauces, stir fry sauces',
    keywords: ['pasta sauce', 'dolmio', 'ragu', 'curry sauce', 'korma sauce', 'tikka sauce', 'stir fry sauce', 'oyster sauce', 'teriyaki', 'pesto'],
    excludeKeywords: [],
    defaultServingG: 125,
    toleranceMin: 50,
    toleranceMax: 250,
    examples: ['Dolmio Bolognese Sauce', 'Loyd Grossman Tomato & Basil', 'Patak\'s Tikka Sauce', 'Blue Dragon Stir Fry'],
    notExamples: ['Tomato Ketchup', 'Mayonnaise'],
  },
  {
    id: 'oil',
    name: 'Cooking Oils',
    description: 'Olive oil, vegetable oil, coconut oil',
    keywords: ['oil', 'olive oil', 'vegetable oil', 'sunflower oil', 'coconut oil', 'rapeseed oil', 'sesame oil', 'fry light'],
    excludeKeywords: ['oily fish', 'essential oil'],
    defaultServingG: 15,
    toleranceMin: 5,
    toleranceMax: 30,
    examples: ['Filippo Berio Olive Oil', 'Crisp n Dry', 'Fry Light', 'Coconut Oil'],
    notExamples: ['Fish Oil Capsules', 'CBD Oil'],
  },
  {
    id: 'vinegar',
    name: 'Vinegar',
    description: 'Balsamic, white wine, malt vinegar',
    keywords: ['vinegar', 'balsamic', 'white wine vinegar', 'red wine vinegar', 'malt vinegar', 'apple cider vinegar', 'rice vinegar'],
    excludeKeywords: [],
    defaultServingG: 15,
    toleranceMin: 5,
    toleranceMax: 30,
    examples: ['Balsamic Vinegar', 'Sarson\'s Malt Vinegar', 'White Wine Vinegar'],
    notExamples: ['Balsamic Glaze', 'Vinaigrette'],
  },
  {
    id: 'jam_honey',
    name: 'Jam, Honey & Sweet Spreads',
    description: 'Jam, marmalade, honey, Nutella, peanut butter',
    keywords: ['jam', 'marmalade', 'honey', 'nutella', 'chocolate spread', 'peanut butter', 'almond butter', 'lemon curd', 'biscoff spread', 'marmite', 'bovril'],
    excludeKeywords: ['jam doughnut', 'jammie dodger'],
    defaultServingG: 15,
    toleranceMin: 10,
    toleranceMax: 40,
    examples: ['Bonne Maman Strawberry Jam', 'Nutella', 'Sun-Pat Peanut Butter', 'Rowse Honey', 'Marmite'],
    notExamples: ['Jam Doughnut', 'PB&J Sandwich'],
  },
  {
    id: 'hummus_dips',
    name: 'Hummus & Dips',
    description: 'Hummus, guacamole, tzatziki, salsa',
    keywords: ['hummus', 'houmous', 'guacamole', 'tzatziki', 'salsa', 'sour cream dip', 'taramasalata', 'baba ganoush'],
    excludeKeywords: [],
    defaultServingG: 50,
    toleranceMin: 25,
    toleranceMax: 100,
    examples: ['Sabra Hummus', 'Fresh Guacamole', 'Doritos Salsa', 'Tzatziki'],
    notExamples: ['Avocado', 'Soured Cream'],
  },
  {
    id: 'pickle_chutney',
    name: 'Pickles & Chutneys',
    description: 'Pickled onions, gherkins, mango chutney',
    keywords: ['pickle', 'pickled', 'gherkin', 'chutney', 'branston', 'relish', 'piccalilli', 'sauerkraut', 'kimchi'],
    excludeKeywords: [],
    defaultServingG: 25,
    toleranceMin: 15,
    toleranceMax: 60,
    examples: ['Branston Pickle', 'Pickled Onions', 'Mango Chutney', 'Gherkins'],
    notExamples: ['Fresh Cucumber', 'Fresh Onion'],
  },

  // ============================================================================
  // FROZEN FOODS
  // ============================================================================
  {
    id: 'ice_cream',
    name: 'Ice Cream',
    description: 'Tubs, cones, lollies, magnums (1-2 scoops or 1 lolly)',
    keywords: ['ice cream', 'gelato', 'magnum', 'ben and jerrys', 'haagen dazs', 'cornetto', 'twister', 'solero', 'ice lolly', 'fab', 'calippo', 'mini milk'],
    excludeKeywords: ['ice cream maker', 'ice cream scoop'],
    defaultServingG: 75,
    servingSizes: [
      { name: 'Small scoop', grams: 60 },
      { name: 'Standard scoop', grams: 75 },
      { name: 'Large scoop', grams: 100 },
    ],
    toleranceMin: 40,
    toleranceMax: 120,
    examples: ['Ben & Jerry\'s Cookie Dough', 'Magnum Classic', 'Haagen-Dazs', 'Cornetto'],
    notExamples: ['Frozen Yoghurt', 'Sorbet'],
  },
  {
    id: 'frozen_veg',
    name: 'Frozen Vegetables',
    description: 'Frozen peas, sweetcorn, mixed veg',
    keywords: ['frozen pea', 'frozen sweetcorn', 'frozen vegetable', 'birds eye', 'frozen mixed', 'frozen spinach', 'frozen broccoli'],
    excludeKeywords: [],
    defaultServingG: 80,
    toleranceMin: 40,
    toleranceMax: 200,
    examples: ['Birds Eye Garden Peas', 'Frozen Sweetcorn', 'Frozen Mixed Vegetables', 'Frozen Spinach'],
    notExamples: ['Fresh Peas', 'Tinned Peas'],
  },
  {
    id: 'frozen_fish_products',
    name: 'Frozen Fish Products',
    description: 'Fish fingers, fish cakes, breaded fish',
    keywords: ['fish finger', 'fish cake', 'battered fish', 'breaded fish', 'fish fillet frozen', 'birds eye fish', 'youngs'],
    excludeKeywords: [],
    defaultServingG: 100,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Birds Eye Fish Fingers', 'Young\'s Fish Cakes', 'Battered Cod', 'Breaded Haddock'],
    notExamples: ['Fresh Salmon Fillet', 'Tinned Tuna'],
  },
  {
    id: 'frozen_chicken_products',
    name: 'Frozen Chicken Products',
    description: 'Chicken nuggets, chicken kievs, chicken dippers',
    keywords: ['chicken nugget', 'chicken dipper', 'chicken kiev', 'chicken goujons', 'breaded chicken', 'southern fried chicken', 'chicken bites'],
    excludeKeywords: [],
    defaultServingG: 100,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Birds Eye Chicken Dippers', 'Chicken Nuggets', 'Chicken Kievs', 'Southern Fried Chicken'],
    notExamples: ['Fresh Chicken Breast', 'Rotisserie Chicken'],
  },

  // ============================================================================
  // MISCELLANEOUS
  // ============================================================================
  {
    id: 'cereal_bar',
    name: 'Cereal & Protein Bars',
    description: 'Cereal bars, protein bars, flapjacks',
    keywords: ['cereal bar', 'protein bar', 'flapjack', 'nutri-grain', 'nakd', 'trek', 'grenade', 'fulfil', 'kind bar', 'nature valley', 'belvita'],
    excludeKeywords: [],
    defaultServingG: 40,
    toleranceMin: 20,
    toleranceMax: 80,
    examples: ['Nature Valley Crunchy', 'Nakd Cocoa Orange', 'Grenade Carb Killa', 'Trek Protein Flapjack'],
    notExamples: ['Chocolate Bar', 'Cereal Box'],
  },
  {
    id: 'baby_food',
    name: 'Baby Food',
    description: 'Baby purees, baby cereals, toddler snacks',
    keywords: ['baby food', 'baby puree', 'ella\'s kitchen', 'cow and gate', 'aptamil', 'hipp organic', 'baby cereal', 'baby rice'],
    excludeKeywords: [],
    defaultServingG: 70,
    toleranceMin: 40,
    toleranceMax: 150,
    examples: ['Ella\'s Kitchen Pouch', 'Cow & Gate Jar', 'Baby Rice', 'Organix Snacks'],
    notExamples: [],
  },
  {
    id: 'supplements',
    name: 'Supplements & Vitamins',
    description: 'Vitamin tablets, protein powder, supplements',
    keywords: ['vitamin', 'supplement', 'protein powder', 'whey', 'creatine', 'omega 3', 'fish oil capsule', 'multivitamin', 'centrum', 'berocca'],
    excludeKeywords: [],
    defaultServingG: 30,
    toleranceMin: 1,
    toleranceMax: 100,
    examples: ['Optimum Nutrition Whey', 'Centrum Multivitamins', 'Omega 3 Capsules', 'Berocca'],
    notExamples: ['Fresh Fish', 'Orange Juice with Vitamins'],
  },
  {
    id: 'tofu_meat_alternatives',
    name: 'Tofu & Meat Alternatives',
    description: 'Tofu, tempeh, Quorn, plant-based meat',
    keywords: ['tofu', 'tempeh', 'quorn', 'beyond meat', 'impossible', 'this isn\'t', 'plant based', 'meat free', 'vegan mince', 'vegan burger', 'seitan'],
    excludeKeywords: [],
    defaultServingG: 100,
    toleranceMin: 50,
    toleranceMax: 200,
    examples: ['Cauldron Tofu', 'Quorn Mince', 'Beyond Burger', 'THIS Isn\'t Chicken'],
    notExamples: ['Chicken Breast', 'Beef Mince'],
  },
  {
    id: 'flour_baking',
    name: 'Flour & Baking Ingredients',
    description: 'Flour, sugar, baking powder, yeast',
    keywords: ['flour', 'plain flour', 'self raising', 'bread flour', 'sugar', 'caster sugar', 'icing sugar', 'brown sugar', 'baking powder', 'yeast', 'cornflour'],
    excludeKeywords: ['sugar free', 'no added sugar'],
    defaultServingG: 30,
    toleranceMin: 5,
    toleranceMax: 100,
    examples: ['Allinson Plain Flour', 'Tate & Lyle Caster Sugar', 'Baking Powder', 'Dried Yeast'],
    notExamples: ['Cake', 'Bread', 'Biscuits'],
  },
  {
    id: 'crackers_crispbreads',
    name: 'Crackers & Crispbreads',
    description: 'Cream crackers, rice cakes, oatcakes, Ryvita',
    keywords: ['cracker', 'cream cracker', 'rice cake', 'ryvita', 'crispbread', 'oatcake', 'water biscuit', 'carr\'s', 'tuc'],
    excludeKeywords: ['prawn cracker', 'christmas cracker'],
    defaultServingG: 20,
    toleranceMin: 10,
    toleranceMax: 60,
    examples: ['Jacob\'s Cream Crackers', 'Ryvita Original', 'Rice Cakes', 'Nairn\'s Oatcakes'],
    notExamples: ['Prawn Crackers', 'Christmas Crackers'],
  },
  {
    id: 'crisps_savoury_snacks',
    name: 'Crisps & Savoury Snacks',
    description: 'Crisps, nuts, pretzels, popcorn',
    keywords: ['crisps', 'chips', 'pretzels', 'twiglets', 'mini cheddars', 'pork scratchings', 'bombay mix', 'wasabi peas'],
    excludeKeywords: [],
    defaultServingG: 30,
    toleranceMin: 15,
    toleranceMax: 80,
    examples: ['Walkers Ready Salted', 'Mini Cheddars', 'Twiglets', 'Pretzels'],
    notExamples: ['Oven Chips', 'Potato Wedges'],
  },
  {
    id: 'other',
    name: 'Other / Uncategorized',
    description: 'Foods that don\'t fit other categories',
    keywords: [],
    excludeKeywords: [],
    defaultServingG: 100,
    toleranceMin: 10,
    toleranceMax: 500,
    examples: [],
    notExamples: [],
  },
];

// ============================================================================
// API INTEGRATION
// ============================================================================

export type AIModel = 'claude-sonnet' | 'gpt-4o';

export interface CategorizationResult {
  foodId: string;
  foodName: string;
  brand: string | null;
  categoryId: string;
  categoryName: string;
  confidence: number; // 0-100
  reasoning: string;
  suggestedServingG: number;
  currentServingG: number | null;
  servingValidated: boolean; // T0 passes sanity check
  packSizeG: number | null; // Extracted from product name if available
  servingSource: 'validated' | 'pack_size' | 'category_default'; // Which tier the serving came from
}

export interface CategorizationBatchResult {
  results: CategorizationResult[];
  totalProcessed: number;
  totalSuccessful: number;
  totalFailed: number;
  processingTimeMs: number;
  model: AIModel;
  cost: {
    inputTokens: number;
    outputTokens: number;
    estimatedCost: number;
  };
}

/**
 * Extract pack size from product name
 * Examples:
 * - "Charlie Bigham's Fish Pie 350g" → 350
 * - "Cadbury Dairy Milk 110g Bar" → 110
 * - "Tesco Lasagne 400g" → 400
 * - "Heinz Baked Beans 4 x 415g" → 415 (single can)
 */
function extractPackSizeFromName(name: string): number | null {
  // Match patterns like "350g", "350 g", "350G"
  // Also handle multi-packs like "4 x 415g" - extract the single unit size

  // First try to match multi-pack format: "4 x 415g" or "4x415g"
  const multiPackMatch = name.match(/(\d+)\s*x\s*(\d+)\s*g\b/i);
  if (multiPackMatch) {
    return parseInt(multiPackMatch[2], 10); // Return single unit size
  }

  // Match standard patterns: "350g", "350 g", "350G"
  // But avoid matching things like "100g per serving" - we want the pack size
  const matches = name.match(/(\d+)\s*g\b/gi);
  if (matches && matches.length > 0) {
    // Take the last match as it's usually the pack size (e.g., "per 100g, 350g pack" → 350)
    // But filter out small values that are clearly serving sizes (like 25g, 30g)
    const sizes = matches.map(m => parseInt(m.replace(/[^\d]/g, ''), 10)).filter(s => s > 50);

    if (sizes.length > 0) {
      // Return the largest value as pack size
      return Math.max(...sizes);
    }
  }

  return null;
}

// Build the system prompt for categorization
function buildSystemPrompt(): string {
  const categoryList = FOOD_CATEGORIES.map(cat => {
    return `
## ${cat.name} (ID: ${cat.id})
${cat.description}
- Default serving: ${cat.defaultServingG}g
- Acceptable T0 range: ${cat.toleranceMin}g - ${cat.toleranceMax}g
- Examples: ${cat.examples.join(', ')}
- NOT this category: ${cat.notExamples.join(', ')}
`;
  }).join('\n');

  return `You are a food categorization expert for a UK nutrition app. Your job is to categorize food products into the correct category.

CRITICAL RULES:
1. Read the FULL product name carefully. "Cadbury Dairy Milk" is CHOCOLATE, not DAIRY.
2. "Milk Chocolate" means chocolate made with milk, NOT milk. Categorize as chocolate_bar.
3. "Chocolate Milkshake" is a milkshake flavored with chocolate. Categorize as milkshake.
4. Brand names matter: "Galaxy" = chocolate, "Yazoo" = milkshake, "Warburtons" = bread
5. If unsure between two categories, pick the more specific one.
6. Consider UK products and brands specifically.

CATEGORIES:
${categoryList}

For each food, respond with JSON in this exact format:
{
  "categoryId": "the_category_id",
  "confidence": 85,
  "reasoning": "Brief explanation of why this category"
}`;
}

// Build the user prompt for a batch of foods
function buildBatchPrompt(foods: Array<{ id: string; name: string; brand: string | null; servingSizeG: number | null }>): string {
  const foodList = foods.map((f, i) => {
    const brand = f.brand ? ` (${f.brand})` : '';
    const serving = f.servingSizeG ? ` [current serving: ${f.servingSizeG}g]` : '';
    return `${i + 1}. ${f.name}${brand}${serving}`;
  }).join('\n');

  return `Categorize these ${foods.length} food products. Return a JSON array with one object per food in the same order:

${foodList}

Respond with ONLY a JSON array, no other text:
[
  {"categoryId": "...", "confidence": 85, "reasoning": "..."},
  ...
]`;
}

// Call Claude API
async function callClaudeAPI(systemPrompt: string, userPrompt: string, apiKey: string): Promise<{ content: string; inputTokens: number; outputTokens: number }> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 8000,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Claude API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return {
    content: data.content[0].text,
    inputTokens: data.usage.input_tokens,
    outputTokens: data.usage.output_tokens,
  };
}

// Call OpenAI API
async function callOpenAIAPI(systemPrompt: string, userPrompt: string, apiKey: string): Promise<{ content: string; inputTokens: number; outputTokens: number }> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      max_tokens: 8000,
      temperature: 0.3,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return {
    content: data.choices[0].message.content,
    inputTokens: data.usage.prompt_tokens,
    outputTokens: data.usage.completion_tokens,
  };
}

// Parse AI response
function parseAIResponse(content: string, foods: Array<{ id: string; name: string; brand: string | null; servingSizeG: number | null }>): CategorizationResult[] {
  // Extract JSON array from response
  const jsonMatch = content.match(/\[[\s\S]*\]/);
  if (!jsonMatch) {
    throw new Error('Could not find JSON array in response');
  }

  const parsed = JSON.parse(jsonMatch[0]);

  if (!Array.isArray(parsed) || parsed.length !== foods.length) {
    throw new Error(`Expected ${foods.length} results, got ${parsed.length}`);
  }

  return parsed.map((result: { categoryId: string; confidence: number; reasoning: string }, index: number) => {
    const food = foods[index];
    const category = FOOD_CATEGORIES.find(c => c.id === result.categoryId) || FOOD_CATEGORIES.find(c => c.id === 'other')!;

    // Extract pack size from product name (e.g., "Charlie Bigham's Fish Pie 350g" → 350)
    const packSizeG = extractPackSizeFromName(food.name);

    // T0: Check if current serving size is valid for this category
    const servingValidated = food.servingSizeG !== null &&
      food.servingSizeG >= category.toleranceMin &&
      food.servingSizeG <= category.toleranceMax;

    // Determine final serving size and source using tiered logic:
    // T0: If DB serving is within tolerance → use it
    // T2: Otherwise → use category default
    // NOTE: Pack size from name is NOT used for serving suggestions (pack size ≠ serving size)
    let suggestedServingG: number;
    let servingSource: 'validated' | 'pack_size' | 'category_default';

    if (servingValidated && food.servingSizeG !== null) {
      // T0: Database serving is valid
      suggestedServingG = food.servingSizeG;
      servingSource = 'validated';
    } else {
      // T2: Use category default (pack size from name is NOT a valid serving size)
      suggestedServingG = category.defaultServingG;
      servingSource = 'category_default';
    }

    return {
      foodId: food.id,
      foodName: food.name,
      brand: food.brand,
      categoryId: category.id,
      categoryName: category.name,
      confidence: result.confidence || 80,
      reasoning: result.reasoning || '',
      suggestedServingG,
      currentServingG: food.servingSizeG,
      servingValidated,
      packSizeG,
      servingSource,
    };
  });
}

// Main categorization function
export async function categorizeFoods(
  foods: Array<{ id: string; name: string; brand: string | null; servingSizeG: number | null }>,
  model: AIModel,
  apiKey: string,
  onProgress?: (processed: number, total: number) => void
): Promise<CategorizationBatchResult> {
  const startTime = Date.now();
  const results: CategorizationResult[] = [];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  let failedCount = 0;

  const systemPrompt = buildSystemPrompt();
  const batchSize = 50; // Process 50 foods at a time

  for (let i = 0; i < foods.length; i += batchSize) {
    const batch = foods.slice(i, i + batchSize);
    const userPrompt = buildBatchPrompt(batch);

    try {
      const response = model === 'claude-sonnet'
        ? await callClaudeAPI(systemPrompt, userPrompt, apiKey)
        : await callOpenAIAPI(systemPrompt, userPrompt, apiKey);

      totalInputTokens += response.inputTokens;
      totalOutputTokens += response.outputTokens;

      const batchResults = parseAIResponse(response.content, batch);
      results.push(...batchResults);
    } catch (error) {
      console.error(`Batch ${i / batchSize + 1} failed:`, error);
      failedCount += batch.length;

      // Add failed results with 'other' category
      batch.forEach(food => {
        results.push({
          foodId: food.id,
          foodName: food.name,
          brand: food.brand,
          categoryId: 'other',
          categoryName: 'Other / Uncategorized',
          confidence: 0,
          reasoning: 'Categorization failed',
          suggestedServingG: 100,
          currentServingG: food.servingSizeG,
          servingValidated: false,
          packSizeG: extractPackSizeFromName(food.name),
          servingSource: 'category_default',
        });
      });
    }

    onProgress?.(Math.min(i + batchSize, foods.length), foods.length);

    // Small delay between batches to avoid rate limiting
    if (i + batchSize < foods.length) {
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }

  // Calculate estimated cost
  const costPerMInputTokens = model === 'claude-sonnet' ? 3.0 : 2.5;
  const costPerMOutputTokens = model === 'claude-sonnet' ? 15.0 : 10.0;
  const estimatedCost = (totalInputTokens / 1_000_000 * costPerMInputTokens) +
                       (totalOutputTokens / 1_000_000 * costPerMOutputTokens);

  return {
    results,
    totalProcessed: foods.length,
    totalSuccessful: foods.length - failedCount,
    totalFailed: failedCount,
    processingTimeMs: Date.now() - startTime,
    model,
    cost: {
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      estimatedCost,
    },
  };
}

// ============================================================================
// SMART MODE - Minimal prompting, let Claude figure it out
// ============================================================================

/**
 * Smart categorization - minimal prompting approach
 * Just sends food names and lets Claude use its training knowledge
 * Much cheaper and often more accurate than verbose prompts
 */
export async function categorizeFoodsSmart(
  foods: Array<{ id: string; name: string; brand: string | null; servingSizeG: number | null }>,
  model: AIModel,
  apiKey: string,
  onProgress?: (processed: number, total: number) => void
): Promise<CategorizationBatchResult> {
  const startTime = Date.now();
  const results: CategorizationResult[] = [];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  let failedCount = 0;

  // Build category ID list just once (much smaller than full descriptions)
  const categoryIds = FOOD_CATEGORIES.map(c => c.id).join(', ');

  const systemPrompt = `You categorize UK food products. Output JSON only.

Categories: ${categoryIds}

Rules:
- CRITICAL: Read the FULL product name carefully - it determines the category, not the brand
- Brands make multiple products: Elmlea makes cream AND butter, Lurpak makes butter AND spreads, etc.
- Product name keywords like "Butter", "Spread", "Cream", "Milk" override any brand assumptions
- Use snake_case category IDs exactly as listed
- Include typical UK serving size in grams
- Confidence 0-100 based on certainty`;

  const batchSize = 100; // Larger batches since prompts are smaller

  for (let i = 0; i < foods.length; i += batchSize) {
    const batch = foods.slice(i, i + batchSize);

    // Minimal format: just numbered list with name and brand
    const foodList = batch.map((f, idx) => {
      const brand = f.brand ? ` | ${f.brand}` : '';
      return `${idx + 1}. ${f.name}${brand}`;
    }).join('\n');

    const userPrompt = `Categorize these ${batch.length} foods. Return JSON array:
[{"id":1,"cat":"category_id","serv":30,"conf":90,"why":"brief reason"},...]

${foodList}`;

    try {
      const response = model === 'claude-sonnet'
        ? await callClaudeAPI(systemPrompt, userPrompt, apiKey)
        : await callOpenAIAPI(systemPrompt, userPrompt, apiKey);

      totalInputTokens += response.inputTokens;
      totalOutputTokens += response.outputTokens;

      // Parse smart response format
      const batchResults = parseSmartResponse(response.content, batch);
      results.push(...batchResults);
    } catch (error) {
      console.error(`Smart batch ${i / batchSize + 1} failed:`, error);
      failedCount += batch.length;

      // Add failed results
      batch.forEach(food => {
        results.push({
          foodId: food.id,
          foodName: food.name,
          brand: food.brand,
          categoryId: 'other',
          categoryName: 'Other / Uncategorized',
          confidence: 0,
          reasoning: 'Smart categorization failed',
          suggestedServingG: 100,
          currentServingG: food.servingSizeG,
          servingValidated: false,
          packSizeG: extractPackSizeFromName(food.name),
          servingSource: 'category_default',
        });
      });
    }

    onProgress?.(Math.min(i + batchSize, foods.length), foods.length);

    // Small delay between batches
    if (i + batchSize < foods.length) {
      await new Promise(resolve => setTimeout(resolve, 300));
    }
  }

  // Calculate cost (should be ~50% cheaper due to smaller prompts)
  const costPerMInputTokens = model === 'claude-sonnet' ? 3.0 : 2.5;
  const costPerMOutputTokens = model === 'claude-sonnet' ? 15.0 : 10.0;
  const estimatedCost = (totalInputTokens / 1_000_000 * costPerMInputTokens) +
                       (totalOutputTokens / 1_000_000 * costPerMOutputTokens);

  return {
    results,
    totalProcessed: foods.length,
    totalSuccessful: foods.length - failedCount,
    totalFailed: failedCount,
    processingTimeMs: Date.now() - startTime,
    model,
    cost: {
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      estimatedCost,
    },
  };
}

/**
 * Parse smart mode response (compact format)
 */
function parseSmartResponse(
  content: string,
  foods: Array<{ id: string; name: string; brand: string | null; servingSizeG: number | null }>
): CategorizationResult[] {
  const results: CategorizationResult[] = [];

  try {
    // Extract JSON array from response
    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      throw new Error('No JSON array found in response');
    }

    const parsed = JSON.parse(jsonMatch[0]) as Array<{
      id: number;
      cat: string;
      serv: number;
      conf: number;
      why: string;
    }>;

    // Map responses back to foods
    for (let i = 0; i < foods.length; i++) {
      const food = foods[i];
      const aiResult = parsed.find(p => p.id === i + 1) || parsed[i];

      if (aiResult) {
        // Validate category exists, fallback to 'other' if not
        const category = FOOD_CATEGORIES.find(c => c.id === aiResult.cat);
        const categoryId = category ? aiResult.cat : 'other';
        const categoryName = category?.name || 'Other / Uncategorized';

        // Debug: Log if category not found
        if (!category) {
          console.warn(`⚠️ Unknown category ID from AI: "${aiResult.cat}" for food: ${food.name}`);
        }

        // Get pack size from name
        const packSizeG = extractPackSizeFromName(food.name);

        // Determine serving using tiered system
        let suggestedServingG = aiResult.serv || 100;
        let servingValidated = false;
        let servingSource: 'validated' | 'pack_size' | 'category_default' = 'category_default';

        if (category) {
          // T0: Current DB serving within tolerance
          if (food.servingSizeG !== null &&
              food.servingSizeG >= category.toleranceMin &&
              food.servingSizeG <= category.toleranceMax) {
            suggestedServingG = food.servingSizeG;
            servingValidated = true;
            servingSource = 'validated';
          }
          // T1: Pack size if under category default
          else if (packSizeG != null &&
                   packSizeG < category.defaultServingG &&
                   packSizeG >= category.toleranceMin) {
            suggestedServingG = packSizeG;
            servingSource = 'pack_size';
          }
          // T2: Use AI's suggested serving (informed by category)
          else {
            suggestedServingG = aiResult.serv || category.defaultServingG;
            servingSource = 'category_default';
          }
        }

        results.push({
          foodId: food.id,
          foodName: food.name,
          brand: food.brand,
          categoryId,
          categoryName,
          confidence: aiResult.conf || 50,
          reasoning: aiResult.why || 'AI categorization',
          suggestedServingG,
          currentServingG: food.servingSizeG,
          servingValidated,
          packSizeG,
          servingSource,
        });
      } else {
        // No matching result from AI
        results.push({
          foodId: food.id,
          foodName: food.name,
          brand: food.brand,
          categoryId: 'other',
          categoryName: 'Other / Uncategorized',
          confidence: 0,
          reasoning: 'No AI response',
          suggestedServingG: 100,
          currentServingG: food.servingSizeG,
          servingValidated: false,
          packSizeG: extractPackSizeFromName(food.name),
          servingSource: 'category_default',
        });
      }
    }
  } catch (error) {
    console.error('Failed to parse smart response:', error, content);
    // Return all as failed
    foods.forEach(food => {
      results.push({
        foodId: food.id,
        foodName: food.name,
        brand: food.brand,
        categoryId: 'other',
        categoryName: 'Other / Uncategorized',
        confidence: 0,
        reasoning: `Parse error: ${error}`,
        suggestedServingG: 100,
        currentServingG: food.servingSizeG,
        servingValidated: false,
        packSizeG: extractPackSizeFromName(food.name),
        servingSource: 'category_default',
      });
    });
  }

  return results;
}

// Get category by ID
export function getCategoryById(categoryId: string): FoodCategory | undefined {
  return FOOD_CATEGORIES.find(c => c.id === categoryId);
}

// Get suggested serving size for a food
export function getSuggestedServingSize(
  categoryId: string,
  currentServingG: number | null,
  packSizeG?: number | null
): { serving: number; tier: 'T0' | 'T1' | 'T2'; source: string } {
  const category = getCategoryById(categoryId);

  if (!category) {
    return { serving: 100, tier: 'T2', source: 'Default fallback' };
  }

  // T0: Use current serving if it's within tolerance
  if (currentServingG !== null &&
      currentServingG >= category.toleranceMin &&
      currentServingG <= category.toleranceMax) {
    return { serving: currentServingG, tier: 'T0', source: 'Database serving (validated)' };
  }

  // T1: Use pack size if it's UNDER category default (prevents over-portioning)
  if (packSizeG != null &&
      packSizeG < category.defaultServingG &&
      packSizeG >= category.toleranceMin) {
    return { serving: packSizeG, tier: 'T1', source: 'Pack size (from name)' };
  }

  // T2: Use category default
  return { serving: category.defaultServingG, tier: 'T1', source: `${category.name} default` };
}
