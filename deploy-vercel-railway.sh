#!/bin/bash
# Vercel + Railway Deployment Script

set -e

echo "🚀 Deploying to Vercel + Railway"
echo "================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command -v git &> /dev/null; then
    echo "❌ Git not installed"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Node.js/npm not installed"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"

# Get credentials
echo -e "\n${BLUE}🔑 Configuration${NC}"
read -p "Enter GitHub repo URL (https://github.com/username/repo): " GITHUB_REPO
read -p "Enter Vercel token (from https://vercel.com/account/tokens): " VERCEL_TOKEN
read -p "Enter Railway token (from https://railway.app/account/tokens): " RAILWAY_TOKEN

# Save tokens safely (add to .env, not in git)
cat >> .env.deployment << EOF
GITHUB_REPO=$GITHUB_REPO
VERCEL_TOKEN=$VERCEL_TOKEN
RAILWAY_TOKEN=$RAILWAY_TOKEN
EOF

echo -e "${GREEN}✅ Tokens saved to .env.deployment${NC}"

# Push to GitHub
echo -e "\n${BLUE}📤 Pushing to GitHub...${NC}"
git add .
git commit -m "chore: add production deployment configs" || true
git push origin main

echo -e "${GREEN}✅ Pushed to GitHub${NC}"

# Deploy Frontend to Vercel
echo -e "\n${BLUE}🚀 Deploying frontend to Vercel...${NC}"
npm install -g vercel

echo -e "${YELLOW}📍 Steps to complete manually:${NC}"
echo "1. Go to: https://vercel.com/new"
echo "2. Import GitHub repo: $GITHUB_REPO"
echo "3. Root directory: MelodieSpark"
echo "4. Framework: Next.js"
echo "5. Add environment variable:"
echo "   NEXT_PUBLIC_API_URL=https://melodiespark-api.railway.app"
echo "6. Click Deploy"
echo ""
echo "After deployment, update your DNS records to point to Vercel."

# Deploy API to Railway
echo -e "\n${BLUE}🚀 Deploying API to Railway...${NC}"

echo -e "${YELLOW}📍 Steps to complete manually:${NC}"
echo "1. Go to: https://railway.app/new"
echo "2. Create new project"
echo "3. Connect GitHub repo: $GITHUB_REPO"
echo "4. Select branch: main"
echo "5. Railway will auto-detect apps/api"
echo "6. Add plugins:"
echo "   - PostgreSQL 16"
echo "   - Redis 7"
echo "7. Set environment variables:"
echo "   - NODE_ENV=production"
echo "   - JWT_SECRET=\$(openssl rand -base64 32)"
echo "   - ANTHROPIC_API_KEY=sk-..."
echo "   - OPENAI_API_KEY=sk-..."
echo ""
echo "After deployment, get the API URL and update NEXT_PUBLIC_API_URL in Vercel."

echo -e "\n${GREEN}✅ Deployment instructions provided${NC}"
echo -e "${BLUE}⏭️  Next steps:${NC}"
echo "1. Complete Vercel deployment (link above)"
echo "2. Complete Railway deployment (link above)"
echo "3. Update environment variables between services"
echo "4. Verify endpoints:"
echo "   - Frontend: https://melodiespark.vercel.app"
echo "   - API: https://melodiespark-api.railway.app/health"
