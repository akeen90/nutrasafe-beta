# NutraSafe Ingredient Finder™ - Setup & Deployment Guide

## Overview
The AI Ingredient Finder feature uses Google Custom Search API and Gemini Flash to automatically find and extract ingredient lists from trusted sources (brand websites, supermarkets, OpenFoodFacts).

## Architecture
- **iOS App**: SwiftUI interface with Firestore caching
- **Cloud Function**: Node.js Express server on Google Cloud Functions
- **APIs Used**: Google Custom Search API + Gemini Flash
- **Caching**: Per-user Firestore collection to minimize API calls

---

## Part 1: API Keys Setup

### 1. Google Custom Search API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project `nutrasafe-705c7` (or create new)
3. Enable **Custom Search API**:
   - Navigate to APIs & Services → Library
   - Search for "Custom Search API"
   - Click "Enable"
4. Create API Key:
   - Go to APIs & Services → Credentials
   - Click "Create Credentials" → "API Key"
   - Copy the key (starts with `AIza...`)
   - **Restrict the key** to Custom Search API only (Security best practice)

### 2. Custom Search Engine ID

1. Go to [Programmable Search Engine](https://programmable search.google.com/controlpanel/all)
2. Click "Add" to create new search engine
3. Configuration:
   - **Sites to search**: Leave empty (will search entire web)
   - **Name**: NutraSafe Ingredient Finder
   - **Search the entire web**: Enable this option
4. After creation, go to "Setup" → "Basics"
5. Copy the **Search engine ID** (format: `abc123...`)

### 3. Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with Google account
3. Click "Create API Key"
4. Select project `nutrasafe-705c7`
5. Copy the generated API key (starts with `AIza...`)

---

## Part 2: Cloud Function Deployment

### Option A: Deploy with environment variables (Recommended)

```bash
# Navigate to function directory
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe/cloud/ingredient-finder"

# Deploy to Google Cloud Functions
gcloud functions deploy findIngredients \
  --runtime nodejs20 \
  --region us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_CSE_KEY=YOUR_CUSTOM_SEARCH_KEY,GOOGLE_CSE_CX=YOUR_SEARCH_ENGINE_ID,GEMINI_API_KEY=YOUR_GEMINI_KEY \
  --project nutrasafe-705c7 \
  --memory 256MB \
  --timeout 30s
```

### Option B: Deploy with Secret Manager (More secure)

```bash
# 1. Create secrets in Secret Manager
echo -n "YOUR_CUSTOM_SEARCH_KEY" | gcloud secrets create nutrasafe-cse-key --data-file=- --project nutrasafe-705c7
echo -n "YOUR_SEARCH_ENGINE_ID" | gcloud secrets create nutrasafe-cse-cx --data-file=- --project nutrasafe-705c7
echo -n "YOUR_GEMINI_KEY" | gcloud secrets create nutrasafe-gemini-key --data-file=- --project nutrasafe-705c7

# 2. Grant Cloud Functions access to secrets
# (This will be prompted during deployment or can be done via IAM)

# 3. Deploy with secret references
gcloud functions deploy findIngredients \
  --runtime nodejs20 \
  --region us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --set-secrets 'GOOGLE_CSE_KEY=nutrasafe-cse-key:latest,GOOGLE_CSE_CX=nutrasafe-cse-cx:latest,GEMINI_API_KEY=nutrasafe-gemini-key:latest' \
  --project nutrasafe-705c7 \
  --memory 256MB \
  --timeout 30s
```

### Verify Deployment

After deployment, you should see:
```
Deploying function (may take a while - up to 2 minutes)...
✓ Deployed function
Available at: https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients
```

Test the endpoint:
```bash
curl -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients \
  -H 'Content-Type: application/json' \
  -d '{"productName":"Alpro Chocolate Soya Drink","brand":"Alpro"}'
```

Expected response:
```json
{
  "ingredients_found": true,
  "ingredients_text": "Water, Pea protein, Flaxseed, Sunflower oil, Cocoa powder...",
  "source_url": "https://www.alpro.com/..."
}
```

---

## Part 3: iOS App Configuration

### 1. Add File to Xcode Project (REQUIRED)

The file `IngredientFinderService.swift` has been created but needs to be added to Xcode:

1. Open `NutraSafeBeta.xcodeproj` in Xcode
2. Right-click on "NutraSafe Beta" folder in Project Navigator
3. Select "Add Files to 'NutraSafe Beta'..."
4. Navigate to: `NutraSafe Beta/Services/IngredientFinderService.swift`
5. Make sure "Copy items if needed" is **UNCHECKED** (file is already in correct location)
6. Make sure "NutraSafe Beta" target is **CHECKED**
7. Click "Add"

### 2. Verify Info.plist Configuration

The endpoint URL has been configured to:
```
https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients
```

This should match the deployed Cloud Function URL.

### 3. Build and Test

1. Build the project in Xcode (Cmd+B)
2. Run on simulator or device
3. Go to Manual Food Entry
4. Expand the "Ingredients (Optional)" section
5. Enter a product name (e.g., "Alpro Chocolate Drink")
6. Optional: Enter brand name
7. Tap "Search with AI"
8. Wait for results
9. Confirm to use the found ingredients

---

## Part 4: Testing & Verification

### Test Cases

1. **Valid Product with Ingredients**
   - Product: "Alpro Chocolate Soya Drink"
   - Brand: "Alpro"
   - Expected: Finds ingredients from alpro.com or retailer site

2. **Product Without Ingredients Available**
   - Product: "Generic Water"
   - Expected: Shows "No ingredients found" message

3. **Rate Limiting**
   - Perform 3 searches within 1 minute
   - Expected: 3rd search shows rate limit error

4. **Caching**
   - Search same product twice
   - Expected: 2nd search is instant (from cache)

### Monitor Costs

- **Custom Search API**: Free tier = 100 queries/day, then $5 per 1000 queries
- **Gemini Flash**: Free tier = 15 RPM, 1 million TPM, 1500 RPD
- **Cloud Functions**: Free tier = 2M invocations/month

Expected costs with 1000 users:
- ~$20-30/month at moderate usage (2-3 searches per user per month)

### Check Firestore Cache

1. Go to Firebase Console → Firestore Database
2. Navigate to: `users/{userId}/ingredientCache`
3. You should see documents with structure:
   ```
   {
     productName: "Alpro Chocolate Soya Drink",
     brand: "Alpro",
     ingredientsText: "Water, Pea protein...",
     sourceUrl: "https://...",
     createdAt: Timestamp
   }
   ```

---

## Part 5: Features & UX

### User-Facing Features
- ✨ AI-powered ingredient search button (sparkles icon)
- 🔄 Loading overlay with branded messaging
- ✅ Confirmation modal with 3 options: Use / Use & Edit / Cancel
- 🔒 Rate limiting: 2 searches per minute
- 💾 Automatic Firestore caching per user
- 🎯 Searches trusted sources: brand sites, Tesco, Asda, Sainsbury's, OpenFoodFacts

### Branding
- "NutraSafe Ingredient Finder™" appears in:
  - Loading message: "NutraSafe Ingredient Finder™ is searching trusted sources..."
  - Success modal subtitle
- Blue-to-purple gradient button design
- Professional confirmation UI with source attribution

---

## Troubleshooting

### Issue: "Ingredient Finder is not configured"
- **Solution**: Verify `Info.plist` has correct Cloud Function URL
- Check that URL doesn't contain `YOUR_PROJECT` placeholder

### Issue: "Rate limit exceeded" on server
- **Cause**: More than 2 requests/minute from same IP
- **Solution**: Wait 60 seconds before retrying

### Issue: "No ingredients found"
- **Cause**: Product not available on searched sites, or AI couldn't extract
- **Solution**: User enters ingredients manually

### Issue: Network error
- **Cause**: Cloud Function not deployed or offline
- **Solution**: Check function status with `gcloud functions describe findIngredients --region us-central1`

### Issue: Build errors in Xcode
- **Cause**: `IngredientFinderService.swift` not added to project
- **Solution**: Follow "Add File to Xcode Project" instructions above

---

## Security Considerations

✅ **Implemented**:
- API keys stored server-side only (not in iOS app)
- Rate limiting on both client (2/min) and server (2/min per IP)
- Firestore security rules prevent cross-user cache access
- No web scraping (uses public Search API only)

🔒 **Recommended Enhancements**:
1. Add Firebase Authentication to Cloud Function (restrict to logged-in users)
2. Move from `--allow-unauthenticated` to `--trigger-http` with auth
3. Add request signing to prevent abuse
4. Monitor Cloud Function logs for suspicious activity

---

## Maintenance

### Update Search Sources
Edit `cloud/ingredient-finder/index.js` line 48:
```javascript
const supermarkets = 'site:tesco.com OR site:asda.com OR site:sainsburys.co.uk OR site:waitrose.com';
```

### Redeploy After Changes
```bash
cd cloud/ingredient-finder
npm run build  # if using TypeScript
gcloud functions deploy findIngredients --region us-central1 --project nutrasafe-705c7
```

### View Logs
```bash
gcloud functions logs read findIngredients --region us-central1 --project nutrasafe-705c7 --limit 50
```

---

## Support

For issues or questions:
1. Check Firebase Console → Cloud Functions → Logs
2. Verify API key quotas in Google Cloud Console
3. Test endpoint directly with curl (see "Verify Deployment" section)
4. Check Xcode console for iOS-side errors

**Feature Owner**: AI Ingredient Finder
**Last Updated**: October 2025
**Cloud Function**: `us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients`
