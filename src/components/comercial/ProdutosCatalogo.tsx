'use client'

import { Fragment, useMemo, useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Pencil } from 'lucide-react'
import { atualizarProduto, criarProduto } from '@/components/comercial/produtos-actions'
import { ANOS, ANO_BASE, GRUPOS_PRODUTO, formatarValor, type Demanda, type Produto } from '@/lib/produtos'
import { nomeDaSerie } from '@/lib/series'
import { formatCurrency } from '@/lib/utils'

const lbl: React.CSSProperties = {
  display: 'block', fontSize: '.68rem', fontWeight: 700, color: '#475569',
  marginBottom: '.3rem', fontFamily: 'var(--font-montserrat,sans-serif)',
}
const inp: React.CSSProperties = {
  width: '100%', padding: '.5rem .65rem', fontSize: '.85rem',
  border: '1.5px solid #e2e8f0', borderRadius: 7, boxSizing: 'border-box',
}
const th: React.CSSProperties = {
  textAlign: 'left', padding: '.6rem .75rem', fontSize: '.62rem', fontWeight: 800,
  textTransform: 'uppercase', letterSpacing: '.07em', color: '#64748b',
  fontFamily: 'var(--font-montserrat,sans-serif)', background: '#f8fafc', whiteSpace: 'nowrap',
}
const td: React.CSSProperties = { padding: '.6rem .75rem', fontSize: '.8rem', color: '#334155', borderTop: '1px solid #f1f5f9' }
const num: React.CSSProperties = { textAlign: 'right', whiteSpace: 'nowrap' }

const moeda = (v: number | null) => (v === null || v === undefined ? '—' : formatCurrency(Number(v)))

function Ficha({ p, ano, demanda }: { p: Produto; ano: number; demanda?: Demanda }) {
  const linhas: [string, string][] = [
    ['Formato fechado', p.formato_fechado ?? '—'],
    ['Largura × altura', p.largura_mm && p.altura_mm ? `${p.largura_mm} × ${p.altura_mm} mm` : '—'],
    ['Papel da capa', [p.papel_capa, p.gramatura_capa ? `${p.gramatura_capa} g/m²` : null].filter(Boolean).join(' · ') || '—'],
    ['Cor da capa', p.cor_capa ?? '—'],
    ['Enobrecimento', p.enobrecimento ?? '—'],
    ['Papelão / forro', [p.papelao, p.forro].filter(Boolean).join(' · ') || '—'],
    ['Papel do miolo', [p.papel_miolo, p.gramatura_miolo ? `${p.gramatura_miolo} g/m²` : null].filter(Boolean).join(' · ') || '—'],
    ['Cor do miolo', p.cor_miolo ?? '—'],
    ['Acabamento', p.acabamento ?? '—'],
    [`Tiragem ${ANO_BASE} (atualizada)`, `${p.tiragem ?? '—'} (${p.tiragem_atualizada ?? '—'})`],
    ['Manuseio', formatarValor(p.valor_manuseio, 4)],
    ['Valor por página', formatarValor(p.valor_pagina, 4)],
    ['Valor da capa', formatarValor(p.valor_capa, 4)],
    ['Valor do shrink', formatarValor(p.valor_shrink, 4)],
    ['Peso líquido unit.', p.peso_liquido_unitario === null ? '—' : formatarValor(p.peso_liquido_unitario, 4)],
    ['Opção do orçamento', p.opcao_orcamento],
  ]
  if (ano !== ANO_BASE) {
    linhas.push([`Escolas em negociação ${ano}`, String(demanda?.escolas ?? 0)])
  }
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(230px, 1fr))', gap: '.6rem 1.5rem' }}>
      {linhas.map(([k, v]) => (
        <div key={k}>
          <div style={{ fontSize: '.6rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.06em', color: '#94a3b8', fontFamily: 'var(--font-montserrat,sans-serif)' }}>{k}</div>
          <div style={{ fontSize: '.8rem', color: '#221d37' }}>{v}</div>
        </div>
      ))}
      {p.observacoes && (
        <div style={{ gridColumn: '1 / -1' }}>
          <div style={{ fontSize: '.6rem', fontWeight: 700, textTransform: 'uppercase', color: '#94a3b8' }}>Observações</div>
          <div style={{ fontSize: '.8rem', color: '#221d37' }}>{p.observacoes}</div>
        </div>
      )}
    </div>
  )
}

/** Cadastro (produto = undefined) e edição (produto = linha) usam o mesmo formulário. */
function ProdutoModal({ produto, onClose }: { produto?: Produto; onClose: () => void }) {
  const router = useRouter()
  const [erro, setErro] = useState<string | null>(null)
  const [pending, startTransition] = useTransition()
  const editando = !!produto

  function salvar(formData: FormData) {
    setErro(null)
    startTransition(async () => {
      const res = produto ? await atualizarProduto(produto.id, formData) : await criarProduto(formData)
      if (res.success) {
        onClose()
        router.refresh()
      } else {
        setErro(res.error ?? 'Não foi possível salvar.')
      }
    })
  }

  const valorInicial = (campo: string) => {
    const v = produto ? (produto as unknown as Record<string, unknown>)[campo] : null
    return v === null || v === undefined ? '' : String(v)
  }

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 2000, background: 'rgba(15,12,26,.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1.5rem' }}>
      <div style={{ width: '100%', maxWidth: 760, maxHeight: '92vh', display: 'flex', flexDirection: 'column', background: '#fff', borderRadius: 4, boxShadow: '0 24px 64px rgba(0,0,0,.35)', overflow: 'hidden' }}>
        <div style={{ padding: '1.1rem 1.5rem', borderBottom: '1px solid #f1f5f9', background: '#fafafa' }}>
          <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.3rem', fontWeight: 700, color: '#221d37' }}>
            {editando ? 'Editar produto' : 'Cadastrar novo produto'}
          </div>
          <div style={{ fontSize: '.72rem', color: '#94a3b8', marginTop: '.2rem' }}>
            {editando
              ? produto!.titulo
              : 'Só o título é obrigatório. A série define em qual série do Registro o livro aparece como sugestão.'}
          </div>
        </div>

        <form action={salvar} style={{ padding: '1.5rem', overflowY: 'auto' }}>
          {GRUPOS_PRODUTO.map(g => (
            <fieldset key={g.titulo} style={{ border: 'none', padding: 0, margin: '0 0 1.25rem' }}>
              <legend style={{ fontSize: '.7rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.07em', color: '#221d37', fontFamily: 'var(--font-montserrat,sans-serif)', marginBottom: '.6rem' }}>
                {g.titulo}
              </legend>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '.85rem 1rem' }}>
                {g.campos.map(c => (
                  <div key={c.campo} style={c.largo ? { gridColumn: '1 / -1' } : undefined}>
                    <label style={lbl}>{c.label}{c.obrigatorio && <span style={{ color: '#36b6e8' }}> *</span>}</label>
                    {c.tipo === 'select' ? (
                      <select name={c.campo} defaultValue={valorInicial(c.campo)} style={inp}>
                        <option value="">—</option>
                        {c.opcoes?.map(o => {
                          const valor = typeof o === 'string' ? o : o.valor
                          const label = typeof o === 'string' ? o : o.label
                          return <option key={valor} value={valor}>{label}</option>
                        })}
                      </select>
                    ) : (
                      <input
                        name={c.campo}
                        type="text"
                        inputMode={c.tipo === 'text' ? undefined : 'decimal'}
                        defaultValue={valorInicial(c.campo)}
                        required={c.obrigatorio}
                        style={inp}
                      />
                    )}
                  </div>
                ))}
              </div>
            </fieldset>
          ))}

          <div style={{ marginBottom: '1.25rem' }}>
            <label style={lbl}>Observações</label>
            <textarea name="observacoes" rows={2} defaultValue={valorInicial('observacoes')} style={{ ...inp, resize: 'vertical' }} />
          </div>

          {erro && (
            <div style={{ marginBottom: '1rem', padding: '.6rem .8rem', borderRadius: 7, background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626', fontSize: '.75rem' }}>
              {erro}
            </div>
          )}

          <div style={{ display: 'flex', gap: '.6rem', justifyContent: 'flex-end' }}>
            <button type="button" onClick={onClose} disabled={pending}
              style={{ padding: '.55rem 1.1rem', borderRadius: 3, border: '1.5px solid #e2e8f0', background: '#fff', color: '#475569', fontSize: '.78rem', fontWeight: 700, cursor: 'pointer' }}>
              Cancelar
            </button>
            <button type="submit" disabled={pending}
              style={{ padding: '.55rem 1.4rem', borderRadius: 3, border: 'none', background: 'linear-gradient(135deg, #36b6e8, #12789f)', color: '#fff', fontSize: '.78rem', fontWeight: 700, cursor: pending ? 'wait' : 'pointer', opacity: pending ? .7 : 1 }}>
              {pending ? 'Salvando…' : editando ? 'Salvar alterações' : 'Salvar produto'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export function ProdutosCatalogo({ produtos, demandaPorAno }: { produtos: Produto[]; demandaPorAno: Record<number, Record<string, Demanda>> }) {
  const [ano, setAno] = useState(ANO_BASE)
  const demanda = demandaPorAno[ano] ?? {}
  const [busca, setBusca] = useState('')
  const [aberto, setAberto] = useState<string | null>(null)
  const [modal, setModal] = useState<{ produto?: Produto } | null>(null)

  const ehBase = ano === ANO_BASE

  // Quantidade do ano: no ano base é a tiragem da planilha; nos demais é a
  // demanda herdada dos Registros (somente leitura).
  const linhas = useMemo(() => {
    const q = busca.trim().toLowerCase()
    return produtos
      .filter(p => !q || `${p.titulo} ${nomeDaSerie(p.serie) ?? ''} ${p.publico ?? ''}`.toLowerCase().includes(q))
      .map(p => {
        const qtd = ehBase ? (p.tiragem_atualizada ?? p.tiragem ?? 0) : (demanda[p.id]?.alunos ?? 0)
        const custoUnit = (Number(p.valor_unitario) || 0) + (Number(p.valor_manuseio) || 0)
        return {
          p, qtd,
          totalCusto: custoUnit * qtd,
          totalVenda: p.valor_venda === null || p.valor_venda === undefined ? null : Number(p.valor_venda) * qtd,
        }
      })
  }, [produtos, demanda, busca, ehBase]) // eslint-disable-line react-hooks/exhaustive-deps

  const somaCusto = linhas.reduce((s, l) => s + l.totalCusto, 0)
  const somaVenda = linhas.reduce((s, l) => s + (l.totalVenda ?? 0), 0)
  const somaQtd = linhas.reduce((s, l) => s + l.qtd, 0)
  const colunas = 10

  return (
    <div>
      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem' }}>
          <span style={{ ...lbl, marginBottom: 0 }}>Ano letivo</span>
          <div style={{ display: 'inline-flex', border: '1.5px solid #e2e8f0', borderRadius: 7, overflow: 'hidden' }}>
            {ANOS.map(a => (
              <button key={a} type="button" onClick={() => { setAno(a); setAberto(null) }}
                style={{
                  padding: '.45rem .95rem', border: 'none', cursor: 'pointer', fontSize: '.8rem', fontWeight: 700,
                  background: a === ano ? '#221d37' : '#fff', color: a === ano ? '#fff' : '#475569',
                  fontFamily: 'var(--font-montserrat,sans-serif)',
                }}>
                {a}
              </button>
            ))}
          </div>
        </div>
        <input
          value={busca} onChange={e => setBusca(e.target.value)}
          placeholder="Buscar por título, série ou público…"
          style={{ ...inp, maxWidth: 340 }}
        />
        <span style={{ fontSize: '.78rem', color: '#64748b', fontFamily: 'var(--font-inter,sans-serif)' }}>
          {linhas.length} de {produtos.length} produtos
        </span>
        <button
          onClick={() => setModal({})}
          style={{
            marginLeft: 'auto', padding: '.5rem 1.1rem', borderRadius: 3, cursor: 'pointer', border: 'none',
            background: 'linear-gradient(135deg, #36b6e8, #12789f)', color: '#fff',
            fontSize: '.78rem', fontWeight: 700, fontFamily: 'var(--font-montserrat,sans-serif)', whiteSpace: 'nowrap',
          }}
        >
          + Cadastrar novo produto
        </button>
      </div>

      {!ehBase && (
        <div style={{ marginBottom: '1rem', padding: '.7rem 1rem', background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: 2, fontSize: '.78rem', color: '#1e40af', fontFamily: 'var(--font-inter,sans-serif)', lineHeight: 1.5 }}>
          <strong>{ano} herda os produtos de {ANO_BASE}.</strong> A quantidade não é digitada: vem dos Registros de
          negociação (alunos de cada série × livros escolhidos), usando o registro mais recente de cada escola.
          Os custos continuam os do orçamento de {ANO_BASE} até serem editados.
        </div>
      )}

      <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 1050 }}>
          <thead>
            <tr>
              <th style={th}>Título</th>
              <th style={th}>Série</th>
              <th style={{ ...th, ...num }}>Págs.</th>
              <th style={{ ...th, ...num }}>Qtd. {ano}{ehBase ? '' : ' (herdada)'}</th>
              <th style={{ ...th, ...num }}>Custo gráfica</th>
              <th style={{ ...th, ...num }}>Custo venda</th>
              <th style={{ ...th, ...num }}>Total gráfica</th>
              <th style={{ ...th, ...num }}>Total venda</th>
              <th style={th}></th>
              <th style={th}></th>
            </tr>
          </thead>
          <tbody>
            {linhas.length === 0 && (
              <tr><td colSpan={colunas} style={{ ...td, textAlign: 'center', color: '#94a3b8', padding: '2rem' }}>
                {produtos.length === 0
                  ? 'Nenhum produto ainda. Rode a migration add_catalogo_livros_e_series.sql ou cadastre o primeiro.'
                  : 'Nenhum produto encontrado.'}
              </td></tr>
            )}
            {linhas.map(({ p, qtd, totalCusto, totalVenda }) => (
              <Fragment key={p.id}>
                <tr>
                  <td style={{ ...td, fontWeight: 600, color: '#221d37' }}>{p.titulo}</td>
                  <td style={td}>{nomeDaSerie(p.serie) ?? '—'}</td>
                  <td style={{ ...td, ...num }}>{p.qtd_paginas ?? '—'}</td>
                  <td style={{ ...td, ...num, color: !ehBase && qtd === 0 ? '#94a3b8' : undefined }}>{qtd}</td>
                  <td style={{ ...td, ...num }}>{moeda(p.valor_unitario)}</td>
                  <td style={{ ...td, ...num, color: p.valor_venda == null ? '#94a3b8' : undefined }}>{moeda(p.valor_venda ?? null)}</td>
                  <td style={{ ...td, ...num, fontWeight: 600 }}>{moeda(totalCusto)}</td>
                  <td style={{ ...td, ...num, fontWeight: 600 }}>{moeda(totalVenda)}</td>
                  <td style={{ ...td, textAlign: 'center' }}>
                    <button type="button" title="Editar produto" aria-label={`Editar ${p.titulo}`}
                      onClick={() => setModal({ produto: p })}
                      style={{ border: '1px solid #e2e8f0', background: '#fff', borderRadius: 6, padding: '.3rem .4rem', cursor: 'pointer', color: '#12789f', display: 'inline-flex' }}>
                      <Pencil size={14} />
                    </button>
                  </td>
                  <td style={{ ...td, whiteSpace: 'nowrap' }}>
                    <button type="button" onClick={() => setAberto(aberto === p.id ? null : p.id)}
                      style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#36b6e8', fontWeight: 700, fontSize: '.8rem' }}>
                      {aberto === p.id ? 'Fechar ▲' : 'Ficha ▼'}
                    </button>
                  </td>
                </tr>
                {aberto === p.id && (
                  <tr><td colSpan={colunas} style={{ ...td, background: '#fafafa' }}><Ficha p={p} ano={ano} demanda={demanda[p.id]} /></td></tr>
                )}
              </Fragment>
            ))}
          </tbody>
          {linhas.length > 0 && (
            <tfoot>
              <tr>
                <td colSpan={3} style={{ ...td, ...num, fontWeight: 700 }}>Total {ano} exibido</td>
                <td style={{ ...td, ...num, fontWeight: 800, color: '#221d37' }}>{somaQtd}</td>
                <td colSpan={2} style={td}></td>
                <td style={{ ...td, ...num, fontWeight: 800, color: '#221d37' }}>{moeda(somaCusto)}</td>
                <td style={{ ...td, ...num, fontWeight: 800, color: '#221d37' }}>{somaVenda > 0 ? moeda(somaVenda) : '—'}</td>
                <td colSpan={2} style={td}></td>
              </tr>
            </tfoot>
          )}
        </table>
      </div>

      {modal && <ProdutoModal produto={modal.produto} onClose={() => setModal(null)} />}
    </div>
  )
}
