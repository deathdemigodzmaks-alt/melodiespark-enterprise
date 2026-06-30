# 🏛️ MelodieSpark Architecture Reference — Phase 2+ Planning

## Phase 1 → Phase 2 Progression

### What's Built (Phase 1)

```
FOUNDATION LAYER
├── Identity & Auth ✅
├── Project/Task System ✅
├── Knowledge Base ✅
├── HyperDirector AI ✅
├── Integration Framework ✅
└── Dashboard MVP ✅
```

### What's Next (Phase 2)

```
BUSINESS LAYER
├── CRM Module
├── Billing System
├── Customer Portal
├── Workflow Builder
└── Marketplace Foundation
```

---

## 📊 CRM Module (Phase 2)

### Data Model Extension

```prisma
model Contact {
  id String @id @default(cuid())
  organizationId String
  firstName String
  lastName String
  email String
  phone String?
  company String?
  status ContactStatus
  
  interactions Interaction[]
  opportunities Opportunity[]
  createdAt DateTime @default(now())
}

model Opportunity {
  id String @id @default(cuid())
  contactId String
  title String
  value Decimal
  stage PipelineStage
  probability Int
  closeDate DateTime?
  
  activities Activity[]
  createdAt DateTime @default(now())
}

model Interaction {
  id String @id @default(cuid())
  contactId String
  type InteractionType // EMAIL, CALL, MEETING, etc.
  summary String
  outcome InteractionOutcome?
  
  createdAt DateTime @default(now())
}

enum ContactStatus { LEAD, PROSPECT, CUSTOMER, INACTIVE }
enum PipelineStage { DISCOVERY, PROPOSAL, NEGOTIATION, WON, LOST }
enum InteractionType { EMAIL, CALL, MEETING, DEMO, PROPOSAL }
enum InteractionOutcome { POSITIVE, NEUTRAL, NEGATIVE }
```

### CRM API Endpoints

```
GET    /api/crm/contacts
POST   /api/crm/contacts
GET    /api/crm/contacts/:id
PATCH  /api/crm/contacts/:id
DELETE /api/crm/contacts/:id

GET    /api/crm/opportunities
POST   /api/crm/opportunities
PATCH  /api/crm/opportunities/:id

GET    /api/crm/pipeline
GET    /api/crm/analytics
```

### HyperDirector CRM Integration

```typescript
// When inbox item is a customer inquiry:
hyperDirector.processCRMInbox(item) → {
  extractContact(),
  createOrUpdateContact(),
  generateOpportunity(),
  scheduleFollowUp(),
  suggestTemplate()
}
```

---

## 💳 Billing Module (Phase 2)

### Data Model Extension

```prisma
model Plan {
  id String @id @default(cuid())
  name String          // Starter, Pro, Enterprise
  price Decimal
  interval BillingInterval  // MONTHLY, YEARLY
  features String[]    // JSON features
  
  subscriptions Subscription[]
}

model Subscription {
  id String @id @default(cuid())
  organizationId String
  planId String
  
  status SubscriptionStatus
  currentPeriodStart DateTime
  currentPeriodEnd DateTime
  stripeSubscriptionId String?
  
  invoices Invoice[]
  createdAt DateTime @default(now())
}

model Invoice {
  id String @id @default(cuid())
  subscriptionId String
  organizationId String
  
  amount Decimal
  status InvoiceStatus
  paidAt DateTime?
  dueDate DateTime
  
  stripeInvoiceId String?
  createdAt DateTime @default(now())
}

model Usage {
  id String @id @default(cuid())
  organizationId String
  
  projectsCreated Int
  tasksGenerated Int
  aiCallsUsed Int
  storageUsedGB Decimal
  
  month DateTime
  createdAt DateTime @default(now())
}

enum SubscriptionStatus { ACTIVE, TRIALING, PAST_DUE, CANCELED }
enum InvoiceStatus { DRAFT, OPEN, PAID, UNCOLLECTIBLE, VOIDED }
enum BillingInterval { MONTHLY, YEARLY }
```

### Billing API Endpoints

```
GET    /api/billing/plans
POST   /api/billing/subscribe
GET    /api/billing/subscription
PATCH  /api/billing/subscription
POST   /api/billing/cancel
GET    /api/billing/invoices
GET    /api/billing/usage
```

### Stripe Integration

```typescript
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY)

// Subscribe to plan
async createSubscription(organizationId, planId) {
  const customer = await stripe.customers.create({
    email: org.email,
    metadata: { organizationId }
  })
  
  const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: stripePriceId }]
  })
  
  // Save to database
  await prisma.subscription.create({
    data: {
      organizationId,
      planId,
      stripeSubscriptionId: subscription.id
    }
  })
}

// Webhook handler
app.post('/webhooks/stripe', async (request) => {
  const event = stripe.webhooks.constructEvent(...)
  
  switch(event.type) {
    case 'invoice.paid':
      // Mark invoice as paid
      break
    case 'customer.subscription.deleted':
      // Cancel access
      break
  }
})
```

---

## 🛒 Marketplace Module (Phase 2)

### Data Model Extension

```prisma
model MarketplaceProduct {
  id String @id @default(cuid())
  
  // Product info
  name String
  description String
  price Decimal
  type ProductType  // AGENT, TEMPLATE, AUTOMATION, COURSE, etc.
  
  // Seller
  creatorId String
  creator User @relation(fields: [creatorId], references: [id])
  
  // Visibility
  published Boolean
  featured Boolean
  rating Decimal
  
  // Content
  sourceCode String?
  documentation String
  thumbnail String?
  
  // Tracking
  salesCount Int @default(0)
  reviewCount Int @default(0)
  
  // Relations
  sales Sale[]
  reviews Review[]
  
  createdAt DateTime @default(now())
}

model Sale {
  id String @id @default(cuid())
  productId String
  buyerId String
  
  amount Decimal
  commissionAmount Decimal
  
  createdAt DateTime @default(now())
}

model Review {
  id String @id @default(cuid())
  productId String
  reviewerId String
  
  rating Int  // 1-5
  comment String?
  
  createdAt DateTime @default(now())
}

enum ProductType { AGENT, TEMPLATE, AUTOMATION, COURSE, PROMPT, PLUGIN }
```

### Marketplace Flow

```
1. Creator publishes product
   ↓
2. Product indexed in marketplace
   ↓
3. Buyer discovers product
   ↓
4. Buyer purchases (Stripe)
   ↓
5. Instant access to product
   ↓
6. Creator receives 70% of sale
   ↓
7. Platform keeps 30%
   ↓
8. Buyer can leave review
```

---

## ⚙️ Workflow Builder (Phase 2)

### Visual Workflow Engine

```typescript
interface WorkflowNode {
  id: string
  type: 'trigger' | 'action' | 'condition' | 'wait'
  config: Record<string, any>
}

interface Workflow {
  id: string
  name: string
  nodes: WorkflowNode[]
  edges: Array<{ from: string, to: string }>
  enabled: boolean
}

// Example workflow (JSON)
{
  "name": "Lead Qualification",
  "nodes": [
    { "id": "n1", "type": "trigger", "config": { "event": "inbox_item" } },
    { "id": "n2", "type": "action", "config": { "action": "classify" } },
    { "id": "n3", "type": "condition", "config": { "if": "is_lead" } },
    { "id": "n4", "type": "action", "config": { "action": "create_contact" } },
    { "id": "n5", "type": "action", "config": { "action": "send_email" } }
  ],
  "edges": [
    { "from": "n1", "to": "n2" },
    { "from": "n2", "to": "n3" },
    { "from": "n3", "to": "n4" },
    { "from": "n4", "to": "n5" }
  ]
}
```

### Workflow Execution Engine

```typescript
async executeWorkflow(workflow: Workflow, trigger: any) {
  const context = { trigger, results: {} }
  
  for (const nodeId of topologicalSort(workflow)) {
    const node = workflow.nodes.find(n => n.id === nodeId)
    
    if (node.type === 'trigger') {
      context.results[nodeId] = trigger
    } else if (node.type === 'condition') {
      const result = evaluateCondition(node.config, context)
      if (!result) break  // Stop execution
    } else if (node.type === 'action') {
      context.results[nodeId] = await executeAction(node.config, context)
    } else if (node.type === 'wait') {
      await wait(node.config.duration)
    }
  }
  
  return context.results
}
```

---

## 📱 Mobile App (Phase 3)

### React Native Structure

```
MelodieSpark Mobile
├── Screens/
│   ├── Auth/
│   ├── Dashboard/
│   ├── Projects/
│   ├── Inbox/
│   ├── Chat/ (Real-time with HyperDirector)
│   └── Settings/
├── Components/
├── Services/ (API, storage, push)
├── Store/ (State management)
└── Navigation/
```

### Key Features

```
✅ Offline-first
✅ Push notifications
✅ Voice input to inbox
✅ Real-time sync
✅ Biometric auth
✅ Dark mode
```

---

## 🎮 Game Engine Integration (Phase 3)

### Real-time Collaboration

```
Users can:
1. Create shared workspaces (like Google Docs)
2. Collaborate in real-time on projects
3. See cursor positions
4. Voice/video chat integrated
5. Presence awareness

Tech:
- WebSocket for real-time updates
- Conflict-free replicated data types (CRDT)
- Operational transformation
```

---

## 🌐 Enterprise Features (Phase 4)

### Multi-tenancy

```
Organizations can:
✅ Have multiple workspaces
✅ Manage teams
✅ Set permissions per workspace
✅ Separate data/analytics
✅ Custom branding
```

### SSO Integration

```
Support for:
✅ SAML 2.0
✅ OpenID Connect
✅ Active Directory
✅ Okta
✅ Auth0
```

### Advanced Analytics

```
✅ Team productivity metrics
✅ Automation ROI
✅ AI cost analysis
✅ Predictive insights
✅ Custom reports
```

---

## 🚀 Scaling Plan

### Stage 1: Stability (Current)
- Single PostgreSQL instance
- Redis for caching
- Local file storage
- Single API server
- **Max: 1K concurrent users**

### Stage 2: Performance (Q2 2025)
- Read replicas
- CDN for static assets
- S3 for files
- Load balancer
- Caching layer
- **Max: 10K concurrent users**

### Stage 3: Distribution (Q3 2025)
- Database sharding by org_id
- Multi-region deployment
- Edge computing
- Global CDN
- **Max: 100K+ concurrent users**

### Stage 4: Enterprise (Q4 2025)
- Dedicated instances
- Custom integrations
- On-premise options
- Disaster recovery
- **Max: Unlimited**

---

## 💡 Revenue Roadmap

### Phase 1 (Now)
```
Monetization: Limited
- Lead generation
- Enterprise pilots
- Early adopter feedback
```

### Phase 2 (Q1 2025)
```
SaaS: Launch pricing tiers
- Starter: $29/user/month
- Pro: $99/user/month
- Enterprise: Custom

Projected: $50K MRR
```

### Phase 3 (Q2-Q3 2025)
```
Marketplace + Services
- Marketplace: 30% commission
- Professional services: $250/hour
- Training: $1K-$10K per org

Projected: $500K MRR
```

### Phase 4 (Q4 2025+)
```
Ecosystem expansion
- API monetization
- White-label licensing
- Reseller programs

Projected: $2M+ MRR
```

---

## 🎯 Success Metrics (Year 1)

```
Users:           10,000+
Orgs:             2,000+
MRR:             $500K
NPS:              50+
Retention:        90%+
AI Accuracy:      90%+
System Uptime:    99.9%
```

---

## 📋 Implementation Checklist

### Immediate (Weeks 1-4)
- [ ] Deploy Phase 1 to production
- [ ] Get first 100 beta users
- [ ] Collect feedback
- [ ] Fix bugs & optimize

### Short-term (Months 2-3)
- [ ] Build CRM module
- [ ] Integrate Stripe
- [ ] Create customer portal
- [ ] Launch beta marketplace

### Medium-term (Months 4-6)
- [ ] Workflow builder UI
- [ ] Mobile app beta
- [ ] Advanced analytics
- [ ] Enterprise SSO

### Long-term (Months 7-12)
- [ ] Multi-agent orchestration
- [ ] Game engine integration
- [ ] On-premise option
- [ ] Enterprise support

---

**The foundation is set. The path is clear. Execute with focus.** 🚀

