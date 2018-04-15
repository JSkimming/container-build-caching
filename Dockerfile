# -- Stage 1 - Build and Publish the identity project --

FROM microsoft/aspnetcore-build:2.0.0 as identity-build

ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true

WORKDIR /publish

# Copy just the solution and proj files to make best use of docker image caching
COPY ./cbc-identity.sln .
COPY ./src/Cbc.Identity/Cbc.Identity.csproj ./src/Cbc.Identity/Cbc.Identity.csproj

# Run restore on just the project files, this should cache the image after restore.
RUN dotnet restore

COPY . .

# Publish application
RUN dotnet publish src/Cbc.Identity/Cbc.Identity.csproj --output ../../out/ --configuration Release --no-restore

# -- Stage 2 - Optimized Image suitable for Deployment --

FROM microsoft/aspnetcore:2.0.0

ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true

WORKDIR /app
EXPOSE 80

COPY --from=identity-build ./publish/out .

ENTRYPOINT ["dotnet", "Cbc.Identity.dll"]
