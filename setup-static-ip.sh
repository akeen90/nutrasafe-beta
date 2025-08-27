#!/bin/bash

# NutraSafe Static IP Setup Script
# Run this script to configure static IP for Firebase Functions

set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
SUBNET_NAME="nutrasafe-subnet"
CONNECTOR_NAME="nutrasafe-vpc-connector"
NAT_GATEWAY_NAME="nutrasafe-nat-gateway"
ROUTER_NAME="nutrasafe-router"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🚀 Setting up static IP for NutraSafe Firebase Functions..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Set PATH for gcloud
export PATH=$PATH:/Users/aaronkeen/google-cloud-sdk/bin

# Set project
echo "📁 Setting project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable vpcaccess.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

echo ""
echo "🌐 Checking/Creating VPC network..."
# Create VPC network if it doesn't exist
if ! gcloud compute networks describe $VPC_NAME >/dev/null 2>&1; then
    echo "Creating VPC network..."
    gcloud compute networks create $VPC_NAME \
        --subnet-mode=custom \
        --bgp-routing-mode=regional
else
    echo "✅ VPC network '$VPC_NAME' already exists"
fi

# Create subnet
echo "📡 Checking/Creating subnet..."
if ! gcloud compute networks subnets describe $SUBNET_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating subnet..."
    gcloud compute networks subnets create $SUBNET_NAME \
        --network=$VPC_NAME \
        --range=10.0.0.0/24 \
        --region=$REGION
else
    echo "✅ Subnet '$SUBNET_NAME' already exists"
fi

# Reserve static IP
echo "🏷️  Checking/Reserving static IP address..."
if ! gcloud compute addresses describe $STATIC_IP_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Reserving static IP..."
    gcloud compute addresses create $STATIC_IP_NAME --region=$REGION
else
    echo "✅ Static IP '$STATIC_IP_NAME' already exists"
fi

# Get the static IP address
STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME \
    --region=$REGION \
    --format="value(address)")

echo "✅ Static IP: $STATIC_IP"

# Create Cloud Router
echo "🛤️  Checking/Creating Cloud Router..."
if ! gcloud compute routers describe $ROUTER_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating Cloud Router..."
    gcloud compute routers create $ROUTER_NAME \
        --network=$VPC_NAME \
        --region=$REGION
else
    echo "✅ Router '$ROUTER_NAME' already exists"
fi

# Create Cloud NAT
echo "🌍 Checking/Creating Cloud NAT with static IP..."
if ! gcloud compute routers nats describe $NAT_GATEWAY_NAME --router=$ROUTER_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating Cloud NAT..."
    gcloud compute routers nats create $NAT_GATEWAY_NAME \
        --router=$ROUTER_NAME \
        --region=$REGION \
        --nat-external-ip-pool=$STATIC_IP_NAME \
        --nat-all-subnet-ip-ranges
else
    echo "✅ NAT gateway '$NAT_GATEWAY_NAME' already exists"
fi

# Create VPC Connector for Firebase Functions
echo "🔗 Checking/Creating VPC connector for Firebase Functions..."
if ! gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; then
    echo "Creating VPC connector... (this may take a few minutes)"
    gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
        --subnet=$SUBNET_NAME \
        --subnet-project=$PROJECT_ID \
        --region=$REGION \
        --min-instances=2 \
        --max-instances=3 \
        --machine-type=e2-micro
else
    echo "✅ VPC connector '$CONNECTOR_NAME' already exists"
fi

echo ""
echo "🎉 Static IP setup completed!"
echo ""
echo "📋 Configuration Summary:"
echo "  Static IP: $STATIC_IP"
echo "  VPC Network: $VPC_NAME"
echo "  Subnet: $SUBNET_NAME"
echo "  VPC Connector: $CONNECTOR_NAME"
echo "  Region: $REGION"
echo ""
echo "🔧 Next Step: Update Firebase Functions to use VPC connector"
echo "   Add this to your firebase/functions/src/index.ts:"
echo ""
echo "   export const searchFoods = functions"
echo "     .runWith({"
echo "       vpcConnector: '$CONNECTOR_NAME',"
echo "       vpcConnectorEgressSettings: 'ALL_TRAFFIC'"
echo "     })"
echo "     .https.onRequest(...);"
echo ""
echo "🌟 All outbound traffic from Firebase Functions will now use: $STATIC_IP"
echo "   Add this IP to your FatSecret API whitelist!"