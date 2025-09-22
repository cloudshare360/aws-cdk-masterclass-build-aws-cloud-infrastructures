#!/bin/bash

# Smart Lambda Invoker Script
# Automatically discovers and invokes Lambda functions from this CDK stack
# Usage: ./smart-invoke.sh [payload-file]

set -e

echo "🔍 Smart Lambda Invoker"
echo "======================="
echo ""

# Function to get stack name from cdk.json or directory
get_stack_name() {
    if [ -f "cdk.json" ]; then
        # Try to extract app name from cdk.json
        local app_name
        app_name=$(grep -o '"app":[[:space:]]*"[^"]*"' cdk.json | cut -d'"' -f4 | head -1)
        if [ -n "$app_name" ]; then
            echo "$(basename "$(pwd)")Stack"
        else
            echo "$(basename "$(pwd)")Stack"
        fi
    else
        echo "$(basename "$(pwd)")Stack"
    fi
}

# Get the stack name
STACK_NAME=$(get_stack_name)
echo "📦 Looking for Lambda functions in stack: $STACK_NAME"

# Find Lambda functions that belong to this stack
echo "🔎 Discovering Lambda functions..."
LAMBDA_FUNCTIONS=$(aws lambda list-functions \
    --query "Functions[?contains(FunctionName, '$STACK_NAME')].{Name:FunctionName,Runtime:Runtime,Handler:Handler}" \
    --output json)

# Check if any functions were found
FUNCTION_COUNT=$(echo "$LAMBDA_FUNCTIONS" | jq length)

if [ "$FUNCTION_COUNT" -eq 0 ]; then
    echo "❌ No Lambda functions found for stack: $STACK_NAME"
    echo ""
    echo "💡 Available functions:"
    aws lambda list-functions --query 'Functions[].FunctionName' --output table
    exit 1
fi

echo "✅ Found $FUNCTION_COUNT Lambda function(s):"
echo "$LAMBDA_FUNCTIONS" | jq -r '.[] | "  • \(.Name) (\(.Runtime), \(.Handler))"'
echo ""

# If multiple functions, let user choose
if [ "$FUNCTION_COUNT" -gt 1 ]; then
    echo "🎯 Multiple functions found. Please select:"
    echo "$LAMBDA_FUNCTIONS" | jq -r 'to_entries[] | "\(.key + 1). \(.value.Name)"'
    echo ""
    read -p "Enter function number (1-$FUNCTION_COUNT): " SELECTION
    
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$FUNCTION_COUNT" ]; then
        echo "❌ Invalid selection"
        exit 1
    fi
    
    FUNCTION_NAME=$(echo "$LAMBDA_FUNCTIONS" | jq -r ".[$((SELECTION-1))].Name")
else
    # Single function, use it
    FUNCTION_NAME=$(echo "$LAMBDA_FUNCTIONS" | jq -r '.[0].Name')
fi

echo "🚀 Selected function: $FUNCTION_NAME"
echo ""

# Prepare response file
RESPONSE_FILE="response-$(date +%Y%m%d_%H%M%S).json"

# Check if payload file is provided
if [ "$1" ]; then
    if [ ! -f "$1" ]; then
        echo "❌ Payload file not found: $1"
        exit 1
    fi
    
    echo "📦 Using payload file: $1"
    echo "📋 Payload content:"
    echo "==================="
    cat "$1" | jq . 2>/dev/null || cat "$1"
    echo ""
    echo "🔄 Invoking function with payload..."
    
    aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        --payload "file://$1" \
        "$RESPONSE_FILE"
else
    echo "📦 No payload provided, using empty payload"
    echo "🔄 Invoking function..."
    
    aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        "$RESPONSE_FILE"
fi

# Check invocation result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Function invoked successfully!"
    echo ""
    echo "📋 Response:"
    echo "============"
    
    # Try to pretty-print JSON, fallback to raw output
    if command -v jq >/dev/null 2>&1; then
        cat "$RESPONSE_FILE" | jq . 2>/dev/null || cat "$RESPONSE_FILE"
    else
        cat "$RESPONSE_FILE"
    fi
    
    echo ""
    echo "💾 Full response saved to: $RESPONSE_FILE"
    
    # Show CloudWatch logs link
    echo ""
    echo "📊 CloudWatch Logs:"
    echo "==================="
    LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
    echo "Log Group: $LOG_GROUP"
    echo "View logs: aws logs tail $LOG_GROUP"
    echo "Stream logs: aws logs tail $LOG_GROUP --follow"
    
else
    echo "❌ Function invocation failed!"
    exit 1
fi

echo ""
echo "🎉 Invocation complete!"