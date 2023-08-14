FROM public.ecr.aws/lambda/dotnet:7 AS base

FROM mcr.microsoft.com/dotnet/sdk:7.0-bullseye-slim as build
WORKDIR /src
COPY ["LambdaEmptyFunction.csproj", "LambdaEmptyFunction/"]
RUN dotnet restore "LambdaEmptyFunction/LambdaEmptyFunction.csproj"
COPY . .
WORKDIR "/src/LambdaEmptyFunction"
RUN dotnet build "LambdaEmptyFunction.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "LambdaEmptyFunction.csproj" -c Release --runtime linux-x64 --self-contained false -o /app/publish -p:PublishReadyToRun=true  

FROM base AS final
WORKDIR /var/task
COPY --from=publish /app/publish .