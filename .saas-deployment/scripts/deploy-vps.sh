#!/bin/bash
# VPS Deployment Script
# Complete automation for deploying to self-hosted VPS

set -e

SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SYSTEM_DIR/../.."
STATE_DIR="$DEPLOY_DIR/state"
LOGS_DIR="$DEPLOY_DIR/logs"

mkdir -p "$STATE_DIR" "$LOGS_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

MAIN_LOG="$LOGS_DIR/vps-deployment.log"
ERROR_LOG="$LOGS_DIR/errors.log"

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$MAIN_LOG"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$MAIN_LOG"; }
log_error() { echo -e "${RED}❌ $1${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"; }
log_step() { echo -e "\n${MAGENTA}▶▶▶ $1 ▶▶▶${NC}"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP: $1" >> "$MAIN_LOG"; }

main() {
    clear
    
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        🖥️ VPS Deployment (Self-Hosted) 🚀                  ║"
    echo "║           Complete Automation                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    log_step "VPS Deployment Setup"
    
    echo -e "${CYAN}Enter VPS details:${NC}"
    read -p "VPS IP address: " vps_ip
    read -p "VPS username (default: root): " vps_user
    read -p "VPS domain name: " vps_domain
    read -p "Email for SSL (Let's Encrypt): " ssl_email
    
    vps_user=${vps_user:-root}
    
    log_info "VPS Configuration:"
    log_info "  IP: $vps_ip"
    log_info "  User: $vps_user"
    log_info "  Domain: $vps_domain"
    
    # Test SSH connection
    log_step "Testing SSH Connection"
    if ssh -o ConnectTimeout=5 "$vps_user@$vps_ip" "echo 'SSH OK'" &>/dev/null; then
        log_success "SSH connection successful"
    else
        log_error "Cannot connect to VPS. Check IP, username, and SSH keys."
        return 1
    fi
    
    # Deploy script
    log_step "Deploying to VPS"
    
    ssh "$vps_user@$vps_ip" << 'DEPLOY_SCRIPT'
set -e

echo "Installing Docker and dependencies..."
apt-get update
apt-get install -y curl git docker.io docker-compose nginx certbot python3-certbot-nginx

echo "Cloning repository..."
cd /opt
git clone https://github.com/YOUR_REPO/melodiespark.git || cd melodiespark && git pull

cd melodiespark/MelodieSpark

echo "Creating .env..."
[ ! -f .env ] && cp .env.example .env

echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/melodiespark << 'NGINX'
server {
    server_name _default_;
    listen 80;
    
    location /api {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/melodiespark /etc/nginx/sites-enabled/
systemctl restart nginx

echo "Verifying services..."
sleep 5
curl -f http://localhost:3001/health || echo "API not responding yet"
curl -f http://localhost:3000 || echo "Frontend not responding yet"

echo "VPS deployment complete!"
DEPLOY_SCRIPT

    log_success "VPS deployment completed"
    
    echo -e "\n${GREEN}🎉 VPS Deployment Complete!${NC}"
    echo "SSH to VPS: ssh $vps_user@$vps_ip"
    echo "Domain: $vps_domain"
    echo "Point DNS A record to: $vps_ip"
}

main "$@"
