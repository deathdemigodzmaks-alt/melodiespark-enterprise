import { InboxItem } from '@melodiespark/database'
import Anthropic from '@anthropic-ai/sdk'

interface AIAnalysisResult {
  classification: string
  intent: string
  confidence: number
  aiAnalysis?: {
    suggestedProject: string
    suggestedTasks: string[]
    keyInsights: string[]
    recommendations: string[]
    modelUsed: string
    tokens: number
  }
}

class HyperDirector {
  private client: Anthropic

  constructor() {
    this.client = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    })
  }

  async analyzeInboxItem(item: InboxItem): Promise<AIAnalysisResult> {
    const prompt = `Analyze this inbox item and provide structured output.

Title: ${item.title}
Content: ${item.content}

Classify it as one of: IDEA, BUG, FEATURE_REQUEST, QUESTION, FEEDBACK, TASK, PROJECT

Then provide:
1. Classification (required)
2. Intent (one sentence summary)
3. Suggested project name (if applicable)
4. Suggested tasks (if applicable, as JSON array)
5. Key insights
6. Recommendations

Respond in JSON format:
{
  "classification": "...",
  "intent": "...",
  "suggestedProject": "..." or null,
  "suggestedTasks": [...],
  "keyInsights": [...],
  "recommendations": [...]
}
`

    try {
      const response = await this.client.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      })

      const content = response.content[0]
      if (content.type !== 'text') {
        throw new Error('Unexpected response type')
      }

      // Extract JSON from response
      const jsonMatch = content.text.match(/\{[\s\S]*\}/)
      if (!jsonMatch) {
        throw new Error('Could not extract JSON from response')
      }

      const analysis = JSON.parse(jsonMatch[0])

      return {
        classification: analysis.classification,
        intent: analysis.intent,
        confidence: 0.85,
        aiAnalysis: {
          suggestedProject: analysis.suggestedProject,
          suggestedTasks: analysis.suggestedTasks || [],
          keyInsights: analysis.keyInsights || [],
          recommendations: analysis.recommendations || [],
          modelUsed: 'claude-3-5-sonnet',
          tokens: response.usage.input_tokens + response.usage.output_tokens,
        },
      }
    } catch (error) {
      console.error('Error analyzing inbox item:', error)

      return {
        classification: 'UNCLASSIFIED',
        intent: 'Analysis failed',
        confidence: 0,
      }
    }
  }

  async generateTasks(projectDescription: string): Promise<string[]> {
    const prompt = `Given this project description, generate 3-5 specific, actionable tasks:

${projectDescription}

Return as JSON array of strings:
["task 1", "task 2", "task 3"]
`

    try {
      const response = await this.client.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 512,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      })

      const content = response.content[0]
      if (content.type !== 'text') {
        return []
      }

      const arrayMatch = content.text.match(/\[[\s\S]*\]/)
      if (!arrayMatch) {
        return []
      }

      return JSON.parse(arrayMatch[0])
    } catch (error) {
      console.error('Error generating tasks:', error)
      return []
    }
  }

  async summarizeContent(content: string): Promise<string> {
    const prompt = `Summarize this content in 2-3 sentences:

${content}
`

    try {
      const response = await this.client.messages.create({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 256,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      })

      const result = response.content[0]
      if (result.type === 'text') {
        return result.text
      }

      return ''
    } catch (error) {
      console.error('Error summarizing content:', error)
      return ''
    }
  }
}

export const hyperDirector = new HyperDirector()
