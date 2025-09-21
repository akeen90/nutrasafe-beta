#!/usr/bin/env python3
"""
Test Google Custom Search API setup
"""

import requests
import json

def test_google_custom_search():
    """Test Google Custom Search API with your configuration"""
    
    # You'll need to replace this with your actual API key
    API_KEY = "AIzaSyCrdKM1X0CVpSaTwD7kFXxh0CAgiU8nUYE"
    SEARCH_ENGINE_ID = "62bfd0c439cef4c48"
    
    if API_KEY == "YOUR_API_KEY_HERE":
        print("❌ Please replace YOUR_API_KEY_HERE with your actual Google API key")
        print("   Get it from: https://console.cloud.google.com/")
        return False
    
    # Test search URL
    test_query = "tesco walkers ready salted crisps ingredients nutrition"
    url = f"https://www.googleapis.com/customsearch/v1"
    
    params = {
        'key': API_KEY,
        'cx': SEARCH_ENGINE_ID,
        'q': test_query,
        'num': 3
    }
    
    print(f"🔍 Testing Google Custom Search API...")
    print(f"   Query: {test_query}")
    print(f"   Search Engine ID: {SEARCH_ENGINE_ID}")
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            
            # Check search info
            search_info = data.get('searchInformation', {})
            total_results = search_info.get('totalResults', '0')
            search_time = search_info.get('searchTime', '0')
            
            print(f"✅ API Working!")
            print(f"   Total results: {total_results}")
            print(f"   Search time: {search_time} seconds")
            
            # Show first few results
            items = data.get('items', [])
            print(f"\n📋 Found {len(items)} results:")
            
            for i, item in enumerate(items[:3], 1):
                title = item.get('title', 'No title')
                link = item.get('link', 'No link')
                snippet = item.get('snippet', 'No snippet')
                
                print(f"\n   {i}. {title}")
                print(f"      URL: {link}")
                print(f"      Preview: {snippet[:100]}...")
            
            return True
            
        elif response.status_code == 403:
            error_data = response.json()
            print(f"❌ API Key issue: {error_data.get('error', {}).get('message', 'Unknown error')}")
            return False
            
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ JSON error: {e}")
        return False

if __name__ == "__main__":
    print("🧪 GOOGLE CUSTOM SEARCH API TEST")
    print("=" * 40)
    
    success = test_google_custom_search()
    
    if success:
        print(f"\n🎯 Setup looks good! Ready to integrate with comprehensive_updater.py")
    else:
        print(f"\n🔧 Follow the setup guide to complete API configuration")