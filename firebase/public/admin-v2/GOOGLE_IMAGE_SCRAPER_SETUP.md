# Google Image Scraper Setup Guide

## Overview

The Google Image Scraper finds official white background product images from manufacturer sites. It uses Google Custom Search API to search for products and analyzes images to filter out:

- Retail site images (Tesco, Sainsbury's, etc.) that often have overlays
- Images with promotional text or labels
- Images with colored backgrounds or graphics
- Low-quality or cropped images

## Features

✅ **Smart Search**: Prioritizes manufacturer websites over retailers
✅ **White Background Detection**: Analyzes images to find clean product shots
✅ **Overlay Detection**: Filters out images with text, labels, or promotional graphics
✅ **Batch Processing**: Run on multiple products or individually
✅ **Quality Scoring**: Ranks images by quality, size, and source
✅ **Live Preview**: Click any image to see full resolution with analysis details

## Setup Instructions

### 1. Create Google API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select an existing one
3. Click **Create Credentials** > **API Key**
4. Copy the API key (keep it secure!)
5. Click **Restrict Key** and enable only **Custom Search API**

### 2. Create Custom Search Engine

1. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/)
2. Click **Add** to create a new search engine
3. **Sites to search**: Select "Search the entire web"
4. **Name**: "NutraSafe Product Images" (or your choice)
5. Click **Create**
6. In the control panel:
   - Enable **Image Search**
   - Set **SafeSearch** to active
   - Copy your **Search engine ID (CX)**

### 3. Configure the App

1. Navigate to `/firebase/public/admin-v2/`
2. Copy `.env.example` to `.env.local`:
   ```bash
   cp .env.example .env.local
   ```
3. Edit `.env.local` and add your credentials:
   ```env
   VITE_GOOGLE_API_KEY=your_actual_api_key_here
   VITE_GOOGLE_CX=your_actual_search_engine_id_here
   ```
4. **IMPORTANT**: `.env.local` is git-ignored. Never commit it to version control!

### 4. Rebuild the App

After adding your API keys, rebuild the Vite app:

```bash
cd /path/to/firebase/public/admin-v2/
npm run build
```

Or for development:

```bash
npm run dev
```

## Usage

### Accessing the Tool

1. Open your admin dashboard
2. Click **"Google Image Scraper"** in the sidebar (purple button)
3. Select which food indices to load
4. Click **"Load Foods"**

### Finding Images

**For Selected Items:**
1. Check the boxes next to products you want images for
2. Click **"Search Selected (X)"** at the top
3. The tool will search Google for each product

**For All Pending Items:**
1. Don't select any items
2. Click **"Search All (X)"** at the top
3. Processes all products without images

### Understanding Results

Each product will show:

- **Current image** (if it exists)
- **Search results** (up to 6 thumbnails)
- **Analysis status**:
  - ✓ **Clean**: White background, no overlays
  - ✗ **Has issues**: Overlays, colored background, or other problems

**Green checkmark badge** on thumbnails = Image is from a manufacturer site

### Reviewing Images

1. Click any thumbnail to see full resolution
2. Analysis details show:
   - Background color confidence (%)
   - Overlay detection
   - Quality score (0-100)
3. Press ESC or click outside to close

### Applying Images

(Upload functionality coming soon - currently for review only)

Once you find good images:
1. Note which products have quality results
2. Download or use the image URLs manually
3. Future update will add one-click upload to Firebase

## API Limits

**Google Custom Search API Free Tier:**
- 100 searches per day
- Each product search = 1 API call
- Monitor usage in [Google Cloud Console](https://console.cloud.google.com/apis/dashboard)

**Paid Tier:**
- $5 per 1,000 additional queries
- Up to 10,000 queries per day

## Troubleshooting

### "API Not Configured" Message

- Check that `.env.local` exists and has your keys
- Ensure you've rebuilt the app after adding keys
- Keys must not have quotes around them in `.env.local`

### No Results Found

- Try simplifying product names (remove extra details)
- Check if the brand name is spelled correctly
- Some products may not have manufacturer images online

### Images Have Overlays

The tool tries to detect overlays but isn't perfect. Common issues:
- Retail "Fresh for X days" labels
- Promotional banners
- Price tags
- "New!" or "On Sale" graphics

These should be filtered out automatically, but some may slip through.

### CORS Errors

Some manufacturer sites block image loading from other domains. The tool uses:
- Proxy requests where possible
- Thumbnail URLs from Google when direct access fails
- This is why some images may appear lower resolution

## Technical Details

### Manufacturer Domains Prioritized

The tool prioritizes these domains:
- nestle.com, unilever.com, pepsico.com, cocacola.com
- kellogs.com, kraftheinz.com, danone.com, mars.com
- UK brands: walkers.co.uk, cadbury.co.uk, mcvities.co.uk, etc.

### Excluded Domains

These are automatically filtered out:
- tesco.com, sainsburys.co.uk, asda.com, morrisons.com
- waitrose.com, ocado.com, amazon.co.uk, ebay.co.uk

### Image Analysis

The tool analyzes:
1. **Background color**: Checks edge pixels for white (RGB > 240)
2. **Overlays**: Detects dark text or colorful graphics
3. **Quality**: Scores based on size, source, and cleanliness

## Support

For issues or questions:
1. Check the browser console for detailed logs
2. Click "Show setup instructions in console" in the UI
3. Review the processing log on the right side panel

## Security Notes

🔒 **API Key Security:**
- Never commit `.env.local` to git
- `.gitignore` already protects it
- If your key is exposed, regenerate it immediately in Google Cloud Console
- Add IP restrictions to your API key for extra security

## Future Enhancements

Planned features:
- One-click upload to Firebase Storage
- Manual image selection from results
- Background removal integration
- Batch upload with progress tracking
- Image cropping and editing tools
