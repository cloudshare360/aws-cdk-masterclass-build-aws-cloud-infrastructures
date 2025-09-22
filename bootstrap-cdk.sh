#!/bin/bash

# AWS CDK Bootstrap Script
# This script bootstraps the AWS CDK in your AWS account and region

set -e  # Exit on any error

echo "🚀 AWS CDK Bootstrap Setup"
echo "=========================="
echo ""

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if AWS CLI is installed
if ! command_exists aws; then
    print_error "AWS CLI is not installed. Please run setup-aws-cdk-env.sh first."
    exit 1
fi

# Check if CDK is installed
if ! command_exists cdk; then
    print_error "AWS CDK is not installed. Please run setup-aws-cdk-env.sh first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS credentials are not configured or invalid. Please check your AWS configuration."
    exit 1
fi

print_success "Prerequisites check passed!"

# Get current AWS account and region information
print_status "Getting AWS account information..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null)

echo "  Account ID: $ACCOUNT_ID"
echo "  Region: $REGION"
echo "  User ARN: $USER_ARN"
echo ""

# Check if CDK is already bootstrapped
print_status "Checking if CDK is already bootstrapped in this region..."
if aws cloudformation describe-stacks --stack-name CDKToolkit --region "$REGION" > /dev/null 2>&1; then
    print_warning "CDK is already bootstrapped in region $REGION"
    echo ""
    
    # Show existing bootstrap stack info
    BOOTSTRAP_VERSION=$(aws cloudformation describe-stacks --stack-name CDKToolkit --region "$REGION" --query 'Stacks[0].Parameters[?ParameterKey==`BootstrapVersion`].ParameterValue' --output text 2>/dev/null || echo "Unknown")
    print_status "Current bootstrap version: $BOOTSTRAP_VERSION"
    
    # Ask if user wants to update/re-bootstrap
    while true; do
        read -p "Would you like to update the bootstrap stack? [y/N]: " update_bootstrap
        update_bootstrap=${update_bootstrap:-N}
        case $update_bootstrap in
            [Yy]* ) 
                FORCE_BOOTSTRAP=true
                break;;
            [Nn]* ) 
                print_status "Skipping bootstrap update."
                FORCE_BOOTSTRAP=false
                break;;
            * ) 
                print_warning "Please answer yes (y) or no (N).";;
        esac
    done
else
    print_status "CDK is not bootstrapped in region $REGION. Proceeding with bootstrap..."
    FORCE_BOOTSTRAP=true
fi

# Perform bootstrap if needed
if [ "$FORCE_BOOTSTRAP" = true ]; then
    echo ""
    print_status "Bootstrapping CDK in account $ACCOUNT_ID, region $REGION..."
    echo "This may take a few minutes..."
    echo ""
    
    # Run CDK bootstrap with verbose output
    if cdk bootstrap aws://$ACCOUNT_ID/$REGION --verbose; then
        print_success "CDK bootstrap completed successfully!"
        
        # Verify bootstrap
        print_status "Verifying bootstrap..."
        if aws cloudformation describe-stacks --stack-name CDKToolkit --region "$REGION" > /dev/null 2>&1; then
            BOOTSTRAP_VERSION=$(aws cloudformation describe-stacks --stack-name CDKToolkit --region "$REGION" --query 'Stacks[0].Parameters[?ParameterKey==`BootstrapVersion`].ParameterValue' --output text 2>/dev/null || echo "Unknown")
            STACK_STATUS=$(aws cloudformation describe-stacks --stack-name CDKToolkit --region "$REGION" --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
            
            print_success "Bootstrap verification passed!"
            echo "  Bootstrap Version: $BOOTSTRAP_VERSION"
            echo "  Stack Status: $STACK_STATUS"
        else
            print_warning "Could not verify bootstrap stack, but bootstrap command succeeded."
        fi
    else
        print_error "CDK bootstrap failed!"
        exit 1
    fi
fi

# Show bootstrap resources created
echo ""
print_status "Bootstrap resources created in your AWS account:"
echo "• S3 bucket for CDK assets (cdk-{qualifier}-assets-{account}-{region})"
echo "• ECR repository for CDK container images"
echo "• IAM roles for CDK deployments"
echo "• CloudFormation stack: CDKToolkit"
echo ""

# Final summary
echo "🎉 CDK Bootstrap Summary"
echo "======================="
print_success "Account: $ACCOUNT_ID"
print_success "Region: $REGION"
if [ "$FORCE_BOOTSTRAP" = true ]; then
    print_success "Bootstrap: Completed"
else
    print_success "Bootstrap: Already exists (no changes made)"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Create a new CDK project: mkdir my-cdk-app && cd my-cdk-app"
echo "2. Initialize CDK app: cdk init app --language typescript"
echo "3. Build the project: npm run build"
echo "4. Deploy your stack: cdk deploy"
echo ""

print_success "CDK is now ready for deployment in your AWS account!"