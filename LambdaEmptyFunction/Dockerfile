FROM public.ecr.aws/lambda/dotnet:7.2023.08.02.10 AS base

FROM mcr.microsoft.com/dotnet/sdk:7.0-bullseye-slim as build
COPY . /src
WORKDIR /src
RUN dotnet build "LambdaEmptyFunction.csproj" -o /app/build

FROM build AS publish
RUN dotnet publish "LambdaEmptyFunction.csproj" -c Release -o /app/publish

FROM base AS final
COPY --from=publish /app/publish ${LAMBDA_TASK_ROOT}
CMD [ "LambdaEmptyFunction::LambdaEmptyFunction.Function::FunctionHandler" ]

#FROM public.ecr.aws/lambda/dotnet:7.2023.08.02.10
##You can alternately also pull these images from DockerHub amazon/aws-lambda-dotnet:6
#
## Copy function code
#COPY publish/* ${LAMBDA_TASK_ROOT}
#
## Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
#CMD ["LambdaEmptyFunction::LambdaEmptyFunction.Function::FunctionHandler"]
