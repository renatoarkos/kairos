import { createAdminClient } from '@/lib/supabase/admin'

// Panorama de mercado: métricas regionais e de porte, calculadas direto do
// cadastro de escolas (escolas) e do banco de leads (leads_escola,
// leads_universal), sem depender do funil de contratação.

export const UF_REGIAO: Record<string, string> = {
  SP: 'Sudeste', RJ: 'Sudeste', MG: 'Sudeste', ES: 'Sudeste',
  PR: 'Sul', SC: 'Sul', RS: 'Sul',
  BA: 'Nordeste', PE: 'Nordeste', CE: 'Nordeste', MA: 'Nordeste', PB: 'Nordeste',
  RN: 'Nordeste', AL: 'Nordeste', SE: 'Nordeste', PI: 'Nordeste',
  PA: 'Norte', AM: 'Norte', RO: 'Norte', RR: 'Norte', AC: 'Norte', AP: 'Norte', TO: 'Norte',
  GO: 'Centro-Oeste', MT: 'Centro-Oeste', MS: 'Centro-Oeste', DF: 'Centro-Oeste',
}
export const REGIOES = ['Norte', 'Nordeste', 'Centro-Oeste', 'Sudeste', 'Sul'] as const

export const FAIXAS = [
  { id: 'pequena', label: 'Pequena (até 150)', min: 1, max: 150 },
  { id: 'media', label: 'Média (150 a 400)', min: 150, max: 400 },
  { id: 'grande', label: 'Grande (400 a 1.000)', min: 400, max: 1000 },
  { id: 'muito', label: 'Muito grande (1.000+)', min: 1000, max: Infinity },
] as const
export const SEM_INFO = 'Sem informação'

export type Base = 'todas' | 'cadastro' | 'leads'

export interface EscolaMercado {
  nome: string
  cidade: string | null
  uf: string | null
  porte: number | null
  origem: 'cadastro' | 'lead' | 'ambos'
  perfil: string | null
  seg: { inf: boolean; f1: boolean; f2: boolean; med: boolean }
}

export interface LinhaUf {
  uf: string; regiao: string; escolas: number; cadastradas: number; leads: number
  alunos: number; comPorte: number; porteMedio: number; pessoas: number
}

export interface Panorama {
  filtros: { base: Base; regiao: string | null }
  kpis: {
    total: number; cadastradas: number; leads: number; alunos: number; comPorte: number
    porteMedio: number; ufs: number; semUf: number; semPorte: number; pessoasLeads: number
  }
  porEstadoMapa: Record<string, number>
  regioes: { regiao: string; escolas: number; alunos: number; porteMedio: number; pessoas: number }[]
  ufs: LinhaUf[]
  faixas: { label: string; escolas: number; alunos: number }[]
  cidades: { cidade: string; uf: string | null; escolas: number; alunos: number }[]
  segmentos: { label: string; count: number }[]
  perfis: { label: string; count: number }[]
}

const norm = (s: string | null | undefined) =>
  (s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim()
const cnpjDigitos = (s: string | null | undefined) => (s ?? '').replace(/\D/g, '')
const tituloCidade = (s: string | null | undefined) => {
  const t = (s ?? '').trim().toLowerCase()
  return t ? t.replace(/(^|\s|-)(\p{L})/gu, (_, a, b) => a + b.toUpperCase()).replace(/\b(Da|De|Do|Das|Dos|E)\b/g, m => m.toLowerCase()) : null
}
const ufValida = (s: string | null | undefined) => {
  const u = (s ?? '').trim().toUpperCase()
  return UF_REGIAO[u] ? u : null
}

// O PostgREST limita a 1.000 linhas por chamada; pagina até trazer tudo.
async function buscarTudo<T>(tabela: string, colunas: string): Promise<T[]> {
  const admin = createAdminClient()
  const todas: T[] = []
  for (let i = 0; ; i += 1000) {
    const { data, error } = await admin.from(tabela).select(colunas).range(i, i + 999)
    if (error || !data) break
    todas.push(...(data as T[]))
    if (data.length < 1000) break
  }
  return todas
}

export function faixaDe(porte: number | null): string {
  if (!porte || porte <= 0) return SEM_INFO
  return (FAIXAS.find(f => porte >= f.min && porte < f.max) ?? FAIXAS[FAIXAS.length - 1]).label
}

export async function getPanorama(filtros: { base?: Base; regiao?: string | null }): Promise<Panorama> {
  const base: Base = filtros.base ?? 'todas'
  const regiao = filtros.regiao && (REGIOES as readonly string[]).includes(filtros.regiao) ? filtros.regiao : null

  const [escolas, leadsEscola, pessoas] = await Promise.all([
    buscarTudo<any>('escolas', 'nome, cnpj, cidade, estado, total_alunos, qtd_infantil, qtd_fund1, qtd_fund2, qtd_medio, perfil_pedagogico, ativa'),
    buscarTudo<any>('leads_escola', 'nome, cnpj, cidade, uf, qtd_alunos, alunos_infantil, alunos_fund1, alunos_fund2, alunos_ens_medio'),
    buscarTudo<any>('leads_universal', 'uf'),
  ])

  // índice das escolas cadastradas por CNPJ e por nome normalizado, pra casar com os leads
  const lista: EscolaMercado[] = []
  const porCnpj = new Map<string, EscolaMercado>()
  const porNome = new Map<string, EscolaMercado>()
  for (const e of escolas.filter((x: any) => x.ativa !== false)) {
    const soma = (e.qtd_infantil ?? 0) + (e.qtd_fund1 ?? 0) + (e.qtd_fund2 ?? 0) + (e.qtd_medio ?? 0)
    const item: EscolaMercado = {
      nome: e.nome, cidade: tituloCidade(e.cidade), uf: ufValida(e.estado),
      porte: e.total_alunos > 0 ? e.total_alunos : soma > 0 ? soma : null,
      origem: 'cadastro', perfil: e.perfil_pedagogico ?? null,
      seg: { inf: (e.qtd_infantil ?? 0) > 0, f1: (e.qtd_fund1 ?? 0) > 0, f2: (e.qtd_fund2 ?? 0) > 0, med: (e.qtd_medio ?? 0) > 0 },
    }
    lista.push(item)
    const c = cnpjDigitos(e.cnpj); if (c.length >= 11) porCnpj.set(c, item)
    porNome.set(norm(e.nome), item)
  }
  for (const l of leadsEscola) {
    const c = cnpjDigitos(l.cnpj)
    const par = (c.length >= 11 ? porCnpj.get(c) : undefined) ?? porNome.get(norm(l.nome))
    const seg = { inf: (l.alunos_infantil ?? 0) > 0, f1: (l.alunos_fund1 ?? 0) > 0, f2: (l.alunos_fund2 ?? 0) > 0, med: (l.alunos_ens_medio ?? 0) > 0 }
    if (par) {
      // a mesma escola: completa o que o cadastro não tem
      par.origem = 'ambos'
      par.uf ??= ufValida(l.uf); par.cidade ??= tituloCidade(l.cidade)
      if (!par.porte && l.qtd_alunos > 0) par.porte = l.qtd_alunos
      par.seg = { inf: par.seg.inf || seg.inf, f1: par.seg.f1 || seg.f1, f2: par.seg.f2 || seg.f2, med: par.seg.med || seg.med }
    } else {
      lista.push({ nome: l.nome, cidade: tituloCidade(l.cidade), uf: ufValida(l.uf), porte: l.qtd_alunos > 0 ? l.qtd_alunos : null, origem: 'lead', perfil: null, seg })
    }
  }

  const naBase = lista.filter(e => base === 'todas' ? true : base === 'cadastro' ? e.origem !== 'lead' : e.origem !== 'cadastro')
  const recorte = naBase.filter(e => !regiao || (e.uf && UF_REGIAO[e.uf] === regiao))

  const comPorte = recorte.filter(e => e.porte)
  const alunos = comPorte.reduce((s, e) => s + (e.porte ?? 0), 0)

  // ── por UF ──
  const ufMap = new Map<string, LinhaUf>()
  for (const e of recorte) {
    if (!e.uf) continue
    const l = ufMap.get(e.uf) ?? { uf: e.uf, regiao: UF_REGIAO[e.uf], escolas: 0, cadastradas: 0, leads: 0, alunos: 0, comPorte: 0, porteMedio: 0, pessoas: 0 }
    l.escolas++
    if (e.origem !== 'lead') l.cadastradas++
    if (e.origem !== 'cadastro') l.leads++
    if (e.porte) { l.alunos += e.porte; l.comPorte++ }
    ufMap.set(e.uf, l)
  }
  for (const p of pessoas) {
    const uf = ufValida(p.uf); if (!uf || (regiao && UF_REGIAO[uf] !== regiao)) continue
    const l = ufMap.get(uf) ?? { uf, regiao: UF_REGIAO[uf], escolas: 0, cadastradas: 0, leads: 0, alunos: 0, comPorte: 0, porteMedio: 0, pessoas: 0 }
    l.pessoas++; ufMap.set(uf, l)
  }
  const ufs = [...ufMap.values()].map(l => ({ ...l, porteMedio: l.comPorte ? Math.round(l.alunos / l.comPorte) : 0 }))
    .sort((a, b) => b.escolas - a.escolas || b.pessoas - a.pessoas)

  const regMap = new Map<string, { escolas: number; alunos: number; comPorte: number; pessoas: number }>()
  for (const l of ufs) {
    const r = regMap.get(l.regiao) ?? { escolas: 0, alunos: 0, comPorte: 0, pessoas: 0 }
    r.escolas += l.escolas; r.alunos += l.alunos; r.comPorte += l.comPorte; r.pessoas += l.pessoas
    regMap.set(l.regiao, r)
  }
  const regioes = REGIOES.filter(r => regMap.has(r)).map(r => {
    const v = regMap.get(r)!
    return { regiao: r, escolas: v.escolas, alunos: v.alunos, porteMedio: v.comPorte ? Math.round(v.alunos / v.comPorte) : 0, pessoas: v.pessoas }
  }).sort((a, b) => b.escolas - a.escolas)

  // ── porte ──
  const faixaMap = new Map<string, { escolas: number; alunos: number }>()
  for (const e of recorte) {
    const f = faixaDe(e.porte); const v = faixaMap.get(f) ?? { escolas: 0, alunos: 0 }
    v.escolas++; v.alunos += e.porte ?? 0; faixaMap.set(f, v)
  }
  const faixas = [...FAIXAS.map(f => f.label), SEM_INFO].map(label => ({ label, ...(faixaMap.get(label) ?? { escolas: 0, alunos: 0 }) }))

  // ── cidades ──
  const cidMap = new Map<string, { cidade: string; uf: string | null; escolas: number; alunos: number }>()
  for (const e of recorte) {
    if (!e.cidade) continue
    const k = `${norm(e.cidade)}|${e.uf ?? ''}`
    const v = cidMap.get(k) ?? { cidade: e.cidade, uf: e.uf, escolas: 0, alunos: 0 }
    v.escolas++; v.alunos += e.porte ?? 0; cidMap.set(k, v)
  }
  const cidades = [...cidMap.values()].sort((a, b) => b.escolas - a.escolas || b.alunos - a.alunos).slice(0, 10)

  // ── segmentos e perfil ──
  const segmentos = [
    { label: 'Infantil', count: recorte.filter(e => e.seg.inf).length },
    { label: 'Fund. I', count: recorte.filter(e => e.seg.f1).length },
    { label: 'Fund. II', count: recorte.filter(e => e.seg.f2).length },
    { label: 'Médio', count: recorte.filter(e => e.seg.med).length },
  ]
  const perfMap = new Map<string, number>()
  for (const e of recorte) if (e.perfil) perfMap.set(e.perfil, (perfMap.get(e.perfil) ?? 0) + 1)
  const NOMES: Record<string, string> = { convencional: 'Convencional', crista_classica: 'Cristã clássica', por_principio: 'Por princípio', evangelica: 'Evangélica', crista_catolica: 'Cristã católica', outro: 'Outro' }
  const perfis = [...perfMap.entries()].map(([k, count]) => ({ label: NOMES[k] ?? k, count })).sort((a, b) => b.count - a.count)

  const pessoasTotal = pessoas.filter(p => { const u = ufValida(p.uf); return !regiao || (u && UF_REGIAO[u] === regiao) }).length
  const porEstadoMapa: Record<string, number> = {}
  for (const l of ufs) if (l.escolas) porEstadoMapa[l.uf] = l.escolas

  return {
    filtros: { base, regiao },
    kpis: {
      total: recorte.length,
      cadastradas: recorte.filter(e => e.origem !== 'lead').length,
      leads: recorte.filter(e => e.origem !== 'cadastro').length,
      alunos, comPorte: comPorte.length,
      porteMedio: comPorte.length ? Math.round(alunos / comPorte.length) : 0,
      ufs: new Set(recorte.map(e => e.uf).filter(Boolean)).size,
      semUf: recorte.filter(e => !e.uf).length,
      semPorte: recorte.length - comPorte.length,
      pessoasLeads: pessoasTotal,
    },
    porEstadoMapa, regioes, ufs, faixas, cidades, segmentos, perfis,
  }
}
