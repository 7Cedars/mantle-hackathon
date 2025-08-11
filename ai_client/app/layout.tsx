import type { Metadata } from 'next'
import './globals.css'
import Navigation from './components/Navigation'

export const metadata: Metadata = {
  title: 'Gemini & Alchemy Chat App',
  description: 'A simple chat interface to test prompts for Gemini & Alchemy',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="font-sans">
        <Navigation />
        <main className="main-content">
          {children}
        </main>
      </body>
    </html>
  )
}
