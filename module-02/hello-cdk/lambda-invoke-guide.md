# Invoking AWS Lambda Functions from Terminal

## Your Lambda Function Details
- **Function Name**: `HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz`
- **Runtime**: Node.js 20.x
- **Handler**: app.handler
- **Memory**: 128 MB

## Method 1: Basic AWS CLI Invoke (Synchronous)

### Simple Invoke without Payload
```bash
cd /workspaces/aws-cdk-ts-master-class/module-02/hello-cdk
aws lambda invoke --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz response.json
cat response.json
```

**Expected Output:**
```json
{"statusCode":200,"body":"{\"message\":\"Hello from CDK!\"}"}
```

### Invoke with JSON Payload (using file)
```bash
# Create payload file
echo '{"name": "John", "age": 30}' > payload.json

# Invoke with payload
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --payload file://payload.json \
  response.json

# View response
cat response.json
```

### Invoke with Inline Payload (Base64 encoded)
```bash
# For simple payloads, encode to base64
echo '{"test": "data"}' | base64 -w 0 > payload.b64

aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --payload fileb://payload.b64 \
  response.json
```

## Method 2: AWS CLI with Different Invocation Types

### Synchronous Invoke (Default - RequestResponse)
```bash
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --invocation-type RequestResponse \
  response.json
```

### Asynchronous Invoke (Event)
```bash
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15gl8quaz \
  --invocation-type Event \
  --payload '{}' \
  response.json
```

### Dry Run (Validate parameters and permissions)
```bash
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --invocation-type DryRun \
  response.json
```

## Method 3: Using AWS CLI with Logs

### Invoke and View Logs
```bash
# Get log group name
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/HelloCdkStack-Hello" \
  --query 'logGroups[0].logGroupName' \
  --output text

# Invoke function
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --log-type Tail \
  response.json

# View recent logs
aws logs tail /aws/lambda/HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz --follow
```

## Method 4: Using Function ARN Instead of Name

```bash
aws lambda invoke \
  --function-name arn:aws:lambda:us-east-1:713665788277:function:HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  response.json
```

## Method 5: Test Different Payloads

### Test with Event-like Payload
```bash
cat > event-payload.json << EOF
{
  "Records": [
    {
      "eventSource": "test",
      "eventName": "TestEvent",
      "body": "Test message from terminal"
    }
  ]
}
EOF

aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --payload file://event-payload.json \
  response.json
```

### Test with API Gateway-like Event
```bash
cat > api-payload.json << EOF
{
  "httpMethod": "GET",
  "path": "/test",
  "queryStringParameters": {
    "param1": "value1"
  },
  "headers": {
    "Content-Type": "application/json"
  },
  "body": null
}
EOF

aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --payload file://api-payload.json \
  response.json
```

## Method 6: Using AWS CLI Aliases (Create Shortcuts)

### Create an alias for easier invocation
```bash
# Add to your ~/.bashrc or ~/.zshrc
alias invoke-hello="aws lambda invoke --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz"

# Then use it like:
invoke-hello response.json
```

## Method 7: Monitoring and Debugging

### Get Function Configuration
```bash
aws lambda get-function \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz
```

### Get Function Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Stream Logs in Real-time
```bash
# Install AWS CLI v2 for log streaming
aws logs tail /aws/lambda/HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz --follow &

# In another terminal, invoke the function
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  response.json
```

## Common Use Cases

### 1. Simple Health Check
```bash
# Quick test to see if function is working
aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  /tmp/response.json && echo "Function is healthy: $(cat /tmp/response.json)"
```

### 2. Load Testing
```bash
# Invoke function multiple times
for i in {1..10}; do
  echo "Invocation $i"
  aws lambda invoke \
    --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
    response_$i.json
done
```

### 3. Performance Testing with Timing
```bash
# Time the invocation
time aws lambda invoke \
  --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
  response.json
```

## Troubleshooting

### Common Errors and Solutions

1. **Function not found**
   ```bash
   # List all functions to verify name
   aws lambda list-functions --query 'Functions[].FunctionName'
   ```

2. **Access denied**
   ```bash
   # Check your AWS credentials
   aws sts get-caller-identity
   ```

3. **Invalid payload**
   ```bash
   # Validate JSON syntax
   echo '{"test": "data"}' | jq .
   ```

4. **Function timeout**
   ```bash
   # Check function timeout setting
   aws lambda get-function-configuration \
     --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz \
     --query 'Timeout'
   ```

## Quick Reference Commands

```bash
# Most common invocation
aws lambda invoke --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz response.json && cat response.json

# With custom payload
echo '{"key":"value"}' > payload.json && aws lambda invoke --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz --payload file://payload.json response.json

# View logs
aws logs tail /aws/lambda/HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz

# Get function info
aws lambda get-function --function-name HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz
```

---

**Note**: Replace `HelloCdkStack-HellolambdaA2299AF8-LWy15lg8quaz` with your actual function name if it changes after redeployment.