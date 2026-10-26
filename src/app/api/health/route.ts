import { NextResponse } from 'next/server'

export async function GET() {
  const envStatus = {
    SUPABASE_URL: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
    SUPABASE_KEY: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    SUPABASE_SERVICE_KEY: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    EMAIL_RESEND: !!process.env.RESEND_API_KEY
  };

  // Essenciais para o sistema funcionar; o e-mail (Resend) é informativo
  const isReady = envStatus.SUPABASE_URL && envStatus.SUPABASE_KEY && envStatus.SUPABASE_SERVICE_KEY;

  return NextResponse.json({
    status: isReady ? 'UP' : 'DEGRADED',
    timestamp: new Date().toISOString(),
    version: '1.0.0-pilot',
    dependencies: envStatus
  })
}
  
