# AWS CDK Masterclass - Build AWS Cloud Infrastructures

## Course Resources

- [Udemy Course](https://gale.udemy.com/course/aws-cdk-masterclass-build-aws-cloud-infrastructures/learn/lecture/33197188#overview)
- [Coursera Course](https://www.coursera.org/learn/packt-mastering-aws-cdk-coding-cloud-architectures-tlyuf/home/module)

## Prerequisites Setup

### Quick Installation (Recommended)

Run the automated installation script:

```bash
./setup-aws-cdk-env.sh
```

This script will install:

- AWS CLI v2
- TypeScript (globally)
- AWS CDK (globally)

### Manual Installation

If you prefer to install manually:

#### 1. Install AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
```

#### 2. Install TypeScript

```bash
npm install -g typescript
```

#### 3. Install AWS CDK

```bash
npm install -g aws-cdk
```

## Environment Validation

After running the setup script, you can validate your environment:

```bash
./validate-aws-cdk-env.sh
```

This validation script checks:

- System prerequisites (Node.js, npm)
- AWS tools (CLI, credentials, configuration)
- Development tools (TypeScript, CDK)
- Environment variables and PATH
- CDK functionality and bootstrap status

## Getting Started

### 1. Create a new CDK project

```bash
mkdir hello-cdk && cd hello-cdk
cdk init app --language typescript
```

### 2. Verify AWS credentials

```bash
aws sts get-caller-identity --query "Account" --output text
```

### 3. Bootstrap CDK (first time only)

```bash
cdk bootstrap
```

### 4. Build and deploy

```bash
npm run build
cdk deploy
```

## Common CDK Commands

- `cdk ls` - List all stacks
- `cdk synth` - Synthesize CloudFormation template
- `cdk diff` - Compare deployed stack with current state
- `cdk deploy` - Deploy stack to AWS
- `cdk destroy` - Delete stack from AWS
