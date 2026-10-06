// Séries atendidas pela Kairós, da Educação Infantil ao 3º ano do Ensino Médio.
// `codigo` é o mesmo sufixo das colunas `qtd_<codigo>` em `escolas` e
// `registros`, e o valor gravado em `produtos_livros.serie` e
// `registro_serie_livros.serie` — uma fonte única pro formulário, a server
// action e o banco.

export interface Serie { codigo: string; label: string }

export interface Segmento {
  id: 'infantil' | 'fund1' | 'fund2' | 'medio'
  label: string
  totalCampo: string // coluna agregada que já existe em registros/escolas
  cor: { fundo: string; borda: string; titulo: string; destaque: string }
  series: Serie[]
}

export const SEGMENTOS: Segmento[] = [
  {
    id: 'infantil', label: 'Educação Infantil', totalCampo: 'qtd_infantil',
    cor: { fundo: '#fff7ed', borda: '#fed7aa', titulo: '#9a3412', destaque: '#ea580c' },
    series: [
      { codigo: 'infantil2', label: 'Infantil 2' },
      { codigo: 'infantil3', label: 'Infantil 3' },
      { codigo: 'infantil4', label: 'Infantil 4' },
      { codigo: 'infantil5', label: 'Infantil 5' },
    ],
  },
  {
    id: 'fund1', label: 'Fundamental I', totalCampo: 'qtd_fund1',
    cor: { fundo: '#eff6ff', borda: '#bfdbfe', titulo: '#1e40af', destaque: '#2563eb' },
    series: [
      { codigo: 'fund1_ano1', label: '1º ano' },
      { codigo: 'fund1_ano2', label: '2º ano' },
      { codigo: 'fund1_ano3', label: '3º ano' },
      { codigo: 'fund1_ano4', label: '4º ano' },
      { codigo: 'fund1_ano5', label: '5º ano' },
    ],
  },
  {
    id: 'fund2', label: 'Fundamental II', totalCampo: 'qtd_fund2',
    cor: { fundo: '#f0fdf4', borda: '#bbf7d0', titulo: '#166534', destaque: '#16a34a' },
    series: [
      { codigo: 'fund2_ano6', label: '6º ano' },
      { codigo: 'fund2_ano7', label: '7º ano' },
      { codigo: 'fund2_ano8', label: '8º ano' },
      { codigo: 'fund2_ano9', label: '9º ano' },
    ],
  },
  {
    id: 'medio', label: 'Ensino Médio', totalCampo: 'qtd_medio',
    cor: { fundo: '#faf5ff', borda: '#e9d5ff', titulo: '#6b21a8', destaque: '#9333ea' },
    series: [
      { codigo: 'medio_1s', label: '1ª série' },
      { codigo: 'medio_2s', label: '2ª série' },
      { codigo: 'medio_3s', label: '3ª série' },
    ],
  },
]

export const SERIES: (Serie & { segmento: Segmento['id'] })[] =
  SEGMENTOS.flatMap(s => s.series.map(x => ({ ...x, segmento: s.id })))

export const nomeDaSerie = (codigo: string | null | undefined) =>
  SERIES.find(s => s.codigo === codigo)?.label ?? null
