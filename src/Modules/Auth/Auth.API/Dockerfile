# ==================================
# Stage 1: Base Runtime Image
# ==================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Create non-root user for security
RUN addgroup --system --gid 1001 appuser && \
    adduser --system --uid 1001 --ingroup appuser appuser

# ==================================
# Stage 2: Build
# ==================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy project files for restore (cache layer)
COPY ["src/Modules/Auth/Auth.API/Auth.API.csproj", "Modules/Auth/Auth.API/"]
COPY ["src/Modules/Auth/Auth.Application/Auth.Application.csproj", "Modules/Auth/Auth.Application/"]
COPY ["src/Modules/Auth/Auth.Infrastructure/Auth.Infrastructure.csproj", "Modules/Auth/Auth.Infrastructure/"]
COPY ["src/Modules/Auth/Auth.Domain/Auth.Domain.csproj", "Modules/Auth/Auth.Domain/"]
COPY ["src/BuildingBlocks/SharedKernel.Application/SharedKernel.Application.csproj", "BuildingBlocks/SharedKernel.Application/"]
COPY ["src/BuildingBlocks/SharedKernel.Domain/SharedKernel.Domain.csproj", "BuildingBlocks/SharedKernel.Domain/"]

# Restore dependencies
RUN dotnet restore "Modules/Auth/Auth.API/Auth.API.csproj"

# Copy all source code
COPY src/ .

# Build
WORKDIR "/src/Modules/Auth/Auth.API"
RUN dotnet build "Auth.API.csproj" -c $BUILD_CONFIGURATION -o /app/build

# ==================================
# Stage 3: Publish
# ==================================
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Auth.API.csproj" \
    -c $BUILD_CONFIGURATION \
    -o /app/publish \
    /p:UseAppHost=false

# ==================================
# Stage 4: Final Runtime Image
# ==================================
FROM base AS final
WORKDIR /app

# Copy published files
COPY --from=publish /app/publish .

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl --fail http://localhost/health || exit 1

# Entry point
ENTRYPOINT ["dotnet", "Auth.API.dll"]
