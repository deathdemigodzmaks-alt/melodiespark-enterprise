import Fastify from 'fastify'
import fastifyJwt from '@fastify/jwt'
import fastifyHelmet from '@fastify/helmet'
import fastifyCors from '@fastify/cors'
import fastifyRateLimit from '@fastify/rate-limit'
import prisma from '@melodiespark/database'
import { logger } from './utils/logger'
import authRoutes from './routes/auth'
import projectRoutes from './routes/projects'
import inboxRoutes from './routes/inbox'
import knowledgeRoutes from './routes/knowledge'
import integrationRoutes from './routes/integrations'

const app = Fastify({
  logger: logger,
  ajv: {
    customOptions: {
      removeAdditional: 'all',
      coerceTypes: true,
      useDefaults: true,
    },
  },
})

// Security middleware
await app.register(fastifyHelmet)
await app.register(fastifyCors, {
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
})
await app.register(fastifyRateLimit, {
  max: 100,
  timeWindow: '15 minutes',
})

// Authentication
await app.register(fastifyJwt, {
  secret: process.env.JWT_SECRET || 'dev-secret-key',
  sign: {
    expiresIn: '7d',
  },
})

// Health check
app.get('/health', async (request, reply) => {
  return {
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  }
})

// Routes
app.register(authRoutes, { prefix: '/api/auth' })
app.register(projectRoutes, { prefix: '/api/projects' })
app.register(inboxRoutes, { prefix: '/api/inbox' })
app.register(knowledgeRoutes, { prefix: '/api/knowledge' })
app.register(integrationRoutes, { prefix: '/api/integrations' })

// Global error handler
app.setErrorHandler((error, request, reply) => {
  logger.error(error)
  reply.status(error.statusCode || 500).send({
    error: error.message,
    statusCode: error.statusCode || 500,
  })
})

// Graceful shutdown
const signals = ['SIGTERM', 'SIGINT']
signals.forEach((signal) => {
  process.on(signal, async () => {
    logger.info(`${signal} received, closing gracefully...`)
    await app.close()
    await prisma.$disconnect()
    process.exit(0)
  })
})

// Start server
const start = async () => {
  try {
    await app.listen({ port: 3001, host: '0.0.0.0' })
    logger.info('🚀 API server started on http://localhost:3001')
  } catch (err) {
    logger.error(err)
    process.exit(1)
  }
}

start()
