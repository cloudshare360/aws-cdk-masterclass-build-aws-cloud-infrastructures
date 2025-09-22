#!/bin/bash

# AWS CDK Environment Setup Script
# This script installs AWS CLI v2, TypeScript, AWS CDK and configures the environment

set -e  # Exit on any error

echo "🚀 Starting AWS CDK Prerequisites Installation..."
echo "================================================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Function to update PATH in profile files
update_path() {
    local path_to_add="$1"
    local profile_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    
    for profile_file in "${profile_files[@]}"; do
        if [[ -f "$profile_file" ]]; then
            if ! grep -q "$path_to_add" "$profile_file"; then
                echo "export PATH=\"$path_to_add:\$PATH\"" >> "$profile_file"
                print_status "Added $path_to_add to $profile_file"
            else
                print_status "$path_to_add already exists in $profile_file"
            fi
        fi
    done
}

# Function to read AWS credentials from CSV file
read_aws_credentials_from_csv() {
    local csv_file="$1"
    
    if [[ ! -f "$csv_file" ]]; then
        print_error "CSV file not found: $csv_file"
        return 1
    fi
    
    # Skip header line and read the first data line
    local credentials_line
    credentials_line=$(tail -n +2 "$csv_file" | head -n 1)
    
    if [[ -z "$credentials_line" ]]; then
        print_error "No credentials found in CSV file"
        return 1
    fi
    
    # Parse CSV line (assuming comma-separated values)
    IFS=',' read -r aws_access_key_id aws_secret_access_key <<< "$credentials_line"
    
    # Remove any leading/trailing whitespace
    aws_access_key_id=$(echo "$aws_access_key_id" | xargs)
    aws_secret_access_key=$(echo "$aws_secret_access_key" | xargs)
    
    if [[ -z "$aws_access_key_id" || -z "$aws_secret_access_key" ]]; then
        print_error "Invalid credentials format in CSV file"
        return 1
    fi
    
    export aws_access_key_id
    export aws_secret_access_key
    return 0
}

# Function to configure AWS profile
configure_aws_profile() {
    print_status "Starting AWS profile configuration..."
    
    echo ""
    echo "🔧 AWS Configuration Setup"
    echo "=========================="
    
    # Try to read credentials from CSV file first
    local csv_file
    csv_file="$(dirname "$0")/master-root.csv"
    
    if read_aws_credentials_from_csv "$csv_file"; then
        print_success "Successfully read AWS credentials from $csv_file"
        echo "  Access Key ID: ${aws_access_key_id:0:10}..."
    else
        print_warning "Could not read from CSV file, falling back to interactive input"
        echo "Please provide your AWS credentials and configuration:"
        echo ""
        
        # Prompt for AWS Access Key ID
        while true; do
            read -p "Enter AWS Access Key ID: " aws_access_key_id
            if [[ -n "$aws_access_key_id" ]]; then
                break
            else
                print_warning "AWS Access Key ID cannot be empty. Please try again."
            fi
        done
        
        # Prompt for AWS Secret Access Key
        while true; do
            read -s -p "Enter AWS Secret Access Key: " aws_secret_access_key
            echo ""
            if [[ -n "$aws_secret_access_key" ]]; then
                break
            else
                print_warning "AWS Secret Access Key cannot be empty. Please try again."
            fi
        done
    fi
    
    # Set default region and output format
    aws_region="us-east-1"
    aws_output="json"
    
    # Create AWS credentials directory if it doesn't exist
    mkdir -p "$HOME/.aws"
    
    # Configure AWS credentials
    cat > "$HOME/.aws/credentials" << EOF
[default]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
EOF
    
    # Configure AWS config
    cat > "$HOME/.aws/config" << EOF
[default]
region = $aws_region
output = $aws_output
EOF
    
    # Set proper permissions
    chmod 600 "$HOME/.aws/credentials"
    chmod 644 "$HOME/.aws/config"
    
    print_success "AWS profile configured successfully!"
    echo "  Region: $aws_region"
    echo "  Output format: $aws_output"
    echo ""
}

# Check if Node.js is installed
print_status "Checking Node.js installation..."
if ! command_exists node; then
    print_error "Node.js is not installed. Please install Node.js first."
    echo "Visit: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version)
print_success "Node.js is installed: $NODE_VERSION"

# Check if npm is installed
if ! command_exists npm; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

NPM_VERSION=$(npm --version)
print_success "npm is installed: $NPM_VERSION"

# Install AWS CLI v2
print_status "Installing AWS CLI v2..."
if command_exists aws; then
    AWS_VERSION=$(aws --version)
    print_success "AWS CLI is already installed: $AWS_VERSION"
else
    print_status "Downloading AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    
    print_status "Extracting AWS CLI..."
    unzip -q awscliv2.zip
    
    print_status "Installing AWS CLI..."
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    
    # Update PATH for AWS CLI
    update_path "/usr/local/bin"
    
    print_status "Cleaning up..."
    rm -rf awscliv2.zip aws/
    
    if command_exists aws; then
        AWS_VERSION=$(aws --version)
        print_success "AWS CLI v2 installed successfully: $AWS_VERSION"
    else
        print_error "AWS CLI installation failed"
        exit 1
    fi
fi

# Install TypeScript globally
print_status "Installing TypeScript globally..."
if command_exists tsc; then
    TSC_VERSION=$(tsc --version)
    print_success "TypeScript is already installed: $TSC_VERSION"
else
    npm install -g typescript
    
    # Get npm global bin path and update PATH
    NPM_GLOBAL_BIN=$(npm config get prefix 2>/dev/null)/bin || NPM_GLOBAL_BIN="/usr/local/bin"
    update_path "$NPM_GLOBAL_BIN"
    
    if command_exists tsc; then
        TSC_VERSION=$(tsc --version)
        print_success "TypeScript installed successfully: $TSC_VERSION"
    else
        print_error "TypeScript installation failed"
        exit 1
    fi
fi

# Install AWS CDK globally
print_status "Installing AWS CDK globally..."
if command_exists cdk; then
    CDK_VERSION=$(cdk --version)
    print_success "AWS CDK is already installed: $CDK_VERSION"
else
    npm install -g aws-cdk
    
    # Get npm global bin path and update PATH (if not already done)
    NPM_GLOBAL_BIN=$(npm config get prefix 2>/dev/null)/bin || NPM_GLOBAL_BIN="/usr/local/bin"
    update_path "$NPM_GLOBAL_BIN"
    
    if command_exists cdk; then
        CDK_VERSION=$(cdk --version)
        print_success "AWS CDK installed successfully: $CDK_VERSION"
    else
        print_error "AWS CDK installation failed"
        exit 1
    fi
fi

# Verify installations
echo ""
echo "🎉 Installation Summary"
echo "======================"
echo "✅ AWS CLI: $(aws --version 2>&1 | head -n1)"
echo "✅ TypeScript: $(tsc --version)"
echo "✅ AWS CDK: $(cdk --version)"
echo ""

# Update current session PATH
NPM_BIN_PATH=$(npm config get prefix 2>/dev/null)/bin || NPM_BIN_PATH="/usr/local/bin"
export PATH="/usr/local/bin:$NPM_BIN_PATH:$PATH"

print_success "All prerequisites installed successfully!"

# Configure AWS Profile
echo ""
print_status "Setting up AWS configuration..."
configure_aws_profile

# Verify AWS credentials if configured
if [[ -f "$HOME/.aws/credentials" ]]; then
    print_status "Verifying AWS credentials..."
    if aws sts get-caller-identity --output text > /dev/null 2>&1; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
        USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null)
        print_success "AWS credentials verified successfully!"
        echo "  Account ID: $ACCOUNT_ID"
        echo "  User ARN: $USER_ARN"
    else
        print_warning "AWS credentials verification failed. Please check your configuration."
    fi
fi

# Show AWS caller identity (principal ID)
echo ""
print_status "Displaying AWS caller identity..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    aws sts get-caller-identity
else
    print_error "Failed to get AWS caller identity. Please check your AWS credentials."
fi

echo ""
echo "🎉 Environment Setup Complete!"
echo "=============================="
print_success "Please restart your terminal or run 'source ~/.bashrc' to update your PATH."
echo ""
echo "📋 Next Steps:"
echo "1. Verify installation: aws --version && cdk --version && tsc --version"
echo "2. Create a new CDK project: mkdir my-cdk-app && cd my-cdk-app && cdk init app --language typescript"
echo "3. Bootstrap CDK (first time only): cdk bootstrap"
echo "4. Build and deploy: npm run build && cdk deploy"
echo ""

# Run validation script as the final step
echo ""
print_status "Running final environment validation..."
SCRIPT_DIR="$(dirname "$0")"
if [[ -f "$SCRIPT_DIR/validate-aws-cdk-env.sh" ]]; then
    bash "$SCRIPT_DIR/validate-aws-cdk-env.sh"
else
    print_warning "Validation script not found: $SCRIPT_DIR/validate-aws-cdk-env.sh"
fi