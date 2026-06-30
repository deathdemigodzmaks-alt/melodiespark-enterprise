# Full dependency list and setup guide
# This file documents ALL dependencies, their purposes, and installation

## RUNTIME DEPENDENCIES

### Frontend Frameworks & UI
- next@^14.0.4          # React meta-framework for production
- react@^18.2.0         # React library
- react-dom@^18.2.0     # React DOM rendering
- tailwindcss@^3.4.1    # Utility-first CSS framework
- lucide-react@^0.309.0 # Icon library

### State Management & Data Fetching
- zustand@^4.4.7        # Lightweight state management
- axios@^1.6.5          # HTTP client for API calls
- @prisma/client@^5.8.0 # Database ORM

### Backend Frameworks
- fastify@^4.25.2       # Fast and low-overhead web framework
- express@^4.18.2       # Web application framework
- @fastify/cors@^8.5.0  # CORS support for Fastify
- @fastify/jwt@^7.2.4   # JWT authentication
- @fastify/helmet@^11.1.1 # Security headers
- @fastify/rate-limit@^9.1.0 # Rate limiting

### Database & Caching
- redis@^4.6.12         # Redis client
- ioredis@^5.3.2        # Redis client (alternative)
- prisma@^5.8.0         # ORM and database toolkit

### Authentication & Security
- jsonwebtoken@^9.1.2   # JWT token generation
- bcryptjs@^2.4.3       # Password hashing
- better-auth@latest    # Authentication library
- helmet@^7.1.0         # Security middleware
- cors@^2.8.5           # CORS middleware

### Logging & Monitoring
- pino@^8.17.2          # JSON logging library
- pino-pretty@^10.3.1   # Pretty print for Pino
- morgan@^1.10.0        # HTTP request logger

### AI & LLM Integration
- litellm@^1.0.0        # LLM API wrapper
- @anthropic-ai/sdk@^0.20.0 # Anthropic Claude API
- openai@^4.40.0        # OpenAI API
- googleapis@^118.0.0   # Google APIs

### Payment & Commerce
- stripe@^14.15.0       # Stripe payment processing

### Queue & Job Processing
- bull@^4.12.2          # Redis-backed task queue
- p-queue@^7.4.1        # Promise queue

### File Handling & Images
- sharp@^0.33.0         # Image processing
- multer@^1.4.5         # File upload middleware

### Cloud Services
- aws-sdk@^2.1555.0     # AWS SDK (legacy)
- @aws-sdk/client-s3@^3.535.0 # AWS S3 SDK (v3)

### Notifications & Integrations
- nodemailer@^6.9.7     # Email sending
- discord.js@^14.14.1   # Discord bot library
- slack-sdk@^6.9.0      # Slack API client
- telegram@^2.22.0      # Telegram Bot API

### Utilities
- date-fns@^2.30.0      # Date manipulation
- lodash@^4.17.21       # Utility functions
- uuid@^9.0.1           # UUID generation
- dotenv@^16.3.1        # Environment variables
- zod@^3.22.4           # Schema validation
- validator@^13.11.0    # String validation
- compression@^1.7.4    # HTTP compression
- joi@^17.12.0          # Schema validation

---

## DEVELOPMENT DEPENDENCIES

### Build Tools
- typescript@^5.3.3     # TypeScript compiler
- tsx@^4.7.0            # TypeScript executor
- ts-node@^10.9.2       # TypeScript REPL

### Code Quality
- eslint@^8.55.0        # Linting
- @typescript-eslint/eslint-plugin@^6.13.0
- @typescript-eslint/parser@^6.13.0
- prettier@^3.1.0       # Code formatter
- lint-staged@^15.2.0   # Pre-commit linting
- husky@^8.0.3          # Git hooks

### Testing
- vitest@^1.1.0         # Vite-native testing framework
- jest@^29.7.0          # JavaScript testing
- @testing-library/react@^14.1.2 # React testing utilities
- @testing-library/jest-dom@^6.1.5
- supertest@^6.3.3      # HTTP assertion library

### Type Definitions
- @types/node@^20.10.6
- @types/react@^18.2.45
- @types/react-dom@^18.2.18
- @types/jest@^29.5.11
- @types/supertest@^6.0.2

### Development Tools
- turbo@^1.10.16        # Monorepo task runner
- nodemon@^3.0.2        # Auto-reload
- concurrently@^8.2.2   # Run multiple commands
- cross-env@^7.0.3      # Cross-platform env vars
- dotenv-cli@^7.3.0     # CLI for .env files

### Docker
- docker-compose@^0.24.8 # Docker Compose CLI

---

## INSTALLATION COMMANDS

```bash
# Install all dependencies
pnpm install

# Install specific workspace
cd apps/api && pnpm install
cd apps/web && pnpm install
cd packages/database && pnpm install

# Update dependencies
pnpm update --interactive

# Audit for vulnerabilities
pnpm audit
pnpm audit --fix

# Clean install
pnpm clean
pnpm install
```

---

## ENVIRONMENT SETUP

### Required Environment Variables

```env
# API
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://user:pass@localhost:5432/db
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# AI/LLM
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_S3_BUCKET=...

# Stripe
STRIPE_SECRET_KEY=sk_...
STRIPE_PUBLISHABLE_KEY=pk_...

# Notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...

DISCORD_BOT_TOKEN=...
SLACK_BOT_TOKEN=...
TELEGRAM_BOT_TOKEN=...

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_ANALYTICS_ID=...
```

---

## DEVELOPMENT SETUP

```bash
# 1. Install dependencies
pnpm install

# 2. Setup environment
cp .env.example .env
# Edit .env with your values

# 3. Setup database
pnpm db:push
pnpm db:migrate

# 4. Start development servers
pnpm dev

# 5. Run tests
pnpm test

# 6. Check code quality
pnpm lint
pnpm type-check
pnpm format:check
```

---

## DEPLOYMENT

```bash
# Build all packages
pnpm build

# Docker build
docker-compose build

# Deploy to cloud
pnpm deploy:cloud

# Deploy to VPS
pnpm deploy:vps

# Deploy to Kubernetes
pnpm deploy:k8s

# Deploy to AWS
pnpm deploy:aws
```

---

## VERSION NOTES

- Node.js: 20.x LTS (recommended)
- npm: 10.x or higher
- pnpm: 8.x (package manager)
- TypeScript: 5.3 (latest)
- React: 18.2 (latest stable)
- Next.js: 14.0 (latest)
