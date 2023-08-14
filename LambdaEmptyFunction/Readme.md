## Here are some steps to follow from Visual Studio:

To deploy your function to AWS Lambda, right click the project in Solution Explorer and select *Publish to AWS Lambda*.

To view your deployed function open its Function View window by double-clicking the function name shown beneath the AWS Lambda node in the AWS Explorer tree.

To perform testing against your deployed function use the Test Invoke tab in the opened Function View window.

To configure event sources for your deployed function, for example to have your function invoked when an object is created in an Amazon S3 bucket, use the Event Sources tab in the opened Function View window.

To update the runtime configuration of your deployed function use the Configuration tab in the opened Function View window.

To view execution logs of invocations of your function use the Logs tab in the opened Function View window.

## Here are some steps to follow to get started from the command line:

You can deploy your application using the [Amazon.Lambda.Tools Global Tool](https://github.com/aws/aws-extensions-for-dotnet-cli#aws-lambda-amazonlambdatools) from the command line. Lambda function packaged as a Docker image require version 5.0.0 or later.

Install Amazon.Lambda.Tools Global Tools if not already installed.
```
dotnet tool install -g Amazon.Lambda.Tools
```

If already installed check if new version is available.
```
dotnet tool update -g Amazon.Lambda.Tools
```

Execute unit tests
```
cd "LambdaEmptyFunction/test/LambdaEmptyFunction.Tests"
dotnet test
```

Deploy function to AWS Lambda
```
cd "LambdaEmptyFunction/src/LambdaEmptyFunction"
dotnet lambda deploy-function
```
