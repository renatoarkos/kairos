import type { Metadata } from 'next'
import type { Viewport } from 'next'
import { Inter, Cormorant_Garamond, Montserrat } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

const cormorant = Cormorant_Garamond({
  subsets: ['latin'],
  variable: '--font-cormorant',
  weight: ['300', '400', '500', '600', '700'],
  display: 'swap',
})

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-montserrat',
  display: 'swap',
})

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  themeColor: '#221d37',
}

export const metadata: Metadata = {
  // TODO: definir metadataBase com o domínio real assim que a Kairós publicar
  // (necessário para o Next.js resolver a URL absoluta da imagem de Open Graph).
  title: 'Kairós — Gestão Comercial para Educação',
  description: 'Plataforma de gestão comercial e inteligência para educação',
  openGraph: {
    images: [{ url: '/images/logo-kairos-color.png', width: 683, height: 228, alt: 'Kairós' }],
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR" className={`${inter.variable} ${cormorant.variable} ${montserrat.variable} h-full antialiased`}>
      <body className="min-h-full">{children}</body>
    </html>
  )
}
