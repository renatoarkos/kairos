import { createAdminClient } from '@/lib/supabase/admin'
import PageHeader from '@/components/layout/PageHeader'
import { ProdutosCatalogo } from '@/components/comercial/ProdutosCatalogo'
import type { Produto } from '@/lib/produtos'

export const dynamic = 'force-dynamic'

export default async function ProdutosPage() {
  // admin: mesmo padrão de metas/registros — a leitura não depende da policy
  // de SELECT do client comum.
  const admin = createAdminClient()
  const { data, error } = await admin
    .from('produtos_livros')
    .select('*')
    .eq('ativo', true)
    .order('serie', { ascending: true, nullsFirst: false })
    .order('titulo')

  return (
    <div>
      <PageHeader
        title="Produtos — Catálogo de Livros"
        subtitle="Ficha técnica e valores dos livros da Kairós"
      />
      <div style={{ padding: '2rem 2.5rem' }}>
        {error && (
          <div style={{ marginBottom: '1rem', padding: '.75rem 1rem', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 2, fontSize: '.8rem', color: '#92400e' }}>
            Não foi possível carregar o catálogo ({error.message}). Confirme se a migration
            <strong> add_catalogo_livros_e_series.sql</strong> foi rodada no Supabase.
          </div>
        )}
        <ProdutosCatalogo produtos={(data ?? []) as Produto[]} />
      </div>
    </div>
  )
}
