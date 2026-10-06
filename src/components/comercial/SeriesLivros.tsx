'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { SEGMENTOS } from '@/lib/series'

export interface ProdutoOpcao {
  id: string
  titulo: string
  serie: string | null
  publico: string | null
}

interface Props {
  produtos: ProdutoOpcao[]
  /** quantidade de alunos por código de série (ex.: { infantil2: 30 }) */
  qtdInicial?: Record<string, number>
  /** ids de livros já escolhidos por série (edição de registro) */
  livrosIniciais?: Record<string, string[]>
  /** totais antigos por segmento, usados só se nenhuma série for preenchida */
  totaisLegados?: Record<string, number>
}

const lbl: React.CSSProperties = {
  display: 'block', fontFamily: 'var(--font-montserrat,sans-serif)',
  fontSize: '.6rem', fontWeight: 700, textTransform: 'uppercase',
  letterSpacing: '.06em', color: '#64748b', marginBottom: '.3rem',
}
const inp: React.CSSProperties = {
  width: '100%', padding: '.45rem .5rem', fontSize: '.875rem', textAlign: 'center',
  fontFamily: 'var(--font-inter,sans-serif)', border: '1.5px solid #e2e8f0',
  borderRadius: 2, background: '#fff', color: '#221d37', outline: 'none', boxSizing: 'border-box',
}

export function SeriesLivros({ produtos, qtdInicial = {}, livrosIniciais = {}, totaisLegados = {} }: Props) {
  const [qtd, setQtd] = useState<Record<string, string>>(
    () => Object.fromEntries(Object.entries(qtdInicial).map(([k, v]) => [k, String(v ?? 0)])),
  )
  const [livros, setLivros] = useState<Record<string, string[]>>(livrosIniciais)

  const porId = useMemo(() => new Map(produtos.map(p => [p.id, p])), [produtos])

  const adicionar = (serie: string, id: string) =>
    setLivros(l => (l[serie]?.includes(id) ? l : { ...l, [serie]: [...(l[serie] ?? []), id] }))
  const remover = (serie: string, id: string) =>
    setLivros(l => ({ ...l, [serie]: (l[serie] ?? []).filter(x => x !== id) }))
  const marcarSugeridos = (serie: string) =>
    setLivros(l => {
      const atuais = new Set(l[serie] ?? [])
      produtos.filter(p => p.serie === serie).forEach(p => atuais.add(p.id))
      return { ...l, [serie]: [...atuais] }
    })

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {produtos.length === 0 && (
        <div style={{ padding: '.75rem 1rem', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 2, fontSize: '.78rem', color: '#92400e', fontFamily: 'var(--font-inter,sans-serif)' }}>
          O catálogo de livros está vazio. Rode a migration <strong>add_catalogo_livros_e_series.sql</strong> ou
          cadastre produtos em <Link href="/comercial/produtos" style={{ color: '#92400e', fontWeight: 700 }}>Produtos</Link>.
        </div>
      )}

      {SEGMENTOS.map(seg => {
        const totalSegmento = seg.series.reduce((s, x) => s + (parseInt(qtd[x.codigo] ?? '0') || 0), 0)
        const legado = totaisLegados[seg.totalCampo] ?? 0
        return (
          <div key={seg.id} style={{ background: seg.cor.fundo, border: `1px solid ${seg.cor.borda}`, borderRadius: 3, padding: '1rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '.75rem' }}>
              <span style={{ ...lbl, color: seg.cor.titulo, fontSize: '.7rem', marginBottom: 0 }}>{seg.label}</span>
              <span style={{ fontSize: '.7rem', fontWeight: 700, color: seg.cor.destaque, fontFamily: 'var(--font-montserrat,sans-serif)' }}>
                {totalSegmento > 0 || legado === 0
                  ? `${totalSegmento} alunos`
                  : `${legado} alunos (total anterior, sem detalhe por série)`}
              </span>
            </div>
            {/* total antigo do segmento: preserva registros anteriores às séries */}
            <input type="hidden" name={seg.totalCampo} value={legado} />

            <div style={{ display: 'flex', flexDirection: 'column', gap: '.65rem' }}>
              {seg.series.map(serie => {
                const escolhidos = livros[serie.codigo] ?? []
                const sugeridos = produtos.filter(p => p.serie === serie.codigo && !escolhidos.includes(p.id))
                const avulsos   = produtos.filter(p => !p.serie && !escolhidos.includes(p.id))
                const outros    = produtos.filter(p => p.serie && p.serie !== serie.codigo && !escolhidos.includes(p.id))
                return (
                  <div key={serie.codigo} style={{ background: '#fff', border: `1px solid ${seg.cor.borda}`, borderRadius: 3, padding: '.75rem' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '90px 110px 1fr', gap: '.75rem', alignItems: 'start' }}>
                      <div style={{ fontSize: '.8rem', fontWeight: 700, color: seg.cor.titulo, fontFamily: 'var(--font-montserrat,sans-serif)', paddingTop: '1.35rem' }}>
                        {serie.label}
                      </div>
                      <div>
                        <label style={lbl}>Alunos</label>
                        <input
                          name={`qtd_${serie.codigo}`} type="number" min="0"
                          value={qtd[serie.codigo] ?? '0'}
                          onChange={e => setQtd(q => ({ ...q, [serie.codigo]: e.target.value }))}
                          style={inp}
                        />
                      </div>
                      <div>
                        <label style={lbl}>Livros desta série ({escolhidos.length})</label>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '.35rem', marginBottom: escolhidos.length ? '.5rem' : 0 }}>
                          {escolhidos.map(id => (
                            <span key={id} style={{
                              display: 'inline-flex', alignItems: 'center', gap: '.35rem',
                              padding: '.25rem .35rem .25rem .6rem', borderRadius: 999,
                              background: seg.cor.fundo, border: `1px solid ${seg.cor.borda}`,
                              fontSize: '.72rem', color: seg.cor.titulo, fontFamily: 'var(--font-inter,sans-serif)',
                            }}>
                              {porId.get(id)?.titulo ?? 'Livro removido do catálogo'}
                              <button type="button" onClick={() => remover(serie.codigo, id)} aria-label="Remover livro"
                                style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: seg.cor.destaque, fontWeight: 800, fontSize: '.85rem', lineHeight: 1, padding: '0 .15rem' }}>
                                ×
                              </button>
                              <input type="hidden" name={`livros_${serie.codigo}`} value={id} />
                            </span>
                          ))}
                        </div>
                        <div style={{ display: 'flex', gap: '.5rem', flexWrap: 'wrap' }}>
                          <select
                            value=""
                            onChange={e => { if (e.target.value) adicionar(serie.codigo, e.target.value) }}
                            disabled={produtos.length === 0}
                            style={{ ...inp, textAlign: 'left', width: 'auto', flex: '1 1 220px', fontSize: '.78rem' }}
                          >
                            <option value="">+ Adicionar livro…</option>
                            {sugeridos.length > 0 && (
                              <optgroup label={`Livros de ${serie.label}`}>
                                {sugeridos.map(p => <option key={p.id} value={p.id}>{p.titulo}</option>)}
                              </optgroup>
                            )}
                            {avulsos.length > 0 && (
                              <optgroup label="Guias e livros sem série">
                                {avulsos.map(p => <option key={p.id} value={p.id}>{p.titulo}</option>)}
                              </optgroup>
                            )}
                            {outros.length > 0 && (
                              <optgroup label="Outras séries">
                                {outros.map(p => <option key={p.id} value={p.id}>{p.titulo}</option>)}
                              </optgroup>
                            )}
                          </select>
                          {produtos.some(p => p.serie === serie.codigo) && (
                            <button type="button" onClick={() => marcarSugeridos(serie.codigo)}
                              style={{ padding: '.4rem .75rem', borderRadius: 2, border: `1.5px solid ${seg.cor.borda}`, background: '#fff', color: seg.cor.titulo, fontSize: '.72rem', fontWeight: 700, cursor: 'pointer', fontFamily: 'var(--font-montserrat,sans-serif)' }}>
                              Marcar todos da série
                            </button>
                          )}
                        </div>
                        {!produtos.some(p => p.serie === serie.codigo) && (
                          <div style={{ marginTop: '.4rem', fontSize: '.68rem', color: '#94a3b8', fontFamily: 'var(--font-inter,sans-serif)' }}>
                            Nenhum livro cadastrado para esta série ainda.{' '}
                            <Link href="/comercial/produtos" style={{ color: seg.cor.destaque, fontWeight: 700 }}>Cadastrar novo produto</Link>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )
      })}
    </div>
  )
}
