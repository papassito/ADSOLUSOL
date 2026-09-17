# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source

# Copy solution and project files first to leverage Docker layer caching.
# This step is only re-run if the .sln or .csproj files change.
COPY ADSOLUSOL.sln .
COPY src/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj ./src/ADSOLUSOL.Domain/
COPY src/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj ./src/ADSOLUSOL.Application/
COPY src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj ./src/ADSOLUSOL.Infrastructure/
COPY src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj ./src/ADSOLUSOL.Presentation.Api/

# Restore dependencies for the entire solution
RUN dotnet restore ADSOLUSOL.sln

# Copy the rest of the source code
COPY . .

# Publish the API project for release
WORKDIR /source/src/ADSOLUSOL.Presentation.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Create the final, lightweight runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
# Create a non-root user for better security
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser
# Create a directory for the SQLite database
RUN mkdir -p /app/data
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ADSOLUSOL.Presentation.Api.dll"]