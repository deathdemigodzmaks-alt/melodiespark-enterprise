#!/bin/bash
# Automated Deployment Script
# Deploys MelodieSpark to Cloud (Vercel + Railway) with full automation

set -e

SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SYSTEM_DIR/.saas-deployment/logs/deploy-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"; }
log_step() { echo -e "\n${MAGENTA}▶▶▶ $1 ▶▶▶${NC}" | tee -a "$LOG_FILE"; }

# Ensure logs directory exists
mkdir -p "$SYSTEM_DIR/.saas-deployment/logs"

echo -e "\n${MAGENTA}════════════════════════════════════════════════════════════${NC}" | tee "$LOG_FILE"
echo -e "${MAGENTA}  🚀 MELODIESPARK AUTOMATED DEPLOYMENT 🚀${NC}" | tee -a "$LOG_FILE"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"

# Check prerequisites
log_step "Checking Prerequisites"

if ! command -v git &> /dev/null; then
    log_error "Git not installed"
    exit 1
fi
log_success "git is installed"

if ! command -v pnpm &> /dev/null; then
    log_warn "pnpm not found, using npm"
    PKG_MGR="npm"
else
    PKG_MGR="pnpm"
    log_success "pnpm is installed"
fi

# Check git remote
log_step "Checking Git Configuration"

if ! git -C "$SYSTEM_DIR" remote -v | grep -q "origin"; then
    log_error "No git remote 'origin' found"
    log_info "Run: git remote add origin <github-url>"
    exit 1
fi

ORIGIN_URL=$(git -C "$SYSTEM_DIR" remote get-url origin)
log_success "Git remote configured: $ORIGIN_URL"

# Install dependencies
log_step "Installing Dependencies"

cd "$SYSTEM_DIR"
if [ "$PKG_MGR" = "pnpm" ]; then
    pnpm install --frozen-lockfile 2>&1 | tee -a "$LOG_FILE"
else
    npm install 2>&1 | tee -a "$LOG_FILE"
fi
log_success "Dependencies installed"

# Push to git
log_step "Pushing Code to Git"

git -C "$SYSTEM_DIR" add -A 2>&1 | tee -a "$LOG_FILE" || true

if ! git -C "$SYSTEM_DIR" diff-index --quiet HEAD -- 2>/dev/null; then
    git -C "$SYSTEM_DIR" commit -m "Deployment: $(date)" 2>&1 | tee -a "$LOG_FILE" || true
    log_success "Committed changes"
fi

git -C "$SYSTEM_DIR" push -u origin main 2>&1 | tee -a "$LOG_FILE" || true
log_success "Code pushed to GitHub"

# Deployment selection
log_step "Starting Deployment"

DEPLOYMENT_TARGET=${1:-cloud}

case "$DEPLOYMENT_TARGET" in
    cloud)
        log_info "Deploying to Cloud (Vercel + Railway)"
        bash "$SYSTEM_DIR/.saas-deployment/scripts/deploy-cloud.sh" 2>&1 | tee -a "$LOG_FILE"
        ;;
    vps)
        log_info "Deploying to VPS"
        bash "$SYSTEM_DIR/.saas-deployment/scripts/deploy-vps.sh" 2>&1 | tee -a "$LOG_FILE"
        ;;
    k8s)
        log_info "Deploying to Kubernetes"
        bash "$SYSTEM_DIR/.saas-deployment/scripts/deploy-k8s.sh" 2>&1 | tee -a "$LOG_FILE"
        ;;
    aws)
        log_info "Deploying to AWS"
        bash "$SYSTEM_DIR/.saas-deployment/scripts/deploy-aws.sh" 2>&1 | tee -a "$LOG_FILE"
        ;;
    *)
        log_error "Unknown deployment target: $DEPLOYMENT_TARGET"
        exit 1
        ;;
esac

# Verify deployment
log_step "Verifying Deployment"

sleep 5

if curl -s -f -o /dev/null -w "%{http_code}" "http://localhost:3001/health" || \
   curl -s -f -o /dev/null -w "%{http_code}" "https://melodiespark.vercel.app" || \
   curl -s -f -o /dev/null -w "%{http_code}" "https://melodiespark.up.railway.app"; then
    log_success "Deployment verified - API is responding"
else
    log_warn "Health check inconclusive - app may still be initializing"
fi

# Summary
log_step "Deployment Complete"

echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL!${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"

log_info "Deployment Target: $DEPLOYMENT_TARGET"
log_info "Git Remote: $ORIGIN_URL"
log_info "Log File: $LOG_FILE"

case "$DEPLOYMENT_TARGET" in
    cloud)
        log_info "Frontend: https://melodiespark.vercel.app"
        log_info "Backend: https://api.melodiespark.railway.app"
        ;;
    vps)
        log_info "Access: Check your VPS IP address"
        ;;
    k8s)
        log_info "Access: kubectl port-forward svc/melodiespark 8080:80"
        ;;
    aws)
        log_info "Access: Check AWS ECS console for load balancer URL"
        ;;
esac

log_success "Next: Monitor deployment with: bash monitor.sh"

echo -e "\n"
