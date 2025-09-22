import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
// import * as sqs from 'aws-cdk-lib/aws-sqs';
import { Function, Runtime, Code }  from 'aws-cdk-lib/aws-lambda';
import { join } from 'path';

export class HelloCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    // example resource
    // const queue = new sqs.Queue(this, 'HelloCdkQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });
    const handler = new Function(this, 'Hello-lambda', {
      runtime: Runtime.NODEJS_20_X,
      handler: 'app.handler',
      memorySize: 128,
      code: Code.fromAsset(join(__dirname, '../lambdas')),
    });
  }
}
