'use client'

import React from 'react'

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="text-center">
        <h1 className="mb-4 text-6xl font-bold text-white">
          🎵 MelodieSpark
        </h1>
        <p className="mb-8 text-xl text-slate-300">
          Enterprise AI Operating System
        </p>
        <p className="text-lg text-slate-400">
          Transform ideas into structured execution
        </p>
        
        <div className="mt-12 flex gap-4 justify-center">
          <button className="rounded-lg bg-blue-600 px-8 py-3 text-white font-semibold hover:bg-blue-700 transition">
            Get Started
          </button>
          <button className="rounded-lg border border-slate-500 px-8 py-3 text-white font-semibold hover:border-slate-400 transition">
            Learn More
          </button>
        </div>
      </div>

      <div className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl">
        <div className="rounded-lg border border-slate-700 p-6">
          <h3 className="text-lg font-semibold text-white mb-2">🚀 Fast</h3>
          <p className="text-slate-400">Lightning-fast performance with global CDN</p>
        </div>
        <div className="rounded-lg border border-slate-700 p-6">
          <h3 className="text-lg font-semibold text-white mb-2">🔒 Secure</h3>
          <p className="text-slate-400">Enterprise-grade security and encryption</p>
        </div>
        <div className="rounded-lg border border-slate-700 p-6">
          <h3 className="text-lg font-semibold text-white mb-2">📊 Scalable</h3>
          <p className="text-slate-400">Auto-scaling infrastructure for any load</p>
        </div>
      </div>

      <footer className="mt-20 text-center text-slate-500">
        <p>© 2024 MelodieSpark. All rights reserved.</p>
      </footer>
    </main>
  )
}
