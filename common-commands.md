# AWS CDK Common Commands Reference

## CDK Initialization

### Initialize in Empty Directory
```bash
cdk init app --language typescript
```

### Initialize in Non-Empty Directory (Force)
```bash
cdk init app --language typescript --force
```

### Initialize Other Project Types
```bash
# Sample app with example constructs
cdk init sample-app --language typescript

# Library for creating constructs
cdk init lib --language typescript

# Empty app (minimal setup)
cdk init app --language typescript --generate-only
```

## Project Management

### Build and Compile
```bash
# Build TypeScript
npm run build

# Build in watch mode
npm run watch

# Run tests
npm test
```

### CDK Commands
```bash
# List all stacks
cdk ls

# Show differences
cdk diff

# Synthesize CloudFormation template
cdk synth

# Deploy stack
cdk deploy

# Deploy specific stack
cdk deploy MyStackName

# Deploy all stacks
cdk deploy --all

# Destroy stack
cdk destroy

# Destroy specific stack
cdk destroy MyStackName
```

## Troubleshooting Commands

### Environment Verification
```bash
# Check CDK version
cdk --version

# Verify AWS credentials
aws sts get-caller-identity

# Check CDK doctor
cdk doctor

# List CDK context
cdk context --list
```

### Common Fixes
```bash
# Clear CDK context
cdk context --clear

# Bootstrap CDK (if not done)
cdk bootstrap

# Force rebuild
rm -rf node_modules cdk.out
npm install
npm run build
```

## Error Solutions

### "cdk init cannot be run in a non-empty directory!"
```bash
# Solution: Use --force flag
cdk init app --language typescript --force
```

### "No stacks to deploy"
```bash
# Check if stacks are listed
cdk ls

# Check if app file is correct
cat bin/your-app-name.ts
```

### "Unable to resolve AWS account to use"
```bash
# Set environment explicitly
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=us-east-1
```

### "Stack is not bootstrapped"
```bash
# Bootstrap CDK
cdk bootstrap aws://ACCOUNT-NUMBER/REGION
```

## Quick Start Checklist

- [ ] Environment setup: `./setup-aws-cdk-env.sh`
- [ ] Bootstrap CDK: `./bootstrap-cdk.sh`
- [ ] Create project: `cdk init app --language typescript --force`
- [ ] Install deps: `npm install`
- [ ] Build: `npm run build`
- [ ] Deploy: `cdk deploy`