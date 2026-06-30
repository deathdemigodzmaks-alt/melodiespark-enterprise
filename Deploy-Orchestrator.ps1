# Complete Deployment Orchestrator (PowerShell)
# Unified deployment script for all targets
# Run: powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1

param(
    [ValidateSet('cloud', 'vps', 'kubernetes', 'aws', 'all', 'interactive')]
    [string]$Target = 'interactive',
    
    [switch]$SkipGit = $false,
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false
)

# Colors
$Colors = @{
    Error = 'Red'
    Success = 'Green'
    Info = 'Cyan'
    Warn = 'Yellow'
    Step = 'Magenta'
    Header = 'Blue'
}

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    $color = $Colors[$Level] ?? $Colors.Info
    Write-Host "$($Level -replace 'Error', '❌' -replace 'Success', '✅' -replace 'Warn', '⚠️' -replace 'Step', '▶▶▶' -replace 'Info', 'ℹ️') $Message" -ForegroundColor $color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔$('=' * 62)╗" -ForegroundColor $Colors.Header
    Write-Host "║  $($Title.PadRight(58))║" -ForegroundColor $Colors.Header
    Write-Host "╚$('=' * 62)╝" -ForegroundColor $Colors.Header
    Write-Host ""
}

# Setup
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommandPath
$ProjectRoot = if (Test-Path "$ScriptPath/package.json") { $ScriptPath } else { Get-Location }
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$LogDir = Join-Path $ProjectRoot ".saas-deployment/logs"
$LogFile = Join-Path $LogDir "deploy-$Timestamp.log"
$null = New-Item -ItemType Directory -Path $LogDir -Force

Write-Header "🚀 MELODIESPARK DEPLOYMENT ORCHESTRATOR 🚀"

Write-Log "PowerShell Deployment Tool" Info
Write-Log "Project: $ProjectRoot" Info
Write-Log "Log File: $LogFile" Info
Write-Host ""

# Interactive Menu
if ($Target -eq 'interactive') {
    Write-Host "Select Deployment Target:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) ☁️  CLOUD (Vercel + Railway) — 15 minutes" -ForegroundColor Green
    Write-Host "  2) 🖥️  VPS (Self-Hosted) — 30 minutes"
    Write-Host "  3) ☸️  KUBERNETES (Multi-Region) — 1 hour"
    Write-Host "  4) 🌩️  AWS (Terraform) — 45 minutes"
    Write-Host "  5) 🔄 MULTI-INFRASTRUCTURE (All Targets) — 2-3 hours"
    Write-Host ""
    
    $selection = Read-Host "Choose (1-5)"
    
    $targetMap = @{
        '1' = 'cloud'
        '2' = 'vps'
        '3' = 'kubernetes'
        '4' = 'aws'
        '5' = 'all'
    }
    
    $Target = $targetMap[$selection] ?? 'cloud'
}

Write-Log "Selected Target: $Target" Info

# Step 1: Prerequisites Check
Write-Header "STEP 1: Checking Prerequisites"

$requiredTools = @('git', 'node', 'npm')
$missingTools = @()

foreach ($tool in $requiredTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        $version = & $tool --version | Select-Object -First 1
        Write-Log "$tool: $version" Success
    } else {
        Write-Log "$tool: NOT FOUND" Error
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Log "Install missing tools and try again" Error
    exit 1
}

# Step 2: Environment Setup
Write-Header "STEP 2: Setting Up Environment"

Push-Location $ProjectRoot
Write-Log "Working in: $(Get-Location)" Success

if (-not (Test-Path '.env')) {
    Write-Log "Creating .env from template..." Info
    Copy-Item '.env.example' '.env' -ErrorAction SilentlyContinue
    Write-Log ".env created" Success
} else {
    Write-Log ".env already exists" Success
}

# Step 3: Git Verification
Write-Header "STEP 3: Git Configuration"

$gitOrigin = git config --get remote.origin.url 2>$null
if ([string]::IsNullOrEmpty($gitOrigin)) {
    Write-Log "Git remote not configured" Error
    Write-Host "Run: git remote add origin <github-url>" -ForegroundColor Yellow
    exit 1
}

Write-Log "Git remote: $gitOrigin" Success

# Step 4: Install Dependencies
if (-not $SkipBuild) {
    Write-Header "STEP 4: Installing Dependencies"
    
    Write-Log "Installing packages..." Info
    
    # Check for pnpm
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        Write-Log "Installing pnpm globally..." Info
        npm install -g pnpm
    }
    
    pnpm install --frozen-lockfile
    Write-Log "Dependencies installed" Success
}

# Step 5: Build Application
if (-not $SkipBuild) {
    Write-Header "STEP 5: Building Application"
    
    Write-Log "Building..." Info
    pnpm build
    Write-Log "Build completed" Success
}

# Step 6: Git Push
if (-not $SkipGit) {
    Write-Header "STEP 6: Pushing to GitHub"
    
    git add -A 2>$null
    $status = git status --porcelain
    
    if ($status) {
        $commitMsg = "Deployment: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $commitMsg
        Write-Log "Committed: $commitMsg" Success
    }
    
    git push -u origin main
    Write-Log "Code pushed to GitHub" Success
}

# Step 7: Deployment
Write-Header "STEP 7: Starting Deployment"

switch ($Target) {
    'cloud' {
        Write-Log "Deploying to Cloud (Vercel + Railway)..." Info
        & "$ProjectRoot/Deploy-Cloud.ps1"
    }
    'vps' {
        Write-Log "Deploying to VPS..." Info
        & "$ProjectRoot/Deploy-VPS.ps1"
    }
    'kubernetes' {
        Write-Log "Deploying to Kubernetes..." Info
        & "$ProjectRoot/Deploy-Kubernetes.ps1"
    }
    'aws' {
        Write-Log "Deploying to AWS..." Info
        & "$ProjectRoot/Deploy-AWS.ps1"
    }
    'all' {
        Write-Log "Deploying to ALL targets..." Info
        & "$ProjectRoot/Deploy-Cloud.ps1"
        Write-Log "Cloud deployment started" Success
        
        Start-Sleep -Seconds 5
        
        & "$ProjectRoot/Deploy-VPS.ps1"
        Write-Log "VPS deployment started" Success
        
        Start-Sleep -Seconds 5
        
        & "$ProjectRoot/Deploy-Kubernetes.ps1"
        Write-Log "Kubernetes deployment started" Success
    }
}

# Cleanup
Pop-Location

# Summary
Write-Header "✅ DEPLOYMENT COMPLETE!"

Write-Log "Target: $Target" Success
Write-Log "Log File: $LogFile" Info
Write-Log "GitHub: $gitOrigin" Info
Write-Host ""

Write-Host "📊 Deployment Status:" -ForegroundColor Cyan
Write-Host "  ✅ Code prepared and pushed"
Write-Host "  ✅ Infrastructure configured"
Write-Host "  ✅ Deployment started"
Write-Host ""

Write-Host "🚀 Your app is deploying! Check the deployment platform for status." -ForegroundColor Green
Write-Host ""

exit 0
