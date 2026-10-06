'use client'

import { Fragment, useMemo, useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { criarProduto } from '@/components/comercial/produtos-actions'
import { GRUPOS_PRODUTO, formatarValor, type Produto } from '@/lib/produtos'
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

function Ficha({ p }: { p: Produto }) {
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
    ['Tiragem (atual)', `${p.tiragem ?? '—'} (${p.tiragem_atualizada ?? '—'})`],
    ['Manuseio', formatarValor(p.valor_manuseio, 4)],
    ['Valor por página', formatarValor(p.valor_pagina, 4)],
    ['Valor da capa', formatarValor(p.valor_capa, 4)],
    ['Valor do shrink', formatarValor(p.valor_shrink, 4)],
    ['Peso líquido unit.', p.peso_liquido_unitario === null ? '—' : formatarValor(p.peso_liquido_unitario, 4)],
    ['Opção do orçamento', p.opcao_orcamento],
  ]
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

function NovoProduto() {
  const router = useRouter()
  const [aberto, setAberto] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const [pending, startTransition] = useTransition()

  function salvar(formData: FormData) {
    setErro(null)
    startTransition(async () => {
      const res = await criarProduto(formData)
      if (res.success) {
        setAberto(false)
        router.refresh()
      } else {
        setErro(res.error ?? 'Não foi possível salvar.')
      }
    })
  }

  return (
    <>
      <button
        onClick={() => setAberto(true)}
        style={{
          padding: '.5rem 1.1rem', borderRadius: 3, cursor: 'pointer', border: 'none',
          background: 'linear-gradient(135deg, #36b6e8, #12789f)', color: '#fff',
          fontSize: '.78rem', fontWeight: 700, fontFamily: 'var(--font-montserrat,sans-serif)', whiteSpace: 'nowrap',
        }}
      >
        + Cadastrar novo produto
      </button>

      {aberto && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 2000, background: 'rgba(15,12,26,.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1.5rem' }}>
          <div style={{ width: '100%', maxWidth: 760, maxHeight: '92vh', display: 'flex', flexDirection: 'column', background: '#fff', borderRadius: 4, boxShadow: '0 24px 64px rgba(0,0,0,.35)', overflow: 'hidden' }}>
            <div style={{ padding: '1.1rem 1.5rem', borderBottom: '1px solid #f1f5f9', background: '#fafafa' }}>
              <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.3rem', fontWeight: 700, color: '#221d37' }}>Cadastrar novo produto</div>
              <div style={{ fontSize: '.72rem', color: '#94a3b8', marginTop: '.2rem' }}>
                Só o título é obrigatório. A série define em qual série do Registro o livro aparece como sugestão.
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
                          <select name={c.campo} defaultValue="" style={inp}>
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
                <textarea name="observacoes" rows={2} style={{ ...inp, resize: 'vertical' }} />
              </div>

              {erro && (
                <div style={{ marginBottom: '1rem', padding: '.6rem .8rem', borderRadius: 7, background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626', fontSize: '.75rem' }}>
                  {erro}
                </div>
              )}

              <div style={{ display: 'flex', gap: '.6rem', justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => { setAberto(false); setErro(null) }} disabled={pending}
                  style={{ padding: '.55rem 1.1rem', borderRadius: 3, border: '1.5px solid #e2e8f0', background: '#fff', color: '#475569', fontSize: '.78rem', fontWeight: 700, cursor: 'pointer' }}>
                  Cancelar
                </button>
                <button type="submit" disabled={pending}
                  style={{ padding: '.55rem 1.4rem', borderRadius: 3, border: 'none', background: 'linear-gradient(135deg, #36b6e8, #12789f)', color: '#fff', fontSize: '.78rem', fontWeight: 700, cursor: pending ? 'wait' : 'pointer', opacity: pending ? .7 : 1 }}>
                  {pending ? 'Salvando…' : 'Salvar produto'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}

export function ProdutosCatalogo({ produtos }: { produtos: Produto[] }) {
  const [busca, setBusca] = useState('')
  const [aberto, setAberto] = useState<string | null>(null)

  const filtrados = useMemo(() => {
    const q = busca.trim().toLowerCase()
    if (!q) return produtos
    return produtos.filter(p => `${p.titulo} ${nomeDaSerie(p.serie) ?? ''} ${p.publico ?? ''}`.toLowerCase().includes(q))
  }, [produtos, busca])

  const totalGeral = filtrados.reduce((s, p) => s + (p.valor_total ?? 0), 0)

  return (
    <div>
      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <input
          value={busca} onChange={e => setBusca(e.target.value)}
          placeholder="Buscar por título, série ou público…"
          style={{ ...inp, maxWidth: 380 }}
        />
        <span style={{ fontSize: '.78rem', color: '#64748b', fontFamily: 'var(--font-inter,sans-serif)' }}>
          {filtrados.length} de {produtos.length} produtos
        </span>
        <div style={{ marginLeft: 'auto' }}><NovoProduto /></div>
      </div>

      <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 880 }}>
          <thead>
            <tr>
              <th style={th}>Título</th>
              <th style={th}>Série</th>
              <th style={th}>Público</th>
              <th style={{ ...th, textAlign: 'right' }}>Págs.</th>
              <th style={{ ...th, textAlign: 'right' }}>Tiragem</th>
              <th style={{ ...th, textAlign: 'right' }}>Valor unit.</th>
              <th style={{ ...th, textAlign: 'right' }}>Valor total</th>
              <th style={th}></th>
            </tr>
          </thead>
          <tbody>
            {filtrados.length === 0 && (
              <tr><td colSpan={8} style={{ ...td, textAlign: 'center', color: '#94a3b8', padding: '2rem' }}>
                {produtos.length === 0
                  ? 'Nenhum produto ainda. Rode a migration add_catalogo_livros_e_series.sql ou cadastre o primeiro.'
                  : 'Nenhum produto encontrado.'}
              </td></tr>
            )}
            {filtrados.map(p => (
              <Fragment key={p.id}>
                <tr onClick={() => setAberto(aberto === p.id ? null : p.id)} style={{ cursor: 'pointer' }}>
                  <td style={{ ...td, fontWeight: 600, color: '#221d37' }}>{p.titulo}</td>
                  <td style={td}>{nomeDaSerie(p.serie) ?? '—'}</td>
                  <td style={td}>{p.publico ?? '—'}</td>
                  <td style={{ ...td, textAlign: 'right' }}>{p.qtd_paginas ?? '—'}</td>
                  <td style={{ ...td, textAlign: 'right' }}>{p.tiragem_atualizada ?? p.tiragem ?? '—'}</td>
                  <td style={{ ...td, textAlign: 'right' }}>{p.valor_unitario === null ? '—' : formatCurrency(p.valor_unitario)}</td>
                  <td style={{ ...td, textAlign: 'right', fontWeight: 600 }}>{p.valor_total === null ? '—' : formatCurrency(p.valor_total)}</td>
                  <td style={{ ...td, color: '#36b6e8', fontWeight: 700, whiteSpace: 'nowrap' }}>{aberto === p.id ? 'Fechar ▲' : 'Ficha ▼'}</td>
                </tr>
                {aberto === p.id && (
                  <tr><td colSpan={8} style={{ ...td, background: '#fafafa' }}><Ficha p={p} /></td></tr>
                )}
              </Fragment>
            ))}
          </tbody>
          {filtrados.length > 0 && (
            <tfoot>
              <tr>
                <td colSpan={6} style={{ ...td, textAlign: 'right', fontWeight: 700 }}>Total do orçamento exibido</td>
                <td style={{ ...td, textAlign: 'right', fontWeight: 800, color: '#221d37' }}>{formatCurrency(totalGeral)}</td>
                <td style={td}></td>
              </tr>
            </tfoot>
          )}
        </table>
      </div>
    </div>
  )
}
