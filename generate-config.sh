#!/bin/bash
# Complete Configuration Generator
# Creates ALL configuration files, folders, and documents

set -e

SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Generating Complete Configuration System..."

# Create folder structure
mkdir -p "$SYSTEM_DIR/.saas-deployment"/{scripts,configs,state,logs,backups,monitoring}
mkdir -p "$SYSTEM_DIR/packages"/{database,auth,utils,api-client}
mkdir -p "$SYSTEM_DIR/services"/{notifications,analytics,ai}
mkdir -p "$SYSTEM_DIR/k8s"/{base,overlays/{dev,staging,prod},monitoring,ingress}
mkdir -p "$SYSTEM_DIR/terraform"/{modules/{vpc,rds,alb,ecs},environments/{dev,staging,prod},outputs}
mkdir -p "$SYSTEM_DIR/.github"/{workflows,actions}
mkdir -p "$SYSTEM_DIR/docs"/{architecture,api,deployment,operations}
mkdir -p "$SYSTEM_DIR/scripts"/{dev,deploy,backup,monitoring}

echo "✅ Folder structure created"

# 1. Prisma Schema
cat > "$SYSTEM_DIR/packages/database/prisma/schema.prisma" << 'EOF'
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
  output   = "./generated/client"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  password  String?
  avatar    String?
  role      String   @default("user")
  status    String   @default("active")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  projects    Project[]
  sessions    Session[]
  apiKeys     ApiKey[]
  auditLogs   AuditLog[]
  notifications Notification[]
}

model Project {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique
  description String?
  icon      String?
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  bots      Bot[]
  logs      Log[]
}

model Bot {
  id        String   @id @default(cuid())
  name      String
  description String?
  status    String   @default("inactive")
  config    Json?
  projectId String
  project   Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  executions BotExecution[]
  logs       Log[]
}

model BotExecution {
  id        String   @id @default(cuid())
  botId     String
  bot       Bot      @relation(fields: [botId], references: [id], onDelete: Cascade)
  status    String
  input     Json?
  output    Json?
  error     String?
  duration  Int?
  
  createdAt DateTime @default(now())
}

model Session {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  token     String   @unique
  expiresAt DateTime
  
  createdAt DateTime @default(now())
}

model ApiKey {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  key       String   @unique
  name      String
  lastUsed  DateTime?
  
  createdAt DateTime @default(now())
}

model AuditLog {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  action    String
  resource  String
  changes   Json?
  
  createdAt DateTime @default(now())
}

model Notification {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  type      String
  title     String
  message   String
  read      Boolean  @default(false)
  
  createdAt DateTime @default(now())
}

model Log {
  id        String   @id @default(cuid())
  projectId String
  project   Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
  botId     String?
  bot       Bot?     @relation(fields: [botId], references: [id], onDelete: SetNull)
  level     String   // info, warn, error
  message   String
  meta      Json?
  
  createdAt DateTime @default(now())
  @@index([projectId])
  @@index([botId])
  @@index([createdAt])
}
EOF

echo "✅ Prisma schema created"

# 2. TypeScript Config
cat > "$SYSTEM_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./apps/web/app/*"],
      "@/api/*": ["./apps/api/src/*"],
      "@/db/*": ["./packages/database/*"],
      "@/auth/*": ["./packages/auth/*"],
      "@/utils/*": ["./packages/utils/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules", ".next", "dist"]
}
EOF

echo "✅ TypeScript config created"

# 3. ESLint Config
cat > "$SYSTEM_DIR/.eslintrc.json" << 'EOF'
{
  "extends": ["next", "prettier"],
  "rules": {
    "@next/next/no-html-link-for-pages": "off",
    "react/no-unescaped-entities": "off",
    "@next/next/no-img-element": "off"
  }
}
EOF

echo "✅ ESLint config created"

# 4. Prettier Config
cat > "$SYSTEM_DIR/.prettierrc.json" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
EOF

echo "✅ Prettier config created"

# 5. GitHub Actions Workflow
cat > "$SYSTEM_DIR/.github/workflows/test.yml" << 'EOF'
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm type-check
      - run: pnpm test
      - run: pnpm build
EOF

echo "✅ GitHub Actions workflow created"

# 6. Environment Template
cat > "$SYSTEM_DIR/.env.example" << 'EOF'
# Environment Configuration Template
# Copy to .env and fill with actual values

# Node & Environment
NODE_ENV=development
PORT=3001
HOST=localhost

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/melodiespark

# Redis/Cache
REDIS_URL=redis://localhost:6379
QDRANT_URL=http://localhost:6333

# Authentication
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# AI/LLM Services
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=

# Notifications
DISCORD_BOT_TOKEN=
SLACK_BOT_TOKEN=
TELEGRAM_BOT_TOKEN=

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_APP_NAME=MelodieSpark
NEXT_PUBLIC_ANALYTICS_ID=

# Monitoring
SENTRY_DSN=
DATADOG_API_KEY=

# Logging
LOG_LEVEL=debug
EOF

echo "✅ Environment template created"

# 7. Docker Compose with all services
cat > "$SYSTEM_DIR/docker-compose.full.yml" << 'EOF'
version: '3.9'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: melodiespark-postgres
    environment:
      POSTGRES_USER: melodiespark
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: melodiespark
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U melodiespark"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - melodiespark

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: melodiespark-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - melodiespark

  # Qdrant Vector Search
  qdrant:
    image: qdrant/qdrant:latest
    container_name: melodiespark-qdrant
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    networks:
      - melodiespark

  # Prometheus Monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: melodiespark-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - melodiespark

  # Grafana Dashboards
  grafana:
    image: grafana/grafana:latest
    container_name: melodiespark-grafana
    ports:
      - "3030:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - melodiespark

  # ELK Stack - Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    container_name: melodiespark-elasticsearch
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - melodiespark

  # ELK Stack - Kibana
  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    container_name: melodiespark-kibana
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - melodiespark

volumes:
  postgres_data:
  redis_data:
  qdrant_data:
  prometheus_data:
  grafana_data:
  elasticsearch_data:

networks:
  melodiespark:
    driver: bridge
EOF

echo "✅ Full Docker Compose created"

# 8. Makefile
cat > "$SYSTEM_DIR/Makefile" << 'EOF'
.PHONY: help install dev build test lint format clean deploy

help:
	@echo "Available commands:"
	@echo "  make install   - Install dependencies"
	@echo "  make dev       - Start development servers"
	@echo "  make build     - Build for production"
	@echo "  make test      - Run tests"
	@echo "  make lint      - Run linter"
	@echo "  make format    - Format code"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make deploy    - Deploy to production"

install:
	pnpm install

dev:
	pnpm dev

build:
	pnpm build

test:
	pnpm test

lint:
	pnpm lint

format:
	pnpm format

clean:
	pnpm clean
	rm -rf node_modules

deploy:
	bash .saas-deployment/scripts/deploy-cloud.sh
EOF

echo "✅ Makefile created"

# 9. Documentation Index
cat > "$SYSTEM_DIR/docs/INDEX.md" << 'EOF'
# MelodieSpark Documentation

## Getting Started
- [Installation](./setup/installation.md)
- [Configuration](./setup/configuration.md)
- [Development](./development/quickstart.md)

## Architecture
- [System Architecture](./architecture/overview.md)
- [Database Schema](./architecture/database.md)
- [API Design](./architecture/api.md)

## Deployment
- [Cloud Deployment](./deployment/cloud.md)
- [VPS Deployment](./deployment/vps.md)
- [Kubernetes](./deployment/kubernetes.md)
- [AWS](./deployment/aws.md)

## Operations
- [Monitoring](./operations/monitoring.md)
- [Logging](./operations/logging.md)
- [Backup & Recovery](./operations/backup.md)
- [Troubleshooting](./operations/troubleshooting.md)

## API Reference
- [REST API](./api/rest.md)
- [WebSocket API](./api/websocket.md)
- [Authentication](./api/auth.md)

## Contributing
- [Code Style](./contributing/style.md)
- [Testing](./contributing/testing.md)
- [Pull Requests](./contributing/pull-requests.md)
EOF

echo "✅ Documentation index created"

# 10. README
cat > "$SYSTEM_DIR/README.md" << 'EOF'
# 🚀 MelodieSpark Enterprise SaaS Platform

## Quick Start

```bash
# Install dependencies
pnpm install

# Setup environment
cp .env.example .env

# Start development
pnpm dev

# Run tests
pnpm test

# Deploy
pnpm deploy:cloud
```

## Documentation

- [Dependencies](./DEPENDENCIES.md)
- [Docs](./docs/INDEX.md)
- [Architecture](./docs/architecture/overview.md)

## Support

For issues and questions, please check the documentation or open an issue on GitHub.
EOF

echo "✅ README created"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ COMPLETE CONFIGURATION SYSTEM GENERATED!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Generated:"
echo "  ✅ Folder structure (.saas-deployment, packages, k8s, terraform)"
echo "  ✅ Prisma database schema"
echo "  ✅ TypeScript configuration"
echo "  ✅ ESLint & Prettier configs"
echo "  ✅ GitHub Actions workflows"
echo "  ✅ Environment template"
echo "  ✅ Full Docker Compose"
echo "  ✅ Makefile"
echo "  ✅ Documentation structure"
echo "  ✅ README"
echo ""
echo "Next steps:"
echo "  1. pnpm install"
echo "  2. cp .env.example .env"
echo "  3. pnpm dev"
echo ""
EOF

chmod +x "$SYSTEM_DIR/generate-config.sh"

# Execute if this script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Create all configurations
    mkdir -p "$SYSTEM_DIR/.saas-deployment"/{scripts,configs,state,logs,backups,monitoring}
    mkdir -p "$SYSTEM_DIR/packages"/{database,auth,utils,api-client}
    mkdir -p "$SYSTEM_DIR/services"/{notifications,analytics,ai}
    mkdir -p "$SYSTEM_DIR/k8s"/{base,overlays,monitoring,ingress}
    mkdir -p "$SYSTEM_DIR/terraform"/{modules,environments,outputs}
    mkdir -p "$SYSTEM_DIR/.github"/{workflows,actions}
    mkdir -p "$SYSTEM_DIR/docs"/{architecture,api,deployment,operations}
    mkdir -p "$SYSTEM_DIR/scripts"/{dev,deploy,backup,monitoring}
    
    echo "✅ All configurations generated successfully!"
fi
