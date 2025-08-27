#!/bin/bash

# Recreate VPC connector with proper configuration
set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
CONNECTOR_SUBNET_NAME="nutrasafe-connector-subnet"
CONNECTOR_NAME="nutrasafe-vpc-connector"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🔧 Recreating VPC connector for NutraSafe..."
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

# Check current connector status
echo "🔍 Checking current VPC connector status..."
CONNECTOR_STATUS=$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --format="value(state)" 2>/dev/null || echo "NOT_FOUND")
echo "Current status: $CONNECTOR_STATUS"

# Delete the broken connector if it exists
if [ "$CONNECTOR_STATUS" != "NOT_FOUND" ]; then
    echo "🗑️  Deleting broken VPC connector..."
    gcloud compute networks vpc-access connectors delete $CONNECTOR_NAME \
        --region=$REGION \
        --quiet
    
    echo "⏳ Waiting for deletion to complete..."
    while gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; do
        echo "   Still deleting... waiting 10 seconds"
        sleep 10
    done
    echo "✅ Old connector deleted successfully!"
fi

# Ensure connector subnet exists with correct CIDR
echo "📡 Ensuring connector subnet is properly configured..."
if ! gcloud compute networks subnets describe $CONNECTOR_SUBNET_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating connector subnet..."
    gcloud compute networks subnets create $CONNECTOR_SUBNET_NAME \
        --network=$VPC_NAME \
        --range=10.0.1.0/28 \
        --region=$REGION
else
    SUBNET_RANGE=$(gcloud compute networks subnets describe $CONNECTOR_SUBNET_NAME --region=$REGION --format="value(ipCidrRange)")
    echo "✅ Connector subnet exists with range: $SUBNET_RANGE"
fi

# Create new VPC connector
echo "🔗 Creating new VPC connector..."
echo "⏳ This will take 3-5 minutes - perfect time for a coffee break! ☕"

gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
    --subnet=$CONNECTOR_SUBNET_NAME \
    --subnet-project=$PROJECT_ID \
    --region=$REGION \
    --min-instances=2 \
    --max-instances=3 \
    --machine-type=e2-micro

echo ""
echo "✅ VPC connector created successfully!"

# Verify the new connector status
echo "🔍 Verifying new connector..."
FINAL_STATUS=$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --format="value(state)")
echo "Final status: $FINAL_STATUS"

echo ""
echo "🎉 VPC connector recreation completed!"
echo ""
echo "📋 Your Configuration:"
echo "  🎯 Static IP: $STATIC_IP"
echo "  🌐 VPC Network: $VPC_NAME"  
echo "  📡 Connector Subnet: $CONNECTOR_SUBNET_NAME (10.0.1.0/28)"
echo "  🔗 VPC Connector: $CONNECTOR_NAME ($FINAL_STATUS)"
echo ""
echo "✅ Ready for Firebase Functions deployment!"
echo ""
echo "🔧 Next Steps:"
echo "   1. Deploy functions: ./deploy-static-functions.sh"
echo "   2. Add IP to FatSecret whitelist: $STATIC_IP"
echo "   3. Test: curl https://us-central1-nutrasafe-705c7.cloudfunctions.net/checkIP"