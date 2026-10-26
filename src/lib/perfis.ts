import type { SupabaseClient } from '@supabase/supabase-js'

// `usuarios` é a tabela viva de contas, mas várias colunas "criado por" /
// "responsável" (escolas, registros, contratos, negociações...) têm chave
// estrangeira para `profiles`. Sem a linha espelhada em `profiles`, qualquer
// gravação feita por esse usuário é recusada (23503). Toda criação/edição de
// conta passa por aqui pra manter as duas tabelas alinhadas.
const ROLES = ['gerente', 'supervisor', 'consultor', 'assistente', 'readonly']

export async function sincronizarPerfil(
  admin: SupabaseClient,
  p: { id: string; email: string; nome: string; role: string; ativo: boolean; telefone?: string | null },
) {
  const { error } = await admin.from('profiles').upsert({
    id: p.id,
    email: p.email,
    full_name: p.nome || p.email,
    role: ROLES.includes(p.role) ? p.role : 'consultor', // profiles.role é enum
    is_active: p.ativo,
    phone: p.telefone ?? null,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'id' })
  if (error) console.error('[perfis] não foi possível sincronizar o perfil:', error.message)
  return error
}
