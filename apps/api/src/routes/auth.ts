import { FastifyInstance } from 'fastify'
import prisma from '@melodiespark/database'

export default async function authRoutes(app: FastifyInstance) {
  // Signup
  app.post(
    '/signup',
    async (request, reply) => {
      const { email, name, password } = request.body as Record<string, any>

      // Check if user exists
      const existing = await prisma.user.findUnique({
        where: { email },
      })

      if (existing) {
        return reply.code(400).send({ error: 'User already exists' })
      }

      // Create user
      const user = await prisma.user.create({
        data: {
          email,
          name,
        },
      })

      // Create organization
      const org = await prisma.organization.create({
        data: {
          name: `${name}'s Organization`,
          slug: `org-${user.id}`,
        },
      })

      // Add user to organization
      await prisma.organizationMember.create({
        data: {
          userId: user.id,
          organizationId: org.id,
          role: 'OWNER',
        },
      })

      // Generate token
      const token = app.jwt.sign(
        {
          id: user.id,
          email: user.email,
          organizationId: org.id,
        },
        {
          expiresIn: '7d',
        }
      )

      return reply.code(201).send({
        user,
        organization: org,
        token,
      })
    }
  )

  // Login
  app.post(
    '/login',
    async (request, reply) => {
      const { email, password } = request.body as Record<string, any>

      const user = await prisma.user.findUnique({
        where: { email },
        include: {
          organizationMembers: {
            include: {
              organization: true,
            },
          },
        },
      })

      if (!user) {
        return reply.code(401).send({ error: 'Invalid credentials' })
      }

      const org = user.organizationMembers[0]?.organization
      if (!org) {
        return reply.code(401).send({ error: 'No organization found' })
      }

      const token = app.jwt.sign(
        {
          id: user.id,
          email: user.email,
          organizationId: org.id,
        },
        {
          expiresIn: '7d',
        }
      )

      return reply.send({
        user,
        organization: org,
        token,
      })
    }
  )

  // Get current user
  app.get(
    '/me',
    { onRequest: [app.authenticate] },
    async (request, reply) => {
      return reply.send(request.user)
    }
  )
}
