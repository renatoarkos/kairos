import PageHeader from '@/components/layout/PageHeader'

export default function SobrePage() {
  return (
    <div>
      <PageHeader title="A Plataforma" subtitle="Kairós Gestão Comercial · Kairós" />
      <div style={{ padding: '2rem 2.5rem', maxWidth: 960, margin: '0 auto' }}>

        {/* ── HERO ──────────────────────────────────────────────── */}
        <div style={{
          background: 'linear-gradient(135deg, #221d37 0%, #2d284a 100%)',
          borderRadius: 6, padding: '2.5rem 3rem', marginBottom: '2rem',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 200, height: 200, borderRadius: '50%', background: 'rgba(54,182,232,.08)', pointerEvents: 'none' }} />
          <div style={{ position: 'absolute', bottom: -60, right: 80, width: 140, height: 140, borderRadius: '50%', background: 'rgba(54,182,232,.05)', pointerEvents: 'none' }} />

          <div style={{ position: 'relative', zIndex: 1, maxWidth: 640 }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '.4rem', background: 'rgba(54,182,232,.15)', border: '1px solid rgba(54,182,232,.3)', borderRadius: 3, padding: '.3rem .85rem', marginBottom: '1.25rem' }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#36b6e8' }} />
              <span style={{ fontSize: '.65rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.1em', color: '#36b6e8', fontFamily: 'var(--font-montserrat,sans-serif)' }}>
                Plataforma Interna · Equipe Comercial
              </span>
            </div>
            <h1 style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: 'clamp(1.6rem, 3vw, 2.2rem)', fontWeight: 700, color: '#fff', lineHeight: 1.15, marginBottom: '.85rem' }}>
              Gestão comercial inteligente<br />
              <span style={{ color: '#36b6e8' }}>para transformar parcerias em impacto</span>
            </h1>
            <p style={{ fontSize: '.9rem', color: 'rgba(255,255,255,.65)', lineHeight: 1.7, fontFamily: 'var(--font-inter,sans-serif)', maxWidth: 520 }}>
              O Kairós Gestão Comercial foi desenvolvido exclusivamente para a equipe da Kairós. Centraliza escolas, negociações, contratos e análises em um único ambiente seguro, ágil e focado em resultados.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '2rem', marginTop: '2rem', flexWrap: 'wrap', position: 'relative', zIndex: 1 }}>
            {[
              ['11', 'módulos integrados'],
              ['360°', 'visão do parceiro'],
              ['Real-time', 'indicadores'],
              ['Seguro', 'acesso por perfil'],
            ].map(([val, sub]) => (
              <div key={val}>
                <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.5rem', fontWeight: 800, color: '#36b6e8', lineHeight: 1 }}>{val}</div>
                <div style={{ fontSize: '.68rem', color: 'rgba(255,255,255,.4)', fontFamily: 'var(--font-montserrat,sans-serif)', marginTop: '.2rem', textTransform: 'uppercase', letterSpacing: '.05em' }}>{sub}</div>
              </div>
            ))}
          </div>
        </div>

        {/* ── PROPÓSITO + JUSTIFICATIVA ────────────────────────── */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem', marginBottom: '1.25rem' }}>
          <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, padding: '1.75rem', boxShadow: '0 2px 8px rgba(34,29,55,.05)', borderTop: '3px solid #36b6e8' }}>
            <div style={{ width: 40, height: 40, borderRadius: 2, background: '#fffbeb', border: '1px solid #fcd34d', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem' }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>
            </div>
            <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.68rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#36b6e8', marginBottom: '.5rem' }}>
              Propósito
            </div>
            <h3 style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.15rem', fontWeight: 700, color: '#221d37', marginBottom: '.65rem', lineHeight: 1.25 }}>
              Centralizar para decidir melhor
            </h3>
            <p style={{ fontSize: '.85rem', color: '#475569', lineHeight: 1.7, fontFamily: 'var(--font-inter,sans-serif)' }}>
              Toda a gestão de propostas, registros de negociações e indicadores de desempenho em um único ambiente. A equipe ganha visão clara das oportunidades e toma decisões estratégicas com base em dados reais.
            </p>
          </div>

          <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, padding: '1.75rem', boxShadow: '0 2px 8px rgba(34,29,55,.05)', borderTop: '3px solid #221d37' }}>
            <div style={{ width: 40, height: 40, borderRadius: 2, background: '#f8fafc', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem' }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
            </div>
            <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.68rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#221d37', marginBottom: '.5rem' }}>
              Por que foi criado
            </div>
            <h3 style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.15rem', fontWeight: 700, color: '#221d37', marginBottom: '.65rem', lineHeight: 1.25 }}>
              Controle, padronização e agilidade
            </h3>
            <p style={{ fontSize: '.85rem', color: '#475569', lineHeight: 1.7, fontFamily: 'var(--font-inter,sans-serif)' }}>
              Sem um sistema único, a equipe perdia tempo com retrabalho e informações espalhadas. Esta plataforma padroniza os processos comerciais, aumenta a agilidade no atendimento e garante rastreabilidade em cada etapa da jornada de parceria.
            </p>
          </div>
        </div>

        {/* ── FUNCIONALIDADES ─────────────────────────────────── */}
        <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, padding: '1.75rem', boxShadow: '0 2px 8px rgba(34,29,55,.05)', marginBottom: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', marginBottom: '1.5rem' }}>
            <div style={{ width: 40, height: 40, borderRadius: 2, background: '#fffbeb', border: '1px solid #fcd34d', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
            </div>
            <div>
              <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.68rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#36b6e8' }}>Módulos Disponíveis</div>
              <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.15rem', fontWeight: 700, color: '#221d37' }}>Tudo que você precisa para vender mais</div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '.75rem' }}>
            {[
              { title: 'Cadastro de Escolas', desc: 'Ficha completa com dados, contatos, perfil pedagógico e alunos por série.' },
              { title: 'Registro de Negociação', desc: 'Documente reuniões e interações com diagnóstico de interesse e prontidão.' },
              { title: 'Dashboard Comercial', desc: 'KPIs ao vivo: leads, potencial financeiro, registros e tarefas da equipe.' },
              { title: 'Jornada de Relacionamento', desc: 'Linha do tempo visual de todo o histórico com cada escola parceira.' },
              { title: 'Jornada Contratual', desc: 'Checklist de progresso com metas de alunos e receita para 2026.' },
              { title: 'Pipeline Kanban', desc: 'Negociações por estágio e por consultor em quadros visuais organizados.' },
              { title: 'Calculadora de Precificação', desc: 'Precificação por segmento com taxas, comissão e manutenção calculados.' },
              { title: 'Downloads', desc: 'Ficha cadastral, minuta do contrato e exportação dos formulários.' },
              { title: 'Formulário para Escolas', desc: 'Página pública para escolas iniciarem o pré-cadastro sem precisar de login.' },
            ].map(f => (
              <div key={f.title} style={{ background: '#f8fafc', border: '1px solid #f1f5f9', borderRadius: 3, padding: '1rem 1.1rem' }}>
                <div style={{ marginBottom: '.5rem' }}>
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
                  </svg>
                </div>
                <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.78rem', fontWeight: 700, color: '#221d37', marginBottom: '.3rem' }}>{f.title}</div>
                <div style={{ fontSize: '.72rem', color: '#64748b', lineHeight: 1.55, fontFamily: 'var(--font-inter,sans-serif)' }}>{f.desc}</div>
              </div>
            ))}
          </div>
        </div>

        {/* ── MISSÃO, VISÃO E VALORES ─────────────────────────── */}
        <div style={{ background: 'linear-gradient(135deg, #221d37, #2d284a)', borderRadius: 4, padding: '1.75rem 2rem', marginBottom: '1.25rem' }}>
          <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.68rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#36b6e8', marginBottom: '1.25rem' }}>
            Identidade da Kairós
          </div>
          {/* Quem somos — frase institucional */}
          <div style={{ background: 'rgba(135,205,232,.06)', borderRadius: 3, padding: '1.25rem 1.5rem', borderLeft: '3px solid #87cde8', marginBottom: '1.5rem' }}>
            <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.65rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#87cde8', marginBottom: '.5rem' }}>Quem somos</div>
            <p style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.05rem', fontStyle: 'italic', color: '#fff', lineHeight: 1.55 }}>
              Kairós — <em>“nós fazemos”</em> — é uma empresa criada com o objetivo de pensar, estudar, produzir e ensinar tecnologia a partir da Cosmovisão Cristã, com comprometimento com uma educação escolar distintamente cristã, que prima pela Verdade, Beleza e Bondade.
            </p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '1.75rem' }}>
            <div style={{ background: 'rgba(255,255,255,.05)', borderRadius: 3, padding: '1.25rem', borderLeft: '3px solid #36b6e8' }}>
              <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.65rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#36b6e8', marginBottom: '.5rem' }}>Missão</div>
              <p style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.05rem', fontStyle: 'italic', color: '#fff', lineHeight: 1.55 }}>
                Promover uma Educação Tecnológica de excelência, pensando, estudando, produzindo e ensinando tecnologia com liberdade e responsabilidade em resposta a Deus.
              </p>
            </div>
            <div style={{ background: 'rgba(255,255,255,.05)', borderRadius: 3, padding: '1.25rem', borderLeft: '3px solid rgba(255,255,255,.2)' }}>
              <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.65rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: 'rgba(255,255,255,.5)', marginBottom: '.5rem' }}>Visão</div>
              <p style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.05rem', fontStyle: 'italic', color: 'rgba(255,255,255,.8)', lineHeight: 1.55 }}>
                Ser uma empresa de referência em Educação Tecnológica fundamentada na Cosmovisão Cristã.
              </p>
            </div>
          </div>

          <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.65rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: 'rgba(255,255,255,.4)', marginBottom: '1rem' }}>
            Valores
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}>
            {[
              { eixo: 'Cosmovisão Cristã',    cor: '#87cde8', desc: 'Toda atividade humana parte da resposta a Deus, criador e mantenedor de todas as coisas.' },
              { eixo: 'Mordomia',             cor: '#36b6e8', desc: 'Cuidado responsável e consciente dos recursos, talentos e tempo confiados a nós.' },
              { eixo: 'Inovação Criacional',  cor: '#34d399', desc: 'Inovar com criatividade e propósito, refletindo o caráter criador de Deus.' },
              { eixo: 'Transformação Integral', cor: '#c084fc', desc: 'Formação completa que alcança a pessoa em todas as suas dimensões.' },
            ].map(e => (
              <div key={e.eixo} style={{ background: 'rgba(255,255,255,.04)', borderRadius: 2, padding: '1rem', borderTop: `2px solid ${e.cor}` }}>
                <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.7rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.07em', color: e.cor, marginBottom: '.5rem' }}>{e.eixo}</div>
                <div style={{ fontSize: '.78rem', color: 'rgba(255,255,255,.7)', lineHeight: 1.55, fontFamily: 'var(--font-inter,sans-serif)' }}>{e.desc}</div>
              </div>
            ))}
          </div>

          {/* Mandato Cultural — citação de fechamento */}
          <div style={{ marginTop: '1.5rem', padding: '1rem 1.25rem', background: 'rgba(255,255,255,.03)', borderRadius: 2, borderLeft: '2px solid rgba(255,255,255,.2)' }}>
            <p style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '.95rem', fontStyle: 'italic', color: 'rgba(255,255,255,.6)', lineHeight: 1.6, margin: 0 }}>
              Compreendemos a tecnologia não como um fim em si mesma, mas como parte do Mandato Cultural.
            </p>
          </div>
        </div>

        {/* ── IMPACTO ESPERADO ─────────────────────────────────── */}
        <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 4, padding: '1.75rem', boxShadow: '0 2px 8px rgba(34,29,55,.05)', marginBottom: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', marginBottom: '1.25rem' }}>
            <div style={{ width: 40, height: 40, borderRadius: 2, background: '#f0fdf4', border: '1px solid #86efac', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
            </div>
            <div>
              <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.68rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.08em', color: '#16a34a' }}>Resultados Esperados</div>
              <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '1.15rem', fontWeight: 700, color: '#221d37' }}>O que queremos alcançar juntos</div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '1rem' }}>
            {[
              { num: '01', title: 'Processos organizados', desc: 'Fluxos comerciais padronizados e rastreáveis do primeiro contato ao contrato assinado.' },
              { num: '02', title: 'Decisões embasadas', desc: 'Analytics e KPIs em tempo real para orientar a estratégia com dados reais da operação.' },
              { num: '03', title: 'Parcerias fortalecidas', desc: 'Histórico completo de cada escola para um atendimento mais consultivo e próximo.' },
            ].map(i => (
              <div key={i.num} style={{ padding: '1.1rem', background: '#f8fafc', borderRadius: 3, border: '1px solid #f1f5f9' }}>
                <div style={{ fontFamily: 'var(--font-cormorant,serif)', fontSize: '2rem', fontWeight: 800, color: '#36b6e8', lineHeight: 1, marginBottom: '.5rem' }}>{i.num}</div>
                <div style={{ fontFamily: 'var(--font-montserrat,sans-serif)', fontSize: '.82rem', fontWeight: 700, color: '#221d37', marginBottom: '.3rem' }}>{i.title}</div>
                <div style={{ fontSize: '.75rem', color: '#64748b', lineHeight: 1.6, fontFamily: 'var(--font-inter,sans-serif)' }}>{i.desc}</div>
              </div>
            ))}
          </div>
        </div>

        {/* ── Rodapé ───────────────────────────────────────────── */}
        <div style={{ textAlign: 'center', padding: '1rem', fontSize: '.72rem', color: '#94a3b8', fontFamily: 'var(--font-montserrat,sans-serif)', letterSpacing: '.03em' }}>
          Kairós © {new Date().getFullYear()} · Central de Inteligência Analítica · Plataforma de uso exclusivo da equipe interna
        </div>

      </div>
    </div>
  )
}

