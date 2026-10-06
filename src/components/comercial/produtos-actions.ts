'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { GRUPOS_PRODUTO } from '@/lib/produtos'

export async function criarProduto(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { success: false, error: 'Não autenticado.' }

  const titulo = String(formData.get('titulo') || '').trim()
  if (!titulo) return { success: false, error: 'Informe o título do produto.' }

  const registro: Record<string, string | number | null> = {}
  for (const campo of GRUPOS_PRODUTO.flatMap(g => g.campos)) {
    const bruto = String(formData.get(campo.campo) ?? '').trim()
    if (campo.tipo === 'text' || campo.tipo === 'select') {
      registro[campo.campo] = bruto || null
      continue
    }
    if (!bruto) { registro[campo.campo] = null; continue }
    // Aceita vírgula decimal ("0,205") como no resto da planilha.
    const num = Number(bruto.replace(',', '.'))
    if (!Number.isFinite(num) || num < 0) {
      return { success: false, error: `Valor inválido em "${campo.label}".` }
    }
    registro[campo.campo] = campo.tipo === 'int' ? Math.round(num) : num
  }
  registro.opcao_orcamento = (registro.opcao_orcamento as string | null) ?? 'Opção capa dura'
  registro.observacoes = String(formData.get('observacoes') || '').trim() || null

  // produtos_livros não tem policy de INSERT pro client comum — usa admin
  // (mesmo padrão de metas_comerciais).
  const admin = createAdminClient()
  const { error } = await admin.from('produtos_livros').insert({ ...registro, criado_por: user.id })

  if (error) {
    if (error.code === '23505') {
      return { success: false, error: 'Já existe um produto com esse título nessa opção de orçamento.' }
    }
    return { success: false, error: error.message }
  }

  revalidatePath('/comercial/produtos')
  return { success: true }
}
