# NutraSafe Background Removal Service

High-quality image background removal using [rembg](https://github.com/danielgatis/rembg) deployed on Google Cloud Run.

## Features

- Removes backgrounds from food product images
- Returns PNG with transparency
- Supports both URL-based and base64 image input
- Batch processing up to 10 images
- Higher quality than browser-based solutions

## Deployment

### Prerequisites

1. [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed
2. Authenticated: `gcloud auth login`
3. Project configured: `gcloud config set project nutrasafe-705c7`

### Deploy to Cloud Run

```bash
cd firebase/rembg-service
./deploy.sh
```

Or manually:

```bash
gcloud run deploy rembg-service \
  --source . \
  --project nutrasafe-705c7 \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 120 \
  --min-instances 0 \
  --max-instances 3
```

### After Deployment

1. Get the service URL from the deployment output
2. Update `imageProcessingService.ts`:

```typescript
const REMBG_SERVICE_URL = 'https://rembg-service-abc123.a.run.app';
const USE_CLOUD_REMBG = true;
```

## API

### Health Check

```bash
curl https://YOUR_SERVICE_URL/
```

### Remove Background (Single Image)

```bash
# From URL
curl -X POST https://YOUR_SERVICE_URL/remove-background \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "https://example.com/food.jpg"}'

# From base64
curl -X POST https://YOUR_SERVICE_URL/remove-background \
  -H "Content-Type: application/json" \
  -d '{"imageData": "data:image/jpeg;base64,/9j/4AAQ..."}'
```

Response:
```json
{
  "success": true,
  "imageData": "data:image/png;base64,...",
  "width": 800,
  "height": 600
}
```

### Batch Processing

```bash
curl -X POST https://YOUR_SERVICE_URL/remove-background-batch \
  -H "Content-Type: application/json" \
  -d '{
    "images": [
      {"id": "1", "imageUrl": "https://example.com/food1.jpg"},
      {"id": "2", "imageUrl": "https://example.com/food2.jpg"}
    ]
  }'
```

## Cost Estimation

- Cloud Run charges: ~$0.00002400 per vCPU-second
- Each image takes ~2-5 seconds to process
- Estimated cost: ~$0.0001-0.0003 per image
- Much cheaper than commercial APIs ($0.10-0.20 per image)

## Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run locally
python main.py
```

Test at http://localhost:8080
