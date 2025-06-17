# --- Build stage ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY CardValidation.sln .
COPY CardValidation.Core/CardValidation.Core.csproj CardValidation.Core/
COPY CardValidation.Tests/CardValidation.Tests.csproj CardValidation.Tests/
COPY CardValidation.Web/CardValidation.Web.csproj CardValidation.Web/

RUN dotnet restore CardValidation.sln
COPY . .
RUN dotnet publish CardValidation.Web/CardValidation.Web.csproj -c Release -o /app/publish

# --- Test stage ---
FROM build AS test
WORKDIR /src

# Run tests and output Allure + coverage
RUN dotnet test CardValidation.Tests/CardValidation.Tests.csproj \
    --logger "trx;LogFileName=all-tests.trx" \
    --results-directory /app/test-results \
    /p:GenerateAllureResult=true \
    /p:CollectCoverage=true \
    /p:CoverletOutputFormat=cobertura \
    /p:CoverletOutput=/app/test-results/coverage.xml

# Copy test and allure results
RUN mkdir -p /app/allure-results && \
    cp -r /src/CardValidation.Tests/allure-results/* /app/allure-results || true

# --- Runtime stage (optional) ---
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "CardValidation.Web.dll"]
