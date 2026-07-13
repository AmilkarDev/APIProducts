# Step 1: Use the official .NET SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies
COPY ["ClientA.Api.csproj", "./"]
RUN dotnet restore "ClientA.Api.csproj"

# Copy the rest of the code and build the app
COPY . .
RUN dotnet publish "ClientA.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Step 2: Use a lighter .NET ASP.NET runtime image to run the app
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080

# Copy the compiled app from the build stage
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ClientA.Api.dll"]