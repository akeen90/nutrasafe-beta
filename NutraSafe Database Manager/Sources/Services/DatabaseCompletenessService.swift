//
//  DatabaseCompletenessService.swift
//  NutraSafe Database Manager
//
//  Service for checking database completeness for UK foods
//  and identifying missing essential items including major UK brands
//  Focus: Adult nutrition tracking (excludes baby food and pet food)
//

import Foundation

@MainActor
class DatabaseCompletenessService: ObservableObject {
    static let shared = DatabaseCompletenessService()

    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentCategory: String = ""
    @Published var scanResults: CompletenessResults?
    @Published var error: String?

    // Caching
    @Published var hasCachedResults: Bool = false
    @Published var cachedFoodsCount: Int = 0
    @Published var lastScanDate: Date?

    // Fetching state
    @Published var isFetching = false
    @Published var fetchProgress: Double = 0
    @Published var fetchedCount: Int = 0
    @Published var totalToFetch: Int = 0

    private var cachedFoods: [FoodItem] = []
    private var isCancelled = false
    private var isFetchCancelled = false

    private init() {}

    // MARK: - Fetch Control

    func cancelFetch() {
        isFetchCancelled = true
    }

    // MARK: - Cache Management

    /// Check if we have cached data
    var canUseCachedScan: Bool {
        return hasCachedResults && scanResults != nil && !cachedFoods.isEmpty
    }

    /// Load database and cache it
    func cacheDatabase(foods: [FoodItem]) {
        cachedFoods = foods
        cachedFoodsCount = foods.count
        hasCachedResults = false // Results not cached yet, just the database
    }

    /// Scan using cached database (no reload)
    func scanWithCachedDatabase() async {
        guard !cachedFoods.isEmpty else {
            error = "No cached database. Please load the database first."
            return
        }
        await scanForCompleteness(foods: cachedFoods)
    }

    /// Clear all cached data
    func clearCache() {
        cachedFoods = []
        cachedFoodsCount = 0
        hasCachedResults = false
        scanResults = nil
        lastScanDate = nil
    }

    // MARK: - Essential UK Food Categories (Adult Nutrition Focus)

    /// Categories and items a complete UK food database should have
    static let essentialCategories: [FoodCategory] = [
        // ============================================
        // FAST FOOD & RESTAURANTS
        // ============================================

        // McDonald's UK
        FoodCategory(name: "McDonald's", items: [
            // Burgers
            "McDonald's Big Mac", "Big Mac", "McDonald's Quarter Pounder with Cheese", "Quarter Pounder",
            "McDonald's Double Quarter Pounder", "McDonald's Cheeseburger", "McDonald's Double Cheeseburger",
            "McDonald's McChicken Sandwich", "McChicken", "McDonald's Filet-O-Fish",
            "McDonald's Hamburger", "McDonald's Mayo Chicken", "McDonald's McPlant",
            "McDonald's Chicken Legend", "Chicken Legend", "McDonald's Big Tasty", "Big Tasty",
            "McDonald's Big Tasty with Bacon", "McDonald's Grand Big Mac",
            // Chicken
            "McDonald's Chicken McNuggets 6 Piece", "McDonald's Chicken McNuggets 9 Piece",
            "McDonald's Chicken McNuggets 20 Piece", "Chicken McNuggets",
            "McDonald's Chicken Selects 3 Piece", "McDonald's Chicken Selects 5 Piece",
            "Chicken Selects", "McDonald's Spicy Chicken McNuggets",
            // Fries & Sides
            "McDonald's Small Fries", "McDonald's Medium Fries", "McDonald's Large Fries",
            "McDonald's Fries", "McDonald's Hash Brown", "McDonald's Mozzarella Dippers",
            "McDonald's Cheese Bites",
            // Breakfast
            "McDonald's Egg McMuffin", "Egg McMuffin", "McDonald's Sausage & Egg McMuffin",
            "McDonald's Bacon & Egg McMuffin", "McDonald's Double Sausage & Egg McMuffin",
            "McDonald's Bacon Roll", "McDonald's Sausage Egg & Cheese Bagel",
            "McDonald's Pancakes", "McDonald's Pancakes & Sausage", "McDonald's Big Breakfast",
            // Wraps & Salads
            "McDonald's Crispy Chicken Wrap", "McDonald's Grilled Chicken Wrap",
            "McDonald's Caesar Salad", "McDonald's Side Salad",
            // Desserts & Drinks
            "McDonald's McFlurry Oreo", "McDonald's McFlurry Smarties", "McFlurry",
            "McDonald's Apple Pie", "McDonald's Vanilla Milkshake", "McDonald's Chocolate Milkshake",
            "McDonald's Strawberry Milkshake", "McDonald's Banana Milkshake",
            "McDonald's Fruit Bag", "McDonald's Carrot Sticks"
        ]),

        // KFC UK
        FoodCategory(name: "KFC", items: [
            // Chicken pieces
            "KFC Original Recipe Chicken", "KFC Original Recipe Breast", "KFC Original Recipe Thigh",
            "KFC Original Recipe Drumstick", "KFC Original Recipe Wing",
            "KFC Crispy Strips", "KFC Hot Wings", "KFC Popcorn Chicken",
            "KFC Boneless Banquet", "KFC Mighty Bucket for One", "KFC Family Feast",
            // Burgers
            "KFC Zinger Burger", "Zinger Burger", "KFC Zinger Stacker", "KFC Tower Burger",
            "KFC Fillet Burger", "KFC Original Recipe Fillet Burger",
            "KFC Double Down", "KFC Twister Wrap", "KFC Boxmaster",
            // Sides
            "KFC Fries", "KFC Large Fries", "KFC Regular Fries",
            "KFC Gravy", "KFC Gravy Regular", "KFC Gravy Large",
            "KFC Coleslaw", "KFC Coleslaw Regular", "KFC Coleslaw Large",
            "KFC Corn on the Cob", "KFC BBQ Beans", "KFC Mashed Potato",
            "KFC Popcorn Chicken", "KFC Mini Fillet Bites",
            // Meals
            "KFC Bargain Bucket", "KFC 6 Piece Bargain Bucket", "KFC 10 Piece Bargain Bucket"
        ]),

        // Burger King UK
        FoodCategory(name: "Burger King", items: [
            "Burger King Whopper", "Whopper", "Burger King Whopper with Cheese",
            "Burger King Double Whopper", "Burger King Whopper Jr",
            "Burger King Bacon Double Cheeseburger", "Burger King Cheeseburger",
            "Burger King Double Cheeseburger", "Burger King Hamburger",
            "Burger King Chicken Royale", "Chicken Royale", "Burger King Crispy Chicken",
            "Burger King Veggie Bean Burger", "Burger King Plant-Based Whopper",
            "Burger King Chicken Nuggets", "Burger King Fries", "Burger King Small Fries",
            "Burger King Medium Fries", "Burger King Large Fries",
            "Burger King Onion Rings", "Burger King Mozzarella Sticks",
            "Burger King Hash Browns", "Burger King King Fusion"
        ]),

        // Nando's UK
        FoodCategory(name: "Nando's", items: [
            // Chicken
            "Nando's Peri-Peri Chicken", "Nando's 1/4 Chicken", "Nando's Quarter Chicken",
            "Nando's 1/2 Chicken", "Nando's Half Chicken", "Nando's Whole Chicken",
            "Nando's Butterfly Chicken", "Nando's Chicken Breast",
            "Nando's 3 Wing Roulette", "Nando's 5 Wing Roulette", "Nando's 10 Wing Roulette",
            "Nando's Chicken Thighs", "Nando's Chicken Wings",
            // Burgers & Wraps
            "Nando's Chicken Burger", "Nando's Double Chicken Burger",
            "Nando's Fino Pitta", "Nando's Peri-Peri Pitta",
            "Nando's Chicken Wrap", "Nando's Rainbow Wrap",
            // Sides
            "Nando's Peri-Peri Chips", "Nando's Regular Chips", "Nando's Large Chips",
            "Nando's Spicy Rice", "Nando's Macho Peas", "Nando's Corn on the Cob",
            "Nando's Coleslaw", "Nando's Mixed Leaf Salad", "Nando's Peri-Peri Nuts",
            "Nando's Garlic Bread", "Nando's Halloumi",
            // Starters
            "Nando's Hummus with Peri-Peri Drizzle", "Nando's Red Pepper Dip",
            "Nando's Spicy Mixed Olives", "Nando's Peri-Peri Wings"
        ]),

        // Greggs UK
        FoodCategory(name: "Greggs", items: [
            // Savoury pastries
            "Greggs Sausage Roll", "Greggs Vegan Sausage Roll", "Greggs Jumbo Sausage Roll",
            "Greggs Steak Bake", "Greggs Vegan Steak Bake",
            "Greggs Chicken Bake", "Greggs Cheese & Onion Bake",
            "Greggs Sausage Bean & Cheese Melt", "Greggs Mexican Chicken Bake",
            "Greggs Festive Bake", "Greggs Peppered Steak Bake",
            // Sandwiches & Baguettes
            "Greggs Ham & Cheese Baguette", "Greggs Tuna Crunch Baguette",
            "Greggs Chicken Club Sandwich", "Greggs BLT Sandwich",
            "Greggs Egg Mayo Sandwich", "Greggs Cheese Salad Sandwich",
            "Greggs Mexican Chicken Wrap", "Greggs Southern Fried Chicken Wrap",
            // Hot Food
            "Greggs Pizza Slice", "Greggs Pepperoni Pizza Slice",
            "Greggs Bacon & Sausage Wrap", "Greggs Bacon Sandwich",
            "Greggs Sausage Breakfast Roll",
            // Sweet
            "Greggs Yum Yum", "Greggs Belgian Bun", "Greggs Doughnut",
            "Greggs Chocolate Eclair", "Greggs Cream Doughnut",
            "Greggs Caramel Shortcake", "Greggs Pink Jammie",
            "Greggs Apple Danish", "Greggs Pain au Chocolat"
        ]),

        // Subway UK
        FoodCategory(name: "Subway", items: [
            // 6-inch Subs
            "Subway Italian BMT 6-inch", "Subway Meatball Marinara 6-inch",
            "Subway Chicken Tikka 6-inch", "Subway Tuna 6-inch",
            "Subway Turkey Breast 6-inch", "Subway Ham 6-inch",
            "Subway Veggie Delite 6-inch", "Subway Steak & Cheese 6-inch",
            "Subway Chicken Teriyaki 6-inch", "Subway Spicy Italian 6-inch",
            "Subway Roast Beef 6-inch", "Subway Chicken & Bacon Ranch 6-inch",
            // Footlong Subs
            "Subway Italian BMT Footlong", "Subway Meatball Marinara Footlong",
            "Subway Chicken Tikka Footlong", "Subway Tuna Footlong",
            "Subway Turkey Breast Footlong", "Subway Ham Footlong",
            "Subway Steak & Cheese Footlong", "Subway Chicken Teriyaki Footlong",
            // Salads
            "Subway Chicken Tikka Salad", "Subway Meatball Marinara Salad",
            "Subway Ham Salad", "Subway Turkey Breast Salad",
            // Cookies & Sides
            "Subway Cookie", "Subway Chocolate Chip Cookie", "Subway Double Chocolate Cookie",
            "Subway White Chip Macadamia", "Subway Raspberry Cheesecake Cookie"
        ]),

        // Pizza Hut UK
        FoodCategory(name: "Pizza Hut", items: [
            // Pizzas (Medium)
            "Pizza Hut Margherita Medium", "Pizza Hut Pepperoni Feast Medium",
            "Pizza Hut BBQ Americano Medium", "Pizza Hut Meat Feast Medium",
            "Pizza Hut Super Supreme Medium", "Pizza Hut Hawaiian Medium",
            "Pizza Hut Veggie Supreme Medium", "Pizza Hut Chicken Supreme Medium",
            // Pizzas (Large)
            "Pizza Hut Margherita Large", "Pizza Hut Pepperoni Feast Large",
            "Pizza Hut BBQ Americano Large", "Pizza Hut Meat Feast Large",
            // Sides
            "Pizza Hut Garlic Bread", "Pizza Hut Cheesy Garlic Bread",
            "Pizza Hut Chicken Wings", "Pizza Hut BBQ Chicken Wings",
            "Pizza Hut Wedges", "Pizza Hut Coleslaw", "Pizza Hut Fries",
            // Pasta
            "Pizza Hut Spaghetti Bolognese", "Pizza Hut Mac & Cheese"
        ]),

        // Domino's UK
        FoodCategory(name: "Domino's", items: [
            // Pizzas (Medium)
            "Domino's Pepperoni Passion Medium", "Domino's Mighty Meaty Medium",
            "Domino's Texas BBQ Medium", "Domino's Vegi Supreme Medium",
            "Domino's Hawaiian Medium", "Domino's Farmhouse Medium",
            "Domino's Margherita Medium", "Domino's Meateor Medium",
            "Domino's American Hot Medium", "Domino's Tandoori Hot Medium",
            "Domino's New Yorker Medium", "Domino's Meteor Medium",
            // Pizzas (Large)
            "Domino's Pepperoni Passion Large", "Domino's Mighty Meaty Large",
            "Domino's Texas BBQ Large", "Domino's Margherita Large",
            // Sides
            "Domino's Garlic Pizza Bread", "Domino's Cheesy Garlic Pizza Bread",
            "Domino's Chicken Strippers", "Domino's Chicken Wings",
            "Domino's Chicken Kickers", "Domino's Potato Wedges",
            "Domino's Coleslaw", "Domino's Cookies"
        ]),

        // Papa John's UK
        FoodCategory(name: "Papa John's", items: [
            "Papa John's Garden Party", "Papa John's Pepperoni",
            "Papa John's The Works", "Papa John's All The Meats",
            "Papa John's Hawaiian", "Papa John's BBQ Chicken",
            "Papa John's Chicken Club", "Papa John's Margherita",
            "Papa John's Papa's Favourite",
            "Papa John's Garlic Bread", "Papa John's Cheesy Garlic Bread",
            "Papa John's Chicken Wings", "Papa John's Chicken Poppers",
            "Papa John's Potato Wedges"
        ]),

        // Costa Coffee UK
        FoodCategory(name: "Costa Coffee", items: [
            // Hot Drinks
            "Costa Latte", "Costa Latte Medium", "Costa Latte Large",
            "Costa Cappuccino", "Costa Cappuccino Medium", "Costa Cappuccino Large",
            "Costa Flat White", "Costa Americano", "Costa Americano Medium",
            "Costa Espresso", "Costa Double Espresso", "Costa Cortado",
            "Costa Mocha", "Costa Hot Chocolate", "Costa Caramel Latte",
            "Costa Vanilla Latte", "Costa Chai Latte", "Costa Matcha Latte",
            // Cold Drinks
            "Costa Iced Latte", "Costa Iced Americano", "Costa Iced Mocha",
            "Costa Frostino Coffee", "Costa Frostino Chocolate",
            // Food
            "Costa Toastie Ham & Cheese", "Costa Bacon Roll",
            "Costa All Day Breakfast Panini", "Costa Sausage Baguette",
            "Costa Croissant", "Costa Pain au Chocolat", "Costa Almond Croissant",
            "Costa Chocolate Twist", "Costa Millionaire's Shortbread",
            "Costa Rocky Road", "Costa Brownie", "Costa Carrot Cake"
        ]),

        // Starbucks UK
        FoodCategory(name: "Starbucks", items: [
            // Hot Drinks
            "Starbucks Latte", "Starbucks Latte Tall", "Starbucks Latte Grande", "Starbucks Latte Venti",
            "Starbucks Cappuccino", "Starbucks Cappuccino Tall", "Starbucks Cappuccino Grande",
            "Starbucks Flat White", "Starbucks Americano", "Starbucks Americano Grande",
            "Starbucks Caramel Macchiato", "Starbucks Vanilla Latte",
            "Starbucks Mocha", "Starbucks Hot Chocolate",
            "Starbucks Pumpkin Spice Latte", "Starbucks Matcha Latte",
            "Starbucks Chai Tea Latte",
            // Cold Drinks
            "Starbucks Frappuccino Coffee", "Starbucks Frappuccino Mocha",
            "Starbucks Frappuccino Caramel", "Starbucks Frappuccino Vanilla",
            "Starbucks Iced Latte", "Starbucks Iced Americano",
            "Starbucks Cold Brew", "Starbucks Refresha",
            // Food
            "Starbucks Bacon Roll", "Starbucks Sausage Roll",
            "Starbucks Egg & Cheese Muffin", "Starbucks All Day Breakfast Wrap",
            "Starbucks Croissant", "Starbucks Chocolate Croissant",
            "Starbucks Blueberry Muffin", "Starbucks Chocolate Muffin",
            "Starbucks Cookie", "Starbucks Brownie", "Starbucks Cake Pop"
        ]),

        // Pret A Manger UK
        FoodCategory(name: "Pret A Manger", items: [
            // Sandwiches & Wraps
            "Pret Chicken Caesar Wrap", "Pret Chicken Avocado Sandwich",
            "Pret Ham & Cheese Baguette", "Pret Tuna Mayo Baguette",
            "Pret Egg Mayo Sandwich", "Pret BLT Sandwich",
            "Pret Falafel Wrap", "Pret Super Club Sandwich",
            "Pret Vegan Meatball Wrap",
            // Hot Food
            "Pret Macaroni Cheese", "Pret Chicken & Rice",
            "Pret Veggie Curry", "Pret Soup of the Day",
            // Salads
            "Pret Chef's Italian Chicken Salad", "Pret Salmon Nicoise Salad",
            "Pret Superfood Salad",
            // Coffee
            "Pret Latte", "Pret Cappuccino", "Pret Flat White",
            "Pret Americano", "Pret Hot Chocolate",
            // Pastries
            "Pret Croissant", "Pret Pain au Chocolat", "Pret Almond Croissant",
            "Pret Cookie", "Pret Brownie"
        ]),

        // Wetherspoons UK
        FoodCategory(name: "Wetherspoons", items: [
            // Breakfast
            "Wetherspoons Large Breakfast", "Wetherspoons Traditional Breakfast",
            "Wetherspoons Full English Breakfast", "Wetherspoons Vegetarian Breakfast",
            "Wetherspoons Eggs Benedict",
            // Mains
            "Wetherspoons Fish & Chips", "Wetherspoons Scampi & Chips",
            "Wetherspoons Chicken Curry", "Wetherspoons Beef Burger",
            "Wetherspoons Classic Burger", "Wetherspoons Gourmet Burger",
            "Wetherspoons Mixed Grill", "Wetherspoons 10oz Rump Steak",
            "Wetherspoons 8oz Sirloin Steak", "Wetherspoons Chicken & Bacon Club",
            "Wetherspoons Lasagne", "Wetherspoons Mac and Cheese",
            "Wetherspoons Sunday Roast Beef", "Wetherspoons Sunday Roast Chicken",
            // Sides
            "Wetherspoons Chips", "Wetherspoons Onion Rings",
            "Wetherspoons Garlic Bread", "Wetherspoons Coleslaw"
        ]),

        // Fish & Chip Shop
        FoodCategory(name: "Fish & Chips", items: [
            // Fish
            "Fish and Chips", "Cod and Chips", "Haddock and Chips",
            "Battered Cod", "Battered Haddock", "Battered Plaice",
            "Battered Sausage", "Battered Saveloy",
            "Chip Shop Fish", "Chip Shop Cod", "Chip Shop Haddock",
            // Chips & Sides
            "Chip Shop Chips", "Chippy Chips", "Chips from Chip Shop",
            "Mushy Peas", "Curry Sauce", "Gravy",
            "Chip Shop Curry Sauce", "Chip Shop Gravy",
            "Pickled Onion", "Pickled Egg", "Gherkin",
            // Other items
            "Chip Shop Pie", "Chip Shop Sausage", "Saveloy",
            "Fishcake", "Fish Cake", "Chip Shop Fishcake",
            "Scampi and Chips", "Roe", "Cod Roe"
        ]),

        // Chinese Takeaway
        FoodCategory(name: "Chinese Takeaway", items: [
            // Starters
            "Prawn Crackers", "Spring Roll", "Vegetable Spring Roll", "Crispy Seaweed",
            "Prawn Toast", "Sesame Prawn Toast", "Chicken Satay", "Crispy Wontons",
            "Spare Ribs", "Salt and Pepper Spare Ribs", "BBQ Spare Ribs",
            "Salt and Pepper Chicken", "Salt and Pepper Squid",
            // Main Dishes
            "Sweet and Sour Chicken", "Sweet and Sour Pork", "Sweet and Sour Chicken Balls",
            "Chicken Chow Mein", "Beef Chow Mein", "Prawn Chow Mein",
            "Special Chow Mein", "Vegetable Chow Mein", "Singapore Chow Mein",
            "Kung Po Chicken", "Szechuan Chicken", "Crispy Shredded Chicken",
            "Crispy Shredded Beef", "Beef with Black Bean Sauce",
            "Chicken with Cashew Nuts", "Chicken with Mushrooms",
            "King Prawn with Vegetables", "King Prawn in Black Bean",
            "Crispy Aromatic Duck", "Duck Pancakes",
            // Rice
            "Egg Fried Rice", "Special Fried Rice", "Chicken Fried Rice",
            "Yeung Chow Fried Rice", "Plain Boiled Rice", "Mushroom Fried Rice",
            // Noodles
            "Chow Mein Noodles", "Singapore Noodles", "Crispy Noodles",
            // Curries
            "Chinese Chicken Curry", "Chinese Beef Curry", "Chinese Prawn Curry",
            "Chips with Curry Sauce"
        ]),

        // Indian Takeaway
        FoodCategory(name: "Indian Takeaway", items: [
            // Starters
            "Poppadom", "Poppadoms", "Onion Bhaji", "Vegetable Samosa", "Meat Samosa",
            "Chicken Pakora", "Prawn Pakora", "Vegetable Pakora",
            "Seekh Kebab", "Chicken Tikka Starter", "Lamb Tikka Starter",
            // Curries
            "Chicken Tikka Masala Takeaway", "Lamb Tikka Masala", "Prawn Tikka Masala",
            "Chicken Korma Takeaway", "Lamb Korma", "Vegetable Korma",
            "Chicken Madras Takeaway", "Lamb Madras", "Prawn Madras",
            "Chicken Vindaloo", "Lamb Vindaloo", "Beef Vindaloo",
            "Chicken Jalfrezi Takeaway", "Lamb Jalfrezi", "Prawn Jalfrezi",
            "Chicken Bhuna", "Lamb Bhuna", "Prawn Bhuna",
            "Chicken Balti Takeaway", "Lamb Balti", "Prawn Balti",
            "Chicken Rogan Josh Takeaway", "Lamb Rogan Josh",
            "Chicken Dhansak", "Lamb Dhansak",
            "Chicken Saag", "Lamb Saag", "Saag Aloo Takeaway",
            "Chicken Pathia", "Lamb Pathia",
            // Biryanis
            "Chicken Biryani Takeaway", "Lamb Biryani Takeaway", "Prawn Biryani",
            "Vegetable Biryani Takeaway", "Special Biryani",
            // Tandoori
            "Tandoori Chicken", "Chicken Tikka", "Lamb Tikka", "Tandoori Mixed Grill",
            // Sides
            "Pilau Rice", "Boiled Rice", "Mushroom Rice", "Keema Rice",
            "Plain Naan", "Garlic Naan", "Peshwari Naan", "Keema Naan",
            "Chapati", "Roti", "Paratha", "Cheese Naan",
            "Tarka Daal", "Daal Makhani", "Bombay Aloo", "Aloo Gobi Takeaway",
            "Chana Masala Takeaway", "Vegetable Curry",
            // Accompaniments
            "Mango Chutney", "Mint Raita", "Lime Pickle", "Onion Salad"
        ]),

        // Kebab Shop
        FoodCategory(name: "Kebab Shop", items: [
            "Doner Kebab", "Doner Meat", "Doner Kebab in Pitta",
            "Doner Kebab in Naan", "Doner Wrap",
            "Chicken Doner", "Chicken Doner Kebab", "Chicken Doner Wrap",
            "Lamb Doner", "Mixed Doner", "Doner Meat and Chips",
            "Shish Kebab", "Lamb Shish", "Chicken Shish", "Kofte Kebab",
            "Chicken Tikka Kebab", "Seekh Kebab Wrap",
            "Kebab Shop Chips", "Chips with Kebab Meat",
            "Kebab Shop Salad", "Chilli Sauce", "Garlic Sauce", "Hot Sauce"
        ]),

        // Five Guys UK
        FoodCategory(name: "Five Guys", items: [
            "Five Guys Hamburger", "Five Guys Cheeseburger", "Five Guys Bacon Burger",
            "Five Guys Bacon Cheeseburger", "Five Guys Little Hamburger",
            "Five Guys Little Cheeseburger", "Five Guys Little Bacon Burger",
            "Five Guys Hot Dog", "Five Guys Cheese Dog", "Five Guys Bacon Dog",
            "Five Guys Veggie Sandwich", "Five Guys Grilled Cheese",
            "Five Guys Fries Regular", "Five Guys Fries Little",
            "Five Guys Cajun Fries", "Five Guys Milkshake"
        ]),

        // Wagamama UK
        FoodCategory(name: "Wagamama", items: [
            "Wagamama Chicken Katsu Curry", "Wagamama Chicken Ramen",
            "Wagamama Pad Thai", "Wagamama Yaki Soba",
            "Wagamama Teriyaki Chicken", "Wagamama Chilli Chicken Ramen",
            "Wagamama Yasai Pad Thai", "Wagamama Yasai Katsu Curry",
            "Wagamama Chicken Gyoza", "Wagamama Prawn Gyoza",
            "Wagamama Edamame", "Wagamama Chicken Steamed Buns",
            "Wagamama Chilli Squid", "Wagamama Duck Gyoza"
        ]),

        // Leon UK
        FoodCategory(name: "Leon", items: [
            "Leon Original Superfood Salad", "Leon Chicken Satay Salad",
            "Leon Moroccan Meatball Hot Box", "Leon Brazilian Chicken Hot Box",
            "Leon Sweet Potato Falafel Wrap", "Leon Grilled Chicken Wrap",
            "Leon LOVe Burger", "Leon Chicken Burger",
            "Leon Baked Fries", "Leon Sweet Potato Fries",
            "Leon Hummus", "Leon Aioli"
        ]),

        // Eat UK
        FoodCategory(name: "Eat (Restaurant)", items: [
            "Eat Chicken Caesar Wrap", "Eat Falafel Wrap", "Eat Tuna Sandwich",
            "Eat Egg & Cress Sandwich", "Eat Ham & Cheese Toastie",
            "Eat Soup", "Eat Macaroni Cheese", "Eat Porridge"
        ]),

        // ============================================
        // MILK & DAIRY
        // ============================================
        FoodCategory(name: "Milk & Dairy", items: [
            // Milk types
            "Whole Milk", "Semi-Skimmed Milk", "Skimmed Milk", "1% Fat Milk",
            "Channel Island Milk", "Jersey Milk", "Organic Whole Milk", "Organic Semi-Skimmed Milk",
            "Lactose Free Milk", "Filtered Milk", "Raw Milk", "UHT Milk", "Long Life Milk",
            // UK Milk brands
            "Cravendale Whole Milk", "Cravendale Semi-Skimmed Milk", "Cravendale Skimmed Milk",
            "Arla Milk", "Arla Organic Milk", "Arla Big Milk", "Arla Lactofree Milk",
            "Yeo Valley Organic Milk", "Graham's Milk",
            // Plant milks
            "Oat Milk", "Almond Milk", "Soy Milk", "Coconut Milk", "Rice Milk", "Hemp Milk", "Cashew Milk",
            "Oatly Oat Milk", "Oatly Barista", "Oatly Chocolate", "Oatly Skinny",
            "Alpro Oat Milk", "Alpro Soya Milk", "Alpro Almond Milk", "Alpro Coconut Milk",
            "Minor Figures Oat Milk", "Califia Farms Oat Milk",
            // Cream
            "Double Cream", "Single Cream", "Whipping Cream", "Clotted Cream", "Soured Cream",
            "Extra Thick Double Cream", "Creme Fraiche", "Half Fat Creme Fraiche",
            "Rodda's Clotted Cream", "Elmlea Double", "Elmlea Single",
            // Butter & spreads
            "Butter", "Unsalted Butter", "Spreadable Butter", "Salted Butter",
            "Lurpak Butter", "Lurpak Spreadable", "Lurpak Lighter",
            "Anchor Butter", "Anchor Spreadable", "Kerrygold Butter",
            "President Butter", "Country Life Butter", "Yeo Valley Butter",
            "Flora", "Flora Light", "Flora Buttery", "Bertolli Spread",
            // Cheese
            "Cheddar Cheese", "Mild Cheddar", "Mature Cheddar", "Extra Mature Cheddar", "Vintage Cheddar",
            "Cathedral City Cheddar", "Cathedral City Mature", "Cathedral City Lighter",
            "Pilgrim's Choice Cheddar", "Seriously Strong Cheddar", "Davidstow Cheddar",
            "Red Leicester", "Double Gloucester", "Stilton", "Blue Stilton",
            "Brie", "Camembert", "Mozzarella", "Parmesan", "Feta", "Halloumi",
            "Goat's Cheese", "Wensleydale", "Cottage Cheese", "Cream Cheese", "Ricotta",
            "Philadelphia Cream Cheese", "Philadelphia Light", "Boursin",
            "Babybel", "Mini Babybel", "Dairylea Triangles", "Laughing Cow",
            "Grated Cheddar", "Grated Mozzarella", "Cheese Slices", "Cheese Strings",
            // Yoghurt
            "Natural Yoghurt", "Greek Yoghurt", "Low Fat Yoghurt", "Fat Free Yoghurt",
            "Strawberry Yoghurt", "Vanilla Yoghurt", "Fruit Yoghurt", "Skyr", "Kefir",
            "Fage Total", "Fage Total 0%", "Fage Total 2%",
            "Yeo Valley Natural Yoghurt", "Yeo Valley Fruit Yoghurt",
            "Muller Corner", "Muller Light", "Muller Rice", "Muller Bliss",
            "Activia Yoghurt", "Activia Intensely Creamy", "Danone Yoghurt",
            "Actimel", "Yakult", "Onken Natural Yoghurt",
            "Arla Skyr", "Arla Protein Yoghurt",
            "Alpro Yoghurt", "Alpro Greek Style"
        ]),

        // ============================================
        // BREAD & BAKERY
        // ============================================
        FoodCategory(name: "Bread & Bakery", items: [
            // Bread types
            "White Bread", "Wholemeal Bread", "Brown Bread", "Granary Bread", "Seeded Bread",
            "Sourdough", "Rye Bread", "Multigrain Bread", "50/50 Bread",
            "White Sliced Bread", "Wholemeal Sliced Bread", "Thick Sliced", "Medium Sliced",
            "Farmhouse Bread", "Bloomer", "Tiger Bread",
            "Bread Roll", "White Roll", "Brown Roll", "Crusty Roll", "Brioche Roll",
            "Baguette", "French Stick", "Ciabatta", "Focaccia", "Panini",
            "Pitta Bread", "White Pitta", "Wholemeal Pitta",
            "Naan Bread", "Plain Naan", "Garlic Naan", "Peshwari Naan",
            "Tortilla Wrap", "Flour Tortilla", "Wholemeal Wrap", "Spinach Wrap",
            "Crumpet", "English Muffin", "Bagel", "Plain Bagel", "Sesame Bagel",
            "Brioche", "Brioche Loaf",
            // Bread brands
            "Warburtons White", "Warburtons Wholemeal", "Warburtons Toastie", "Warburtons Crumpets",
            "Warburtons Thins", "Warburtons Wraps", "Warburtons Bagels",
            "Hovis White", "Hovis Wholemeal", "Hovis Best of Both", "Hovis Granary",
            "Kingsmill White", "Kingsmill Wholemeal", "Kingsmill 50/50",
            "Roberts Bakery", "Genius Gluten Free",
            "Mission Wraps", "Old El Paso Wraps", "New York Bakery Bagels",
            // Sweet bakery
            "Croissant", "Pain au Chocolat", "Danish Pastry", "Cinnamon Swirl",
            "Scone", "Plain Scone", "Fruit Scone", "Cheese Scone",
            "Hot Cross Bun", "Chelsea Bun", "Iced Bun",
            "Doughnut", "Jam Doughnut", "Ring Doughnut", "Custard Doughnut",
            "Krispy Kreme Original Glazed", "Krispy Kreme Chocolate",
            "Muffin", "Blueberry Muffin", "Chocolate Chip Muffin",
            "Flapjack", "Brownie", "Millionaire Shortbread"
        ]),

        // ============================================
        // EGGS
        // ============================================
        FoodCategory(name: "Eggs", items: [
            "Egg", "Large Egg", "Medium Egg", "Small Egg",
            "Free Range Egg", "Free Range Large Egg", "Free Range Medium Egg",
            "Organic Egg", "Organic Free Range Egg", "Barn Egg",
            "Duck Egg", "Quail Egg",
            "Boiled Egg", "Soft Boiled Egg", "Hard Boiled Egg",
            "Fried Egg", "Poached Egg", "Scrambled Egg",
            "Omelette", "Cheese Omelette",
            "Egg White", "Egg Yolk",
            "Clarence Court Eggs", "Happy Egg Co", "Two Chicks Egg White"
        ]),

        // ============================================
        // MEAT & POULTRY
        // ============================================
        FoodCategory(name: "Meat & Poultry", items: [
            // Chicken
            "Chicken Breast", "Chicken Breast Fillet", "Chicken Mini Fillets",
            "Chicken Thigh", "Chicken Drumstick", "Chicken Wing", "Chicken Leg",
            "Whole Chicken", "Roast Chicken", "Rotisserie Chicken",
            "Chicken Mince", "Chicken Strips", "Diced Chicken",
            "Free Range Chicken", "Organic Chicken", "Corn Fed Chicken",
            // Beef
            "Beef Mince", "Lean Beef Mince", "5% Fat Beef Mince", "20% Fat Beef Mince",
            "Beef Steak", "Sirloin Steak", "Rump Steak", "Ribeye Steak", "Fillet Steak",
            "Beef Roasting Joint", "Topside", "Silverside", "Beef Brisket",
            "Beef Burger", "Diced Beef", "Braising Steak", "Stewing Steak",
            // Pork
            "Pork Chop", "Pork Loin", "Pork Belly", "Pork Ribs",
            "Pork Mince", "Pork Sausage", "Pork Steak", "Diced Pork",
            "Pulled Pork", "Pork Shoulder",
            // Lamb
            "Lamb Chop", "Lamb Mince", "Lamb Leg", "Lamb Shoulder", "Lamb Shank",
            "Diced Lamb", "Lamb Steak",
            // Turkey
            "Turkey Breast", "Turkey Mince", "Turkey Steak",
            "Turkey Bacon", "Turkey Sausage",
            // Bacon
            "Bacon", "Streaky Bacon", "Back Bacon", "Smoked Bacon", "Unsmoked Bacon",
            "Bacon Rashers", "Bacon Medallions", "Bacon Lardons", "Pancetta",
            // Ham
            "Ham", "Cooked Ham", "Sliced Ham", "Honey Roast Ham", "Smoked Ham",
            "Gammon", "Gammon Steak", "Parma Ham", "Prosciutto",
            // Sausages
            "Pork Sausage", "Cumberland Sausage", "Lincolnshire Sausage",
            "Chipolata", "Cocktail Sausage", "Chorizo",
            "Richmond Sausages", "Walls Sausages", "Heck Sausages",
            "Peperami", "Scotch Egg", "Pork Pie",
            // Deli meats
            "Sliced Chicken", "Sliced Turkey", "Salami", "Pepperoni", "Pastrami",
            // Plant-based
            "Quorn Mince", "Quorn Pieces", "Quorn Sausages", "Quorn Fillets",
            "Beyond Burger", "Beyond Mince", "Beyond Sausage",
            "Linda McCartney Sausages", "Linda McCartney Burgers"
        ]),

        // ============================================
        // FISH & SEAFOOD
        // ============================================
        FoodCategory(name: "Fish & Seafood", items: [
            // Salmon
            "Salmon Fillet", "Salmon Steak", "Smoked Salmon", "Scottish Smoked Salmon",
            "Hot Smoked Salmon", "Scottish Salmon", "Organic Salmon",
            // Cod
            "Cod Fillet", "Cod Loin", "Battered Cod", "Breaded Cod", "Smoked Cod",
            // Haddock
            "Haddock Fillet", "Smoked Haddock", "Battered Haddock",
            // Tuna
            "Tuna Steak", "Tinned Tuna", "Tuna in Brine", "Tuna in Spring Water",
            "John West Tuna", "Princes Tuna",
            // Other white fish
            "Sea Bass", "Trout", "Rainbow Trout", "Plaice", "Sole", "Monkfish", "Halibut",
            "Tilapia", "Basa", "Pollock",
            // Oily fish
            "Mackerel Fillet", "Smoked Mackerel", "Peppered Mackerel",
            "Sardines", "Tinned Sardines", "Anchovies", "Kippers",
            // Shellfish
            "Prawns", "King Prawns", "Tiger Prawns", "Cooked Prawns", "Raw Prawns",
            "Crab", "Crab Meat", "Crab Sticks", "Lobster",
            "Mussels", "Scallops", "Squid", "Calamari",
            // Fish products
            "Fish Fingers", "Birds Eye Fish Fingers", "Fish Cake",
            "Fish Pie Mix", "Battered Fish", "Breaded Fish", "Scampi"
        ]),

        // ============================================
        // FRUITS
        // ============================================
        FoodCategory(name: "Fruits", items: [
            // Apples
            "Apple", "Gala Apple", "Braeburn Apple", "Pink Lady Apple", "Granny Smith",
            "Cox Apple", "Jazz Apple", "Fuji Apple", "Cooking Apple", "Bramley Apple",
            // Citrus
            "Orange", "Navel Orange", "Satsuma", "Clementine", "Mandarin", "Easy Peeler",
            "Grapefruit", "Pink Grapefruit", "Lemon", "Lime",
            // Bananas
            "Banana", "Fairtrade Banana", "Organic Banana", "Plantain",
            // Berries
            "Strawberries", "Raspberries", "Blueberries", "Blackberries",
            "Cherries", "Mixed Berries", "Forest Fruits",
            // Stone fruits
            "Pear", "Conference Pear", "Peach", "Nectarine", "Plum", "Apricot",
            // Grapes
            "Grapes", "Red Grapes", "Green Grapes", "Black Grapes", "Seedless Grapes",
            // Tropical
            "Mango", "Pineapple", "Kiwi", "Papaya", "Passion Fruit", "Lychee",
            "Coconut", "Pomegranate", "Fig", "Dragon Fruit",
            // Melons
            "Melon", "Cantaloupe", "Honeydew Melon", "Watermelon",
            // Avocado
            "Avocado", "Ripe Avocado", "Hass Avocado",
            // Dried fruits
            "Raisins", "Sultanas", "Dried Apricot", "Dried Mango", "Dates", "Medjool Date",
            "Prunes", "Dried Cranberries", "Mixed Dried Fruit"
        ]),

        // ============================================
        // VEGETABLES
        // ============================================
        FoodCategory(name: "Vegetables", items: [
            // Potatoes
            "Potato", "New Potatoes", "Baby Potatoes", "Baking Potato", "Jacket Potato",
            "Maris Piper", "King Edward", "Sweet Potato",
            "Mashed Potato", "Roast Potato", "Boiled Potato",
            // Root vegetables
            "Carrot", "Baby Carrot", "Parsnip", "Beetroot", "Swede", "Turnip", "Celeriac",
            // Onion family
            "Onion", "White Onion", "Red Onion", "Spring Onion", "Shallot", "Leek",
            "Garlic", "Garlic Clove",
            // Brassicas
            "Broccoli", "Tenderstem Broccoli", "Cauliflower", "Cabbage", "Red Cabbage",
            "Brussels Sprouts", "Kale", "Cavolo Nero", "Pak Choi",
            // Leafy greens
            "Spinach", "Baby Spinach", "Lettuce", "Iceberg Lettuce", "Cos Lettuce",
            "Little Gem Lettuce", "Rocket", "Watercress", "Salad Leaves", "Mixed Salad",
            // Beans & pods
            "Peas", "Garden Peas", "Frozen Peas", "Petit Pois",
            "Mangetout", "Sugar Snap Peas", "Green Beans", "Runner Beans", "Broad Beans",
            "Edamame",
            // Squash
            "Courgette", "Butternut Squash", "Pumpkin", "Marrow",
            // Nightshades
            "Tomato", "Cherry Tomatoes", "Vine Tomatoes", "Beef Tomato",
            "Tinned Tomatoes", "Chopped Tomatoes", "Passata", "Tomato Puree",
            "Pepper", "Red Pepper", "Green Pepper", "Yellow Pepper", "Mixed Peppers",
            "Chilli", "Red Chilli", "Green Chilli", "Jalapeno",
            "Aubergine",
            // Mushrooms
            "Mushrooms", "Button Mushrooms", "Chestnut Mushrooms", "Portobello Mushrooms",
            "Shiitake Mushrooms", "Oyster Mushrooms",
            // Other
            "Cucumber", "Celery", "Asparagus", "Fennel", "Artichoke",
            "Corn on the Cob", "Sweetcorn", "Baby Corn",
            // Frozen vegetables
            "Frozen Peas", "Birds Eye Peas", "Frozen Sweetcorn", "Frozen Mixed Vegetables",
            "Frozen Broccoli", "Frozen Spinach"
        ]),

        // ============================================
        // RICE, PASTA & GRAINS
        // ============================================
        FoodCategory(name: "Rice, Pasta & Grains", items: [
            // Rice
            "White Rice", "Brown Rice", "Basmati Rice", "Long Grain Rice",
            "Jasmine Rice", "Arborio Rice", "Risotto Rice", "Wild Rice",
            "Easy Cook Rice", "Sushi Rice",
            "Tilda Basmati Rice", "Tilda Pure Basmati", "Tilda Microwave Rice",
            "Uncle Ben's Rice", "Uncle Ben's Microwave Rice",
            "Microwave Rice", "Microwave Pilau Rice", "Microwave Egg Fried Rice",
            // Pasta
            "Spaghetti", "Linguine", "Tagliatelle", "Fettuccine", "Pappardelle",
            "Penne", "Rigatoni", "Fusilli", "Farfalle", "Conchiglie",
            "Macaroni", "Orzo", "Lasagne Sheets", "Cannelloni",
            "Tortellini", "Ravioli", "Gnocchi",
            "Wholewheat Pasta", "Gluten Free Pasta",
            "Fresh Pasta", "Fresh Tagliatelle", "Fresh Ravioli",
            "De Cecco Pasta", "Barilla Pasta", "Napolina Pasta",
            // Noodles
            "Egg Noodles", "Rice Noodles", "Udon Noodles", "Soba Noodles",
            "Ramen Noodles", "Instant Noodles", "Pot Noodle",
            "Blue Dragon Noodles", "Sharwood's Noodles",
            // Grains
            "Couscous", "Giant Couscous", "Bulgur Wheat",
            "Quinoa", "Pearl Barley", "Spelt",
            "Polenta",
            // Oats
            "Porridge Oats", "Rolled Oats", "Jumbo Oats", "Steel Cut Oats",
            "Quaker Oats", "Scott's Porage Oats"
        ]),

        // ============================================
        // BEANS & PULSES
        // ============================================
        FoodCategory(name: "Beans & Pulses", items: [
            "Baked Beans", "Heinz Baked Beans", "Heinz No Added Sugar Beans", "Branston Beans",
            "Kidney Beans", "Red Kidney Beans", "Tinned Kidney Beans",
            "Chickpeas", "Tinned Chickpeas",
            "Butter Beans", "Black Beans", "Cannellini Beans", "Borlotti Beans",
            "Haricot Beans", "Mixed Beans", "Four Bean Mix",
            "Red Lentils", "Green Lentils", "Puy Lentils", "Brown Lentils",
            "Split Peas", "Mushy Peas", "Marrowfat Peas",
            "Tofu", "Firm Tofu", "Silken Tofu", "Smoked Tofu",
            "Tempeh", "Falafel", "Hummus", "Houmous"
        ]),

        // ============================================
        // CONDIMENTS & SAUCES
        // ============================================
        FoodCategory(name: "Condiments & Sauces", items: [
            // Table sauces
            "Tomato Ketchup", "Heinz Tomato Ketchup", "HP Sauce", "Brown Sauce",
            "Mayonnaise", "Hellmann's Mayonnaise", "Hellmann's Light Mayo",
            "Salad Cream", "Heinz Salad Cream",
            // Mustard
            "English Mustard", "Colman's English Mustard", "Dijon Mustard", "Wholegrain Mustard",
            // Asian sauces
            "Soy Sauce", "Kikkoman Soy Sauce", "Tamari",
            "Teriyaki Sauce", "Oyster Sauce", "Hoisin Sauce", "Sweet Chilli Sauce",
            "Sriracha", "Worcestershire Sauce", "Lea & Perrins",
            // Hot sauces
            "Tabasco", "Frank's Red Hot", "Nando's Peri-Peri Sauce",
            // British
            "Mint Sauce", "Horseradish Sauce", "Apple Sauce", "Cranberry Sauce", "Tartare Sauce",
            // Oils
            "Olive Oil", "Extra Virgin Olive Oil", "Vegetable Oil", "Sunflower Oil",
            "Rapeseed Oil", "Sesame Oil", "Coconut Oil", "Fry Light",
            // Vinegar
            "Malt Vinegar", "Sarson's Vinegar", "Balsamic Vinegar", "White Wine Vinegar",
            "Apple Cider Vinegar", "Rice Vinegar",
            // Sweet
            "Honey", "Clear Honey", "Runny Honey", "Manuka Honey", "Rowse Honey",
            "Golden Syrup", "Lyle's Golden Syrup", "Maple Syrup", "Agave Syrup",
            // Cooking sauces
            "Pasta Sauce", "Dolmio Bolognese", "Pesto", "Green Pesto", "Sacla Pesto",
            "Curry Sauce", "Korma Sauce", "Tikka Masala Sauce",
            "Patak's Curry Paste", "Sharwood's Curry Sauce",
            "Stir Fry Sauce", "Blue Dragon Sauce"
        ]),

        // ============================================
        // SPREADS
        // ============================================
        FoodCategory(name: "Spreads", items: [
            // Jam
            "Jam", "Strawberry Jam", "Raspberry Jam", "Apricot Jam",
            "Reduced Sugar Jam", "Marmalade", "Orange Marmalade",
            "Hartley's Jam", "Bonne Maman Jam", "Tiptree Jam",
            // Nut butters
            "Peanut Butter", "Smooth Peanut Butter", "Crunchy Peanut Butter",
            "Almond Butter", "Cashew Butter",
            "Sun-Pat Peanut Butter", "Whole Earth Peanut Butter", "Pip & Nut",
            // Chocolate spreads
            "Nutella", "Chocolate Spread", "Cadbury Chocolate Spread",
            "Lotus Biscoff Spread",
            // Savoury
            "Marmite", "Bovril", "Sandwich Spread", "Lemon Curd"
        ]),

        // ============================================
        // BREAKFAST CEREALS
        // ============================================
        FoodCategory(name: "Breakfast Cereals", items: [
            // Flakes
            "Cornflakes", "Kellogg's Corn Flakes", "Bran Flakes", "All-Bran",
            "Frosties", "Kellogg's Frosties", "Special K", "Special K Red Berries",
            // Wheat
            "Weetabix", "Weetabix Original", "Weetabix Protein",
            "Shredded Wheat", "Shreddies", "Frosted Shreddies",
            // Puffed
            "Rice Krispies", "Coco Pops", "Sugar Puffs",
            // Oat
            "Cheerios", "Honey Cheerios", "Crunchy Nut Cornflakes",
            // Porridge
            "Porridge", "Ready Brek", "Quaker Oat So Simple",
            // Muesli & Granola
            "Muesli", "Alpen", "Alpen No Added Sugar",
            "Granola", "Honey Granola", "Jordans Granola",
            // Kids
            "Weetos", "Cookie Crisp", "Krave", "Lion Cereal",
            // Healthy
            "Grape-Nuts", "Fibre One", "Nestle Fitness"
        ]),

        // ============================================
        // CRISPS & SAVOURY SNACKS
        // ============================================
        FoodCategory(name: "Crisps & Savoury Snacks", items: [
            // Walkers
            "Walkers Crisps", "Walkers Ready Salted", "Walkers Cheese and Onion",
            "Walkers Salt and Vinegar", "Walkers Prawn Cocktail",
            "Walkers Sensations", "Walkers Max", "Walkers Baked",
            // Kettle
            "Kettle Chips", "Kettle Lightly Salted", "Kettle Mature Cheddar",
            // Tyrrell's
            "Tyrrell's Crisps", "Tyrrell's Sea Salt",
            // McCoy's
            "McCoy's Crisps", "McCoy's Ridge Cut",
            // Pringles
            "Pringles", "Pringles Original", "Pringles Sour Cream", "Pringles Salt and Vinegar",
            // Doritos
            "Doritos", "Doritos Cool Original", "Doritos Chilli Heatwave", "Doritos Tangy Cheese",
            // Baked snacks
            "Quavers", "Wotsits", "Monster Munch", "Frazzles", "Nik Naks",
            "Skips", "Squares", "French Fries", "Space Raiders", "Hula Hoops",
            // Popcorn
            "Popcorn", "Sweet Popcorn", "Salted Popcorn", "Butterkist", "Propercorn",
            // Pretzels
            "Pretzels", "Twiglets", "Mini Cheddars",
            // Crackers
            "Ritz Crackers", "TUC Crackers", "Jacob's Crackers",
            // Nuts
            "Mixed Nuts", "Salted Peanuts", "Dry Roasted Peanuts", "Cashews", "KP Nuts"
        ]),

        // ============================================
        // BISCUITS
        // ============================================
        FoodCategory(name: "Biscuits", items: [
            // Digestives
            "Digestive Biscuits", "McVitie's Digestives", "Chocolate Digestive",
            "Milk Chocolate Digestive", "Dark Chocolate Digestive",
            // Tea biscuits
            "Rich Tea", "McVitie's Rich Tea", "Nice Biscuits",
            // Hobnobs
            "Hobnobs", "McVitie's Hobnobs", "Chocolate Hobnobs",
            // Cream biscuits
            "Custard Creams", "Bourbons", "Oreo", "Oreo Original", "Oreo Double Stuff",
            "Party Rings", "Jammie Dodgers",
            // Shortbread
            "Shortbread", "Walker's Shortbread",
            // Chocolate biscuits
            "Jaffa Cakes", "McVitie's Jaffa Cakes",
            "Penguin", "Club Biscuit", "Blue Riband",
            "KitKat Biscuit", "Twix Biscuit",
            // Wafers
            "Pink Wafer", "Tunnock's Wafer", "Tunnock's Tea Cake",
            // Premium
            "Lotus Biscoff", "Fox's Biscuits", "Border Biscuits",
            // Savoury
            "Cream Crackers", "Jacob's Cream Crackers",
            "Ryvita", "Rice Cakes",
            // Cookies
            "Cookie", "Chocolate Chip Cookie", "Maryland Cookies"
        ]),

        // ============================================
        // CHOCOLATE & SWEETS
        // ============================================
        FoodCategory(name: "Chocolate & Sweets", items: [
            // Cadbury
            "Dairy Milk", "Cadbury Dairy Milk", "Dairy Milk Whole Nut", "Dairy Milk Fruit and Nut",
            "Dairy Milk Caramel", "Cadbury Flake", "Cadbury Twirl", "Cadbury Crunchie",
            "Cadbury Wispa", "Cadbury Boost", "Cadbury Double Decker",
            "Cadbury Buttons", "Cadbury Fingers", "Cadbury Roses", "Cadbury Heroes",
            "Cadbury Creme Egg", "Cadbury Mini Eggs",
            // Galaxy
            "Galaxy", "Galaxy Smooth Milk", "Galaxy Caramel",
            "Galaxy Minstrels", "Maltesers", "M&Ms", "M&Ms Peanut",
            // Mars
            "Mars Bar", "Snickers", "Milky Way", "Bounty", "Twix", "Topic",
            // Nestle
            "KitKat", "KitKat 4 Finger", "KitKat Chunky",
            "Aero", "Aero Mint", "Yorkie", "Toffee Crisp", "Munchies",
            "Smarties", "Milkybar", "Quality Street", "Rolo", "Lion Bar",
            "After Eight",
            // Ferrero
            "Ferrero Rocher", "Kinder Bueno", "Kinder Surprise", "Kinder Chocolate",
            // Lindt
            "Lindt", "Lindt Excellence", "Lindt Lindor",
            // Other
            "Toblerone", "Terry's Chocolate Orange",
            "Reese's Peanut Butter Cups",
            // Sweets
            "Haribo", "Haribo Tangfastics", "Haribo Starmix", "Haribo Goldbears",
            "Wine Gums", "Fruit Pastilles", "Jelly Babies", "Jelly Tots",
            "Skittles", "Starburst",
            // Mints
            "Polo", "Polo Mints", "Extra Strong Mints", "Tic Tac",
            // Toffees
            "Werther's Original", "Toffee"
        ]),

        // ============================================
        // DRINKS
        // ============================================
        FoodCategory(name: "Drinks", items: [
            // Juices
            "Orange Juice", "Fresh Orange Juice", "Tropicana Orange Juice",
            "Apple Juice", "Copella Apple Juice", "Cranberry Juice",
            "Grape Juice", "Pineapple Juice", "Tomato Juice",
            // Smoothies
            "Smoothie", "Innocent Smoothie", "Naked Smoothie",
            // Squash
            "Squash", "Orange Squash", "Blackcurrant Squash",
            "Robinsons Squash", "Robinsons Orange", "Vimto Squash", "Ribena Squash",
            // Cola
            "Coca-Cola", "Coca-Cola Zero", "Diet Coke",
            "Pepsi", "Pepsi Max", "Diet Pepsi", "Dr Pepper",
            // Lemonade
            "Lemonade", "7UP", "Sprite", "Sprite Zero",
            // Orange
            "Fanta", "Fanta Orange", "Tango", "Tango Orange", "Orangina",
            // Other fizzy
            "Irn-Bru", "Lucozade", "Lucozade Energy", "Lucozade Sport",
            "Ribena", "Vimto", "Appletiser", "J2O", "San Pellegrino",
            // Energy drinks
            "Red Bull", "Monster Energy", "Relentless", "Rockstar",
            // Water
            "Water", "Still Water", "Sparkling Water",
            "Evian", "Volvic", "Highland Spring", "Buxton", "Perrier",
            "Tonic Water", "Fever-Tree Tonic",
            // Hot drinks
            "Tea", "English Breakfast Tea", "Earl Grey",
            "PG Tips", "Yorkshire Tea", "Tetley", "Twinings",
            "Green Tea", "Peppermint Tea", "Camomile Tea",
            "Coffee", "Instant Coffee", "Ground Coffee",
            "Nescafe", "Nescafe Gold", "Kenco", "Lavazza",
            "Hot Chocolate", "Cadbury Hot Chocolate", "Galaxy Hot Chocolate"
        ]),

        // ============================================
        // READY MEALS
        // ============================================
        FoodCategory(name: "Ready Meals", items: [
            // Italian
            "Lasagne", "Beef Lasagne", "Vegetable Lasagne",
            "Spaghetti Bolognese", "Macaroni Cheese", "Carbonara", "Cannelloni",
            // British
            "Shepherd's Pie", "Cottage Pie", "Fish Pie",
            "Bangers and Mash", "Toad in the Hole", "Beef Stew",
            "Roast Dinner", "Sunday Roast", "Steak Pie", "Chicken Pie",
            // Indian
            "Chicken Tikka Masala", "Chicken Korma", "Chicken Jalfrezi", "Chicken Madras",
            "Lamb Curry", "Vegetable Curry", "Biryani", "Chicken Biryani",
            "Balti", "Rogan Josh", "Saag Aloo", "Chana Masala",
            // Chinese
            "Sweet and Sour Chicken", "Chicken Chow Mein", "Egg Fried Rice",
            "Crispy Chilli Beef", "Singapore Noodles",
            // Thai
            "Thai Green Curry", "Thai Red Curry", "Pad Thai", "Massaman Curry",
            // Pizza
            "Pizza", "Margherita Pizza", "Pepperoni Pizza", "Hawaiian Pizza", "Meat Feast Pizza",
            "Dr Oetker Ristorante", "Chicago Town Pizza", "Goodfella's Pizza",
            // Frozen convenience
            "Fish and Chips", "Oven Chips", "McCain Chips", "McCain Home Chips",
            "Potato Waffles", "Birds Eye Waffles", "Hash Browns",
            "Chicken Nuggets", "Birds Eye Chicken Nuggets", "Chicken Dippers",
            "Chicken Kiev", "Chicken Goujons",
            "Aunt Bessie's Yorkshire Puddings", "Yorkshire Puddings"
        ]),

        // ============================================
        // SOUP
        // ============================================
        FoodCategory(name: "Soup", items: [
            "Tomato Soup", "Cream of Tomato Soup", "Heinz Cream of Tomato",
            "Chicken Soup", "Chicken Noodle Soup", "Vegetable Soup",
            "Mushroom Soup", "Cream of Mushroom Soup",
            "Minestrone", "Leek and Potato Soup", "Oxtail Soup",
            "Pea and Ham Soup", "Lentil Soup",
            "Carrot and Coriander Soup", "Butternut Squash Soup",
            "Heinz Soup", "Baxters Soup", "Covent Garden Soup"
        ]),

        // ============================================
        // FROZEN FOODS
        // ============================================
        FoodCategory(name: "Frozen Foods", items: [
            // Ice cream
            "Ice Cream", "Vanilla Ice Cream", "Chocolate Ice Cream",
            "Ben & Jerry's", "Ben & Jerry's Cookie Dough", "Ben & Jerry's Chocolate Fudge Brownie",
            "Haagen-Dazs", "Haagen-Dazs Vanilla", "Haagen-Dazs Salted Caramel",
            "Magnum", "Magnum Classic", "Magnum White",
            "Cornetto", "Solero", "Feast", "Twister", "Calippo",
            "Carte D'Or", "Viennetta",
            // Frozen fruit
            "Frozen Fruit", "Frozen Berries", "Frozen Mango",
            // Frozen meat
            "Frozen Chicken Breast", "Frozen Prawns", "Frozen Mince", "Frozen Burgers",
            // Frozen bread
            "Frozen Bread", "Frozen Croissants", "Frozen Garlic Bread"
        ]),

        // ============================================
        // KITCHEN STAPLES
        // ============================================
        FoodCategory(name: "Kitchen Staples", items: [
            // Flour
            "Plain Flour", "Self-Raising Flour", "Strong Bread Flour", "Wholemeal Flour",
            "Cornflour", "Rice Flour", "Almond Flour",
            // Sugar
            "Granulated Sugar", "Caster Sugar", "Icing Sugar", "Brown Sugar",
            "Demerara Sugar", "Muscovado Sugar",
            // Baking
            "Baking Powder", "Bicarbonate of Soda", "Yeast", "Dried Yeast",
            "Vanilla Extract", "Cocoa Powder", "Chocolate Chips",
            // Stock & gravy
            "Stock Cube", "Chicken Stock Cube", "Beef Stock Cube", "Vegetable Stock Cube",
            "Oxo", "Oxo Cubes", "Knorr Stock Cubes",
            "Gravy Granules", "Bisto Gravy"
        ])
    ]

    struct FoodCategory {
        let name: String
        let items: [String]
    }

    // MARK: - Scan Results

    struct CompletenessResults {
        let totalCategories: Int
        let totalExpectedItems: Int
        let foundItems: Int
        let missingItems: [MissingItem]
        let categoryBreakdown: [CategoryResult]
        let completenessPercentage: Double
        let scanDate: Date

        struct MissingItem: Identifiable {
            let id = UUID()
            let name: String
            let category: String
            var suggestedData: SuggestedFoodData?
        }

        struct CategoryResult: Identifiable, Hashable {
            let id = UUID()
            let name: String
            let expectedCount: Int
            let foundCount: Int
            let missingItems: [String]

            var completeness: Double {
                guard expectedCount > 0 else { return 100 }
                return Double(foundCount) / Double(expectedCount) * 100
            }

            static func == (lhs: CategoryResult, rhs: CategoryResult) -> Bool {
                lhs.id == rhs.id
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }
    }

    struct SuggestedFoodData {
        let name: String
        let brand: String?
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double?
        let sugar: Double?
        let sodium: Double?
        let saturatedFat: Double?
        let source: String
        let barcode: String?
        let imageURL: String?
        let ingredientsText: String?

        // Serving information
        let servingDescription: String?
        let servingSizeG: Double?
        let isPerUnit: Bool  // True for meals like Big Mac where nutrition is per item

        // For per-unit items, these are the actual per-unit values
        let perUnitCalories: Double?
        let perUnitProtein: Double?
        let perUnitCarbs: Double?
        let perUnitFat: Double?
    }

    // MARK: - Scanning

    func cancelScan() {
        isCancelled = true
    }

    func scanForCompleteness(foods: [FoodItem]) async {
        isScanning = true
        isCancelled = false
        scanProgress = 0
        scanResults = nil
        error = nil

        var missingItems: [CompletenessResults.MissingItem] = []
        var categoryResults: [CompletenessResults.CategoryResult] = []
        var totalFound = 0

        let totalCategories = Self.essentialCategories.count

        for (index, category) in Self.essentialCategories.enumerated() {
            if isCancelled { break }

            currentCategory = category.name
            scanProgress = Double(index) / Double(totalCategories)

            var foundInCategory = 0
            var missingInCategory: [String] = []

            for expectedItem in category.items {
                if isCancelled { break }

                // Check if this item (or similar) exists in database
                let found = foods.contains { food in
                    matchesExpectedItem(food: food, expected: expectedItem)
                }

                if found {
                    foundInCategory += 1
                    totalFound += 1
                } else {
                    missingInCategory.append(expectedItem)
                    missingItems.append(CompletenessResults.MissingItem(
                        name: expectedItem,
                        category: category.name,
                        suggestedData: nil
                    ))
                }
            }

            categoryResults.append(CompletenessResults.CategoryResult(
                name: category.name,
                expectedCount: category.items.count,
                foundCount: foundInCategory,
                missingItems: missingInCategory
            ))
        }

        let totalExpected = Self.essentialCategories.reduce(0) { $0 + $1.items.count }

        let now = Date()
        scanResults = CompletenessResults(
            totalCategories: totalCategories,
            totalExpectedItems: totalExpected,
            foundItems: totalFound,
            missingItems: missingItems,
            categoryBreakdown: categoryResults,
            completenessPercentage: totalExpected > 0 ? Double(totalFound) / Double(totalExpected) * 100 : 0,
            scanDate: now
        )

        // Update cache status
        hasCachedResults = true
        lastScanDate = now
        cachedFoods = foods
        cachedFoodsCount = foods.count

        scanProgress = 1.0
        currentCategory = ""
        isScanning = false
    }

    /// Check if a food matches an expected item (strict matching)
    /// Only matches if the food is actually the expected item, not just contains some words
    private func matchesExpectedItem(food: FoodItem, expected: String) -> Bool {
        let foodName = food.name.lowercased().trimmingCharacters(in: .whitespaces)
        let foodBrand = (food.brand ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        let expectedLower = expected.lowercased().trimmingCharacters(in: .whitespaces)

        // Exact match on name
        if foodName == expectedLower {
            return true
        }

        // Exact match on brand (for items like "J20" where brand = item name)
        if !foodBrand.isEmpty && foodBrand == expectedLower {
            return true
        }

        // Brand + name = expected (e.g., brand "McDonald's" + name "Big Mac" = "McDonald's Big Mac")
        let brandPlusName = "\(foodBrand) \(foodName)".trimmingCharacters(in: .whitespaces)
        if brandPlusName == expectedLower {
            return true
        }

        // Name + brand = expected (alternate order)
        let namePlusBrand = "\(foodName) \(foodBrand)".trimmingCharacters(in: .whitespaces)
        if namePlusBrand == expectedLower {
            return true
        }

        // Food name contains expected as a word (for brand searches like "J20")
        // Only match if expected is a single word and appears as a complete word in name
        if !expectedLower.contains(" ") && expectedLower.count >= 2 {
            let nameWords = foodName.split(separator: " ").map { String($0).lowercased() }
            if nameWords.contains(expectedLower) {
                return true
            }
            // Also check brand words
            let brandWords = foodBrand.split(separator: " ").map { String($0).lowercased() }
            if brandWords.contains(expectedLower) {
                return true
            }
        }

        // Name matches expected without brand prefix
        // e.g., expected "McDonald's Big Mac" matches name "Big Mac" with brand "McDonald's"
        let expectedWords = expectedLower.split(separator: " ").map { String($0) }
        if expectedWords.count >= 2 {
            // Check if first word(s) match brand and rest matches name
            if !foodBrand.isEmpty {
                // Try removing brand from expected and see if rest matches name
                if expectedLower.hasPrefix(foodBrand) {
                    let remainder = String(expectedLower.dropFirst(foodBrand.count)).trimmingCharacters(in: .whitespaces)
                    if remainder == foodName || foodName.hasPrefix(remainder) || remainder.hasPrefix(foodName) {
                        return true
                    }
                }
            }
        }

        // Check if food name starts with expected (for partial matches like "Whole Milk" matching "Whole Milk Semi-Skimmed")
        if foodName.hasPrefix(expectedLower) && expectedLower.count >= 5 {
            return true
        }

        // Check if expected starts with food name (for when DB has shorter name)
        if expectedLower.hasPrefix(foodName) && foodName.count >= 5 {
            return true
        }

        return false
    }

    // MARK: - Fetch Data from Online Sources

    func fetchSuggestedDataForMissingItems(_ missingItems: [CompletenessResults.MissingItem]) async -> [CompletenessResults.MissingItem] {
        var updatedItems: [CompletenessResults.MissingItem] = []

        isFetching = true
        isFetchCancelled = false
        fetchedCount = 0
        totalToFetch = missingItems.count
        fetchProgress = 0

        for var item in missingItems {
            if isFetchCancelled {
                // Add remaining items without fetching
                updatedItems.append(item)
                continue
            }

            currentCategory = "Fetching: \(item.name)"

            // Try to find data from Open Food Facts, with enhanced search for meals
            if let data = await searchOpenFoodFacts(query: item.name, category: item.category) {
                item.suggestedData = data
            }

            updatedItems.append(item)
            fetchedCount += 1
            fetchProgress = Double(fetchedCount) / Double(totalToFetch)
        }

        currentCategory = ""
        isFetching = false
        fetchProgress = 1.0
        return updatedItems
    }

    private func searchOpenFoodFacts(query: String, category: String) async -> SuggestedFoodData? {
        // Determine if this is likely a per-unit meal (fast food, takeaway)
        let isFastFoodCategory = category.lowercased().contains("mcdonald") ||
            category.lowercased().contains("kfc") ||
            category.lowercased().contains("burger king") ||
            category.lowercased().contains("nando") ||
            category.lowercased().contains("greggs") ||
            category.lowercased().contains("subway") ||
            category.lowercased().contains("pizza") ||
            category.lowercased().contains("chinese") ||
            category.lowercased().contains("indian") ||
            category.lowercased().contains("kebab") ||
            category.lowercased().contains("takeaway") ||
            category.lowercased().contains("five guys") ||
            category.lowercased().contains("wagamama")

        // Include category/brand name in search for better matching
        var searchTerms = query
        if isFastFoodCategory {
            // For fast food, ensure we include the brand name in the search
            let brand = category.components(separatedBy: " ").first ?? category
            if !query.lowercased().contains(brand.lowercased()) {
                searchTerms = "\(brand) \(query)"
            }
        }

        let encodedQuery = searchTerms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerms
        // Request more fields for comprehensive data - get 10 results to find best match
        let urlString = "https://uk.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=10&fields=product_name,brands,nutriments,code,serving_size,serving_quantity,quantity,image_front_url,ingredients_text_en,ingredients_text"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for search: \(searchTerms)")
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NutraSafe Database Manager/1.0", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let products = json["products"] as? [[String: Any]] else {
                print("⚠️ No products found for: \(searchTerms)")
                return nil
            }

            print("🔍 Search '\(searchTerms)' returned \(products.count) results")

            // Find the best matching product
            let queryLower = query.lowercased()
            let categoryLower = category.lowercased()

            // Score each product and find the best match
            var bestProduct: [String: Any]?
            var bestScore = 0

            for product in products {
                guard let nutriments = product["nutriments"] as? [String: Any] else { continue }

                // Must have some nutrition data
                let calories = (nutriments["energy-kcal_100g"] as? Double) ?? (nutriments["energy-kcal"] as? Double) ?? 0
                guard calories > 0 else { continue }

                let productName = (product["product_name"] as? String ?? "").lowercased()
                let productBrand = (product["brands"] as? String ?? "").lowercased()

                var score = 0

                // Score based on name match
                if productName.contains(queryLower) || queryLower.contains(productName) {
                    score += 10
                }

                // Check key words from query
                let queryWords = queryLower.split(separator: " ").filter { $0.count > 2 }
                for word in queryWords {
                    if productName.contains(word) {
                        score += 3
                    }
                    if productBrand.contains(word) {
                        score += 2
                    }
                }

                // Brand match for fast food categories
                if isFastFoodCategory {
                    // Check if the brand matches the category (e.g., McDonald's in product brand)
                    let categoryWords = categoryLower.split(separator: " ").map { String($0) }
                    for catWord in categoryWords {
                        if productBrand.contains(catWord) || productName.contains(catWord) {
                            score += 5
                        }
                    }
                }

                print("   - '\(productName)' by '\(productBrand)': score=\(score), cal=\(calories)")

                if score > bestScore {
                    bestScore = score
                    bestProduct = product
                }
            }

            // Require minimum score for fast food to avoid wrong matches
            if isFastFoodCategory && bestScore < 5 {
                print("⚠️ No good match found for fast food item: \(query) (best score: \(bestScore))")
                return nil
            }

            guard let selectedProduct = bestProduct ?? products.first,
                  let nutriments = selectedProduct["nutriments"] as? [String: Any] else {
                print("⚠️ No valid product found for: \(searchTerms)")
                return nil
            }

            let name = selectedProduct["product_name"] as? String ?? query
            let brand = selectedProduct["brands"] as? String
            let barcode = selectedProduct["code"] as? String
            let imageURL = selectedProduct["image_front_url"] as? String
            let ingredientsText = (selectedProduct["ingredients_text_en"] as? String) ?? (selectedProduct["ingredients_text"] as? String)

            print("✅ Selected: '\(name)' by '\(brand ?? "unknown")' (score: \(bestScore))")

            // Serving info
            let servingSize = selectedProduct["serving_size"] as? String
            var servingSizeG: Double? = nil
            if let servingQuantity = selectedProduct["serving_quantity"] as? Double {
                servingSizeG = servingQuantity
            } else if let quantity = selectedProduct["quantity"] as? String {
                // Try to parse grams from quantity string like "200g"
                if let match = quantity.range(of: #"(\d+(?:\.\d+)?)\s*g"#, options: .regularExpression) {
                    servingSizeG = Double(quantity[match].replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces))
                }
            }

            // Nutrition values
            let calories100g = (nutriments["energy-kcal_100g"] as? Double) ?? (nutriments["energy-kcal"] as? Double) ?? 0
            let protein100g = (nutriments["proteins_100g"] as? Double) ?? (nutriments["proteins"] as? Double) ?? 0
            let carbs100g = (nutriments["carbohydrates_100g"] as? Double) ?? (nutriments["carbohydrates"] as? Double) ?? 0
            let fat100g = (nutriments["fat_100g"] as? Double) ?? (nutriments["fat"] as? Double) ?? 0
            let fiber = nutriments["fiber_100g"] as? Double
            let sugar = nutriments["sugars_100g"] as? Double
            let sodium = nutriments["sodium_100g"] as? Double
            let saturatedFat = nutriments["saturated-fat_100g"] as? Double

            // Get per-serving values for per-unit items
            let caloriesServing = nutriments["energy-kcal_serving"] as? Double
            let proteinServing = nutriments["proteins_serving"] as? Double
            let carbsServing = nutriments["carbohydrates_serving"] as? Double
            let fatServing = nutriments["fat_serving"] as? Double

            // Validate that we have reasonable data
            guard calories100g > 0 || protein100g > 0 || carbs100g > 0 || fat100g > 0 else {
                print("⚠️ No nutrition data for: \(name)")
                return nil
            }

            // Determine if this should be per-unit
            // For fast food items, if we have per-serving data and no 100g conversion makes sense, use per-unit
            let isPerUnit = isFastFoodCategory && (caloriesServing != nil || servingSizeG != nil)

            print("📊 Nutrition for '\(name)': cal=\(calories100g), prot=\(protein100g), carbs=\(carbs100g), fat=\(fat100g), isPerUnit=\(isPerUnit)")

            return SuggestedFoodData(
                name: name,
                brand: brand,
                calories: calories100g,
                protein: protein100g,
                carbs: carbs100g,
                fat: fat100g,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium != nil ? sodium! * 1000 : nil, // Convert to mg
                saturatedFat: saturatedFat,
                source: "Open Food Facts",
                barcode: barcode,
                imageURL: imageURL,
                ingredientsText: ingredientsText,
                servingDescription: servingSize,
                servingSizeG: servingSizeG,
                isPerUnit: isPerUnit,
                perUnitCalories: caloriesServing,
                perUnitProtein: proteinServing,
                perUnitCarbs: carbsServing,
                perUnitFat: fatServing
            )
        } catch {
            print("❌ Error searching Open Food Facts: \(error)")
            return nil
        }
    }
}
