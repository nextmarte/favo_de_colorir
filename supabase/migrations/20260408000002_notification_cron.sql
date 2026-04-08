-- ============================================
-- Cron jobs para notificações de presença
-- Requer pg_cron habilitado no Supabase (Dashboard > Database > Extensions)
-- ============================================

-- Notificação 24h antes: roda todo dia às 9h (horário de Brasília = 12h UTC)
SELECT cron.schedule(
  'notify-confirmation-24h',
  '0 12 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/enviar-notificacao',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := '{"type": "confirmation_24h"}'::jsonb
  );
  $$
);

-- Lembrete 6h antes: roda todo dia às 6h (horário de Brasília = 9h UTC)
SELECT cron.schedule(
  'notify-reminder-6h',
  '0 9 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/enviar-notificacao',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := '{"type": "reminder_6h"}'::jsonb
  );
  $$
);
