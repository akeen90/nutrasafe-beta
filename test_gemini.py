#!/usr/bin/env python3
"""
Quick test of Gemini API
"""

import google.generativeai as genai

print("🔥 Testing Gemini API...")

try:
    # Configure API
    genai.configure(api_key="AIzaSyDE4qk8npyY7VaU3n3tjkknHs6Gj3bRJJw")
    
    # Create model
    model = genai.GenerativeModel('gemini-1.5-flash')
    print("✅ Model created successfully")
    
    # Test simple prompt
    response = model.generate_content("Say 'Hello from Gemini!'")
    print(f"✅ Response: {response.text}")
    
except Exception as e:
    print(f"❌ Error: {e}")