# 🔍 Google Custom Search API Setup Guide

## Step 1: Get Google API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable **Custom Search API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Custom Search API"
   - Click "Enable"
4. Create API Key:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the API key (you'll need this)

## Step 2: Create Custom Search Engine

1. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/controlpanel/all)
2. Click "Add" to create new search engine
3. Configure search engine:
   - **Sites to search**: Add these UK food sites:
     ```
     tesco.com/*
     asda.com/*
     sainsburys.co.uk/*
     waitrose.com/*
     mars.co.uk/*
     nestle.co.uk/*
     unilever.co.uk/*
     cadbury.co.uk/*
     kelloggs.co.uk/*
     walkers.co.uk/*
     ```
   - **Language**: English
   - **Name**: "UK Food Nutrition Search"
4. Click "Create"
5. Copy the **Search Engine ID** (looks like: `1234567890abcdef:ghijklmnop`)

## Step 3: Configure Firebase Environment Variables

Run these commands to set up the API credentials:

```bash
cd /Users/aaronkeen/Documents/My\ Apps/NutraSafe\ Beta/firebase/functions

# Set Google Custom Search API Key
firebase functions:config:set google.custom_search_api_key="YOUR_API_KEY_HERE"

# Set Search Engine ID  
firebase functions:config:set google.search_engine_id="YOUR_SEARCH_ENGINE_ID_HERE"
```

Replace:
- `YOUR_API_KEY_HERE` with your Google API key
- `YOUR_SEARCH_ENGINE_ID_HERE` with your search engine ID

## Step 4: Update Environment Variables in Code

The code expects these environment variables:
- `process.env.GOOGLE_CUSTOM_SEARCH_API_KEY`
- `process.env.GOOGLE_SEARCH_ENGINE_ID`

## Step 5: Deploy and Test

After setting up the credentials:

```bash
# Build and deploy functions
npm run build
firebase deploy --only functions:workingAIVerify
```

## 📊 Usage Limits

- **Free tier**: 100 searches per day
- **Paid**: $5 per 1000 searches (up to 10,000 daily)
- Current implementation uses 1-3 searches per AI verification

## 🎯 Expected Results

With Google Custom Search API configured, AI verification will:

1. **Search UK sites directly** for "Mars Bar nutrition per 100g"
2. **Extract real nutrition data** from Tesco, ASDA, Mars.co.uk, etc.
3. **Get product images and weights** from official sources
4. **Show accurate source links** (e.g., "tesco.com (Google Search)")
5. **No more AI generation fallback** for common UK products

## 🔧 Testing

Test with Mars Bar to verify it's working:
- Should find real Tesco or Mars.co.uk nutrition data
- Should show "tesco.com (Google Search)" or "mars.co.uk (Google Search)" as source
- Should include product weight (51g) and official ingredients

## 🚨 Troubleshooting

If still getting AI generation:
1. Check Firebase functions logs: `firebase functions:log`
2. Verify API key and search engine ID are set correctly
3. Ensure Custom Search API is enabled in Google Cloud Console
4. Check daily usage limits haven't been exceeded

The Google Custom Search approach is much more reliable than web scraping and will give you accurate UK food data! 🚀