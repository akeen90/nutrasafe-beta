# How to Get API Keys for NutraSafe Ingredient Finder

This guide will walk you through getting the 3 required API keys step-by-step.

---

## Part 1: Google Custom Search API Key (5 minutes)

### Step 1: Enable Custom Search API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Select your project **`nutrasafe-705c7`** from the dropdown at the top
   - If you don't see it, click "Select a Project" → find "nutrasafe-705c7"

4. **Enable the API**:
   - In the left sidebar, click **"APIs & Services"** → **"Library"**
   - In the search box, type: `Custom Search API`
   - Click on **"Custom Search API"**
   - Click the blue **"Enable"** button
   - Wait 10-30 seconds for it to enable

### Step 2: Create API Key

1. Go to **"APIs & Services"** → **"Credentials"** (left sidebar)
2. Click **"+ CREATE CREDENTIALS"** at the top
3. Select **"API Key"** from the dropdown
4. A popup will show your new API key (starts with `AIza...`)
5. **COPY THIS KEY** and save it somewhere safe (you'll need it later)

### Step 3: Restrict the API Key (Security Best Practice)

1. In the popup, click **"RESTRICT KEY"**
2. Under "API restrictions":
   - Select **"Restrict key"**
   - Click **"Select APIs"** dropdown
   - Check **"Custom Search API"**
   - Uncheck everything else
3. Click **"Save"** at the bottom

**Result**: You now have your `GOOGLE_CSE_KEY` ✅

Example: `AIzaSyD1234567890abcdefghijklmnopqrstuv`

---

## Part 2: Custom Search Engine ID (10 minutes)

This creates a search engine that will search the web for ingredients.

### Step 1: Create Search Engine

1. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/controlpanel/all)
2. Sign in with the same Google account
3. Click **"Add"** button (blue button on the left)

### Step 2: Configure Search Engine

Fill in the form:

**Search engine name:**
```
NutraSafe Ingredient Finder
```

**What to search:**
- Select **"Search the entire web"**
- DO NOT add specific sites here - we'll search specific sites programmatically

**Search settings:**
- Leave defaults as-is
- **Image search**: OFF
- **SafeSearch**: ON (recommended)
- **Language**: English

Click **"Create"**

### Step 3: Get Search Engine ID

1. After creation, you'll see your new search engine
2. Click on it to open settings
3. Go to **"Overview"** tab (or "Setup" → "Basics")
4. Find **"Search engine ID"** section
5. **COPY the Search engine ID** (looks like: `a1234567890bcdefg:hijklmnop`)

**Result**: You now have your `GOOGLE_CSE_CX` ✅

Example: `017576662512468239146:omuauf_lfve`

### Step 4: Enable "Search the entire web" (Important!)

1. Still in the search engine settings
2. Go to **"Setup"** → **"Basics"**
3. Scroll down to **"Search the entire web"**
4. Toggle it **ON** (should be green)
5. Click **"Update"** at the bottom

---

## Part 3: Gemini API Key (3 minutes)

### Step 1: Go to Google AI Studio

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with the same Google account

### Step 2: Create API Key

1. Click **"Get API key"** or **"Create API key"**
2. You'll see options:
   - **Create API key in new project** (if you don't have one)
   - **Create API key in existing project** ← Select this
3. Select **`nutrasafe-705c7`** from the dropdown
4. Click **"Create API key in existing project"**

### Step 3: Copy the Key

1. Your API key will appear (starts with `AIza...`)
2. **COPY THIS KEY** and save it somewhere safe
3. Click **"Done"**

**Result**: You now have your `GEMINI_API_KEY` ✅

Example: `AIzaSyABCDEF123456789_abcdefghijklmnopqr`

---

## Part 4: Test Your Keys

Before deploying, let's verify the keys work:

### Test 1: Custom Search API

Open Terminal and run:

```bash
curl "https://www.googleapis.com/customsearch/v1?key=YOUR_GOOGLE_CSE_KEY&cx=YOUR_GOOGLE_CSE_CX&q=alpro+chocolate+ingredients"
```

Replace:
- `YOUR_GOOGLE_CSE_KEY` with your actual key from Part 1
- `YOUR_GOOGLE_CSE_CX` with your actual ID from Part 2

**Expected**: JSON response with search results
**Error**: Check if you copied the keys correctly

### Test 2: Gemini API

```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=YOUR_GEMINI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Say hello"
      }]
    }]
  }'
```

Replace `YOUR_GEMINI_API_KEY` with your actual key from Part 3

**Expected**: JSON response with "hello" message
**Error**: Check if you copied the key correctly

---

## Part 5: Deploy Cloud Function

Now that you have all 3 keys, deploy the function:

### Option A: Deploy with Environment Variables (Easier)

```bash
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe/cloud/ingredient-finder"

gcloud functions deploy findIngredients \
  --runtime nodejs20 \
  --region us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_CSE_KEY=AIzaSy...,GOOGLE_CSE_CX=017576...,GEMINI_API_KEY=AIzaSyA... \
  --project nutrasafe-705c7 \
  --memory 256MB \
  --timeout 30s
```

**Replace the `...` parts with your actual keys!**

### Option B: Deploy with Secret Manager (More Secure)

If you prefer to use Secret Manager:

```bash
# 1. Create secrets
echo -n "YOUR_GOOGLE_CSE_KEY" | gcloud secrets create nutrasafe-cse-key --data-file=- --project nutrasafe-705c7
echo -n "YOUR_GOOGLE_CSE_CX" | gcloud secrets create nutrasafe-cse-cx --data-file=- --project nutrasafe-705c7
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create nutrasafe-gemini-key --data-file=- --project nutrasafe-705c7

# 2. Deploy with secrets
cd "/Users/aaronkeen/Documents/My Apps/NutraSafe/cloud/ingredient-finder"

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

### Deployment Output

After 1-2 minutes, you should see:

```
✓ Deployed function findIngredients
Available at: https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients
```

**The URL should already match what's in your Info.plist!** ✅

---

## Part 6: Test End-to-End

### Test the Cloud Function Directly

```bash
curl -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients \
  -H 'Content-Type: application/json' \
  -d '{"productName":"Alpro Chocolate Soya Drink","brand":"Alpro"}'
```

**Expected Response:**
```json
{
  "ingredients_found": true,
  "ingredients_text": "Water, Sugar, Hulled soya beans (2.9%), ...",
  "source_url": "https://www.alpro.com/..."
}
```

### Test in the iOS App

1. Build and run the app in Xcode (Cmd+R)
2. Go to **Manual Food Entry**
3. Enter food name: `Alpro Chocolate Soya Drink`
4. Enter brand: `Alpro`
5. Expand **"Ingredients (Optional)"**
6. Tap **"Search with AI"** button
7. Wait 3-5 seconds
8. You should see a modal with found ingredients! 🎉

---

## Troubleshooting

### "API key not valid" error

- **Cause**: Key copied incorrectly or not enabled
- **Fix**: Go back to Cloud Console → Credentials and verify the key

### "Search engine does not exist" error

- **Cause**: Custom Search Engine ID is wrong
- **Fix**: Go to [Programmable Search](https://programmablesearchengine.google.com/) and copy the ID again

### "Permission denied" error

- **Cause**: API not enabled or quota exceeded
- **Fix**: Go to Cloud Console → APIs & Services → Dashboard and check status

### "No ingredients found" in app

- **Cause**: Cloud Function isn't deployed or product not found
- **Fix**: Test the curl command above first to isolate the issue

### Rate limit errors

- **Free tier limits**:
  - Custom Search: 100 queries/day free
  - Gemini Flash: 15 requests/minute, 1500/day free
- **Fix**: Wait for quota to reset or upgrade to paid tier

---

## Summary

You should now have:

✅ **GOOGLE_CSE_KEY**: `AIzaSy...` (Custom Search API key)
✅ **GOOGLE_CSE_CX**: `017576...` (Search Engine ID)
✅ **GEMINI_API_KEY**: `AIzaSyA...` (Gemini API key)
✅ **Cloud Function**: Deployed at `https://us-central1-nutrasafe-705c7.cloudfunctions.net/findIngredients`
✅ **iOS App**: Ready to use the feature!

**Keep your keys secure!** Don't share them or commit them to git.

---

## Cost Estimate

With normal usage (1000 active users, 2-3 searches/user/month):

- **Custom Search**: $15-20/month (after free tier)
- **Gemini Flash**: FREE (well within limits)
- **Cloud Functions**: FREE (within free tier)

**Total**: ~$15-20/month

If costs are too high, you can:
1. Reduce search quota per user
2. Rely more on Firestore caching (instant + free)
3. Use cheaper alternatives to Custom Search API

---

## Questions?

If something doesn't work:

1. Check the Cloud Function logs:
   ```bash
   gcloud functions logs read findIngredients --region us-central1 --project nutrasafe-705c7 --limit 50
   ```

2. Check Xcode console for iOS errors

3. Verify all keys are copied correctly (no extra spaces!)

Good luck! 🚀
