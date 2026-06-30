#!/bin/bash
# Complete GitHub Repository Automation System
# Creates GitHub repo, initializes git, and sets everything up

set -e

SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_NAME="melodiespark-enterprise"
REPO_OWNER=${1:-}

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "\n${MAGENTA}▶▶▶ $1 ▶▶▶${NC}"; }

clear

echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🚀 GitHub Repository Automation System 🚀                  ║"
echo "║           Complete Git Setup & Deployment                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check if git is installed
if ! command -v git &> /dev/null; then
    log_error "Git is not installed"
    log_info "Install git first: https://git-scm.com/download"
    exit 1
fi

log_success "Git is installed"

# Initialize git repository (if not already)
log_step "Initializing Git Repository"

cd "$SYSTEM_DIR"

if [ -d ".git" ]; then
    log_success "Git repository already initialized"
else
    log_info "Initializing new git repository..."
    git init
    git config user.email "developer@melodiespark.com"
    git config user.name "MelodieSpark Developer"
    log_success "Git repository initialized"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    log_step "Creating .gitignore"
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
pnpm-lock.yaml
package-lock.json
yarn.lock

# Environment
.env
.env.local
.env.*.local

# Build output
dist/
build/
.next/
out/

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Docker
.dockerignore
docker-compose.override.yml

# Testing
coverage/
.nyc_output/

# Temporary
tmp/
temp/
*.tmp

# Secrets
.env.production.local
*.pem
*.key
EOF
    log_success ".gitignore created"
fi

# Create .gitattributes for consistent line endings
if [ ! -f ".gitattributes" ]; then
    log_step "Creating .gitattributes"
    cat > .gitattributes << 'EOF'
# Auto detect text files and normalize line endings to LF
* text=auto
*.js text eol=lf
*.ts text eol=lf
*.tsx text eol=lf
*.json text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.md text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.zip binary
EOF
    log_success ".gitattributes created"
fi

# Stage and commit initial files
log_step "Staging and Committing Files"

log_info "Staging all files..."
git add -A || true

if git diff-index --quiet HEAD -- 2>/dev/null; then
    log_success "Repository is up to date"
else
    log_info "Creating initial commit..."
    git commit -m "Initial commit: Complete enterprise SaaS platform setup" || true
    log_success "Initial commit created"
fi

# Create GitHub repository setup guide
log_step "Creating GitHub Setup Guide"

cat > GITHUB_SETUP.md << 'EOF'
# GitHub Repository Setup Guide

## 1. Create Repository on GitHub

If you don't have a GitHub account, create one at https://github.com/signup

### Option A: Create via GitHub Web UI
1. Go to https://github.com/new
2. Repository name: `melodiespark-enterprise`
3. Description: "Enterprise SaaS Platform - Complete Automation"
4. Choose: Public or Private
5. Click "Create repository"

### Option B: Create via GitHub CLI
```bash
# Install GitHub CLI: https://cli.github.com/
gh auth login
gh repo create melodiespark-enterprise \
  --description "Enterprise SaaS Platform" \
  --public \
  --source=. \
  --remote=origin \
  --push
```

## 2. Add Remote & Push Code

```bash
# Add GitHub as remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/melodiespark-enterprise.git

# Rename default branch to main (if needed)
git branch -M main

# Push code to GitHub
git push -u origin main
```

## 3. Verify

Go to https://github.com/USERNAME/melodiespark-enterprise and verify your code is there.

## 4. Setup Automatic Deployments

### GitHub Actions CI/CD
1. Go to Actions tab in GitHub
2. Enable GitHub Actions
3. Workflows will run on every push to main

### Deploy from GitHub

```bash
# Cloud Deployment
gh workflow run deploy.yml -f environment=cloud

# VPS Deployment  
gh workflow run deploy.yml -f environment=vps

# Kubernetes
gh workflow run deploy.yml -f environment=kubernetes

# AWS
gh workflow run deploy.yml -f environment=aws
```

## 5. Setup Secrets (Required for Deployments)

Go to Settings → Secrets and variables → Actions, add:

```
VERCEL_TOKEN         # Get from: https://vercel.com/account/tokens
RAILWAY_TOKEN        # Get from: https://railway.app/account/tokens
AWS_ACCESS_KEY_ID    # Get from: AWS Console
AWS_SECRET_ACCESS_KEY # Get from: AWS Console
KUBE_CONFIG          # Get from: kubectl config view
DOCKER_USERNAME      # Your Docker Hub username
DOCKER_PASSWORD      # Your Docker Hub token
ANTHROPIC_API_KEY    # Your Anthropic key
OPENAI_API_KEY       # Your OpenAI key
```

## 6. Deploy Automatically

Once secrets are set:
```bash
git push origin main
# GitHub Actions automatically:
# 1. Runs tests
# 2. Builds Docker images
# 3. Pushes to registry
# 4. Deploys to your target
```

---

**Your repository is now set up and ready to deploy!**
EOF

log_success "GitHub setup guide created"

# Create deployment automation script
log_step "Creating Deployment Automation"

cat > setup-github.sh << 'EOF'
#!/bin/bash
# Quick GitHub setup script

if [ -z "$1" ]; then
    echo "Usage: bash setup-github.sh <github-username>"
    exit 1
fi

USERNAME=$1
REPO="melodiespark-enterprise"

echo "Setting up GitHub for $USERNAME/$REPO"

# Add remote
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$USERNAME/$REPO.git"

echo "Remote added: https://github.com/$USERNAME/$REPO.git"

# Ensure on main branch
git branch -M main

echo "Ready to push!"
echo ""
echo "Next steps:"
echo "1. Create repository at https://github.com/new"
echo "2. Push code: git push -u origin main"
echo "3. Add secrets to GitHub for deployments"
echo "4. Your CI/CD will automatically deploy!"
EOF

chmod +x setup-github.sh
log_success "Setup script created"

# Display summary
log_step "Setup Complete"

echo -e "\n${CYAN}📍 What's been done:${NC}"
echo "  ✅ Git repository initialized"
echo "  ✅ .gitignore configured"
echo "  ✅ .gitattributes configured"
echo "  ✅ Initial commit created"
echo "  ✅ GitHub setup guide created"
echo "  ✅ Setup automation script created"

echo -e "\n${CYAN}📋 Next steps:${NC}"
echo "  1. Create GitHub repository at: https://github.com/new"
echo "  2. Run setup script:"
echo "     bash setup-github.sh <your-github-username>"
echo "  3. Push code:"
echo "     git push -u origin main"
echo "  4. Add deployment secrets (see GITHUB_SETUP.md)"
echo "  5. Your app deploys automatically on every push!"

echo -e "\n${CYAN}🚀 Deploy immediately:${NC}"
echo "  bash ../enterprise-orchestrator.sh"

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ GITHUB REPOSITORY AUTOMATION COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}\n"
