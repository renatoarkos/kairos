import Link from 'next/link'
import PageHeader from '@/components/layout/PageHeader'
import { KpiCard, MiniBarChart } from '@/components/comercial/DashboardCharts'
import { BrasilMapa } from '@/components/comercial/BrasilMapa'
import { getPanorama, REGIOES, SEM_INFO, type Base } from '@/lib/panorama'

export const dynamic = 'force-dynamic'

interface Props { searchParams: Promise<{ base?: string; regiao?: string }> }

const card: React.CSSProperties = {
  background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4,
  overflow: 'hidden', boxShadow: '0 2px 8px rgba(34,29,55,.05)',
}
const cardHead: React.CSSProperties = {
  padding: '.85rem 1.4rem', borderBottom: '1px solid #f1f5f9', background: '#fafafa',
}
const cardTitle: React.CSSProperties = {
  fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.74rem', fontWeight: 800,
  textTransform: 'uppercase', letterSpacing: '.07em', color: '#221d37',
}
const cardSub: React.CSSProperties = { fontSize: '.7rem', color: '#94a3b8', fontFamily: 'var(--font-inter,sans-serif)', marginTop: '.15rem' }
const th: React.CSSProperties = {
  textAlign: 'left', padding: '.5rem .8rem', fontSize: '.6rem', fontWeight: 800, textTransform: 'uppercase',
  letterSpacing: '.07em', color: '#64748b', fontFamily: 'var(--font-montserrat,sans-serif)', background: '#f8fafc', whiteSpace: 'nowrap',
}
const td: React.CSSProperties = { padding: '.5rem .8rem', fontSize: '.78rem', color: '#334155', borderTop: '1px solid #f1f5f9', whiteSpace: 'nowrap' }
const dir: React.CSSProperties = { textAlign: 'right' }

const pill = (ativo: boolean): React.CSSProperties => ({
  padding: '.35rem .8rem', borderRadius: 999, fontSize: '.72rem', fontWeight: 700, textDecoration: 'none',
  fontFamily: 'var(--font-montserrat,sans-serif)',
  background: ativo ? 'linear-gradient(135deg, #36b6e8, #87cde8)' : '#F1F5F9', color: ativo ? '#fff' : '#475569',
})

const BASES: { id: Base; label: string }[] = [
  { id: 'todas', label: 'Todas as escolas' },
  { id: 'cadastro', label: 'Cadastradas' },
  { id: 'leads', label: 'Escolas-lead (congressos)' },
]
const fmt = (n: number) => n.toLocaleString('pt-BR')
const ico = (d: string) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d={d} /></svg>
)

export default async function PanoramaPage({ searchParams }: Props) {
  const params = await searchParams
  const base = (['todas', 'cadastro', 'leads'].includes(params.base ?? '') ? params.base : 'todas') as Base
  const regiao = REGIOES.includes(params.regiao as any) ? (params.regiao as string) : null
  const d = await getPanorama({ base, regiao })
  const k = d.kpis
  const url = (b: Base, r: string | null) => `/comercial/panorama?base=${b}${r ? `&regiao=${encodeURIComponent(r)}` : ''}`
  const maxFaixa = Math.max(1, ...d.faixas.map(f => f.escolas))
  const pct = (a: number, b: number) => (b ? Math.round((a / b) * 100) : 0)

  return (
    <div>
      <PageHeader title="Panorama de Mercado" subtitle="Escolas por região e por porte, cruzando o cadastro e os leads" />
      <div style={{ padding: '2rem 2.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>

        {/* ── Filtros ── */}
        <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ display: 'flex', gap: '.4rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <span style={{ ...cardSub, marginRight: '.3rem', fontWeight: 700, textTransform: 'uppercase' }}>Base</span>
            {BASES.map(b => <Link key={b.id} href={url(b.id, regiao)} style={pill(base === b.id)}>{b.label}</Link>)}
          </div>
          <div style={{ display: 'flex', gap: '.4rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <span style={{ ...cardSub, marginRight: '.3rem', fontWeight: 700, textTransform: 'uppercase' }}>Região</span>
            <Link href={url(base, null)} style={pill(!regiao)}>Todas</Link>
            {REGIOES.map(r => <Link key={r} href={url(base, r)} style={pill(regiao === r)}>{r}</Link>)}
          </div>
        </div>

        {/* ── KPIs ── */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '1rem' }}>
          <KpiCard label="Escolas" valor={fmt(k.total)} cor="#2563eb" bg="#eff6ff" border="#bfdbfe"
            sub={`${fmt(k.cadastradas)} cadastradas · ${fmt(k.leads)} como lead`} icon={ico('M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z')} />
          <KpiCard label="Alunos mapeados" valor={fmt(k.alunos)} cor="#16a34a" bg="#f0fdf4" border="#86efac"
            sub={`em ${fmt(k.comPorte)} escolas com porte informado`} icon={ico('M22 10v6M2 10l10-5 10 5-10 5z')} />
          <KpiCard label="Porte médio" valor={k.porteMedio ? `${fmt(k.porteMedio)} alunos` : '—'} cor="#b45309" bg="#fffbeb" border="#fcd34d"
            sub="média das escolas com porte informado" icon={ico('M18 20V10M12 20V4M6 20v-6')} />
          <KpiCard label="Estados" valor={k.ufs} cor="#7c3aed" bg="#f5f3ff" border="#ddd6fe"
            sub={regiao ? `na região ${regiao}` : 'com ao menos uma escola'} icon={ico('M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z')} />
          <KpiCard label="Pessoas no Banco de Leads" valor={fmt(k.pessoasLeads)} cor="#0d9488" bg="#f0fdfa" border="#99f6e4"
            sub="contatos de congressos e formulários" href="/leads-banco" icon={ico('M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')} />
        </div>

        {/* ── Mapa + regiões ── */}
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(300px, 380px) 1fr', gap: '1.5rem' }}>
          <div style={card}>
            <div style={cardHead}><div style={cardTitle}>Distribuição no mapa</div><div style={cardSub}>nº de escolas por estado</div></div>
            <div style={{ padding: '1rem' }}>
              {Object.keys(d.porEstadoMapa).length ? <BrasilMapa porEstado={d.porEstadoMapa} width={340} height={340} />
                : <div style={{ ...cardSub, textAlign: 'center', padding: '2rem' }}>Sem escolas com estado informado neste recorte.</div>}
            </div>
          </div>
          <div style={card}>
            <div style={cardHead}><div style={cardTitle}>Por região</div><div style={cardSub}>escolas, alunos mapeados e contatos no banco de leads</div></div>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead><tr><th style={th}>Região</th><th style={{ ...th, ...dir }}>Escolas</th><th style={{ ...th, ...dir }}>% do total</th><th style={{ ...th, ...dir }}>Alunos</th><th style={{ ...th, ...dir }}>Porte médio</th><th style={{ ...th, ...dir }}>Pessoas (leads)</th></tr></thead>
                <tbody>
                  {d.regioes.length === 0 && <tr><td style={{ ...td, color: '#94a3b8' }} colSpan={6}>Sem dados neste recorte.</td></tr>}
                  {d.regioes.map(r => (
                    <tr key={r.regiao}>
                      <td style={{ ...td, fontWeight: 700, color: '#221d37' }}><Link href={url(base, r.regiao)} style={{ color: 'inherit', textDecoration: 'none' }}>{r.regiao}</Link></td>
                      <td style={{ ...td, ...dir }}>{fmt(r.escolas)}</td>
                      <td style={{ ...td, ...dir }}>{pct(r.escolas, d.regioes.reduce((s, x) => s + x.escolas, 0))}%</td>
                      <td style={{ ...td, ...dir }}>{r.alunos ? fmt(r.alunos) : '—'}</td>
                      <td style={{ ...td, ...dir }}>{r.porteMedio ? fmt(r.porteMedio) : '—'}</td>
                      <td style={{ ...td, ...dir }}>{fmt(r.pessoas)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* ── Porte + cidades ── */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
          <div style={card}>
            <div style={cardHead}><div style={cardTitle}>Tamanho das escolas</div><div style={cardSub}>faixas por nº de alunos</div></div>
            <div style={{ padding: '1.2rem 1.4rem', display: 'flex', flexDirection: 'column', gap: '.9rem' }}>
              {d.faixas.map(f => (
                <div key={f.label}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.75rem', marginBottom: '.25rem', fontFamily: 'var(--font-inter,sans-serif)' }}>
                    <span style={{ fontWeight: 700, color: f.label === SEM_INFO ? '#94a3b8' : '#334155' }}>{f.label}</span>
                    <span style={{ color: '#475569' }}><strong style={{ color: '#221d37' }}>{fmt(f.escolas)}</strong> escolas · {pct(f.escolas, k.total)}%{f.alunos ? ` · ${fmt(f.alunos)} alunos` : ''}</span>
                  </div>
                  <div style={{ height: 12, background: '#f1f5f9', borderRadius: 6, overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${Math.max((f.escolas / maxFaixa) * 100, f.escolas ? 3 : 0)}%`, background: f.label === SEM_INFO ? '#cbd5e1' : 'linear-gradient(90deg,#36b6e8,#2563eb)', borderRadius: 6 }} />
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div style={card}>
            <div style={cardHead}><div style={cardTitle}>Principais cidades</div><div style={cardSub}>top 10 por nº de escolas</div></div>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead><tr><th style={th}>Cidade</th><th style={th}>UF</th><th style={{ ...th, ...dir }}>Escolas</th><th style={{ ...th, ...dir }}>Alunos</th></tr></thead>
              <tbody>
                {d.cidades.length === 0 && <tr><td style={{ ...td, color: '#94a3b8' }} colSpan={4}>Sem cidades informadas neste recorte.</td></tr>}
                {d.cidades.map(c => (
                  <tr key={`${c.cidade}-${c.uf}`}>
                    <td style={{ ...td, fontWeight: 600, color: '#221d37' }}>{c.cidade}</td><td style={td}>{c.uf ?? '—'}</td>
                    <td style={{ ...td, ...dir }}>{fmt(c.escolas)}</td><td style={{ ...td, ...dir }}>{c.alunos ? fmt(c.alunos) : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* ── Estados ── */}
        <div style={card}>
          <div style={cardHead}><div style={cardTitle}>Por estado</div><div style={cardSub}>todos os estados com escolas ou contatos no banco de leads</div></div>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead><tr><th style={th}>UF</th><th style={th}>Região</th><th style={{ ...th, ...dir }}>Escolas</th><th style={{ ...th, ...dir }}>Cadastradas</th><th style={{ ...th, ...dir }}>Como lead</th><th style={{ ...th, ...dir }}>Alunos</th><th style={{ ...th, ...dir }}>Porte médio</th><th style={{ ...th, ...dir }}>Pessoas (leads)</th></tr></thead>
              <tbody>
                {d.ufs.map(u => (
                  <tr key={u.uf}>
                    <td style={{ ...td, fontWeight: 700, color: '#221d37' }}>{u.uf}</td><td style={td}>{u.regiao}</td>
                    <td style={{ ...td, ...dir, fontWeight: 700 }}>{fmt(u.escolas)}</td><td style={{ ...td, ...dir }}>{fmt(u.cadastradas)}</td><td style={{ ...td, ...dir }}>{fmt(u.leads)}</td>
                    <td style={{ ...td, ...dir }}>{u.alunos ? fmt(u.alunos) : '—'}</td><td style={{ ...td, ...dir }}>{u.porteMedio ? fmt(u.porteMedio) : '—'}</td><td style={{ ...td, ...dir }}>{fmt(u.pessoas)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* ── Segmentos e perfil ── */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
          <MiniBarChart title="Segmentos informados (escolas)" data={d.segmentos} colorHex="#b45309" labelWidth={70} />
          <MiniBarChart title="Perfil pedagógico (escolas cadastradas)" data={d.perfis} colorHex="#7c3aed" labelWidth={110} />
        </div>

        {/* ── Qualidade dos dados ── */}
        <div style={{ ...card, background: '#fffbeb', borderColor: '#fde68a' }}>
          <div style={{ padding: '1rem 1.4rem', fontSize: '.78rem', color: '#78350f', lineHeight: 1.6, fontFamily: 'var(--font-inter,sans-serif)' }}>
            <strong>Cobertura dos dados:</strong> {fmt(k.comPorte)} de {fmt(k.total)} escolas ({pct(k.comPorte, k.total)}%) têm nº de alunos informado
            e {fmt(k.total - k.semUf)} ({pct(k.total - k.semUf, k.total)}%) têm estado. As métricas de alunos e porte médio consideram só as escolas com porte informado;
            quando uma escola está no cadastro e também no banco de leads, os dados dos dois lados se completam.
            Para melhorar o painel, preencha o nº de alunos e o estado em <Link href="/comercial/escolas" style={{ color: '#92400e', fontWeight: 700 }}>Escolas</Link>.
          </div>
        </div>
      </div>
    </div>
  )
}
