# Google Custom Search API Setup Guide

## Step 1: Create Google Cloud Project & Get API Key

### 1.1 Go to Google Cloud Console
Visit: https://console.cloud.google.com/

### 1.2 Create or Select Project
- Click "Select a project" at the top
- Either create a new project or select existing one
- Project name suggestion: "NutraSafe-Food-Search"

### 1.3 Enable Custom Search JSON API
- Go to "APIs & Services" > "Library"
- Search for "Custom Search JSON API"
- Click on it and press "ENABLE"

### 1.4 Create API Credentials
- Go to "APIs & Services" > "Credentials"
- Click "CREATE CREDENTIALS" > "API key"
- Copy the API key (keep it safe!)
- Optional: Click "RESTRICT KEY" to limit to Custom Search JSON API only

## Step 2: Verify Your Custom Search Engine

Your search engine ID: `62bfd0c439cef4c48`

### 2.1 Check Search Engine Configuration
Visit: https://cse.google.com/cse/all
- Find your search engine with ID: 62bfd0c439cef4c48
- Verify it's configured for UK food retailers:
  - tesco.com
  - sainsburys.co.uk
  - asda.com
  - morrisons.com
  - waitrose.com

### 2.2 Test Search Engine
Try this URL in your browser (replace YOUR_API_KEY):
```
https://www.googleapis.com/customsearch/v1?key=YOUR_API_KEY&cx=62bfd0c439cef4c48&q=tesco+walkers+crisps
```

## Step 3: Usage Limits & Billing

### Free Tier
- 100 searches per day free
- $5 per 1000 additional queries
- Perfect for testing and initial runs

### For Production
- Consider upgrading if processing 40,000 products
- Monitor usage in Google Cloud Console

## Step 4: Integration

Once you have your API key, we'll update the comprehensive_updater.py to use:
- API Key: [Your generated key]
- Search Engine ID: 62bfd0c439cef4c48

## Security Note
- Never commit API keys to git
- Store in environment variable or secure config file