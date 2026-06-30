#!/bin/bash
# VPS Deployment Script (DigitalOcean, Linode, AWS EC2, etc.)

set -e

echo "🚀 Deploying to VPS"
echo "=================="

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
read -p "Enter VPS IP address: " VPS_IP
read -p "Enter VPS username (default: root): " VPS_USER
VPS_USER=${VPS_USER:-root}
read -p "Enter domain name (e.g., melodiespark.com): " DOMAIN
read -p "Enter email for SSL (Let's Encrypt): " SSL_EMAIL

echo -e "${BLUE}📋 VPS Configuration${NC}"
echo "IP: $VPS_IP"
echo "User: $VPS_USER"
echo "Domain: $DOMAIN"

# Test SSH connection
echo -e "\n${BLUE}🔗 Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 $VPS_USER@$VPS_IP "echo 'Connected'" &>/dev/null; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo "❌ Cannot connect to VPS. Check IP, username, and SSH keys."
    exit 1
fi

# Deploy script
DEPLOY_SCRIPT='#!/bin/bash
set -e

echo "🚀 Installing dependencies..."

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "📥 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📥 Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Install Nginx and Certbot
apt-get install -y nginx certbot python3-certbot-nginx

# Clone repository
cd /home/$USER
if [ ! -d "melodiespark" ]; then
    git clone https://github.com/YOUR_REPO/melodiespark.git
fi

cd melodiespark/MelodieSpark

# Create .env
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Edit .env with your API keys"
fi

# Build and start services
echo "🐳 Building Docker images..."
docker-compose build

echo "🚀 Starting services..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Wait for services
sleep 10

# Verify services
docker-compose ps

echo "✅ Services running!"
'

# Upload and execute deployment script
echo -e "\n${BLUE}📤 Uploading deployment script...${NC}"

ssh $VPS_USER@$VPS_IP bash << EOF
$DEPLOY_SCRIPT
EOF

echo -e "${GREEN}✅ Initial deployment complete${NC}"

# Setup Nginx
echo -e "\n${BLUE}🔧 Configuring Nginx...${NC}"

NGINX_CONFIG="server {
    server_name $DOMAIN www.$DOMAIN;
    listen 80;

    client_max_body_size 100M;

    # API proxy
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Frontend proxy
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
"

ssh $VPS_USER@$VPS_IP bash << EOF
echo '$NGINX_CONFIG' | sudo tee /etc/nginx/sites-available/melodiespark > /dev/null
sudo ln -sf /etc/nginx/sites-available/melodiespark /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
EOF

echo -e "${GREEN}✅ Nginx configured${NC}"

# Setup SSL with Let's Encrypt
echo -e "\n${BLUE}🔐 Setting up SSL certificate...${NC}"

ssh $VPS_USER@$VPS_IP sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN -m $SSL_EMAIL --agree-tos --non-interactive

echo -e "${GREEN}✅ SSL certificate installed${NC}"

# Setup auto-renewal
echo -e "\n${BLUE}⏰ Setting up certificate auto-renewal...${NC}"

ssh $VPS_USER@$VPS_IP sudo systemctl enable certbot.timer

echo -e "${GREEN}✅ Auto-renewal enabled${NC}"

# Setup monitoring
echo -e "\n${BLUE}📊 Setting up monitoring...${NC}"

MONITOR_SCRIPT='#!/bin/bash
# Basic health check script

while true; do
    # Check services
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health)
    WEB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
    
    # Log status
    echo "$(date): API=$API_STATUS, WEB=$WEB_STATUS" >> /var/log/melodiespark-health.log
    
    # Alert if services down
    if [ "$API_STATUS" != "200" ] || [ "$WEB_STATUS" != "200" ]; then
        echo "⚠️  Service down at $(date)" | mail -s "MelodieSpark Alert" admin@melodiespark.com
    fi
    
    sleep 300  # Check every 5 minutes
done
'

ssh $VPS_USER@$VPS_IP bash << EOF
echo '$MONITOR_SCRIPT' | sudo tee /usr/local/bin/melodiespark-monitor.sh > /dev/null
sudo chmod +x /usr/local/bin/melodiespark-monitor.sh
EOF

echo -e "${GREEN}✅ Monitoring script installed${NC}"

# Setup backup
echo -e "\n${BLUE}💾 Setting up daily backups...${NC}"

BACKUP_SCRIPT='#!/bin/bash
# Daily backup script

BACKUP_DIR="/backups/melodiespark"
mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec -T postgres pg_dump -U melodiespark melodiespark | gzip > $BACKUP_DIR/db-$(date +%Y%m%d-%H%M%S).sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $(date)" >> /var/log/melodiespark-backup.log
'

ssh $VPS_USER@$VPS_IP bash << EOF
echo '$BACKUP_SCRIPT' | sudo tee /usr/local/bin/melodiespark-backup.sh > /dev/null
sudo chmod +x /usr/local/bin/melodiespark-backup.sh

# Add to crontab (runs daily at 2 AM)
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/melodiespark-backup.sh") | sudo crontab -
EOF

echo -e "${GREEN}✅ Daily backup configured${NC}"

# Print summary
echo -e "\n${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📍 Access your application:${NC}"
echo "   https://$DOMAIN"
echo ""
echo -e "${BLUE}📊 Services running on VPS:${NC}"
echo "   Frontend:  http://localhost:3000 (behind Nginx)"
echo "   API:       http://localhost:3001 (behind Nginx)"
echo "   Database:  localhost:5432"
echo "   Redis:     localhost:6379"
echo ""
echo -e "${BLUE}🔐 SSL Certificate:${NC}"
echo "   Domain: $DOMAIN"
echo "   Auto-renewal: Enabled"
echo ""
echo -e "${BLUE}💾 Backups:${NC}"
echo "   Daily at 2 AM UTC"
echo "   Location: /backups/melodiespark"
echo ""
echo -e "${BLUE}📊 Monitoring:${NC}"
echo "   Health checks: Every 5 minutes"
echo "   Log: /var/log/melodiespark-health.log"
echo ""
echo -e "${YELLOW}⚠️  Don't forget:${NC}"
echo "   1. Update DNS A record to $VPS_IP"
echo "   2. Configure email for monitoring alerts"
echo "   3. Review .env on VPS for security"
echo "   4. Setup log rotation: sudo nano /etc/logrotate.d/melodiespark"
echo ""
