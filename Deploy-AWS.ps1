# AWS Deployment Script (PowerShell)
# Deploy MelodieSpark to AWS with Terraform
# Run: powershell -ExecutionPolicy Bypass -File Deploy-AWS.ps1

param(
    [string]$AWSRegion = "us-east-1",
    [string]$Environment = "production",
    [string]$Project = "melodiespark"
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
Write-Host "║  🌩️  AWS DEPLOYMENT — Terraform Automation               ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

Write-Log "AWS Deployment Configuration" Step
Write-Log "Region: $AWSRegion"
Write-Log "Environment: $Environment"
Write-Log "Project: $Project"
Write-Host ""

# Check Prerequisites
Write-Log "Checking AWS Prerequisites" Step

$missingTools = @()

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Log "AWS CLI not found" Error
    $missingTools += "aws-cli"
} else {
    $awsVersion = aws --version
    Write-Log "AWS CLI: $awsVersion" Success
}

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Log "Terraform not found" Error
    $missingTools += "terraform"
} else {
    $tfVersion = terraform -version | Select-Object -First 1
    Write-Log "Terraform: $tfVersion" Success
}

if ($missingTools.Count -gt 0) {
    Write-Log "Install missing tools:" Error
    foreach ($tool in $missingTools) {
        Write-Log "  - $tool" Warn
    }
    exit 1
}

# Check AWS Credentials
Write-Log "Checking AWS Credentials" Step

try {
    $awsIdentity = aws sts get-caller-identity --region $AWSRegion 2>$null | ConvertFrom-Json
    Write-Log "AWS Account: $($awsIdentity.Account)" Success
    Write-Log "AWS User/Role: $($awsIdentity.Arn)" Success
} catch {
    Write-Log "AWS Credentials not configured" Error
    Write-Log "Run: aws configure" Warn
    exit 1
}

# Terraform Setup
Write-Log "Initializing Terraform" Step

$terraformDir = "terraform/environments/$Environment"

if (-not (Test-Path $terraformDir)) {
    New-Item -ItemType Directory -Path $terraformDir -Force | Out-Null
}

Push-Location $terraformDir

# Create terraform.tfvars
Write-Log "Creating Terraform Variables" Step

$tfvars = @"
region  = "$AWSRegion"
environment = "$Environment"
project = "$Project"

# RDS Configuration
db_engine = "postgres"
db_version = "16.1"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20

# ECS Configuration
app_name = "$Project"
app_cpu = 256
app_memory = 512
app_port = 3001
desired_count = 2

# Tags
common_tags = {
  Project     = "$Project"
  Environment = "$Environment"
  ManagedBy   = "Terraform"
  CreatedAt   = "$(Get-Date -Format 'yyyy-MM-dd')"
}
"@

Set-Content -Path "terraform.tfvars" -Value $tfvars
Write-Log "terraform.tfvars created" Success

# Terraform Init
Write-Log "Running terraform init" Step

terraform init
Write-Log "Terraform initialized" Success

# Terraform Plan
Write-Log "Creating Terraform Plan" Step

terraform plan -out=tfplan
Write-Log "Terraform plan created" Success

# Ask for confirmation
Write-Host ""
Write-Host "Review the Terraform plan above." -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Apply Terraform changes? (yes/no)"

if ($confirm -ne 'yes') {
    Write-Log "Terraform apply cancelled" Warn
    Pop-Location
    exit 0
}

# Terraform Apply
Write-Log "Applying Terraform Configuration" Step

terraform apply tfplan
Write-Log "Terraform apply completed" Success

# Get Outputs
Write-Log "Retrieving Deployment Information" Step

$outputs = terraform output -json | ConvertFrom-Json

Write-Host ""
Write-Host "Deployment Outputs:" -ForegroundColor Cyan

if ($outputs.load_balancer_dns) {
    Write-Log "Load Balancer: $($outputs.load_balancer_dns.value)" Success
}

if ($outputs.rds_endpoint) {
    Write-Log "Database: $($outputs.rds_endpoint.value)" Success
}

if ($outputs.ecr_repository_url) {
    Write-Log "ECR Repository: $($outputs.ecr_repository_url.value)" Success
}

# Push Docker Images
Write-Log "Pushing Docker Images to ECR" Step

$ecrUrl = $outputs.ecr_repository_url.value
$accountId = $awsIdentity.Account

Write-Log "Authenticating with ECR" Info
aws ecr get-login-password --region $AWSRegion | docker login --username AWS --password-stdin "$accountId.dkr.ecr.$AWSRegion.amazonaws.com"

Write-Log "Building API image" Info
docker build -t "$ecrUrl/api:latest" -f apps/api/Dockerfile .

Write-Log "Building Web image" Info
docker build -t "$ecrUrl/web:latest" -f apps/web/Dockerfile .

Write-Log "Pushing API image" Info
docker push "$ecrUrl/api:latest"

Write-Log "Pushing Web image" Info
docker push "$ecrUrl/web:latest"

Write-Log "Images pushed to ECR" Success

# ECS Deployment
Write-Log "Deploying to ECS" Step

$ecsCluster = "$project-cluster"
$ecsService = "$project-service"

aws ecs update-service `
    --cluster $ecsCluster `
    --service $ecsService `
    --force-new-deployment `
    --region $AWSRegion

Write-Log "ECS deployment started" Success

# Wait for service to stabilize
Write-Log "Waiting for ECS service to stabilize..." Info
Start-Sleep -Seconds 10

$serviceStatus = aws ecs describe-services `
    --cluster $ecsCluster `
    --services $ecsService `
    --region $AWSRegion | ConvertFrom-Json

if ($serviceStatus.services[0].status -eq 'ACTIVE') {
    Write-Log "ECS service is active" Success
} else {
    Write-Log "ECS service status: $($serviceStatus.services[0].status)" Warn
}

# Cleanup
Pop-Location

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ AWS DEPLOYMENT COMPLETE!                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Log "Infrastructure deployed to AWS" Success
Write-Log "Region: $AWSRegion" Info
Write-Log "Environment: $Environment" Info
Write-Log ""
Write-Log "Monitor deployment:" Step
Write-Log "  aws ecs describe-services --cluster $ecsCluster --services $ecsService"
Write-Log ""
Write-Log "View logs:" Step
Write-Log "  aws logs tail /ecs/$project-task --follow"

exit 0
