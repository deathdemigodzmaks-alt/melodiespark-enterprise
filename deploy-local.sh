#!/bin/bash
# Local Docker Deployment (Development)

set -e

echo "🐳 Local Docker Deployment"
echo "=========================="

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Docker
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not installed${NC}"
    echo "Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose not installed${NC}"
    echo "Install from: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker installed:${NC}"
docker --version
docker-compose --version || docker compose --version

# Setup environment
cd MelodieSpark

echo -e "\n${BLUE}📝 Setting up environment...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Edit .env with your API keys${NC}"
    echo "   ANTHROPIC_API_KEY=sk-..."
    echo "   OPENAI_API_KEY=sk-..."
else
    echo -e "${GREEN}✅ .env already exists${NC}"
fi

# Validate compose
echo -e "\n${BLUE}🔍 Validating docker-compose.yml...${NC}"
docker-compose config --quiet
echo -e "${GREEN}✅ Compose file valid${NC}"

# Build images
echo -e "\n${BLUE}🔨 Building Docker images...${NC}"
echo "This may take 5-10 minutes..."

docker-compose build

echo -e "${GREEN}✅ Build complete${NC}"

# Start services
echo -e "\n${BLUE}🚀 Starting services...${NC}"

docker-compose up -d

# Wait for services to be ready
echo -e "\n${BLUE}⏳ Waiting for services to become healthy...${NC}"

for i in {1..30}; do
    if docker-compose ps | grep -q "healthy"; then
        echo -e "${GREEN}✅ Services ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Verify services
echo -e "\n${BLUE}📊 Service status:${NC}"
docker-compose ps

# Test connectivity
echo -e "\n${BLUE}🧪 Testing connectivity...${NC}"

# Give services a moment
sleep 3

echo "Testing API health endpoint..."
if curl -s http://localhost:3001/health > /dev/null; then
    echo -e "${GREEN}✅ API responding${NC}"
else
    echo -e "${YELLOW}⚠️  API not responding yet (normal on first start)${NC}"
fi

echo "Testing frontend..."
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✅ Frontend responding${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend not responding yet${NC}"
fi

# Print summary
echo -e "\n${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}✅ LOCAL DEPLOYMENT COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📍 Access services:${NC}"
echo "   Frontend:      http://localhost:3000"
echo "   API:           http://localhost:3001"
echo "   API Health:    http://localhost:3001/health"
echo "   Database:      localhost:5432"
echo "   Redis:         localhost:6379"
echo "   Vector Search: http://localhost:6333"
echo ""
echo -e "${BLUE}🛠️  Common commands:${NC}"
echo "   View logs:     docker-compose logs -f"
echo "   View API logs: docker-compose logs -f api"
echo "   Rebuild:       docker-compose build --no-cache"
echo "   Stop:          docker-compose down"
echo "   Reset:         docker-compose down -v && docker-compose up -d"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "   Quick ref:     cat QUICK_REFERENCE.txt"
echo "   Full docs:     cat DEPLOYMENT_GUIDE.md"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "   - Code changes auto-reload (hot reload enabled)"
echo "   - Database persists in volumes"
echo "   - Logs available: docker-compose logs"
echo "   - Access PostgreSQL: docker-compose exec postgres psql -U melodiespark -d melodiespark"
echo ""
