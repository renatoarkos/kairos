'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { atualizarMetas } from '@/components/comercial/metas-actions'
import type { Metas } from '@/lib/metas'

interface Props { metas: Metas }

const CAMPOS: { chave: keyof Metas; label: string; campo: string }[] = [
  { chave: 'metaReunioes',      label: 'Meta de Reuniões',       campo: 'meta_reunioes' },
  { chave: 'metaPropostas',     label: 'Meta de Propostas',      campo: 'meta_propostas' },
  { chave: 'metaMinutas',       label: 'Meta de Minutas',        campo: 'meta_minutas' },
  { chave: 'metaEscolasNovas',  label: 'Meta de Escolas Novas',  campo: 'meta_escolas_novas' },
  { chave: 'metaAlunos',        label: 'Meta de Alunos',         campo: 'meta_alunos' },
  { chave: 'metaReceita',       label: 'Meta de Receita (R$)',   campo: 'meta_receita' },
]

export function MetasForm({ metas }: Props) {
  const router = useRouter()
  const [aberto, setAberto] = useState(false)
  const [erro, setErro] = useState<string | null>(null)
  const [pending, startTransition] = useTransition()

  function salvar(formData: FormData) {
    setErro(null)
    startTransition(async () => {
      const res = await atualizarMetas(formData)
      if (res.success) {
        setAberto(false)
        router.refresh()
      } else {
        setErro(res.error ?? 'Não foi possível salvar.')
      }
    })
  }

  if (!aberto) {
    return (
      <button
        onClick={() => setAberto(true)}
        style={{
          padding: '.5rem 1rem', borderRadius: 3, cursor: 'pointer',
          border: '1.5px solid rgba(255,255,255,.25)', background: 'rgba(255,255,255,.08)',
          color: '#fff', fontSize: '.75rem', fontWeight: 700,
          fontFamily: 'var(--font-montserrat,sans-serif)', whiteSpace: 'nowrap',
        }}
      >
        ✎ Editar metas
      </button>
    )
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 2000, background: 'rgba(15,12,26,.55)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1.5rem',
    }}>
      <div style={{
        width: '100%', maxWidth: 520, background: '#fff', borderRadius: 4,
        boxShadow: '0 24px 64px rgba(0,0,0,.35)', overflow: 'hidden',
      }}>
        <div style={{ padding: '1.1rem 1.5rem', borderBottom: '1px solid #f1f5f9', background: '#fafafa' }}>
          <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.3rem', fontWeight: 700, color: '#221d37' }}>
            Editar Metas Comerciais
          </div>
          <div style={{ fontSize: '.72rem', color: '#94a3b8', fontFamily: 'var(--font-inter,sans-serif)', marginTop: '.2rem' }}>
            Esses números alimentam os KPIs de /comercial, /comercial/contratos, /comercial/funil-contratacao e esta página.
          </div>
        </div>

        <form action={salvar} style={{ padding: '1.5rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            {CAMPOS.map(c => (
              <div key={c.campo}>
                <label style={{ display: 'block', fontSize: '.68rem', fontWeight: 700, color: '#475569', marginBottom: '.3rem', fontFamily: 'var(--font-montserrat,sans-serif)' }}>
                  {c.label}
                </label>
                <input
                  name={c.campo}
                  type="number"
                  min={0}
                  step={c.chave === 'metaReceita' ? 1000 : 1}
                  defaultValue={metas[c.chave] as number}
                  required
                  style={{ width: '100%', padding: '.5rem .65rem', fontSize: '.85rem', border: '1.5px solid #e2e8f0', borderRadius: 7, boxSizing: 'border-box' }}
                />
              </div>
            ))}
          </div>

          <div style={{ marginBottom: '1.25rem' }}>
            <label style={{ display: 'block', fontSize: '.68rem', fontWeight: 700, color: '#475569', marginBottom: '.3rem', fontFamily: 'var(--font-montserrat,sans-serif)' }}>
              Prazo
            </label>
            <input
              name="prazo"
              type="date"
              defaultValue={metas.prazoISO}
              required
              style={{ width: '100%', padding: '.5rem .65rem', fontSize: '.85rem', border: '1.5px solid #e2e8f0', borderRadius: 7, boxSizing: 'border-box' }}
            />
          </div>

          {erro && (
            <div style={{ marginBottom: '1rem', padding: '.6rem .8rem', borderRadius: 7, background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626', fontSize: '.75rem', fontFamily: 'var(--font-inter,sans-serif)' }}>
              {erro}
            </div>
          )}

          <div style={{ display: 'flex', gap: '.6rem', justifyContent: 'flex-end' }}>
            <button
              type="button"
              onClick={() => { setAberto(false); setErro(null) }}
              disabled={pending}
              style={{ padding: '.55rem 1.1rem', borderRadius: 3, border: '1.5px solid #e2e8f0', background: '#fff', color: '#475569', fontSize: '.78rem', fontWeight: 700, cursor: 'pointer', fontFamily: 'var(--font-montserrat,sans-serif)' }}
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={pending}
              style={{ padding: '.55rem 1.1rem', borderRadius: 3, border: 'none', background: '#36b6e8', color: '#fff', fontSize: '.78rem', fontWeight: 700, cursor: pending ? 'wait' : 'pointer', fontFamily: 'var(--font-montserrat,sans-serif)' }}
            >
              {pending ? 'Salvando...' : 'Salvar metas'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
