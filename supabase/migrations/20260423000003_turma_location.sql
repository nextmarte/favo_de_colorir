-- Local da aula (sala, bancada, área). Aluna nova precisa saber pra onde ir
-- sem ligar no WhatsApp da Débora.

ALTER TABLE public.turmas
  ADD COLUMN location TEXT;

ALTER TABLE public.turmas
  ADD COLUMN address TEXT;

-- Config global do ateliê (endereço padrão + dicas de local).
-- Débora configura uma vez; aulas sem location específico herdam.
INSERT INTO public.app_config (key, value, description) VALUES
  ('studio_address',
   '"Tijuca, Rio de Janeiro · RJ"'::jsonb,
   'Endereço padrão do ateliê exibido em aulas'),
  ('studio_maps_url',
   'null'::jsonb,
   'URL do Google Maps do ateliê (opcional)')
ON CONFLICT (key) DO NOTHING;
