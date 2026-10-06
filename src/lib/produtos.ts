import { SEGMENTOS } from '@/lib/series'

// Catálogo de livros — tabela `produtos_livros` (migrations/add_catalogo_livros_e_series.sql).
// Carga inicial: planilha "2309 Kairos Educacional.xlsx". Cadastro de novos
// produtos em /comercial/produtos (ProdutosCatalogo.tsx + produtos-actions.ts).

export interface Produto {
  id: string
  opcao_orcamento: string
  titulo: string
  serie: string | null
  publico: string | null
  largura_mm: number | null
  altura_mm: number | null
  formato_fechado: string | null
  papel_capa: string | null
  gramatura_capa: number | null
  cor_capa: string | null
  enobrecimento: string | null
  papelao: string | null
  forro: string | null
  papel_miolo: string | null
  gramatura_miolo: number | null
  cor_miolo: string | null
  qtd_paginas: number | null
  acabamento: string | null
  shrink: number | null
  tipo_venda: string | null
  tiragem: number | null
  tiragem_atualizada: number | null
  valor_manuseio: number | null
  valor_pagina: number | null
  valor_capa: number | null
  valor_shrink: number | null
  valor_unitario: number | null
  peso_liquido_unitario: number | null
  valor_total: number | null
  observacoes: string | null
  ativo: boolean
}

export type CampoProduto = {
  campo: string
  label: string
  tipo: 'text' | 'int' | 'money' | 'select'
  opcoes?: (string | { valor: string; label: string })[]
  obrigatorio?: boolean
  largo?: boolean
}

export const GRUPOS_PRODUTO: { titulo: string; campos: CampoProduto[] }[] = [
  {
    titulo: 'Identificação',
    campos: [
      { campo: 'titulo', label: 'Título / descrição', tipo: 'text', obrigatorio: true, largo: true },
      {
        campo: 'serie', label: 'Série', tipo: 'select',
        opcoes: SEGMENTOS.flatMap(seg => seg.series.map(x => ({ valor: x.codigo, label: `${seg.label} — ${x.label}` }))),
      },
      { campo: 'publico', label: 'Público', tipo: 'select', opcoes: ['Aluno', 'Professor'] },
      { campo: 'tipo_venda', label: 'Kit / avulso', tipo: 'select', opcoes: ['Avulso', 'Kit'] },
      { campo: 'opcao_orcamento', label: 'Opção do orçamento', tipo: 'text' },
    ],
  },
  {
    titulo: 'Formato',
    campos: [
      { campo: 'largura_mm', label: 'Largura (mm)', tipo: 'int' },
      { campo: 'altura_mm', label: 'Altura (mm)', tipo: 'int' },
      { campo: 'formato_fechado', label: 'Formato fechado (mm)', tipo: 'text' },
    ],
  },
  {
    titulo: 'Capa',
    campos: [
      { campo: 'papel_capa', label: 'Papel da capa', tipo: 'text' },
      { campo: 'gramatura_capa', label: 'Gramatura (g/m²)', tipo: 'int' },
      { campo: 'cor_capa', label: 'Cor da capa', tipo: 'text' },
      { campo: 'enobrecimento', label: 'Enobrecimento', tipo: 'text' },
      { campo: 'papelao', label: 'Papelão', tipo: 'text' },
      { campo: 'forro', label: 'Forro', tipo: 'text' },
    ],
  },
  {
    titulo: 'Miolo e acabamento',
    campos: [
      { campo: 'papel_miolo', label: 'Papel do miolo', tipo: 'text' },
      { campo: 'gramatura_miolo', label: 'Gramatura (g/m²)', tipo: 'int' },
      { campo: 'cor_miolo', label: 'Cor do miolo', tipo: 'text' },
      { campo: 'qtd_paginas', label: 'Qtd. de páginas', tipo: 'int' },
      { campo: 'acabamento', label: 'Acabamento', tipo: 'text', largo: true },
      { campo: 'shrink', label: 'Shrink', tipo: 'int' },
    ],
  },
  {
    titulo: 'Tiragem e valores',
    campos: [
      { campo: 'tiragem', label: 'Tiragem', tipo: 'int' },
      { campo: 'tiragem_atualizada', label: 'Tiragem atualizada', tipo: 'int' },
      { campo: 'valor_manuseio', label: 'Valor manuseio (R$)', tipo: 'money' },
      { campo: 'valor_pagina', label: 'Valor página (R$)', tipo: 'money' },
      { campo: 'valor_capa', label: 'Valor capa (R$)', tipo: 'money' },
      { campo: 'valor_shrink', label: 'Valor shrink (R$)', tipo: 'money' },
      { campo: 'valor_unitario', label: 'Valor unitário (R$)', tipo: 'money' },
      { campo: 'peso_liquido_unitario', label: 'Peso líquido unitário', tipo: 'money' },
    ],
  },
]

export function formatarValor(v: number | null | undefined, casas = 2): string {
  if (v === null || v === undefined) return '—'
  return Number(v).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: casas })
}
