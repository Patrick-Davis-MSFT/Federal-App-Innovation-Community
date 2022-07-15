#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
EXPOSE 4026
EXPOSE 4024
EXPOSE 4022

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["DebugWebAPI/DebugWebAPI.csproj", "DebugWebAPI/"]
RUN dotnet restore "DebugWebAPI/DebugWebAPI.csproj"
COPY . .
WORKDIR "/src/DebugWebAPI"
RUN dotnet build "DebugWebAPI.csproj" -c Debug -o /app/build

FROM build AS publish
RUN dotnet publish "DebugWebAPI.csproj" -c Debug -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DebugWebAPI.dll"]