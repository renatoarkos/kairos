'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'

export async function atualizarMetas(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { success: false, error: 'Não autenticado.' }

  const num = (campo: string) => {
    const v = Number(formData.get(campo))
    return Number.isFinite(v) && v >= 0 ? v : 0
  }
  const prazo = String(formData.get('prazo') || '')
  if (!prazo) return { success: false, error: 'Informe o prazo.' }

  // metas_comerciais não tem policy de UPDATE liberada pro client comum
  // (mesmo padrão de notas_escola/contratos) — usa admin.
  const admin = createAdminClient()
  const { error } = await admin.from('metas_comerciais').update({
    meta_alunos:        num('meta_alunos'),
    meta_receita:        num('meta_receita'),
    meta_reunioes:       num('meta_reunioes'),
    meta_propostas:      num('meta_propostas'),
    meta_minutas:        num('meta_minutas'),
    meta_escolas_novas:  num('meta_escolas_novas'),
    prazo,
    updated_at: new Date().toISOString(),
    atualizado_por: user.id,
  }).eq('id', 1)

  if (error) return { success: false, error: error.message }

  // As metas alimentam KPIs em 4 páginas — revalida todas pra nunca mostrar
  // número desatualizado numa e o novo na outra.
  revalidatePath('/comercial/metas')
  revalidatePath('/comercial')
  revalidatePath('/comercial/contratos')
  revalidatePath('/comercial/funil-contratacao')

  return { success: true }
}
