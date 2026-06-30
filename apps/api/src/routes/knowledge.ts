import { FastifyInstance } from 'fastify'
import prisma from '@melodiespark/database'

export default async function knowledgeRoutes(app: FastifyInstance) {
  // Create knowledge entry
  app.post(
    '/',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { title, content, category, tags } = request.body as Record<string, any>

      const entry = await prisma.knowledgeEntry.create({
        data: {
          title,
          content,
          category,
          tags: tags || [],
          organizationId: request.user.organizationId,
        },
      })

      return reply.code(201).send(entry)
    }
  )

  // Search knowledge
  app.get(
    '/search',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { q } = request.query as { q: string }

      if (!q) {
        return reply.code(400).send({ error: 'Search query required' })
      }

      const results = await prisma.knowledgeEntry.findMany({
        where: {
          organizationId: request.user.organizationId,
          OR: [
            { title: { contains: q, mode: 'insensitive' } },
            { content: { contains: q, mode: 'insensitive' } },
          ],
        },
      })

      return reply.send(results)
    }
  )

  // Get all knowledge
  app.get(
    '/',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const entries = await prisma.knowledgeEntry.findMany({
        where: {
          organizationId: request.user.organizationId,
        },
        orderBy: {
          createdAt: 'desc',
        },
      })

      return reply.send(entries)
    }
  )
}
