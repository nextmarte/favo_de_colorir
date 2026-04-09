-- Fix v2: simplificar — qualquer user autenticado pode inserir notificações
-- (o app controla quem pode via lógica de negócio)
DROP POLICY IF EXISTS "Admin and system insert notifications" ON public.notifications;

CREATE POLICY "Authenticated users insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
