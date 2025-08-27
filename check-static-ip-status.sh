#!/bin/bash

# Check existing static IP infrastructure
set -e

PROJECT_ID="nutrasafe-705c7"
REGION="us-central1"
VPC_NAME="nutrasafe-vpc"
SUBNET_NAME="nutrasafe-subnet"
CONNECTOR_NAME="nutrasafe-vpc-connector"
NAT_GATEWAY_NAME="nutrasafe-nat-gateway"
ROUTER_NAME="nutrasafe-router"
STATIC_IP_NAME="nutrasafe-static-ip"

echo "🔍 Checking existing infrastructure for NutraSafe..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Set PATH for gcloud
export PATH=$PATH:/Users/aaronkeen/google-cloud-sdk/bin

# Check VPC network
echo "🌐 Checking VPC network..."
if gcloud compute networks describe $VPC_NAME >/dev/null 2>&1; then
    echo "✅ VPC network '$VPC_NAME' exists"
else
    echo "❌ VPC network '$VPC_NAME' missing"
fi

# Check subnet
echo "📡 Checking subnet..."
if gcloud compute networks subnets describe $SUBNET_NAME --region=$REGION >/dev/null 2>&1; then
    echo "✅ Subnet '$SUBNET_NAME' exists"
    SUBNET_RANGE=$(gcloud compute networks subnets describe $SUBNET_NAME --region=$REGION --format="value(ipCidrRange)")
    echo "   Range: $SUBNET_RANGE"
else
    echo "❌ Subnet '$SUBNET_NAME' missing"
fi

# Check static IP
echo "🏷️  Checking static IP..."
if gcloud compute addresses describe $STATIC_IP_NAME --region=$REGION >/dev/null 2>&1; then
    STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME --region=$REGION --format="value(address)")
    echo "✅ Static IP '$STATIC_IP_NAME' exists: $STATIC_IP"
else
    echo "❌ Static IP '$STATIC_IP_NAME' missing"
fi

# Check router
echo "🛤️  Checking Cloud Router..."
if gcloud compute routers describe $ROUTER_NAME --region=$REGION >/dev/null 2>&1; then
    echo "✅ Router '$ROUTER_NAME' exists"
else
    echo "❌ Router '$ROUTER_NAME' missing"
fi

# Check NAT gateway
echo "🌍 Checking Cloud NAT..."
if gcloud compute routers nats describe $NAT_GATEWAY_NAME --router=$ROUTER_NAME --region=$REGION >/dev/null 2>&1; then
    echo "✅ NAT gateway '$NAT_GATEWAY_NAME' exists"
else
    echo "❌ NAT gateway '$NAT_GATEWAY_NAME' missing"
fi

# Check VPC connector
echo "🔗 Checking VPC connector..."
if gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION >/dev/null 2>&1; then
    echo "✅ VPC connector '$CONNECTOR_NAME' exists"
    CONNECTOR_STATUS=$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --format="value(state)")
    echo "   Status: $CONNECTOR_STATUS"
else
    echo "❌ VPC connector '$CONNECTOR_NAME' missing"
fi

echo ""
echo "📋 Summary:"
if gcloud compute addresses describe $STATIC_IP_NAME --region=$REGION >/dev/null 2>&1; then
    STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME --region=$REGION --format="value(address)")
    echo "🎯 Your static IP address: $STATIC_IP"
    echo "   Add this IP to your FatSecret API whitelist!"
else
    echo "⚠️  No static IP found - run setup script to complete configuration"
fi