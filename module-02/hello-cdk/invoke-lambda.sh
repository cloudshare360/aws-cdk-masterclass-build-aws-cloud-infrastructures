#!/bin/bash

# Simple Lambda Invoker Script
# Usage: ./invoke-lambda.sh [payload-file]

FUNCTION_NAME="HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz"
RESPONSE_FILE="response.json"

echo "🚀 Invoking Lambda Function: $FUNCTION_NAME"
echo "==============================================="

if [ "$1" ]; then
    echo "📦 Using payload file: $1"
    aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        --payload "file://$1" \
        "$RESPONSE_FILE"
else
    echo "📦 No payload provided, using empty payload"
    aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        "$RESPONSE_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Function invoked successfully!"
    echo "📋 Response:"
    echo "============"
    cat "$RESPONSE_FILE" | jq . 2>/dev/null || cat "$RESPONSE_FILE"
    echo ""
    echo ""
    echo "💡 Raw response saved to: $RESPONSE_FILE"
else
    echo "❌ Function invocation failed!"
    exit 1
fi