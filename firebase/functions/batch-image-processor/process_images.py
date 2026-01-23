#!/usr/bin/env python3
"""
NutraSafe Batch Image Processor
================================
1. Reads all foods with barcodes from Algolia
2. Fetches best images from OpenFoodFacts
3. Downloads and cleans images with rembg
4. Uploads to Firebase Storage
5. Updates Firestore with new image URLs

Usage:
    python process_images.py --test 10       # Test with 10 images
    python process_images.py --all           # Process all images
    python process_images.py --resume        # Resume from last checkpoint
"""

import os
import sys
import json
import time
import argparse
import hashlib
from pathlib import Path
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from rembg import remove
from PIL import Image
import io

# Try to import firebase-admin (optional, for upload step)
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, storage
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("Warning: firebase-admin not installed. Upload step will be skipped.")

# ============================================================================
# Configuration
# ============================================================================

ALGOLIA_APP_ID = "WK0TIF84M2"
ALGOLIA_API_KEY = "577cc4ee3fed660318917bbb54abfb2e"  # Search key

ALGOLIA_INDICES = [
    "verified_foods",
    "foods",
    "manual_foods",
    "user_added",
    "ai_enhanced",
    "ai_manually_added",
    "tesco_products",
    "uk_foods_cleaned",
    "fast_foods_database",
    "generic_database",
]

# Index to Firestore collection mapping
INDEX_TO_COLLECTION = {
    "verified_foods": "verifiedFoods",
    "foods": "foods",
    "manual_foods": "manualFoods",
    "user_added": "userAddedFoods",
    "ai_enhanced": "aiEnhancedFoods",
    "ai_manually_added": "aiManuallyAddedFoods",
    "tesco_products": "tescoProducts",
    # These don't have Firestore backing
    "uk_foods_cleaned": None,
    "fast_foods_database": None,
    "generic_database": None,
}

OFF_API_BASE = "https://world.openfoodfacts.org/api/v2/product"
OFF_UK_API_BASE = "https://uk.openfoodfacts.org/api/v2/product"

# Directories
SCRIPT_DIR = Path(__file__).parent
WORK_DIR = SCRIPT_DIR / "work"
ORIGINALS_DIR = WORK_DIR / "originals"
CLEANED_DIR = WORK_DIR / "cleaned"
CHECKPOINT_FILE = WORK_DIR / "checkpoint.json"
RESULTS_FILE = WORK_DIR / "results.json"

# Firebase Storage bucket
STORAGE_BUCKET = "nutrasafe-705c7.appspot.com"

# ============================================================================
# Helpers
# ============================================================================

def setup_directories():
    """Create working directories."""
    WORK_DIR.mkdir(exist_ok=True)
    ORIGINALS_DIR.mkdir(exist_ok=True)
    CLEANED_DIR.mkdir(exist_ok=True)

def load_checkpoint():
    """Load processing checkpoint."""
    if CHECKPOINT_FILE.exists():
        with open(CHECKPOINT_FILE) as f:
            return json.load(f)
    return {"processed": [], "failed": [], "last_index": 0}

def save_checkpoint(checkpoint):
    """Save processing checkpoint."""
    with open(CHECKPOINT_FILE, "w") as f:
        json.dump(checkpoint, f, indent=2)

def get_image_hash(barcode):
    """Generate a unique filename from barcode."""
    return hashlib.md5(barcode.encode()).hexdigest()[:12]

# ============================================================================
# Step 1: Fetch barcodes from Algolia
# ============================================================================

def algolia_search(index_name, query="", page=0, hits_per_page=1000):
    """Search Algolia using REST API."""
    url = f"https://{ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes/{index_name}/query"
    headers = {
        "X-Algolia-Application-Id": ALGOLIA_APP_ID,
        "X-Algolia-API-Key": ALGOLIA_API_KEY,
        "Content-Type": "application/json",
    }
    data = {
        "query": query,
        "page": page,
        "hitsPerPage": hits_per_page,
        "attributesToRetrieve": ["objectID", "barcode", "gtin", "ean", "name", "brandName", "imageUrl"],
    }
    response = requests.post(url, headers=headers, json=data, timeout=30)
    response.raise_for_status()
    return response.json()

def fetch_all_barcodes():
    """Fetch all foods with barcodes from all Algolia indices."""
    print("\n📊 Step 1: Fetching barcodes from Algolia...")

    all_foods = []

    for index_name in ALGOLIA_INDICES:
        print(f"  Scanning {index_name}...", end=" ", flush=True)

        foods_in_index = []

        # Browse all records using search with pagination
        page = 0
        while True:
            try:
                result = algolia_search(index_name, page=page)
            except Exception as e:
                print(f"Error: {e}")
                break

            hits = result.get("hits", [])
            if not hits:
                break

            for hit in hits:
                barcode = hit.get("barcode") or hit.get("gtin") or hit.get("ean")
                if barcode:
                    foods_in_index.append({
                        "objectID": hit.get("objectID", ""),
                        "barcode": str(barcode).strip(),
                        "name": hit.get("name", ""),
                        "brandName": hit.get("brandName", ""),
                        "currentImageUrl": hit.get("imageUrl"),
                        "sourceIndex": index_name,
                        "firestoreCollection": INDEX_TO_COLLECTION.get(index_name),
                    })

            page += 1
            if page >= result.get("nbPages", 0):
                break

        print(f"{len(foods_in_index)} with barcodes")
        all_foods.extend(foods_in_index)

    # Deduplicate by barcode (keep first occurrence)
    seen_barcodes = set()
    unique_foods = []
    for food in all_foods:
        if food["barcode"] not in seen_barcodes:
            seen_barcodes.add(food["barcode"])
            unique_foods.append(food)

    print(f"\n  Total: {len(all_foods)} foods with barcodes")
    print(f"  Unique barcodes: {len(unique_foods)}")

    return unique_foods

# ============================================================================
# Step 2: Fetch images from OpenFoodFacts
# ============================================================================

def fetch_off_image(barcode):
    """Fetch best image URL from OpenFoodFacts."""
    # Try UK first, then world
    for base_url in [OFF_UK_API_BASE, OFF_API_BASE]:
        try:
            url = f"{base_url}/{barcode}.json"
            response = requests.get(url, timeout=10)

            if response.status_code == 200:
                data = response.json()
                product = data.get("product", {})

                if product:
                    # Try to get best front image
                    selected = product.get("selected_images", {})
                    front = selected.get("front", {})
                    display = front.get("display", {})

                    # Prefer English
                    for lang in ["en", "uk", "gb"]:
                        if lang in display:
                            return display[lang]

                    # Any language
                    if display:
                        return list(display.values())[0]

                    # Fall back to main front image
                    if product.get("image_front_url"):
                        return product["image_front_url"]

        except Exception as e:
            pass

    return None

def download_image(url, filepath):
    """Download image to local file."""
    try:
        response = requests.get(url, timeout=30)
        if response.status_code == 200:
            with open(filepath, "wb") as f:
                f.write(response.content)
            return True
    except Exception as e:
        pass
    return False

# ============================================================================
# Step 3: Clean images with rembg
# ============================================================================

def clean_image(input_path, output_path):
    """Remove background from image using rembg."""
    try:
        with open(input_path, "rb") as f:
            input_data = f.read()

        # Load and process
        input_image = Image.open(io.BytesIO(input_data))

        # Convert mode if needed
        if input_image.mode == "P":
            input_image = input_image.convert("RGBA")
        elif input_image.mode not in ("RGB", "RGBA"):
            input_image = input_image.convert("RGB")

        # Remove background
        output_image = remove(input_image)

        # Save as PNG with transparency
        output_image.save(output_path, "PNG", optimize=True)
        return True

    except Exception as e:
        print(f"    Error cleaning: {e}")
        return False

# ============================================================================
# Step 4: Upload to Firebase Storage
# ============================================================================

def init_firebase():
    """Initialize Firebase Admin SDK."""
    if not FIREBASE_AVAILABLE:
        return None

    # Check for service account
    sa_path = SCRIPT_DIR.parent / "service-account.json"
    if not sa_path.exists():
        sa_path = SCRIPT_DIR / "service-account.json"

    if not sa_path.exists():
        print("  Warning: No service-account.json found. Upload will be skipped.")
        print(f"  Place it at: {sa_path}")
        return None

    try:
        cred = credentials.Certificate(str(sa_path))
        firebase_admin.initialize_app(cred, {
            "storageBucket": STORAGE_BUCKET
        })
        return True
    except Exception as e:
        print(f"  Firebase init error: {e}")
        return None

def upload_to_storage(local_path, remote_path):
    """Upload file to Firebase Storage and return public URL."""
    try:
        bucket = storage.bucket()
        blob = bucket.blob(remote_path)
        blob.upload_from_filename(str(local_path), content_type="image/png")
        blob.make_public()
        return blob.public_url
    except Exception as e:
        print(f"    Upload error: {e}")
        return None

# ============================================================================
# Step 5: Update Firestore
# ============================================================================

def update_firestore(collection, doc_id, image_url):
    """Update Firestore document with new image URL."""
    if not collection:
        return False  # Algolia-only index

    try:
        db = firestore.client()
        db.collection(collection).document(doc_id).update({
            "imageUrl": image_url,
            "imageUpdatedAt": datetime.now(),
            "imageSource": "off_cleaned"
        })
        return True
    except Exception as e:
        print(f"    Firestore error: {e}")
        return False

# ============================================================================
# Main Processing Pipeline
# ============================================================================

def process_food(food, download_only=False):
    """Process a single food item."""
    barcode = food["barcode"]
    img_hash = get_image_hash(barcode)

    original_path = ORIGINALS_DIR / f"{img_hash}.jpg"
    cleaned_path = CLEANED_DIR / f"{img_hash}.png"

    result = {
        "barcode": barcode,
        "objectID": food["objectID"],
        "sourceIndex": food["sourceIndex"],
        "name": food["name"],
        "status": "pending",
    }

    # Step 2: Fetch from OFF
    if not original_path.exists():
        off_url = fetch_off_image(barcode)
        if not off_url:
            result["status"] = "no_off_image"
            return result

        if not download_image(off_url, original_path):
            result["status"] = "download_failed"
            return result

        result["offImageUrl"] = off_url

    if download_only:
        result["status"] = "downloaded"
        return result

    # Step 3: Clean with rembg
    if not cleaned_path.exists():
        if not clean_image(original_path, cleaned_path):
            result["status"] = "clean_failed"
            return result

    result["localCleanedPath"] = str(cleaned_path)
    result["status"] = "cleaned"

    return result

def process_batch(foods, args):
    """Process a batch of foods."""
    checkpoint = load_checkpoint()
    processed_barcodes = set(checkpoint["processed"])

    # Filter out already processed
    to_process = [f for f in foods if f["barcode"] not in processed_barcodes]

    if args.resume:
        print(f"\n📌 Resuming from checkpoint: {len(processed_barcodes)} already done")

    print(f"\n🔄 Processing {len(to_process)} foods...")

    results = {
        "success": [],
        "no_image": [],
        "failed": [],
    }

    start_time = time.time()

    for i, food in enumerate(to_process):
        barcode = food["barcode"]
        name = food["name"][:40] if food["name"] else "Unknown"

        print(f"\n[{i+1}/{len(to_process)}] {barcode} - {name}")

        result = process_food(food, download_only=args.download_only)

        if result["status"] == "cleaned" or result["status"] == "downloaded":
            print(f"  ✅ {result['status']}")
            results["success"].append(result)
            checkpoint["processed"].append(barcode)
        elif result["status"] == "no_off_image":
            print(f"  ⚪ No image in OFF")
            results["no_image"].append(result)
            checkpoint["processed"].append(barcode)
        else:
            print(f"  ❌ {result['status']}")
            results["failed"].append(result)
            checkpoint["failed"].append(barcode)

        # Save checkpoint every 50 items
        if (i + 1) % 50 == 0:
            save_checkpoint(checkpoint)
            elapsed = time.time() - start_time
            rate = (i + 1) / elapsed
            remaining = (len(to_process) - i - 1) / rate / 3600
            print(f"\n  💾 Checkpoint saved. Rate: {rate:.1f}/sec, ETA: {remaining:.1f}h")

    # Final save
    save_checkpoint(checkpoint)

    # Summary
    elapsed = time.time() - start_time
    print(f"\n" + "="*60)
    print(f"✅ Complete!")
    print(f"  Success: {len(results['success'])}")
    print(f"  No OFF image: {len(results['no_image'])}")
    print(f"  Failed: {len(results['failed'])}")
    print(f"  Time: {elapsed/60:.1f} minutes")
    print(f"="*60)

    # Save results
    with open(RESULTS_FILE, "w") as f:
        json.dump(results, f, indent=2)

    return results

def upload_results():
    """Upload cleaned images to Firebase Storage and update Firestore."""
    print("\n☁️  Uploading to Firebase Storage...")

    if not init_firebase():
        print("  Skipping upload - Firebase not configured")
        return

    # Load results
    if not RESULTS_FILE.exists():
        print("  No results file found. Run processing first.")
        return

    with open(RESULTS_FILE) as f:
        results = json.load(f)

    success_items = results.get("success", [])

    print(f"  {len(success_items)} images to upload")

    uploaded = 0
    for item in success_items:
        if "localCleanedPath" not in item:
            continue

        local_path = Path(item["localCleanedPath"])
        if not local_path.exists():
            continue

        barcode = item["barcode"]
        remote_path = f"food-images/cleaned/{barcode}.png"

        print(f"  Uploading {barcode}...", end=" ", flush=True)

        url = upload_to_storage(local_path, remote_path)
        if url:
            item["uploadedUrl"] = url
            uploaded += 1
            print("✅")

            # Update Firestore if applicable
            collection = INDEX_TO_COLLECTION.get(item.get("sourceIndex"))
            if collection:
                update_firestore(collection, item["objectID"], url)
        else:
            print("❌")

    print(f"\n  Uploaded: {uploaded}/{len(success_items)}")

    # Save updated results
    with open(RESULTS_FILE, "w") as f:
        json.dump(results, f, indent=2)

# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="NutraSafe Batch Image Processor")
    parser.add_argument("--test", type=int, metavar="N", help="Test with N images")
    parser.add_argument("--all", action="store_true", help="Process all images")
    parser.add_argument("--resume", action="store_true", help="Resume from checkpoint")
    parser.add_argument("--download-only", action="store_true", help="Only download, don't clean")
    parser.add_argument("--upload", action="store_true", help="Upload cleaned images to Firebase")
    parser.add_argument("--stats", action="store_true", help="Show statistics only")

    args = parser.parse_args()

    setup_directories()

    if args.upload:
        upload_results()
        return

    if args.stats:
        checkpoint = load_checkpoint()
        print(f"Processed: {len(checkpoint['processed'])}")
        print(f"Failed: {len(checkpoint['failed'])}")
        print(f"Originals: {len(list(ORIGINALS_DIR.glob('*')))}")
        print(f"Cleaned: {len(list(CLEANED_DIR.glob('*')))}")
        return

    # Fetch all barcodes
    foods = fetch_all_barcodes()

    if args.test:
        foods = foods[:args.test]
        print(f"\n🧪 Test mode: Processing {args.test} images")
    elif not args.all and not args.resume:
        print("\nUsage:")
        print("  python process_images.py --test 10    # Test with 10")
        print("  python process_images.py --all        # Process all")
        print("  python process_images.py --resume     # Resume")
        print("  python process_images.py --upload     # Upload to Firebase")
        return

    # Process
    process_batch(foods, args)

    print("\n📁 Output directories:")
    print(f"  Originals: {ORIGINALS_DIR}")
    print(f"  Cleaned:   {CLEANED_DIR}")
    print(f"\nNext step: python process_images.py --upload")

if __name__ == "__main__":
    main()
