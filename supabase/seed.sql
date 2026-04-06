-- ============================================
-- Seed Data — Favo de Colorir
-- ============================================

-- Tipos de Argila
INSERT INTO public.tipos_argila (name, price_per_kg) VALUES
  ('Branca', 12.00),
  ('Vermelha', 10.00),
  ('Grês', 15.00),
  ('Porcelana', 20.00);

-- Tipos de Peça (com preço de queima esmalte)
INSERT INTO public.tipos_peca (name, glaze_firing_price) VALUES
  ('Caneca', 5.50),
  ('Prato sobremesa', 8.00),
  ('Prato raso', 12.00),
  ('Tigela pequena', 6.00),
  ('Tigela grande', 10.00),
  ('Vaso pequeno', 8.00),
  ('Vaso grande', 15.00),
  ('Escultura pequena', 7.00),
  ('Escultura grande', 14.00);

-- Planos
INSERT INTO public.planos (name, type, price, duration_months, cancellation_notice_days, cancellation_penalty_pct) VALUES
  ('Mensal', 'monthly', 350.00, 1, 15, NULL),
  ('Trimestral', 'quarterly', 300.00, 3, NULL, 20.00),
  ('Semestral', 'semi_annual', 270.00, 6, NULL, 20.00),
  ('Aula Avulsa', 'single', 120.00, 0, NULL, NULL),
  ('Oficina', 'workshop', 180.00, 0, NULL, NULL);

-- Políticas do Ateliê
INSERT INTO public.policies (title, content, version) VALUES
  ('Regras de Reposição', 'Máximo de 1 reposição por mês. A reposição deve ser solicitada com pelo menos 1 dia de antecedência. Caso falte à reposição agendada, não será possível reagendar. A administração pode liberar reposições extras em casos excepcionais.', 1),
  ('Política de Faltas', 'A confirmação de presença é obrigatória. Você receberá uma notificação 1 dia antes de cada aula para confirmar sua presença ("Vou" ou "Não vou"). Caso não responda, um lembrete será enviado 6 horas antes. A falta sem aviso prévio será registrada.', 1),
  ('Cobrança de Materiais', 'A argila utilizada é cobrada por quilograma conforme o tipo escolhido. A queima de biscoito (1ª queima) não é cobrada. A queima de esmalte (2ª queima) é cobrada por peça, com valores variando conforme o tipo e tamanho da peça. Os valores são informados no app e totalizado mensalmente.', 1),
  ('Cancelamento', 'Plano mensal: aviso com 10-15 dias de antecedência. Planos trimestral e semestral: multa de 20% do valor restante do contrato. A solicitação de cancelamento deve ser feita pela administração do app.', 1),
  ('Regras da Comunidade', 'A comunidade é um espaço de troca e inspiração. Mantenha o respeito com todos os membros. Conteúdo político, ofensivo ou inadequado será removido. A moderação é feita pela equipe do ateliê. O descumprimento das regras pode resultar em suspensão do acesso.', 1);
