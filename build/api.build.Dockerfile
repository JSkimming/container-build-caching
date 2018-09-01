FROM microsoft/dotnet:2.1-sdk

ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true

WORKDIR /publish

# Copy just the solution and proj files to make best use of docker image caching
COPY ./cbc-api.sln .
COPY ./src/Cbc.Api/Cbc.Api.csproj ./src/Cbc.Api/Cbc.Api.csproj
COPY ./src/Cbc.Common/Cbc.Common.csproj ./src/Cbc.Common/Cbc.Common.csproj

# Run restore on just the project files, this should cache the image after restore.
RUN dotnet restore

COPY ./src/stylecop.json ./src/stylecop.json
COPY ./src/stylecop.ruleset ./src/stylecop.ruleset
COPY ./src/Cbc.Api/ ./src/Cbc.Api/
COPY ./src/Cbc.Common/ ./src/Cbc.Common/

# Publish application
RUN dotnet publish src/Cbc.Api/Cbc.Api.csproj --output ../../out/ --configuration Release --no-restore
