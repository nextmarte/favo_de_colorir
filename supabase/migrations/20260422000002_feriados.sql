-- ============================================
-- FERIADOS — gerador de aulas pula essas datas
-- ============================================

CREATE TABLE public.feriados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_feriados_date ON public.feriados(date);

ALTER TABLE public.feriados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos leem feriados"
  ON public.feriados FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin gerencia feriados"
  ON public.feriados FOR ALL
  USING (public.auth_role() = 'admin');

-- Previne aulas duplicadas (turma+data) — corrige race condition do gerar-aulas
ALTER TABLE public.aulas
  ADD CONSTRAINT aulas_turma_data_unique UNIQUE (turma_id, scheduled_date);

-- Seed inicial: feriados nacionais principais de 2026
INSERT INTO public.feriados (date, name) VALUES
  ('2026-01-01', 'Ano Novo'),
  ('2026-02-16', 'Carnaval'),
  ('2026-02-17', 'Carnaval'),
  ('2026-02-18', 'Quarta de Cinzas'),
  ('2026-04-03', 'Sexta-feira Santa'),
  ('2026-04-21', 'Tiradentes'),
  ('2026-05-01', 'Dia do Trabalho'),
  ('2026-06-04', 'Corpus Christi'),
  ('2026-09-07', 'Independência'),
  ('2026-10-12', 'Nossa Senhora Aparecida'),
  ('2026-11-02', 'Finados'),
  ('2026-11-15', 'Proclamação da República'),
  ('2026-11-20', 'Dia da Consciência Negra'),
  ('2026-12-25', 'Natal')
ON CONFLICT (date) DO NOTHING;
