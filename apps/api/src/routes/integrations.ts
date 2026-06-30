import { FastifyInstance } from 'fastify'
import prisma from '@melodiespark/database'

export default async function integrationRoutes(app: FastifyInstance) {
  // Get integrations
  app.get(
    '/',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const integrations = await prisma.integration.findMany({
        where: {
          organizationId: request.user.organizationId,
        },
      })

      return reply.send(integrations)
    }
  )

  // Create ClickUp integration
  app.post(
    '/clickup',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { apiKey } = request.body as Record<string, any>

      const integration = await prisma.integration.create({
        data: {
          organizationId: request.user.organizationId,
          type: 'CLICKUP',
          credentials: JSON.stringify({ apiKey }),
        },
      })

      return reply.code(201).send(integration)
    }
  )

  // Sync with ClickUp
  app.post(
    '/clickup/sync',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      // This would call ClickUp API to sync projects and tasks
      // For now, just return success
      return reply.send({ status: 'sync_started' })
    }
  )
}
