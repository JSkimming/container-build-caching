# -- Stage 1 - Pickup the build latest

FROM cbc-identity-build-intermediate as build

# -- Stage 2 - Optimized Image suitable for Deployment --

FROM microsoft/dotnet:2.1-aspnetcore-runtime

ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true

WORKDIR /app
EXPOSE 80

COPY --from=build ./publish/out .

ENTRYPOINT ["dotnet", "Cbc.Identity.dll"]
