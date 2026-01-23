# NutraSafe Batch Image Processor

Bulk process all food images:
1. Fetch from OpenFoodFacts
2. Remove backgrounds with rembg
3. Upload to Firebase Storage
4. Update Firestore

## Setup

```bash
cd firebase/functions/batch-image-processor

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Firebase Setup (for upload step)

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save as `service-account.json` in this folder or parent `functions/` folder

## Usage

### Test with a few images first
```bash
python process_images.py --test 10
```

### Process all images
```bash
python process_images.py --all
```

### Resume if interrupted
```bash
python process_images.py --resume
```

### Check progress
```bash
python process_images.py --stats
```

### Upload to Firebase (after processing)
```bash
python process_images.py --upload
```

## What It Does

1. **Scans Algolia** - Gets all foods with barcodes from 10 indices
2. **Deduplicates** - Removes duplicate barcodes
3. **Fetches OFF** - Gets best image from OpenFoodFacts (UK first, then World)
4. **Downloads** - Saves original to `work/originals/`
5. **Cleans** - Removes background, saves to `work/cleaned/`
6. **Uploads** - Sends to Firebase Storage `food-images/cleaned/`
7. **Updates** - Sets new imageUrl in Firestore

## Output

```
work/
├── originals/       # Downloaded images from OFF
├── cleaned/         # Background-removed PNGs
├── checkpoint.json  # Progress tracking (resume support)
└── results.json     # Processing results
```

## Time Estimates

| Images | Download | Clean | Total |
|--------|----------|-------|-------|
| 1,000  | ~10 min  | ~20 min | ~30 min |
| 10,000 | ~1.5 hr  | ~3 hr | ~4.5 hr |
| 85,000 | ~12 hr   | ~24 hr | ~36 hr |

Run overnight with `--all` and it'll checkpoint progress every 50 images.

## Tips

- Use `--download-only` first to grab all OFF images, then clean separately
- If your Mac sleeps, use `caffeinate -i python process_images.py --all`
- Check `work/cleaned/` folder to preview results
- The script skips already-processed barcodes (safe to restart)
