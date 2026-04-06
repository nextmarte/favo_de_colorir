-- ============================================
-- Favo de Colorir — Schema Inicial (MVP)
-- Módulos: M1 Auth, M2 Agenda, M3 Materiais, M4 Cobrança, M5 Feed
-- ============================================

-- ============================================
-- M1: AUTH & PROFILES
-- ============================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  birth_date DATE,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('admin', 'teacher', 'assistant', 'student')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'inactive', 'blocked')),
  notification_preferences JSONB DEFAULT '{"new_post": true, "comment_reply": true}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  version INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT true,
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.policy_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  policy_id UUID NOT NULL REFERENCES public.policies(id),
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address TEXT,
  user_agent TEXT,
  UNIQUE(user_id, policy_id)
);

-- ============================================
-- M2: AGENDA
-- ============================================

CREATE TABLE public.turmas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  modality TEXT NOT NULL CHECK (modality IN ('regular', 'workshop', 'single')),
  day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  capacity INT NOT NULL DEFAULT 8,
  teacher_id UUID REFERENCES public.profiles(id),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.turma_alunos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  turma_id UUID NOT NULL REFERENCES public.turmas(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'waitlist')),
  UNIQUE(turma_id, student_id)
);

CREATE TABLE public.aulas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  turma_id UUID NOT NULL REFERENCES public.turmas(id),
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.presencas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aula_id UUID NOT NULL REFERENCES public.aulas(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  confirmation TEXT NOT NULL DEFAULT 'pending'
    CHECK (confirmation IN ('pending', 'confirmed', 'declined', 'no_response')),
  attended BOOLEAN,
  is_makeup BOOLEAN NOT NULL DEFAULT false,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(aula_id, student_id)
);

CREATE TABLE public.reposicoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  original_aula_id UUID NOT NULL REFERENCES public.aulas(id),
  makeup_aula_id UUID REFERENCES public.aulas(id),
  month_year TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'scheduled', 'completed', 'expired')),
  admin_override BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.lista_espera (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  turma_id UUID NOT NULL REFERENCES public.turmas(id),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  position INT NOT NULL,
  notified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'notified', 'accepted', 'expired', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- M3: MATERIAIS
-- ============================================

CREATE TABLE public.tipos_argila (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price_per_kg NUMERIC(10,2) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.tipos_peca (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  glaze_firing_price NUMERIC(10,2) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.registros_argila (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aula_id UUID NOT NULL REFERENCES public.aulas(id),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  tipo_argila_id UUID NOT NULL REFERENCES public.tipos_argila(id),
  kg_used NUMERIC(6,3) NOT NULL,
  kg_returned NUMERIC(6,3) NOT NULL DEFAULT 0,
  kg_net NUMERIC(6,3) GENERATED ALWAYS AS (kg_used - kg_returned) STORED,
  registered_by UUID NOT NULL REFERENCES public.profiles(id),
  synced BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.pecas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  aula_id UUID REFERENCES public.aulas(id),
  tipo_peca_id UUID NOT NULL REFERENCES public.tipos_peca(id),
  stage TEXT NOT NULL DEFAULT 'modeled'
    CHECK (stage IN ('modeled', 'painted', 'bisque_fired', 'glaze_fired')),
  height_cm NUMERIC(6,1),
  diameter_cm NUMERIC(6,1),
  weight_g NUMERIC(8,1),
  notes TEXT,
  registered_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.registros_queima (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  peca_id UUID NOT NULL REFERENCES public.pecas(id),
  firing_type TEXT NOT NULL CHECK (firing_type IN ('bisque', 'glaze')),
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  fired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  registered_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- M4: COBRANÇA
-- ============================================

CREATE TABLE public.planos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL
    CHECK (type IN ('monthly', 'quarterly', 'semi_annual', 'single', 'workshop')),
  price NUMERIC(10,2) NOT NULL,
  duration_months INT NOT NULL DEFAULT 1,
  cancellation_notice_days INT,
  cancellation_penalty_pct NUMERIC(5,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.assinaturas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  plano_id UUID NOT NULL REFERENCES public.planos(id),
  turma_id UUID REFERENCES public.turmas(id),
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'cancelled', 'expired', 'suspended')),
  auto_renew BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.cobrancas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id),
  month_year TEXT NOT NULL,
  plan_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  clay_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  firing_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(10,2) GENERATED ALWAYS AS (plan_amount + clay_amount + firing_amount) STORED,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'pending', 'notified', 'paid', 'overdue', 'cancelled')),
  payment_method TEXT CHECK (payment_method IN ('pix', 'card', 'external')),
  payment_reference TEXT,
  paid_at TIMESTAMPTZ,
  notified_at TIMESTAMPTZ,
  admin_confirmed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(student_id, month_year)
);

CREATE TABLE public.cobranca_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cobranca_id UUID NOT NULL REFERENCES public.cobrancas(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('plan', 'clay', 'firing')),
  description TEXT NOT NULL,
  quantity NUMERIC(10,3),
  unit_price NUMERIC(10,2),
  total NUMERIC(10,2) NOT NULL,
  reference_id UUID
);

-- ============================================
-- M5: FEED PESSOAL
-- ============================================

CREATE TABLE public.feed_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  aula_id UUID REFERENCES public.aulas(id),
  peca_id UUID REFERENCES public.pecas(id),
  entry_type TEXT NOT NULL
    CHECK (entry_type IN ('class_note', 'piece_update', 'photo', 'quick_note')),
  content TEXT,
  note_color TEXT,
  is_public BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.feed_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feed_entry_id UUID NOT NULL REFERENCES public.feed_entries(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  thumbnail_path TEXT,
  caption TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- NOTIFICAÇÕES
-- ============================================

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN NOT NULL DEFAULT false,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_presencas_aula ON public.presencas(aula_id);
CREATE INDEX idx_presencas_student ON public.presencas(student_id);
CREATE INDEX idx_aulas_turma_date ON public.aulas(turma_id, scheduled_date);
CREATE INDEX idx_registros_argila_student ON public.registros_argila(student_id);
CREATE INDEX idx_registros_argila_aula ON public.registros_argila(aula_id);
CREATE INDEX idx_cobrancas_student_month ON public.cobrancas(student_id, month_year);
CREATE INDEX idx_feed_entries_student ON public.feed_entries(student_id, created_at DESC);
CREATE INDEX idx_notifications_user ON public.notifications(user_id, read, created_at DESC);
CREATE INDEX idx_turma_alunos_student ON public.turma_alunos(student_id);
CREATE INDEX idx_reposicoes_student_month ON public.reposicoes(student_id, month_year);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admin views all profiles"
  ON public.profiles FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Teachers view student profiles"
  ON public.profiles FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

CREATE POLICY "Users update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admin updates all profiles"
  ON public.profiles FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Anyone can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policies (public read)
ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads active policies"
  ON public.policies FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admin manages policies"
  ON public.policies FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Policy Acceptances
ALTER TABLE public.policy_acceptances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own acceptances"
  ON public.policy_acceptances FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own acceptances"
  ON public.policy_acceptances FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin views all acceptances"
  ON public.policy_acceptances FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Turmas (all authenticated can read)
ALTER TABLE public.turmas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read turmas"
  ON public.turmas FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin manages turmas"
  ON public.turmas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Turma Alunos
ALTER TABLE public.turma_alunos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own enrollments"
  ON public.turma_alunos FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Admin and teachers see all enrollments"
  ON public.turma_alunos FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

CREATE POLICY "Admin manages enrollments"
  ON public.turma_alunos FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Aulas
ALTER TABLE public.aulas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read aulas"
  ON public.aulas FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin and teachers manage aulas"
  ON public.aulas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Presencas
ALTER TABLE public.presencas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own presenca"
  ON public.presencas FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Students update own confirmation"
  ON public.presencas FOR UPDATE
  USING (auth.uid() = student_id);

CREATE POLICY "Admin and teachers manage presencas"
  ON public.presencas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Reposicoes
ALTER TABLE public.reposicoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own reposicoes"
  ON public.reposicoes FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Students insert own reposicoes"
  ON public.reposicoes FOR INSERT
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Admin manages all reposicoes"
  ON public.reposicoes FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Lista de Espera
ALTER TABLE public.lista_espera ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own waitlist"
  ON public.lista_espera FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Students join waitlist"
  ON public.lista_espera FOR INSERT
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Admin manages waitlist"
  ON public.lista_espera FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Tipos Argila (public read)
ALTER TABLE public.tipos_argila ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read tipos_argila"
  ON public.tipos_argila FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin manages tipos_argila"
  ON public.tipos_argila FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Tipos Peca (public read)
ALTER TABLE public.tipos_peca ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read tipos_peca"
  ON public.tipos_peca FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin manages tipos_peca"
  ON public.tipos_peca FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Registros Argila
ALTER TABLE public.registros_argila ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own clay records"
  ON public.registros_argila FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Teachers and admin manage clay records"
  ON public.registros_argila FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Pecas
ALTER TABLE public.pecas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own pecas"
  ON public.pecas FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Teachers and admin manage pecas"
  ON public.pecas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Registros Queima
ALTER TABLE public.registros_queima ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own firing records"
  ON public.registros_queima FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.pecas WHERE id = registros_queima.peca_id AND student_id = auth.uid()
  ));

CREATE POLICY "Teachers and admin manage firing records"
  ON public.registros_queima FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Planos (public read)
ALTER TABLE public.planos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read planos"
  ON public.planos FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin manages planos"
  ON public.planos FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Assinaturas
ALTER TABLE public.assinaturas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own subscription"
  ON public.assinaturas FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Admin manages subscriptions"
  ON public.assinaturas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Cobrancas
ALTER TABLE public.cobrancas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own charges"
  ON public.cobrancas FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Admin manages all charges"
  ON public.cobrancas FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Cobranca Itens
ALTER TABLE public.cobranca_itens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students see own charge items"
  ON public.cobranca_itens FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.cobrancas WHERE id = cobranca_itens.cobranca_id AND student_id = auth.uid()
  ));

CREATE POLICY "Admin manages charge items"
  ON public.cobranca_itens FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Feed Entries
ALTER TABLE public.feed_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students manage own feed"
  ON public.feed_entries FOR ALL
  USING (auth.uid() = student_id);

CREATE POLICY "Active users see public feed"
  ON public.feed_entries FOR SELECT
  USING (
    is_public = true
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND status = 'active')
  );

-- Feed Photos
ALTER TABLE public.feed_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see photos of accessible feed entries"
  ON public.feed_photos FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.feed_entries
    WHERE id = feed_photos.feed_entry_id
    AND (student_id = auth.uid() OR is_public = true)
  ));

CREATE POLICY "Students manage own feed photos"
  ON public.feed_photos FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.feed_entries
    WHERE id = feed_photos.feed_entry_id AND student_id = auth.uid()
  ));

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "System inserts notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- FCM Tokens
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own tokens"
  ON public.fcm_tokens FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check reposition limit (max 1/month unless admin override)
CREATE OR REPLACE FUNCTION public.check_reposition_limit(
  p_student_id UUID,
  p_month_year TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM public.reposicoes
    WHERE student_id = p_student_id
      AND month_year = p_month_year
      AND admin_override = false
      AND status IN ('pending', 'scheduled', 'completed')
  );
END;
$$;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_pecas_updated_at
  BEFORE UPDATE ON public.pecas
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_feed_entries_updated_at
  BEFORE UPDATE ON public.feed_entries
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- VIEWS
-- ============================================

-- Monthly consumption per student (for billing)
CREATE OR REPLACE VIEW public.v_consumo_mensal_aluna AS
SELECT
  ra.student_id,
  to_char(a.scheduled_date, 'YYYY-MM') AS month_year,
  ta.name AS clay_type,
  ta.price_per_kg,
  SUM(ra.kg_net) AS total_kg,
  SUM(ra.kg_net * ta.price_per_kg) AS total_clay_cost
FROM public.registros_argila ra
JOIN public.aulas a ON a.id = ra.aula_id
JOIN public.tipos_argila ta ON ta.id = ra.tipo_argila_id
GROUP BY ra.student_id, to_char(a.scheduled_date, 'YYYY-MM'), ta.name, ta.price_per_kg;

-- Monthly firing costs per student
CREATE OR REPLACE VIEW public.v_queimas_mensal_aluna AS
SELECT
  p.student_id,
  to_char(rq.fired_at, 'YYYY-MM') AS month_year,
  tp.name AS piece_type,
  COUNT(*) AS firing_count,
  SUM(rq.price) AS total_firing_cost
FROM public.registros_queima rq
JOIN public.pecas p ON p.id = rq.peca_id
JOIN public.tipos_peca tp ON tp.id = p.tipo_peca_id
WHERE rq.firing_type = 'glaze'
GROUP BY p.student_id, to_char(rq.fired_at, 'YYYY-MM'), tp.name;
