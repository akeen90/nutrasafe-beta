#!/bin/bash

# Create VPC connector using IP range instead of subnet
set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
CONNECTOR_NAME="nutrasafe-vpc-connector"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🔧 Creating VPC connector with IP range for NutraSafe..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Set PATH for gcloud
export PATH=$PATH:/Users/aaronkeen/google-cloud-sdk/bin

# Get the static IP address
STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME \
    --region=$REGION \
    --format="value(address)")

echo "🎯 Using static IP: $STATIC_IP"

# Check if connector exists
if gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; then
    echo "🗑️  Deleting existing connector..."
    gcloud compute networks vpc-access connectors delete $CONNECTOR_NAME \
        --region=$REGION \
        --quiet
    
    echo "⏳ Waiting for deletion..."
    while gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; do
        echo "   Still deleting... waiting 10 seconds"
        sleep 10
    done
    echo "✅ Old connector deleted!"
fi

# Create VPC connector using IP range (simpler approach)
echo "🔗 Creating VPC connector with IP range..."
echo "⏳ This takes 3-5 minutes - grab that coffee! ☕"

gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
    --network=$VPC_NAME \
    --region=$REGION \
    --range=10.0.2.0/28 \
    --min-instances=2 \
    --max-instances=3 \
    --machine-type=e2-micro

echo ""
echo "✅ VPC connector created successfully!"

# Verify the connector status
echo "🔍 Verifying connector status..."
sleep 5
FINAL_STATUS=$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --format="value(state)")
echo "Connector status: $FINAL_STATUS"

echo ""
echo "🎉 VPC connector setup completed!"
echo ""
echo "📋 Your Configuration:"
echo "  🎯 Static IP: $STATIC_IP"
echo "  🌐 VPC Network: $VPC_NAME"
echo "  🔗 VPC Connector: $CONNECTOR_NAME ($FINAL_STATUS)"
echo "  📡 Connector Range: 10.0.2.0/28"
echo ""
echo "✅ Ready for Firebase Functions deployment!"
echo ""
echo "🔧 Next Steps:"
echo "   1. Deploy functions: ./deploy-static-functions.sh"
echo "   2. Add IP to FatSecret: $STATIC_IP"
echo "   3. Test static IP: curl https://us-central1-nutrasafe-705c7.cloudfunctions.net/checkIP"
echo ""
echo "🍌 Test food search:"
echo "   curl -X POST -H 'Content-Type: application/json' -d '{\"query\": \"banana\"}' \\"
echo "        https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoods"