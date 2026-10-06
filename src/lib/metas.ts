import { createAdminClient } from '@/lib/supabase/admin'

export interface Metas {
  metaAlunos: number
  metaReceita: number
  metaReunioes: number
  metaPropostas: number
  metaMinutas: number
  metaEscolasNovas: number
  prazo: string       // dd/mm/aaaa — pronto pra exibir
  prazoISO: string    // aaaa-mm-dd — pro <input type="date">
}

// Usado só se a linha em `metas_comerciais` ainda não existir (banco não
// migrado) — mesmos últimos números confirmados no briefing da Kairós
// (2026-09-21/28, ver memória "kairos-briefing-real-negocio"): reuniões e
// prazo de Hugo (Diretor Executivo), receita de Francieudes (Diretor
// Financeiro); alunos/propostas/minutas ainda sem número oficial da Kairós.
const METAS_PADRAO: Metas = {
  metaAlunos: 4000,
  metaReceita: 1000000,
  metaReunioes: 50,
  metaPropostas: 25,
  metaMinutas: 15,
  metaEscolasNovas: 100,
  prazo: '31/12/2026',
  prazoISO: '2026-12-31',
}

function formatarPrazoBR(prazoISO: string): string {
  try {
    return new Date(prazoISO + 'T00:00:00').toLocaleDateString('pt-BR')
  } catch {
    return prazoISO
  }
}

// Metas comerciais — editáveis em /comercial/metas (ver MetasForm.tsx e
// metas-actions.ts), gravadas na tabela singleton `metas_comerciais`
// (migrations/add_metas_comerciais.sql). Antes eram constantes hardcoded
// duplicadas aqui e num objeto local em comercial/metas/page.tsx.
export async function getMetas(): Promise<Metas> {
  const admin = createAdminClient()
  const { data } = await admin.from('metas_comerciais').select('*').eq('id', 1).maybeSingle()

  if (!data) return METAS_PADRAO

  return {
    metaAlunos: data.meta_alunos,
    metaReceita: Number(data.meta_receita),
    metaReunioes: data.meta_reunioes,
    metaPropostas: data.meta_propostas,
    metaMinutas: data.meta_minutas,
    metaEscolasNovas: data.meta_escolas_novas,
    prazo: formatarPrazoBR(data.prazo),
    prazoISO: data.prazo,
  }
}
