#!/bin/bash

# Fix VPC connector by creating proper subnet
set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
CONNECTOR_SUBNET_NAME="nutrasafe-connector-subnet"
CONNECTOR_NAME="nutrasafe-vpc-connector"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🔧 Fixing VPC connector subnet for NutraSafe..."
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

# Create a dedicated subnet for VPC connector with /28 CIDR
echo "📡 Creating dedicated VPC connector subnet..."
if ! gcloud compute networks subnets describe $CONNECTOR_SUBNET_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating connector subnet with /28 CIDR..."
    gcloud compute networks subnets create $CONNECTOR_SUBNET_NAME \
        --network=$VPC_NAME \
        --range=10.0.1.0/28 \
        --region=$REGION
    echo "✅ Connector subnet created successfully!"
else
    echo "✅ Connector subnet already exists"
fi

# Now create VPC connector with the proper subnet
echo "🔗 Creating VPC connector..."
if ! gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating VPC connector with dedicated subnet... (this takes 3-5 minutes)"
    echo "☕ Perfect time for that coffee!"
    
    gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
        --subnet=$CONNECTOR_SUBNET_NAME \
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
echo "🎉 VPC connector setup completed!"
echo ""
echo "📋 Your Configuration:"
echo "  🎯 Static IP: $STATIC_IP"
echo "  🌐 VPC Network: $VPC_NAME"
echo "  📡 Main Subnet: nutrasafe-subnet (10.0.0.0/24)"
echo "  📡 Connector Subnet: $CONNECTOR_SUBNET_NAME (10.0.1.0/28)"
echo "  🔗 VPC Connector: $CONNECTOR_NAME"
echo ""
echo "✅ Ready for Firebase Functions deployment!"
echo ""
echo "🔧 Next Steps:"
echo "   1. Deploy functions: ./deploy-static-functions.sh"
echo "   2. Add IP to FatSecret whitelist: $STATIC_IP"
echo "   3. Test: curl https://us-central1-nutrasafe-705c7.cloudfunctions.net/checkIP"