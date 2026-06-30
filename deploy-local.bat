@echo off
REM MelodieSpark Docker Quick Deploy Script (Windows)

echo 🚀 MelodieSpark Docker Setup
echo ================================

REM Check Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker not installed
    exit /b 1
)

echo ✅ Docker found: 
docker --version

REM Check Docker Compose
docker-compose --version >nul 2>&1
if errorlevel 1 (
    docker compose version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Docker Compose not installed
        exit /b 1
    )
)

echo ✅ Docker Compose found

REM Setup environment
if not exist .env (
    echo.
    echo 📝 Creating .env from template...
    copy .env.example .env
    echo ⚠️  Edit .env with your API keys
) else (
    echo ✅ .env already exists
)

REM Validate compose
echo.
echo 🔍 Validating docker-compose.yml...
docker-compose config --quiet
if errorlevel 1 (
    echo ❌ Compose validation failed
    exit /b 1
)
echo ✅ Compose file is valid

REM Build
echo.
set /p BUILD="Build Docker images? (y/n): "
if /i "%BUILD%"=="y" (
    echo 🔨 Building images...
    docker-compose build
    echo ✅ Build complete
)

REM Start
echo.
set /p START="Start services? (y/n): "
if /i "%START%"=="y" (
    echo 🚀 Starting MelodieSpark...
    docker-compose up -d
    echo.
    echo ✅ Services started!
    echo.
    echo 📍 Access services:
    echo    Frontend:   http://localhost:3000
    echo    API:        http://localhost:3001
    echo    Database:   localhost:5432
    echo.
    echo 📊 View logs:
    echo    docker-compose logs -f
    echo.
    echo ⏸️  Stop services:
    echo    docker-compose down
) else (
    echo Skipped startup
)

pause
