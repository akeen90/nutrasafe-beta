#!/bin/bash
# Deploy NutraSafe Background Removal Service to Cloud Run

# Configuration
PROJECT_ID="nutrasafe-705c7"
SERVICE_NAME="rembg-service"
REGION="us-central1"

echo "Building and deploying $SERVICE_NAME to Cloud Run..."

# Build and deploy in one command (uses Cloud Build)
gcloud run deploy $SERVICE_NAME \
  --source . \
  --project $PROJECT_ID \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 120 \
  --min-instances 0 \
  --max-instances 3 \
  --concurrency 4

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --project $PROJECT_ID --region $REGION --format='value(status.url)')

echo ""
echo "Deployment complete!"
echo "Service URL: $SERVICE_URL"
echo ""
echo "Test with:"
echo "  curl $SERVICE_URL"
echo ""
echo "Update your imageProcessingService.ts with:"
echo "  const REMBG_SERVICE_URL = '$SERVICE_URL';"
