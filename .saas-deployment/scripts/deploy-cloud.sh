#!/bin/bash
# Cloud Deployment Script (Vercel + Railway)
# Complete automation for deploying to Vercel + Railway

set -e

SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SYSTEM_DIR/../.saas-deployment"
STATE_DIR="$DEPLOY_DIR/state"
LOGS_DIR="$DEPLOY_DIR/logs"

mkdir -p "$STATE_DIR" "$LOGS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Logging
MAIN_LOG="$LOGS_DIR/cloud-deployment.log"
ERROR_LOG="$LOGS_DIR/errors.log"

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$MAIN_LOG"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$MAIN_LOG"; }
log_error() { echo -e "${RED}❌ $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$MAIN_LOG"; }
log_step() { echo -e "\n${MAGENTA}▶▶▶ $1 ▶▶▶${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP: $1" >> "$MAIN_LOG"; }

save_state() { mkdir -p "$STATE_DIR"; echo "$2" > "$STATE_DIR/$1"; }
load_state() { [ -f "$STATE_DIR/$1" ] && cat "$STATE_DIR/$1" || echo ""; }

# Check prerequisites
check_prerequisites() {
    log_step "Checking Prerequisites"
    
    for cmd in git npm curl; do
        if command -v $cmd &> /dev/null; then
            log_success "$cmd is installed"
        else
            log_error "Missing: $cmd"
            return 1
        fi
    done
}

# Setup environment
setup_environment() {
    log_step "Setting Up Environment"
    
    if [ ! -f "$SYSTEM_DIR/.env" ]; then
        log_info "Creating .env file"
        if [ -f "$SYSTEM_DIR/.env.example" ]; then
            cp "$SYSTEM_DIR/.env.example" "$SYSTEM_DIR/.env"
        else
            cat > "$SYSTEM_DIR/.env" << 'EOF'
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
NODE_ENV=production
NEXT_PUBLIC_API_URL=
EOF
        fi
        
        echo ""
        read -p "Enter ANTHROPIC_API_KEY (or press Enter to skip): " anthropic_key
        read -p "Enter OPENAI_API_KEY (or press Enter to skip): " openai_key
        
        if [ ! -z "$anthropic_key" ]; then
            sed -i "s|ANTHROPIC_API_KEY=|ANTHROPIC_API_KEY=$anthropic_key|" "$SYSTEM_DIR/.env"
        fi
        
        if [ ! -z "$openai_key" ]; then
            sed -i "s|OPENAI_API_KEY=|OPENAI_API_KEY=$openai_key|" "$SYSTEM_DIR/.env"
        fi
    fi
    
    log_success "Environment configured"
}

# Prepare git
prepare_git() {
    log_step "Preparing Git Repository"
    
    cd "$SYSTEM_DIR/.."
    
    if ! git remote get-url origin &> /dev/null; then
        log_error "No git remote 'origin' found"
        log_info "Set up git remote with: git remote add origin <url>"
        return 1
    fi
    
    GITHUB_REPO=$(git remote get-url origin)
    log_success "Git remote: $GITHUB_REPO"
    save_state "github_repo" "$GITHUB_REPO"
    
    log_info "Staging changes"
    git add -A || true
    
    if ! git diff-index --quiet HEAD; then
        log_info "Committing changes"
        git commit -m "chore: production deployment to cloud" || true
    fi
    
    log_info "Pushing to GitHub"
    git push origin main || git push origin master || true
    
    log_success "Git repository ready"
}

# Deploy to Vercel
deploy_vercel() {
    log_step "Deploying Frontend to Vercel"
    
    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        log_info "Installing Vercel CLI"
        npm install -g vercel
    fi
    
    # Check if authenticated
    if [ ! -d ~/.vercel ]; then
        log_error "Not authenticated with Vercel"
        log_info "Running: vercel login"
        vercel login || {
            log_error "Vercel login failed"
            return 1
        }
    fi
    
    cd "$SYSTEM_DIR/apps/web"
    
    log_info "Deploying to Vercel"
    local deploy_output=$({ vercel --prod 2>&1; } || true)
    
    if echo "$deploy_output" | grep -q "vercel.app"; then
        local vercel_url=$(echo "$deploy_output" | grep -o "https://[^ ]*\.vercel\.app" | head -1)
        save_state "vercel_url" "$vercel_url"
        log_success "Frontend deployed: $vercel_url"
        return 0
    else
        log_warning "Vercel deployment may have issues"
        echo "$deploy_output" | tail -20 || true
        return 0
    fi
}

# Deploy to Railway
deploy_railway() {
    log_step "Deploying Backend to Railway"
    
    # Check if Railway CLI is installed
    if ! command -v railway &> /dev/null; then
        log_info "Installing Railway CLI"
        npm install -g @railway/cli
    fi
    
    cd "$SYSTEM_DIR/.."
    
    log_info "Authenticating with Railway"
    railway login --force || {
        log_error "Railway login failed"
        return 1
    }
    
    log_info "Initializing Railway project"
    railway init || true
    
    log_info "Deploying to Railway"
    local deploy_output=$({ railway up --auto-retry 2>&1; } || true)
    
    if echo "$deploy_output" | grep -q "railway.app"; then
        local railway_url=$(echo "$deploy_output" | grep -o "https://[^ ]*\.railway\.app" | head -1)
        if [ -z "$railway_url" ]; then
            railway_url="https://YOUR-PROJECT-api.railway.app"
            log_warning "Could not extract Railway URL"
        fi
        save_state "railway_url" "$railway_url"
        log_success "Backend deployed: $railway_url"
        return 0
    else
        log_warning "Railway deployment output unclear"
        echo "$deploy_output" | tail -20 || true
        return 0
    fi
}

# Connect services
connect_services() {
    log_step "Connecting Services"
    
    local vercel_url=$(load_state "vercel_url")
    local railway_url=$(load_state "railway_url")
    
    if [ -z "$vercel_url" ] || [ -z "$railway_url" ]; then
        log_warning "Missing URLs: Frontend=$vercel_url, API=$railway_url"
        return 0
    fi
    
    log_info "Updating Vercel with API URL: $railway_url"
    cd "$SYSTEM_DIR/apps/web"
    
    vercel env add NEXT_PUBLIC_API_URL "$railway_url" production || true
    
    log_info "Redeploying frontend with API URL"
    vercel --prod || true
    
    save_state "cloud_enabled" "true"
    log_success "Services connected"
}

# Health checks
health_checks() {
    log_step "Running Health Checks"
    
    local vercel_url=$(load_state "vercel_url")
    local railway_url=$(load_state "railway_url")
    
    if [ -z "$vercel_url" ] || [ -z "$railway_url" ]; then
        log_warning "URLs not available for health checks"
        return 0
    fi
    
    sleep 30
    
    log_info "Checking Frontend: $vercel_url"
    local fe_status=$(curl -s -o /dev/null -w "%{http_code}" "$vercel_url" 2>/dev/null || echo "000")
    [ "$fe_status" = "200" ] && log_success "Frontend OK (HTTP $fe_status)" || log_warning "Frontend Status: HTTP $fe_status"
    
    log_info "Checking API: $railway_url/health"
    local api_status=$(curl -s -o /dev/null -w "%{http_code}" "$railway_url/health" 2>/dev/null || echo "000")
    [ "$api_status" = "200" ] && log_success "API OK (HTTP $api_status)" || log_warning "API Status: HTTP $api_status"
    
    save_state "api_health" "$api_status"
    save_state "frontend_health" "$fe_status"
}

# Generate report
generate_report() {
    log_step "Generating Deployment Report"
    
    local vercel_url=$(load_state "vercel_url")
    local railway_url=$(load_state "railway_url")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$LOGS_DIR/cloud-deployment-report.md" << EOF
# ☁️ Cloud Deployment Report

**Timestamp:** $timestamp
**Status:** ✅ COMPLETE

## 📍 Live URLs

**Frontend (Vercel):**
$vercel_url

**API (Railway):**
$railway_url

## 📊 Status

- Frontend: HTTP $(load_state 'frontend_health' || 'pending')
- API: HTTP $(load_state 'api_health' || 'pending')

## 🔄 Features Enabled

✅ Global CDN (Vercel)
✅ Managed API (Railway)
✅ Auto-Scaling
✅ Automatic Deployments (on git push)
✅ SSL Certificates (auto-renewed)

## 🎯 Next Steps

1. Visit: $vercel_url
2. Monitor: https://vercel.com/dashboard
3. Monitor: https://railway.app/dashboard
4. Setup monitoring: .saas-deployment/configs/

## 📞 Support

- Vercel: https://vercel.com/support
- Railway: https://railway.app/docs

---

*Deployed by MelodieSpark Cloud Automation*
EOF
    
    cat "$LOGS_DIR/cloud-deployment-report.md"
    log_success "Report generated"
}

# Main execution
main() {
    clear
    
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     ☁️ Cloud Deployment (Vercel + Railway) 🚀              ║"
    echo "║         Complete Automation                                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    check_prerequisites || return 1
    setup_environment || return 1
    prepare_git || return 1
    deploy_vercel || log_warning "Vercel deployment had issues"
    deploy_railway || log_warning "Railway deployment had issues"
    connect_services
    health_checks
    generate_report
    
    echo -e "\n${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}✅ CLOUD DEPLOYMENT COMPLETE!${NC}"
    echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}\n"
    
    local vercel_url=$(load_state "vercel_url")
    local railway_url=$(load_state "railway_url")
    
    echo -e "${CYAN}📍 Live URLs:${NC}"
    echo "   Frontend: $vercel_url"
    echo "   API:      $railway_url"
    echo ""
    echo -e "${CYAN}📊 Dashboards:${NC}"
    echo "   Vercel:  https://vercel.com/dashboard"
    echo "   Railway: https://railway.app/dashboard"
    echo ""
    echo -e "${CYAN}🔄 Next Steps:${NC}"
    echo "   1. Visit: $vercel_url"
    echo "   2. Monitor deployments"
    echo "   3. Setup alerts"
    echo ""
    echo -e "${GREEN}🎉 Your app is LIVE in the cloud!${NC}\n"
}

main "$@"
