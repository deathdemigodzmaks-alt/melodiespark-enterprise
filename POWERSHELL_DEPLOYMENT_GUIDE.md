# POWERSHELL DEPLOYMENT GUIDE

Complete PowerShell-based deployment automation for MelodieSpark

---

## 🚀 QUICK START (PowerShell)

### Prerequisites

```powershell
# Check PowerShell version (5.0+)
$PSVersionTable.PSVersion

# If needed, upgrade PowerShell: https://github.com/PowerShell/PowerShell/releases
```

### One-Command Deployment

```powershell
# Interactive Mode (Choose target)
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1

# Cloud Deployment (15 minutes)
powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1

# VPS Deployment (30 minutes)
powershell -ExecutionPolicy Bypass -File Deploy-VPS.ps1

# Kubernetes (1 hour)
powershell -ExecutionPolicy Bypass -File Deploy-Kubernetes.ps1

# AWS (45 minutes)
powershell -ExecutionPolicy Bypass -File Deploy-AWS.ps1
```

---

## 📋 DEPLOYMENT OPTIONS

### Option 1: Cloud (Vercel + Railway) ⭐ FASTEST

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1
```

**What it does:**
- ✅ Installs all dependencies
- ✅ Builds frontend & backend
- ✅ Commits and pushes to GitHub
- ✅ Creates Vercel & Railway configs
- ✅ Generates deployment guide

**Time:** 15 minutes  
**Cost:** $25-85/month  
**Effort:** Easy

---

### Option 2: VPS (Self-Hosted)

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-VPS.ps1 `
    -VPSHost "your-vps.com" `
    -VPSUser "deploy" `
    -SSHKey "$env:USERPROFILE\.ssh\id_rsa"
```

**What it does:**
- ✅ Connects to VPS via SSH
- ✅ Installs Docker & dependencies
- ✅ Clones repository
- ✅ Sets up docker-compose
- ✅ Configures nginx reverse proxy

**Time:** 30 minutes  
**Cost:** $6-20/month  
**Effort:** Medium

---

### Option 3: Kubernetes

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Kubernetes.ps1 `
    -KubeContext "docker-desktop" `
    -Namespace "melodiespark" `
    -ImageTag "latest"
```

**What it does:**
- ✅ Creates namespace
- ✅ Deploys PostgreSQL
- ✅ Deploys Redis
- ✅ Deploys application (3 replicas)
- ✅ Configures auto-scaling
- ✅ Sets up health checks

**Time:** 1 hour  
**Cost:** $50-200/month  
**Effort:** Hard

---

### Option 4: AWS (Terraform)

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-AWS.ps1 `
    -AWSRegion "us-east-1" `
    -Environment "production"
```

**What it does:**
- ✅ Initializes Terraform
- ✅ Creates VPC & networking
- ✅ Sets up RDS (PostgreSQL)
- ✅ Configures ElastiCache (Redis)
- ✅ Creates ECS cluster
- ✅ Sets up load balancer
- ✅ Configures auto-scaling

**Time:** 45 minutes  
**Cost:** $100-500/month  
**Effort:** Hard

---

## 🎯 INTERACTIVE MODE

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1
```

This launches an interactive menu:

```
Select Deployment Target:

  1) ☁️  CLOUD (Vercel + Railway) — 15 minutes
  2) 🖥️  VPS (Self-Hosted) — 30 minutes
  3) ☸️  KUBERNETES (Multi-Region) — 1 hour
  4) 🌩️  AWS (Terraform) — 45 minutes
  5) 🔄 MULTI-INFRASTRUCTURE (All Targets) — 2-3 hours

Choose (1-5): 
```

---

## 📝 COMPLETE SCRIPT LIST

| Script | Purpose | Time |
|--------|---------|------|
| `Deploy-Orchestrator.ps1` | Master control center | - |
| `Deploy-Cloud.ps1` | Vercel + Railway automation | 15 min |
| `Deploy-VPS.ps1` | Self-hosted setup | 30 min |
| `Deploy-Kubernetes.ps1` | K8s deployment | 1 hour |
| `Deploy-AWS.ps1` | AWS Terraform | 45 min |

---

## 🔧 ADVANCED OPTIONS

### Skip Git Push

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1 `
    -SkipGit
```

### Skip Build

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1 `
    -SkipBuild
```

### Verbose Output

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1 `
    -Verbose
```

---

## 🔐 SETTING ENVIRONMENT VARIABLES

### Global Environment Variables

```powershell
# Set for current session
$env:VERCEL_TOKEN = "your-vercel-token"
$env:RAILWAY_TOKEN = "your-railway-token"
$env:GITHUB_TOKEN = "your-github-token"

# Set permanently (User)
[Environment]::SetEnvironmentVariable('VERCEL_TOKEN', 'your-token', 'User')

# Set permanently (System - requires admin)
[Environment]::SetEnvironmentVariable('VERCEL_TOKEN', 'your-token', 'Machine')
```

### Get Tokens

```powershell
# Vercel
# Go to: https://vercel.com/account/tokens

# Railway
# Go to: https://railway.app/account/tokens

# GitHub
# Go to: https://github.com/settings/tokens
```

---

## 📊 DEPLOYMENT COMPARISON

| Aspect | Cloud | VPS | K8s | AWS |
|--------|-------|-----|-----|-----|
| **Time** | 15 min ⭐ | 30 min | 1 hr | 45 min |
| **Cost** | $25-85 | $6-20 | $50-200 | $100-500 |
| **Setup** | Easy ⭐ | Medium | Hard | Hard |
| **Scaling** | Auto | Manual | Auto | Auto |
| **Complexity** | Low | Medium | High | High |

---

## 🐛 TROUBLESHOOTING

### PowerShell Execution Policy

```powershell
# If you get "cannot be loaded because running scripts..."
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run script
powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1
```

### SSH Connection Issues (VPS)

```powershell
# Test SSH connection
ssh -i "C:\Users\YourUser\.ssh\id_rsa" user@your-vps.com "echo test"

# Generate SSH key
ssh-keygen -t rsa -b 4096
```

### AWS Credentials Not Found

```powershell
# Configure AWS CLI
aws configure

# Or set environment variables
$env:AWS_ACCESS_KEY_ID = "your-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret"
$env:AWS_DEFAULT_REGION = "us-east-1"
```

### Docker Not Found

```powershell
# Install Docker Desktop
# https://www.docker.com/products/docker-desktop

# Or use WSL 2
wsl --install

# Or use Rancher Desktop
# https://rancherdesktop.io/
```

---

## 📋 COMPLETE WORKFLOW

### Step 1: Choose Target

```powershell
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1
```

### Step 2: Follow Prompts

The script will:
- Check prerequisites
- Install dependencies
- Build application
- Commit & push code
- Generate configs
- Start deployment

### Step 3: Monitor Deployment

Check your deployment platform:
- **Vercel:** https://vercel.com/dashboard
- **Railway:** https://railway.app/dashboard
- **Kubernetes:** `kubectl get pods -n melodiespark`
- **AWS:** AWS Console → ECS

### Step 4: Verify

```powershell
# Test frontend
Invoke-WebRequest "https://melodiespark.vercel.app"

# Test backend
Invoke-WebRequest "https://api-melodiespark.railway.app/health"
```

---

## ✅ WHAT YOU GET

✅ Fully automated deployment  
✅ No manual steps  
✅ Error handling & logging  
✅ Auto-retry on failures  
✅ Detailed status messages  
✅ Complete documentation  

---

## 🎉 START DEPLOYMENT

```powershell
# Interactive (recommended)
powershell -ExecutionPolicy Bypass -File Deploy-Orchestrator.ps1

# Or direct to cloud
powershell -ExecutionPolicy Bypass -File Deploy-Cloud.ps1
```

Your MelodieSpark SaaS will be **LIVE in 15 minutes!** 🚀

---

**Need help?** Check the logs in `.saas-deployment/logs/`
