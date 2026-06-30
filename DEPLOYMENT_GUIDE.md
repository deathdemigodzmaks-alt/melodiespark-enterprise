# Production Deployment Guide

## Local Development (Docker Compose)

```bash
cd MelodieSpark

# Set environment variables
cp .env.example .env
# Edit .env with your API keys:
# - ANTHROPIC_API_KEY
# - OPENAI_API_KEY

# Start full stack (all services)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop stack
docker-compose down
```

**Services:**
- Frontend: http://localhost:3000 (Next.js)
- API: http://localhost:3001 (Fastify)
- Database: localhost:5432 (PostgreSQL)
- Cache: localhost:6379 (Redis)
- Vector Search: http://localhost:6333 (Qdrant)

---

## Frontend Deployment: Vercel

### Method 1: Direct Deploy (Recommended)

1. Push code to GitHub:
```bash
git add .
git commit -m "Add Dockerfiles and deployment configs"
git push origin main
```

2. Go to https://vercel.com/new
3. Import your GitHub repository
4. Vercel auto-detects Next.js in `MelodieSpark/apps/web`
5. Set environment variable:
   - `NEXT_PUBLIC_API_URL` = your API endpoint (e.g., `https://api.railway.app`)
6. Click Deploy

**Cost:** Free tier (5 deployments/day), or $20/mo Pro

---

## Backend API Deployment: Railway

### Method 1: Connect from GitHub

1. Go to https://railway.app
2. New Project → GitHub repo
3. Railway auto-detects `apps/api` service
4. Set environment variables:
   - `DATABASE_URL` = Railway PostgreSQL connection string
   - `REDIS_URL` = Railway Redis connection string
   - `JWT_SECRET` = secure random string
   - `ANTHROPIC_API_KEY` = your key
   - `OPENAI_API_KEY` = your key

5. Deploy

**Cost:** $5/mo starter, $20/mo hobby

### Method 2: Manual Docker Push

```bash
# Build locally
docker build -t melodiespark-api -f MelodieSpark/apps/api/Dockerfile .

# Tag for Railway registry
docker tag melodiespark-api registry.railway.app/melodiespark/api:latest

# Push
docker push registry.railway.app/melodiespark/api:latest
```

---

## Database: Railway PostgreSQL

1. In Railway dashboard, add PostgreSQL plugin
2. Railway generates `DATABASE_URL` automatically
3. Use in your api environment variable

---

## Full Stack on Single VPS (Production)

### Prerequisites
- VPS with Docker & Docker Compose (DigitalOcean, Linode, AWS EC2)
- Domain name
- SSL certificate (use Let's Encrypt via Certbot)

### Deploy

```bash
# SSH into VPS
ssh root@your-vps-ip

# Clone repo
git clone <your-repo> melodiespark
cd melodiespark

# Create .env with production values
cat > .env << EOF
NODE_ENV=production
DATABASE_URL=postgresql://user:password@localhost:5432/melodiespark
REDIS_URL=redis://localhost:6379
JWT_SECRET=$(openssl rand -base64 32)
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
EOF

# Build and start
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify
docker-compose ps

# View logs
docker-compose logs -f api
docker-compose logs -f web
```

### Setup Reverse Proxy (Nginx + SSL)

```bash
# Install Nginx
sudo apt update && sudo apt install nginx certbot python3-certbot-nginx -y

# Create Nginx config
sudo tee /etc/nginx/sites-available/melodiespark > /dev/null << EOF
server {
    server_name melodiespark.com www.melodiespark.com;
    listen 80;

    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/melodiespark /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL
sudo certbot --nginx -d melodiespark.com -d www.melodiespark.com

# Auto-renew
sudo systemctl enable certbot.timer
```

---

## Monitoring & Logs

### Docker Compose
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f web

# Last 100 lines
docker-compose logs --tail=100 api
```

### Production (systemd)
```bash
# If running as service
journalctl -u docker.service -f

# Docker logs
docker logs -f melodiespark-api
docker logs -f melodiespark-web
```

---

## Scaling

### Horizontal Scaling (Multiple Instances)

```yaml
# docker-compose.prod.yml
version: '3.9'
services:
  api:
    # ... existing config
    deploy:
      replicas: 3
      
  web:
    deploy:
      replicas: 2
```

Deploy:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### With Load Balancer (Nginx/HAProxy)
- Use Nginx upstream to round-robin across api instances
- Use sticky sessions if needed

---

## Environment Variables

Create `.env.example`:
```
NODE_ENV=production
DATABASE_URL=postgresql://user:password@host:5432/db
REDIS_URL=redis://host:6379
JWT_SECRET=your-secret-key
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
QDRANT_URL=http://qdrant:6333
```

Users copy to `.env` and fill in values.

---

## Debugging

```bash
# Check service health
docker-compose ps

# Inspect api container
docker inspect melodiespark-api

# Test api endpoint
curl http://localhost:3001/health

# Test web page
curl http://localhost:3000

# Access database
psql postgresql://melodiespark:dev-password@localhost:5432/melodiespark

# Redis CLI
redis-cli -h localhost
```

---

## CI/CD: GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker images
        run: |
          docker build -f MelodieSpark/apps/api/Dockerfile -t api:latest .
          docker build -f MelodieSpark/apps/web/Dockerfile -t web:latest .
      
      - name: Push to Registry
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker push api:latest
          docker push web:latest
      
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd melodiespark
            docker-compose pull
            docker-compose up -d
```

---

## Summary

| Environment | Frontend | Backend | Database | Cost |
|---|---|---|---|---|
| Local Dev | `localhost:3000` | `localhost:3001` | Docker | Free |
| Vercel + Railway | Vercel | Railway | Railway | $25-40/mo |
| Single VPS | nginx proxy | Docker | PostgreSQL | $5-20/mo |
| Kubernetes | K8s ingress | K8s pods | Managed DB | $50+ /mo |

Start with Vercel + Railway for simplicity. Move to VPS or Kubernetes as you scale.
