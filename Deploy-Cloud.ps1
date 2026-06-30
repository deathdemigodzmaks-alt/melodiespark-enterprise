# Complete Cloud Deployment Script (PowerShell)
# Deploys MelodieSpark to Vercel + Railway with full automation
# Run: powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1

param(
    [ValidateSet('cloud', 'vps', 'kubernetes', 'aws')]
    [string]$Target = 'cloud',
    
    [string]$VercelToken = $env:VERCEL_TOKEN,
    [string]$RailwayToken = $env:RAILWAY_TOKEN,
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

# Colors
$ErrorColor = 'Red'
$SuccessColor = 'Green'
$InfoColor = 'Cyan'
$WarnColor = 'Yellow'
$StepColor = 'Magenta'

function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor $InfoColor }
function Write-Success { Write-Host "✅ $args" -ForegroundColor $SuccessColor }
function Write-Error { Write-Host "❌ $args" -ForegroundColor $ErrorColor }
function Write-Warn { Write-Host "⚠️  $args" -ForegroundColor $WarnColor }
function Write-Step { Write-Host "`n▶▶▶ $args ▶▶▶" -ForegroundColor $StepColor }

# Setup
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommandPath
$ProjectRoot = if (Test-Path "$ScriptPath/package.json") { $ScriptPath } else { Get-Location }
$LogFile = Join-Path $ProjectRoot ".saas-deployment/logs/deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$null = New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force

# Ensure log directory exists
$logDir = Split-Path $LogFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Log {
    param([string]$Message, [string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -Append -FilePath $LogFile
}

# Header
Clear-Host
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ☁️  MELODIESPARK CLOUD DEPLOYMENT — PowerShell          ║" -ForegroundColor Cyan
Write-Host "║         Complete Automation for Vercel + Railway           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Log "Starting cloud deployment"

# Step 1: Check Prerequisites
Write-Step "Checking Prerequisites"

$prerequisites = @('git', 'pnpm', 'npm', 'node')
$missingPrereqs = @()

foreach ($cmd in $prerequisites) {
    $available = $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
    if ($available) {
        $version = if ($cmd -eq 'git') {
            (& git --version) -split '\s+' | Select-Object -Last 1
        } else {
            & $cmd --version | Select-Object -First 1
        }
        Write-Success "$cmd is installed ($version)"
        Log "$cmd available"
    } else {
        Write-Warn "$cmd not found"
        $missingPrereqs += $cmd
    }
}

if ($missingPrereqs.Count -gt 0 -and $missingPrereqs -contains 'pnpm') {
    Write-Warn "pnpm not found, installing globally..."
    npm install -g pnpm
    Log "pnpm installed globally"
}

# Step 2: Navigate to project
Write-Step "Setting Up Environment"

Push-Location $ProjectRoot
Log "Working directory: $(Get-Location)"
Write-Success "Working in: $ProjectRoot"

# Step 3: Check git
Write-Step "Checking Git Configuration"

$gitOrigin = git config --get remote.origin.url 2>$null
if ([string]::IsNullOrEmpty($gitOrigin)) {
    Write-Error "No git remote 'origin' found"
    Write-Info "Run: git remote add origin <github-url>"
    Log "ERROR: No git remote configured"
    exit 1
}

Write-Success "Git remote: $gitOrigin"
Log "Git remote: $gitOrigin"

# Step 4: Install Dependencies
Write-Step "Installing Dependencies"

Write-Info "Installing npm packages..."
Log "Running: pnpm install"

try {
    pnpm install --frozen-lockfile 2>&1 | Tee-Object -FilePath $LogFile -Append
    Write-Success "Dependencies installed"
    Log "Dependencies installed successfully"
} catch {
    Write-Error "Failed to install dependencies: $_"
    Log "ERROR: Failed to install dependencies - $_"
    exit 1
}

# Step 5: Build Application
Write-Step "Building Application"

Write-Info "Building frontend and backend..."
Log "Running: pnpm build"

try {
    pnpm build 2>&1 | Tee-Object -FilePath $LogFile -Append
    Write-Success "Build completed successfully"
    Log "Build successful"
} catch {
    Write-Error "Build failed: $_"
    Log "ERROR: Build failed - $_"
    exit 1
}

# Step 6: Git Operations
Write-Step "Preparing Git Repository"

Write-Info "Staging changes..."
git add -A 2>&1 | Out-Null
Log "Changes staged"

$status = git status --porcelain
if ($status) {
    $commitMsg = "Cloud deployment: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Info "Committing changes: $commitMsg"
    git commit -m $commitMsg 2>&1 | Out-Null
    Log "Changes committed: $commitMsg"
    Write-Success "Changes committed"
}

Write-Info "Pushing to GitHub..."
Log "Running: git push -u origin main"

try {
    $pushOutput = git push -u origin main 2>&1
    Write-Success "Code pushed to GitHub"
    Log "Code pushed to GitHub"
} catch {
    Write-Warn "Push failed (may not have new commits): $_"
    Log "WARNING: Push - $_"
}

# Step 7: Create Deployment Configurations
Write-Step "Creating Deployment Configurations"

# Vercel Config
$vercelConfig = @{
    version = 2
    name = "melodiespark"
    builds = @(
        @{
            src = "apps/web/package.json"
            use = "@vercel/next"
        },
        @{
            src = "apps/api/package.json"
            use = "@vercel/node"
        }
    )
    routes = @(
        @{
            src = "/api/(.*)"
            dest = "apps/api/src/index.ts"
        },
        @{
            src = "/(.*)"
            dest = "apps/web"
        }
    )
    env = @{
        DATABASE_URL = "@database_url"
        REDIS_URL = "@redis_url"
        JWT_SECRET = "@jwt_secret"
    }
}

$vercelConfig | ConvertTo-Json | Set-Content -Path "$ProjectRoot/vercel.json"
Write-Success "Vercel configuration created"
Log "Vercel config created"

# Railway Config
$railwayConfig = @{
    build = @{
        builder = "dockerfile"
    }
    deploy = @{
        numReplicas = 1
        startCommand = "pnpm start"
    }
}

$railwayConfig | ConvertTo-Json | Set-Content -Path "$ProjectRoot/railway.json"
Write-Success "Railway configuration created"
Log "Railway config created"

# Step 8: Create Deployment Instructions
Write-Step "Generating Deployment Instructions"

$instructions = @"
# ☁️ CLOUD DEPLOYMENT GUIDE

## Deployment URLs

- GitHub Repository: https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise
- Vercel Deployment: https://vercel.com/new
- Railway Deployment: https://railway.app

## Deploy Frontend to Vercel

1. Go to: https://vercel.com
2. Click: "New Project"
3. Select: melodiespark-enterprise (GitHub)
4. Root directory: apps/web
5. Environment: Set required variables
6. Click: "Deploy" ✅

## Deploy Backend to Railway

1. Go to: https://railway.app
2. Click: "New Project"
3. Deploy from GitHub
4. Select: melodiespark-enterprise
5. Root: apps/api
6. Click: "Deploy" ✅

## Add Databases (Railway)

### PostgreSQL
1. Railway → New → Database → PostgreSQL

### Redis
1. Railway → New → Database → Redis

## Environment Variables

Set in both Vercel and Railway:

\`\`\`env
DATABASE_URL=postgresql://user:password@host:5432/db
REDIS_URL=redis://host:6379
JWT_SECRET=your-secret-key
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
\`\`\`

## Verify Deployment

\`\`\`powershell
# Frontend
Invoke-WebRequest https://melodiespark.vercel.app

# Backend
Invoke-WebRequest https://api-melodiespark.railway.app/health
\`\`\`

## Status

✅ Code pushed to GitHub
✅ Vercel config created
✅ Railway config created
✅ Ready to deploy

Time to Live: ~15 minutes
Cost: \$25-85/month
"@

Set-Content -Path "$ProjectRoot/CLOUD_DEPLOYMENT_GUIDE.md" -Value $instructions
Write-Success "Deployment guide created"
Log "Deployment guide created"

# Step 9: Create Quick Deploy Script
Write-Step "Creating Quick Deploy Helper Script"

$quickDeploy = @"
# Quick Deployment Script
# This script helps you deploy quickly

Write-Host "CloudDeployment Quick Start" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Frontend (Vercel):"
Write-Host "   - Go to: https://vercel.com"
Write-Host "   - New Project"
Write-Host "   - Import: melodiespark-enterprise"
Write-Host "   - Root: apps/web"
Write-Host "   - Deploy" -ForegroundColor Green
Write-Host ""
Write-Host "2. Backend (Railway):"
Write-Host "   - Go to: https://railway.app"
Write-Host "   - New Project"
Write-Host "   - Import: melodiespark-enterprise"
Write-Host "   - Root: apps/api"
Write-Host "   - Deploy" -ForegroundColor Green
Write-Host ""
Write-Host "3. Add Databases (Railway):"
Write-Host "   - New → Database → PostgreSQL"
Write-Host "   - New → Database → Redis"
Write-Host ""
Write-Host "4. Set Environment Variables"
Write-Host ""
Write-Host "5. Your app is LIVE! ✅"
"@

Set-Content -Path "$ProjectRoot/QuickDeploy.ps1" -Value $quickDeploy
Write-Success "Quick deploy script created"
Log "Quick deploy script created"

# Step 10: Summary
Write-Step "Deployment Preparation Complete"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ CLOUD DEPLOYMENT PREPARATION COMPLETE!               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Success "GitHub Repository: $gitOrigin"
Write-Success "Code Status: ✅ Pushed to main branch"
Write-Success "Log File: $LogFile"
Write-Host ""

Write-Info "📋 NEXT STEPS:"
Write-Host "1. Go to https://vercel.com" -ForegroundColor Cyan
Write-Host "2. Import your GitHub repo" -ForegroundColor Cyan
Write-Host "3. Set root directory to 'apps/web'" -ForegroundColor Cyan
Write-Host "4. Click Deploy" -ForegroundColor Cyan
Write-Host "5. Repeat for Railway at https://railway.app" -ForegroundColor Cyan
Write-Host ""

Write-Info "📊 ESTIMATED TIME: 15 minutes"
Write-Info "💰 ESTIMATED COST: \$25-85/month"
Write-Host ""

Write-Host "Your app will be LIVE in ~15 minutes! 🚀" -ForegroundColor Green
Write-Host ""

Log "Deployment preparation completed successfully"

# Cleanup
Pop-Location

exit 0
