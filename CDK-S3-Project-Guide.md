# AWS CDK Sample Project: S3 Bucket Provisioning

This guide walks you through creating your first AWS CDK project and provisioning an S3 bucket.

## Prerequisites

Before starting, ensure you have completed the following:

1. **Environment Setup**: Run `./setup-aws-cdk-env.sh` to install all prerequisites
2. **CDK Bootstrap**: Run `./bootstrap-cdk.sh` to bootstrap CDK in your AWS account
3. **Verify Installation**: Confirm AWS CLI, CDK, and TypeScript are installed

```bash
# Verify installations
aws --version
cdk --version
tsc --version
```

## Step 1: Create a New CDK Project

### 1.1 Create Project Directory
```bash
# Create a new directory for your CDK project
mkdir my-s3-project
cd my-s3-project
```

### 1.2 Initialize CDK App
```bash
# Initialize a new TypeScript CDK application
cdk init app --language typescript

# If directory is not empty, use --force flag
cdk init app --language typescript --force
```

**Note**: If you get the error "cdk init cannot be run in a non-empty directory!", use the `--force` flag to initialize the project anyway.

This command creates:
- `lib/` - Contains your stack definitions
- `bin/` - Contains the CDK app entry point
- `test/` - Contains unit tests
- `package.json` - Node.js dependencies
- `cdk.json` - CDK configuration
- `tsconfig.json` - TypeScript configuration

### 1.3 Install Dependencies
```bash
# Install all dependencies
npm install
```

## Step 2: Understanding the Project Structure

After initialization, your project structure will look like:

```
my-s3-project/
├── bin/
│   └── my-s3-project.ts          # App entry point
├── lib/
│   └── my-s3-project-stack.ts    # Stack definition
├── test/
│   └── my-s3-project.test.ts     # Unit tests
├── cdk.json                      # CDK configuration
├── package.json                  # Dependencies
├── tsconfig.json                 # TypeScript config
└── README.md                     # Project documentation
```

## Step 3: Create S3 Bucket Stack

### 3.1 Update the Stack File

Edit the file `lib/my-s3-project-stack.ts`:

```typescript
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';

export class MyS3ProjectStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create an S3 bucket with basic configuration
    const myBucket = new s3.Bucket(this, 'MyFirstBucket', {
      // Bucket name (optional - will auto-generate if not specified)
      bucketName: `my-cdk-bucket-${this.account}-${this.region}`,
      
      // Versioning enabled
      versioned: true,
      
      // Encryption
      encryption: s3.BucketEncryption.S3_MANAGED,
      
      // Public access settings
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      
      // Lifecycle rules
      lifecycleRules: [
        {
          id: 'delete-old-versions',
          enabled: true,
          noncurrentVersionExpiration: cdk.Duration.days(30),
        },
      ],
      
      // Removal policy (be careful with this in production!)
      removalPolicy: cdk.RemovalPolicy.DESTROY, // This allows CDK to delete the bucket
      autoDeleteObjects: true, // This deletes objects when stack is deleted
    });

    // Output the bucket name and ARN
    new cdk.CfnOutput(this, 'BucketName', {
      value: myBucket.bucketName,
      description: 'Name of the S3 bucket',
    });

    new cdk.CfnOutput(this, 'BucketArn', {
      value: myBucket.bucketArn,
      description: 'ARN of the S3 bucket',
    });

    new cdk.CfnOutput(this, 'BucketUrl', {
      value: `https://${myBucket.bucketName}.s3.${this.region}.amazonaws.com`,
      description: 'URL of the S3 bucket',
    });
  }
}
```

### 3.2 Understanding the S3 Configuration

The S3 bucket is configured with:

- **Unique Name**: Uses account ID and region to ensure uniqueness
- **Versioning**: Enabled to keep multiple versions of objects
- **Encryption**: S3-managed encryption for security
- **Public Access**: Blocked to prevent accidental public exposure
- **Lifecycle Rules**: Automatically delete old versions after 30 days
- **Removal Policy**: Allows destruction for demo purposes (use caution in production)

### 3.3 Update the App Entry Point (Optional)

The file `bin/my-s3-project.ts` should look like:

```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { MyS3ProjectStack } from '../lib/my-s3-project-stack';

const app = new cdk.App();
new MyS3ProjectStack(app, 'MyS3ProjectStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
```

## Step 4: Build and Validate

### 4.1 Compile TypeScript
```bash
# Build the project
npm run build
```

### 4.2 Validate CDK Code
```bash
# Check for any CDK errors
cdk doctor
```

### 4.3 Synthesize CloudFormation Template
```bash
# Generate CloudFormation template
cdk synth
```

This creates a `cdk.out/` directory with the generated CloudFormation template. You can inspect `cdk.out/MyS3ProjectStack.template.json` to see what will be deployed.

## Step 5: Deploy the Stack

### 5.1 Preview Changes
```bash
# See what will be deployed
cdk diff
```

### 5.2 Deploy to AWS
```bash
# Deploy the stack
cdk deploy
```

You'll see output like:
```
✅  MyS3ProjectStack

✨  Deployment time: 45.67s

Outputs:
MyS3ProjectStack.BucketArn = arn:aws:s3:::my-cdk-bucket-123456789012-us-east-1
MyS3ProjectStack.BucketName = my-cdk-bucket-123456789012-us-east-1
MyS3ProjectStack.BucketUrl = https://my-cdk-bucket-123456789012-us-east-1.s3.us-east-1.amazonaws.com

Stack ARN:
arn:aws:cloudformation:us-east-1:123456789012:stack/MyS3ProjectStack/12345678-1234-1234-1234-123456789012
```

## Step 6: Verify Deployment

### 6.1 Check in AWS Console
1. Go to [AWS S3 Console](https://console.aws.amazon.com/s3/)
2. Look for your bucket: `my-cdk-bucket-{account}-{region}`
3. Verify the bucket settings match your configuration

### 6.2 Test with AWS CLI
```bash
# List your buckets
aws s3 ls

# Upload a test file
echo "Hello from CDK!" > test.txt
aws s3 cp test.txt s3://my-cdk-bucket-123456789012-us-east-1/

# List objects in your bucket
aws s3 ls s3://my-cdk-bucket-123456789012-us-east-1/
```

## Step 7: Advanced S3 Features (Optional)

### 7.1 Add CORS Configuration
```typescript
// Add to your bucket configuration
cors: [
  {
    allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.POST],
    allowedOrigins: ['*'],
    allowedHeaders: ['*'],
  },
],
```

### 7.2 Add Event Notifications
```typescript
// Add Lambda trigger on object creation
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';

const myFunction = new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.NODEJS_18_X,
  handler: 'index.handler',
  code: lambda.Code.fromInline(`
    exports.handler = async (event) => {
      console.log('S3 event:', JSON.stringify(event, null, 2));
    };
  `),
});

myBucket.addEventNotification(
  s3.EventType.OBJECT_CREATED,
  new s3n.LambdaDestination(myFunction)
);
```

## Step 8: Clean Up

When you're done experimenting:

### 8.1 Delete the Stack
```bash
# This will delete all resources created by the stack
cdk destroy
```

### 8.2 Clean Up Local Files
```bash
# Remove project directory
cd ..
rm -rf my-s3-project
```

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Ensure your AWS credentials have sufficient permissions
   - Try `aws sts get-caller-identity` to verify credentials

2. **Bucket Name Conflicts**
   - S3 bucket names must be globally unique
   - The template uses account ID and region to avoid conflicts

3. **CDK Version Mismatch**
   - Ensure all CDK packages use the same version
   - Run `npm update` to update dependencies

4. **TypeScript Compilation Errors**
   - Run `npm run build` to see detailed error messages
   - Check your TypeScript configuration

### Useful Commands

```bash
# List all stacks
cdk ls

# Show differences between deployed and local
cdk diff

# Show CloudFormation template
cdk synth

# Deploy with verbose output
cdk deploy --verbose

# Show CDK version
cdk --version

# Get help
cdk --help
```

## Next Steps

After completing this tutorial, you can:

1. **Explore Other AWS Services**: Try adding Lambda functions, DynamoDB tables, or API Gateway
2. **Learn CDK Patterns**: Study AWS CDK construct libraries
3. **Add Testing**: Write unit tests for your CDK code
4. **CI/CD Pipeline**: Set up automated deployment pipelines
5. **Multi-Environment**: Deploy to different environments (dev, staging, prod)

## Additional Resources

- [AWS CDK Developer Guide](https://docs.aws.amazon.com/cdk/v2/guide/)
- [AWS CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/)
- [CDK Examples Repository](https://github.com/aws-samples/aws-cdk-examples)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

---

🎉 **Congratulations!** You've successfully created and deployed your first CDK project with an S3 bucket!