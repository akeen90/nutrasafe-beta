#!/bin/bash

# Complete the static IP setup by creating only missing components
set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
SUBNET_NAME="nutrasafe-subnet"
CONNECTOR_NAME="nutrasafe-vpc-connector"
ROUTER_NAME="nutrasafe-router"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🔧 Completing static IP setup for NutraSafe..."
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
echo ""

# Check if VPC connector exists, if not create it
echo "🔗 Checking VPC connector..."
if ! gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating VPC connector... (this takes 3-5 minutes)"
    echo "☕ Time for a coffee break!"
    
    gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
        --subnet=$SUBNET_NAME \
        --subnet-project=$PROJECT_ID \
        --region=$REGION \
        --min-instances=2 \
        --max-instances=3 \
        --machine-type=e2-micro
    
    echo "✅ VPC connector created successfully!"
else
    echo "✅ VPC connector already exists"
    CONNECTOR_STATUS=$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --format="value(state)")
    echo "   Status: $CONNECTOR_STATUS"
fi

echo ""
echo "🎉 Static IP setup completed!"
echo ""
echo "📋 Your Configuration:"
echo "  🎯 Static IP: $STATIC_IP"
echo "  🌐 VPC Network: $VPC_NAME"
echo "  📡 Subnet: $SUBNET_NAME ($REGION)"
echo "  🔗 VPC Connector: $CONNECTOR_NAME"
echo ""
echo "✅ Ready for Firebase Functions deployment!"
echo ""
echo "🔧 Next Step: Deploy your functions with VPC connector:"
echo "   cd '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta'"
echo "   ./deploy-static-functions.sh"
echo ""
echo "📌 Add this IP to FatSecret whitelist: $STATIC_IP"