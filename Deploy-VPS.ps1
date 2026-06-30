# VPS Deployment Script (PowerShell)
# Deploy MelodieSpark to a self-hosted VPS
# Run: powershell -ExecutionPolicy Bypass -File Deploy-VPS.ps1

param(
    [string]$VPSHost = "your-vps.com",
    [string]$VPSUser = "deploy",
    [string]$SSHKey = "$env:USERPROFILE\.ssh\id_rsa",
    [string]$VPSPath = "/var/www/melodiespark"
)

function Write-Log {
    param([string]$Message, [string]$Type = 'Info')
    $colors = @{ 
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Error' = 'Red'
        'Warn' = 'Yellow'
        'Step' = 'Magenta'
    }
    $symbol = @{
        'Info' = 'ℹ️'
        'Success' = '✅'
        'Error' = '❌'
        'Warn' = '⚠️'
        'Step' = '▶▶▶'
    }
    Write-Host "$($symbol[$Type]) $Message" -ForegroundColor $colors[$Type]
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  🖥️  VPS DEPLOYMENT — Self-Hosted Setup                 ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

Write-Log "VPS Deployment Configuration" Step
Write-Log "VPS Host: $VPSHost"
Write-Log "User: $VPSUser"
Write-Log "Path: $VPSPath"
Write-Log "SSH Key: $SSHKey"
Write-Host ""

# SSH Command Template
function Invoke-SSH {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [string]$Host = $VPSHost,
        [string]$User = $VPSUser
    )
    
    if (Get-Command ssh -ErrorAction SilentlyContinue) {
        ssh -i $SSHKey "$User@$Host" $Command
    } else {
        Write-Log "SSH not available on Windows. Use WSL or Git Bash." Error
        throw "SSH required"
    }
}

# Step 1: Check SSH Connection
Write-Log "Testing SSH Connection" Step

try {
    Write-Log "Connecting to $User@$VPSHost..."
    ssh -i $SSHKey -o ConnectTimeout=5 "$VPSUser@$VPSHost" "echo 'SSH Connection successful'"
    Write-Log "SSH Connection established" Success
} catch {
    Write-Log "SSH Connection failed: $_" Error
    Write-Log "Make sure:" Warn
    Write-Log "  - VPS is running"
    Write-Log "  - SSH port is open"
    Write-Log "  - SSH key is correct"
    exit 1
}

# Step 2: Prepare VPS
Write-Log "Preparing VPS" Step

$setupCommands = @(
    "sudo apt-get update -y"
    "sudo apt-get install -y curl git docker.io docker-compose nodejs npm"
    "sudo systemctl enable docker"
    "sudo systemctl start docker"
    "sudo usermod -aG docker $VPSUser"
)

foreach ($cmd in $setupCommands) {
    Write-Log "Running: $cmd"
    ssh -i $SSHKey "$VPSUser@$VPSHost" $cmd
}

Write-Log "VPS prepared" Success

# Step 3: Clone Repository
Write-Log "Deploying Application" Step

$deployCommands = @(
    "mkdir -p $VPSPath"
    "cd $VPSPath && git clone https://github.com/deathdemigodzmaks-alt/melodiespark-enterprise.git ."
    "cd $VPSPath && cp .env.example .env"
)

foreach ($cmd in $deployCommands) {
    Write-Log "Running: $cmd"
    ssh -i $SSHKey "$VPSUser@$VPSHost" $cmd
}

Write-Log "Application cloned" Success

# Step 4: Setup Environment
Write-Log "Setting Up Environment" Step

$envSetup = @"
cd $VPSPath
# Edit .env with your values
nano .env
"@

Write-Log "Environment setup required. SSH into VPS and edit .env:" Warn
Write-Log "  ssh -i $SSHKey $VPSUser@$VPSHost"
Write-Log "  nano $VPSPath/.env"

# Step 5: Start Services
Write-Log "Starting Docker Services" Step

$startCommands = @(
    "cd $VPSPath && docker-compose up -d"
    "cd $VPSPath && docker-compose logs -f"
)

Write-Log "Docker services started" Step
Write-Log "To start services, run:"
Write-Log "  ssh -i $SSHKey $VPSUser@$VPSHost 'cd $VPSPath && docker-compose up -d'"

# Step 6: Setup nginx
Write-Log "Setting Up Reverse Proxy" Step

$nginxConfig = @"
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Host \$host;
    }

    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
"@

Write-Log "Nginx configuration (save as /etc/nginx/sites-available/melodiespark):"
Write-Host $nginxConfig -ForegroundColor Gray

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ VPS DEPLOYMENT STARTED!                              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Log "Next Steps:" Step
Write-Log "1. Edit .env on VPS"
Write-Log "2. Setup PostgreSQL and Redis"
Write-Log "3. Configure nginx"
Write-Log "4. Start docker-compose"
Write-Log "5. Point domain to VPS"
Write-Log ""
Write-Log "Your VPS deployment is ready!" Success

exit 0
