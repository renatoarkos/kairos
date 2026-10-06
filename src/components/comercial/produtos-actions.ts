'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { GRUPOS_PRODUTO } from '@/lib/produtos'

type Resultado = { success: boolean; error?: string }

// Lê o formulário de produto (cadastro e edição usam os mesmos campos).
function lerProduto(formData: FormData):
  | { ok: true; registro: Record<string, string | number | boolean | null> }
  | { ok: false; error: string } {
  const titulo = String(formData.get('titulo') || '').trim()
  if (!titulo) return { ok: false, error: 'Informe o título do produto.' }

  const registro: Record<string, string | number | boolean | null> = {}
  for (const campo of GRUPOS_PRODUTO.flatMap(g => g.campos)) {
    const bruto = String(formData.get(campo.campo) ?? '').trim()
    if (campo.tipo === 'text' || campo.tipo === 'select') {
      registro[campo.campo] = bruto || null
      continue
    }
    if (!bruto) { registro[campo.campo] = null; continue }
    // Aceita vírgula decimal ("0,205") como na planilha.
    const num = Number(bruto.replace(',', '.'))
    if (!Number.isFinite(num) || num < 0) {
      return { ok: false, error: `Valor inválido em "${campo.label}".` }
    }
    registro[campo.campo] = campo.tipo === 'int' ? Math.round(num) : num
  }
  registro.opcao_orcamento = (registro.opcao_orcamento as string | null) ?? 'Opção capa dura'
  registro.observacoes = String(formData.get('observacoes') || '').trim() || null
  return { ok: true, registro }
}

function traduzirErro(error: { code?: string; message: string }): string {
  if (error.code === '23505') return 'Já existe um produto com esse título nessa opção de orçamento.'
  if (error.code === '42703' || /valor_venda/.test(error.message)) {
    return 'O banco ainda não tem a coluna de custo de venda. Rode a migration add_custo_venda_e_demanda_2027.sql no Supabase.'
  }
  return error.message
}

// produtos_livros não tem policy de INSERT/UPDATE pro client comum — escrita
// via admin (mesmo padrão de metas_comerciais).
export async function criarProduto(formData: FormData): Promise<Resultado> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { success: false, error: 'Não autenticado.' }

  const lido = lerProduto(formData)
  if (!lido.ok) return { success: false, error: lido.error }

  const { error } = await createAdminClient().from('produtos_livros').insert({ ...lido.registro, criado_por: user.id })
  if (error) return { success: false, error: traduzirErro(error) }

  revalidatePath('/comercial/produtos')
  return { success: true }
}

export async function atualizarProduto(id: string, formData: FormData): Promise<Resultado> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { success: false, error: 'Não autenticado.' }
  if (!id) return { success: false, error: 'Produto não informado.' }

  const lido = lerProduto(formData)
  if (!lido.ok) return { success: false, error: lido.error }

  const { error } = await createAdminClient()
    .from('produtos_livros')
    .update({ ...lido.registro, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) return { success: false, error: traduzirErro(error) }

  revalidatePath('/comercial/produtos')
  revalidatePath('/comercial/registros/novo')
  return { success: true }
}
