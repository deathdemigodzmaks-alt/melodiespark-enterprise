import { FastifyInstance } from 'fastify'
import prisma from '@melodiespark/database'
import { z } from 'zod'

const CreateProjectSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
})

export default async function projectRoutes(app: FastifyInstance) {
  // Create project
  app.post<{ Body: z.infer<typeof CreateProjectSchema> }>(
    '/',
    {
      onRequest: [app.authenticate],
      schema: {
        body: CreateProjectSchema,
      },
    },
    async (request, reply) => {
      const userId = request.user.id
      const { name, description } = request.body

      const project = await prisma.project.create({
        data: {
          name,
          description,
          userId,
          organizationId: request.user.organizationId,
        },
      })

      return reply.code(201).send(project)
    }
  )

  // List projects
  app.get(
    '/',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const projects = await prisma.project.findMany({
        where: {
          organizationId: request.user.organizationId,
        },
        include: {
          tasks: true,
          milestones: true,
        },
      })

      return reply.send(projects)
    }
  )

  // Get project
  app.get(
    '/:id',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { id } = request.params as { id: string }

      const project = await prisma.project.findUnique({
        where: { id },
        include: {
          tasks: true,
          milestones: true,
        },
      })

      if (!project) {
        return reply.code(404).send({ error: 'Project not found' })
      }

      return reply.send(project)
    }
  )

  // Update project
  app.patch(
    '/:id',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { id } = request.params as { id: string }
      const updates = request.body as Record<string, any>

      const project = await prisma.project.update({
        where: { id },
        data: updates,
      })

      return reply.send(project)
    }
  )

  // Delete project
  app.delete(
    '/:id',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      const { id } = request.params as { id: string }

      await prisma.project.delete({
        where: { id },
      })

      return reply.code(204).send()
    }
  )
}
