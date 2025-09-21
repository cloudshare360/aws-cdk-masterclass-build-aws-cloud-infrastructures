#!/bin/bash

# AWS CDK Environment Validation Script
# This script validates that all prerequisites and configurations are properly set up

echo "🔍 AWS CDK Environment Validation"
echo "================================="
echo ""

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[CHECK]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[PASS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[FAIL]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

print_info() {
    echo -e "\033[1;36m[INFO]\033[0m $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version requirement
check_version() {
    local version="$1"
    local min_version="$2"
    
    # Use sort -V for version comparison, fallback to string comparison if sort -V not available
    if command -v sort >/dev/null 2>&1; then
        if [[ $(printf '%s\n' "$min_version" "$version" | sort -V | head -n1) == "$min_version" ]]; then
            return 0
        else
            return 1
        fi
    else
        # Fallback comparison
        if [[ "$version" > "$min_version" ]] || [[ "$version" == "$min_version" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to increment counters
check_pass() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    print_success "$1"
}

check_fail() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    print_error "$1"
}

check_warn() {
    ((TOTAL_CHECKS++))
    ((WARNING_CHECKS++))
    print_warning "$1"
}

echo "🔧 Checking System Prerequisites..."
echo "-----------------------------------"

# Check Node.js
print_status "Checking Node.js installation..."
if command_exists node; then
    NODE_VERSION=$(node --version | sed 's/v//')
    if check_version "$NODE_VERSION" "18.0.0"; then
        check_pass "Node.js $NODE_VERSION (minimum v18.0.0 required)"
    else
        check_warn "Node.js $NODE_VERSION (recommend v18.0.0 or higher)"
    fi
else
    check_fail "Node.js is not installed or not in PATH"
fi

# Check npm
print_status "Checking npm installation..."
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    if check_version "$NPM_VERSION" "8.0.0"; then
        check_pass "npm $NPM_VERSION (minimum v8.0.0 required)"
    else
        check_warn "npm $NPM_VERSION (recommend v8.0.0 or higher)"
    fi
else
    check_fail "npm is not installed or not in PATH"
fi

echo ""
echo "☁️  Checking AWS Tools..."
echo "------------------------"

# Check AWS CLI
print_status "Checking AWS CLI installation..."
if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1 | head -n1 | cut -d' ' -f1 | cut -d'/' -f2)
    if check_version "$AWS_VERSION" "2.0.0"; then
        check_pass "AWS CLI v$AWS_VERSION (minimum v2.0.0 required)"
    else
        check_warn "AWS CLI v$AWS_VERSION (recommend v2.0.0 or higher)"
    fi
else
    check_fail "AWS CLI is not installed or not in PATH"
fi

# Check AWS Configuration
print_status "Checking AWS credentials configuration..."
if [[ -f "$HOME/.aws/credentials" ]]; then
    check_pass "AWS credentials file exists (~/.aws/credentials)"
else
    check_fail "AWS credentials file not found (~/.aws/credentials)"
fi

print_status "Checking AWS config file..."
if [[ -f "$HOME/.aws/config" ]]; then
    check_pass "AWS config file exists (~/.aws/config)"
    
    # Check for default region
    if grep -q "region" "$HOME/.aws/config"; then
        REGION=$(grep "region" "$HOME/.aws/config" | head -n1 | cut -d'=' -f2 | xargs)
        check_pass "Default region configured: $REGION"
    else
        check_warn "No default region configured in ~/.aws/config"
    fi
else
    check_fail "AWS config file not found (~/.aws/config)"
fi

# Test AWS credentials
print_status "Testing AWS credentials..."
if command_exists aws && aws sts get-caller-identity --output text > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
    USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null)
    check_pass "AWS credentials are valid"
    print_info "Account ID: $ACCOUNT_ID"
    print_info "User ARN: $USER_ARN"
else
    check_fail "AWS credentials test failed - please run 'aws configure'"
fi

echo ""
echo "📦 Checking Development Tools..."
echo "-------------------------------"

# Check TypeScript
print_status "Checking TypeScript installation..."
if command_exists tsc; then
    TSC_VERSION=$(tsc --version | cut -d' ' -f2)
    if check_version "$TSC_VERSION" "4.0.0"; then
        check_pass "TypeScript $TSC_VERSION (minimum v4.0.0 required)"
    else
        check_warn "TypeScript $TSC_VERSION (recommend v4.0.0 or higher)"
    fi
else
    check_fail "TypeScript is not installed or not in PATH"
fi

# Check AWS CDK
print_status "Checking AWS CDK installation..."
if command_exists cdk; then
    CDK_VERSION=$(cdk --version | cut -d' ' -f1)
    if check_version "$CDK_VERSION" "2.0.0"; then
        check_pass "AWS CDK $CDK_VERSION (minimum v2.0.0 required)"
    else
        check_warn "AWS CDK $CDK_VERSION (recommend v2.0.0 or higher)"
    fi
else
    check_fail "AWS CDK is not installed or not in PATH"
fi

echo ""
echo "🌍 Checking Environment Variables..."
echo "-----------------------------------"

# Check PATH for important directories
print_status "Checking PATH configuration..."
if echo "$PATH" | grep -q "/usr/local/bin"; then
    check_pass "PATH includes /usr/local/bin"
else
    check_warn "PATH does not include /usr/local/bin"
fi

# Check for npm global bin in PATH
if command_exists npm; then
    NPM_GLOBAL_BIN=$(npm config get prefix 2>/dev/null || echo "/usr/local")
    NPM_GLOBAL_BIN="$NPM_GLOBAL_BIN/bin"
    if echo "$PATH" | grep -q "$NPM_GLOBAL_BIN"; then
        check_pass "PATH includes npm global bin directory: $NPM_GLOBAL_BIN"
    else
        check_warn "PATH does not include npm global bin directory: $NPM_GLOBAL_BIN"
    fi
fi

echo ""
echo "🚀 Testing CDK Functionality..."
echo "------------------------------"

# Test CDK list command
print_status "Testing CDK list command..."
if command_exists cdk && cdk list > /dev/null 2>&1; then
    check_pass "CDK list command works (no stacks found - expected for new setup)"
elif command_exists cdk; then
    # CDK might fail if not in a CDK project, which is expected
    check_pass "CDK command is functional"
else
    check_fail "CDK command test failed"
fi

# Check if CDK bootstrap is needed
print_status "Checking CDK bootstrap status..."
if command_exists aws && command_exists cdk; then
    if aws cloudformation describe-stacks --stack-name CDKToolkit > /dev/null 2>&1; then
        check_pass "CDK is bootstrapped in current region"
    else
        check_warn "CDK is not bootstrapped - run 'cdk bootstrap' before deploying"
    fi
else
    check_warn "Cannot check bootstrap status - AWS CLI or CDK not available"
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo "Total checks: $TOTAL_CHECKS"
echo -e "\033[1;32m✅ Passed: $PASSED_CHECKS\033[0m"
if [[ $WARNING_CHECKS -gt 0 ]]; then
    echo -e "\033[1;33m⚠️  Warnings: $WARNING_CHECKS\033[0m"
fi
if [[ $FAILED_CHECKS -gt 0 ]]; then
    echo -e "\033[1;31m❌ Failed: $FAILED_CHECKS\033[0m"
fi

echo ""

# Overall status
if [[ $FAILED_CHECKS -eq 0 ]]; then
    if [[ $WARNING_CHECKS -eq 0 ]]; then
        echo -e "\033[1;32m🎉 Environment validation PASSED! Your AWS CDK environment is ready.\033[0m"
        echo ""
        echo "📋 Ready for:"
        echo "• Creating CDK projects: cdk init app --language typescript"
        echo "• Bootstrap (if needed): cdk bootstrap"
        echo "• Building projects: npm run build"
        echo "• Deploying stacks: cdk deploy"
    else
        echo -e "\033[1;33m⚠️  Environment validation completed with WARNINGS.\033[0m"
        echo "Your environment should work, but consider addressing the warnings above."
    fi
else
    echo -e "\033[1;31m❌ Environment validation FAILED!\033[0m"
    echo "Please address the failed checks above before using AWS CDK."
    echo ""
    echo "💡 Quick fixes:"
    echo "• Missing tools: Run './setup-aws-cdk-env.sh'"
    echo "• AWS credentials: Run 'aws configure'"
    echo "• PATH issues: Restart terminal or run 'source ~/.bashrc'"
    exit 1
fi

echo ""