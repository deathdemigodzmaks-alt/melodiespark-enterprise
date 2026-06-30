'use client'

import { useState } from 'react'
import axios from 'axios'
import { Brain, Inbox, FileText, Zap } from 'lucide-react'

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'

export default function DashboardPage() {
  const [activeTab, setActiveTab] = useState('inbox')
  const [inboxItems, setInboxItems] = useState<any[]>([])
  const [projects, setProjects] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  const handleNewIdea = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setLoading(true)

    const formData = new FormData(e.currentTarget)
    const title = formData.get('title') as string
    const content = formData.get('content') as string

    try {
      const response = await axios.post(
        `${API_BASE}/api/inbox`,
        { title, content, source: 'MANUAL' },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem('token')}`,
          },
        }
      )

      setInboxItems([response.data, ...inboxItems])
      ;(e.target as HTMLFormElement).reset()
    } catch (error) {
      console.error('Error creating inbox item:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <header className="border-b border-purple-500/20 backdrop-blur-sm">
        <nav className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Brain className="w-8 h-8 text-purple-400" />
            <span className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-600">
              MelodieSpark
            </span>
          </div>
          <div className="flex items-center gap-4">
            <button className="px-4 py-2 text-purple-300 hover:text-purple-100">
              Dashboard
            </button>
            <button className="px-4 py-2 text-slate-400 hover:text-slate-200">
              Settings
            </button>
          </div>
        </nav>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          {[
            { label: 'Inbox', value: inboxItems.length, icon: Inbox },
            { label: 'Projects', value: projects.length, icon: FileText },
            { label: 'AI Processed', value: inboxItems.filter(i => i.status === 'PROCESSED').length, icon: Zap },
            { label: 'Automations', value: 0, icon: Zap },
          ].map((stat) => (
            <div
              key={stat.label}
              className="bg-gradient-to-br from-purple-500/10 to-pink-500/10 border border-purple-500/20 rounded-lg p-6"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-purple-400">{stat.label}</p>
                  <p className="text-3xl font-bold text-white mt-2">{stat.value}</p>
                </div>
                <stat.icon className="w-8 h-8 text-purple-400 opacity-50" />
              </div>
            </div>
          ))}
        </div>

        {/* Tabs */}
        <div className="flex gap-4 mb-6 border-b border-purple-500/20">
          {[
            { id: 'inbox', label: 'Inbox', icon: Inbox },
            { id: 'projects', label: 'Projects', icon: FileText },
            { id: 'knowledge', label: 'Knowledge', icon: Brain },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-3 flex items-center gap-2 border-b-2 transition ${
                activeTab === tab.id
                  ? 'border-purple-500 text-purple-400'
                  : 'border-transparent text-slate-400 hover:text-slate-300'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </div>

        {/* New Idea Form */}
        {activeTab === 'inbox' && (
          <div className="bg-slate-800/50 border border-purple-500/20 rounded-lg p-6 mb-6">
            <h3 className="text-lg font-semibold text-white mb-4">Add New Idea</h3>
            <form onSubmit={handleNewIdea} className="space-y-4">
              <input
                type="text"
                name="title"
                placeholder="Idea title..."
                className="w-full px-4 py-2 bg-slate-700/50 border border-purple-500/20 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                required
              />
              <textarea
                name="content"
                placeholder="Describe your idea..."
                rows={4}
                className="w-full px-4 py-2 bg-slate-700/50 border border-purple-500/20 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
                required
              />
              <button
                type="submit"
                disabled={loading}
                className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg font-semibold hover:opacity-90 disabled:opacity-50"
              >
                {loading ? 'Processing...' : 'Submit Idea'}
              </button>
            </form>
          </div>
        )}

        {/* Inbox Items */}
        {activeTab === 'inbox' && (
          <div className="space-y-4">
            {inboxItems.length === 0 ? (
              <div className="text-center py-12 text-slate-400">
                No inbox items yet. Add an idea above to get started.
              </div>
            ) : (
              inboxItems.map((item) => (
                <div
                  key={item.id}
                  className="bg-slate-800/30 border border-purple-500/20 rounded-lg p-4"
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h4 className="font-semibold text-white">{item.title}</h4>
                      <p className="text-sm text-slate-400 mt-1">{item.content}</p>
                      <div className="flex gap-2 mt-3">
                        <span className="px-2 py-1 bg-purple-500/20 text-purple-300 text-xs rounded">
                          {item.classification}
                        </span>
                        <span className="px-2 py-1 bg-slate-700/50 text-slate-300 text-xs rounded">
                          {item.status}
                        </span>
                      </div>
                    </div>
                    <span className="text-xs text-slate-500">
                      {new Date(item.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </main>
    </div>
  )
}
