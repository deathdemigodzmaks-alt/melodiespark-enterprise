import { FastifyInstance } from 'fastify'
import prisma from '@melodiespark/database'
import { z } from 'zod'
import { hyperDirector } from '../ai/hyperdirector'

const CreateInboxItemSchema = z.object({
  title: z.string().min(1),
  content: z.string(),
  source: z.enum(['MANUAL', 'EMAIL', 'SLACK', 'API']).default('MANUAL'),
})

export default async function inboxRoutes(app: FastifyInstance) {
  // Create inbox item
  app.post<{ Body: z.infer<typeof CreateInboxItemSchema> }>(
    '/',
    {
      onRequest: [app.authenticate],
      schema: {
        body: CreateInboxItemSchema,
      },
    },
    async (request, reply) => {
      const userId = request.user.id
      const organizationId = request.user.organizationId
      const { title, content, source } = request.body

      // Create inbox item
      const inboxItem = await prisma.inboxItem.create({
        data: {
          title,
          content,
          userId,
          organizationId,
          source,
          status: 'PROCESSING',
        },
      })

      // Trigger AI processing asynchronously
      processInboxItemAsync(inboxItem.id, organizationId).catch(console.error)

      return reply.code(201).send(inboxItem)
    }
  )

  // Get inbox items
  app.get(
    '/',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const items = await prisma.inboxItem.findMany({
        where: {
          organizationId: request.user.organizationId,
        },
        include: {
          aiAnalysis: true,
          project: true,
          task: true,
        },
        orderBy: {
          createdAt: 'desc',
        },
      })

      return reply.send(items)
    }
  )

  // Process inbox item with HyperDirector
  app.post(
    '/:id/process',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { id } = request.params as { id: string }

      const item = await prisma.inboxItem.findUnique({
        where: { id },
      })

      if (!item) {
        return reply.code(404).send({ error: 'Inbox item not found' })
      }

      // Process with HyperDirector
      const analysis = await hyperDirector.analyzeInboxItem(item)

      return reply.send(analysis)
    }
  )

  // Archive inbox item
  app.patch(
    '/:id/archive',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { id } = request.params as { id: string }

      const item = await prisma.inboxItem.update({
        where: { id },
        data: { status: 'ARCHIVED' },
      })

      return reply.send(item)
    }
  )
}

async function processInboxItemAsync(
  inboxItemId: string,
  organizationId: string
) {
  try {
    const item = await prisma.inboxItem.findUnique({
      where: { id: inboxItemId },
    })

    if (!item) return

    const analysis = await hyperDirector.analyzeInboxItem(item)

    // Update inbox item with results
    await prisma.inboxItem.update({
      where: { id: inboxItemId },
      data: {
        classification: analysis.classification,
        intent: analysis.intent,
        confidence: analysis.confidence,
        status: 'PROCESSED',
        processedAt: new Date(),
      },
    })

    // Create AI analysis record
    if (analysis.aiAnalysis) {
      await prisma.aiAnalysis.create({
        data: {
          inboxItemId,
          suggestedProject: analysis.aiAnalysis.suggestedProject,
          suggestedTasks: analysis.aiAnalysis.suggestedTasks,
          keyInsights: analysis.aiAnalysis.keyInsights,
          recommendations: analysis.aiAnalysis.recommendations,
          modelUsed: analysis.aiAnalysis.modelUsed,
          tokens: analysis.aiAnalysis.tokens || 0,
        },
      })

      // Auto-create project if suggested
      if (analysis.aiAnalysis.suggestedProject) {
        const userId = item.userId
        const project = await prisma.project.create({
          data: {
            name: analysis.aiAnalysis.suggestedProject,
            description: item.content,
            userId,
            organizationId,
          },
        })

        // Create tasks
        for (const taskTitle of analysis.aiAnalysis.suggestedTasks) {
          await prisma.task.create({
            data: {
              title: taskTitle,
              projectId: project.id,
              description: `Generated from inbox item: ${item.title}`,
            },
          })
        }

        // Update inbox item with project
        await prisma.inboxItem.update({
          where: { id: inboxItemId },
          data: { projectId: project.id },
        })
      }
    }
  } catch (error) {
    console.error('Error processing inbox item:', error)

    // Mark as failed
    await prisma.inboxItem.update({
      where: { id: inboxItemId },
      data: { status: 'PROCESSED' },
    })
  }
}
