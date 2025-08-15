import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Providers } from '../config/Providers'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Mantle x Powers - AI x Blockchain',
  description: 'A small set of tokenholders control governance in most on-chain organisations - including Mantle. This PoC uses AI to identify different types of users based on their transaction history, not token holdings, and assigns powers accordingly.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}
