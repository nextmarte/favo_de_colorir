-- Fix: admin precisa poder inserir notificações
-- A policy "System inserts" com WITH CHECK (true) não funciona para users autenticados
-- porque Postgres RLS precisa de pelo menos uma policy que permita o INSERT para o role

DROP POLICY IF EXISTS "System inserts notifications" ON public.notifications;

CREATE POLICY "Admin and system insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (
    public.auth_role() IN ('admin', 'teacher')
    OR auth.uid() IS NULL  -- service role (edge functions)
  );
