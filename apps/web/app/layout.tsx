import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'MelodieSpark - Enterprise AI Operating System',
  description: 'Transform ideas into structured execution',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="bg-slate-950 text-slate-50">
        <div className="min-h-screen">
          {children}
        </div>
      </body>
    </html>
  )
}
