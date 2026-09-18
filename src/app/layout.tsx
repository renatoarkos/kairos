import type { Metadata } from 'next'
import type { Viewport } from 'next'
import { Bodoni_Moda, Montserrat } from 'next/font/google'
import './globals.css'

// Tipografia real da Kairós, extraída das fontes embutidas no manual de
// marca oficial (kairós-apresentação.pdf): títulos em Bodoni BT Bold
// Italic, texto/wordmark em Gotham (Light/Bold/Black). Bodoni BT e Gotham
// são licenciadas (não disponíveis no Google Fonts) — usamos os
// equivalentes livres mais próximos: Bodoni Moda (mesma família Bodoni,
// com itálico) e Montserrat (substituto padrão de mercado pra Gotham,
// inclusive é o que já roda no site institucional da Kairós).
// Reaproveita a variável --font-inter (nome legado da base We Make) pra
// não precisar tocar as centenas de usos já espalhados pelo código.
const bodoni = Bodoni_Moda({
  subsets: ['latin'],
  variable: '--font-cormorant',
  weight: ['400', '500', '600', '700', '800', '900'],
  style: ['normal', 'italic'],
  display: 'swap',
})

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-montserrat',
  display: 'swap',
})

const montserratBody = Montserrat({
  subsets: ['latin'],
  variable: '--font-inter',
  weight: ['300', '400', '500', '600'],
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
    <html lang="pt-BR" className={`${montserratBody.variable} ${bodoni.variable} ${montserrat.variable} h-full antialiased`}>
      <body className="min-h-full">{children}</body>
    </html>
  )
}
