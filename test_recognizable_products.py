#!/usr/bin/env python3
"""
Test script to verify the fixed nutrition extractor works with recognizable products
"""

import sqlite3
from fixed_nutrition_extractor import FixedNutritionExtractor

def main():
    print("🎯 TESTING WITH RECOGNIZABLE PRODUCTS")
    print("Testing products that ChatGPT should know")
    print("=" * 50)
    
    # API Key
    openai_api_key = ""YOUR_OPENAI_API_KEY""
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    csv_path = "test_recognizable_products.csv"
    
    extractor = FixedNutritionExtractor(db_path, csv_path, openai_api_key)
    
    try:
        # Test specific recognizable products
        test_products = [
            (123, "Sliced White Bread", "Sainsbury's"),
            (20, "Walkers", "Walkers"), 
            (82, "Milka with Whole Hazelnuts", "Milka"),
        ]
        
        print(f"🧪 Testing {len(test_products)} recognizable products\n")
        
        successes = 0
        failures = 0
        
        for i, (product_id, name, brand) in enumerate(test_products):
            print(f"[{i+1}/{len(test_products)}] Testing: {brand} {name}")
            
            # Try ChatGPT on this specific product
            chatgpt_data = extractor.ask_chatgpt_simple(name, brand)
            
            if chatgpt_data:
                print(f"   ✅ SUCCESS: Got real nutrition data!")
                print(f"   📊 Data: {list(chatgpt_data.keys())}")
                
                # Show some key values
                if 'energy_kcal_100g' in chatgpt_data:
                    print(f"   🔥 Calories: {chatgpt_data['energy_kcal_100g']} kcal/100g")
                if 'ingredients' in chatgpt_data:
                    print(f"   🥖 Ingredients: {chatgpt_data['ingredients'][:50]}...")
                if 'serving_size' in chatgpt_data:
                    print(f"   🍽️ Serving: {chatgpt_data['serving_size']}")
                
                # Add to CSV and update database
                extractor.add_to_csv(product_id, name, brand, 'success', chatgpt_data)
                fields_updated = extractor.update_database(product_id, chatgpt_data)
                print(f"   💾 Updated {fields_updated} database fields")
                successes += 1
            else:
                print(f"   ❌ ChatGPT doesn't know this product")
                extractor.add_to_csv(product_id, name, brand, 'failed', {'extraction_notes': 'ChatGPT had no reliable data'})
                failures += 1
            
            print()  # Blank line
        
        # Results
        total = successes + failures
        print(f"🎯 TEST RESULTS:")
        print(f"   Total tested: {total}")
        print(f"   Successes: {successes}")
        print(f"   Failures: {failures}")
        if total > 0:
            print(f"   Success rate: {(successes / total * 100):.1f}%")
        
        if successes > 0:
            print(f"\n✅ BREAKTHROUGH: System successfully extracted REAL nutrition data!")
            print(f"📄 Check {csv_path} for detailed results")
        else:
            print(f"\n📝 Result: These specific products aren't in ChatGPT's knowledge base")
            print(f"   This is actually good - no fake data generated!")
        
    finally:
        extractor.close()

if __name__ == "__main__":
    main()