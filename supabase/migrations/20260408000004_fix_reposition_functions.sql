-- ============================================
-- Fix: aplicar funções de reposição e lista de espera
-- (separado do cron que requer pg_cron)
-- ============================================

CREATE OR REPLACE FUNCTION public.can_request_reposition(
  p_student_id UUID,
  p_month_year TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INT;
  v_has_override BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.reposicoes
    WHERE student_id = p_student_id
      AND month_year = p_month_year
      AND admin_override = true
  ) INTO v_has_override;

  IF v_has_override THEN
    RETURN true;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.reposicoes
  WHERE student_id = p_student_id
    AND month_year = p_month_year
    AND status != 'expired';

  RETURN v_count < 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.advance_waitlist(p_turma_id UUID)
RETURNS VOID AS $$
DECLARE
  v_next RECORD;
  v_capacity INT;
  v_enrolled INT;
BEGIN
  SELECT capacity INTO v_capacity FROM public.turmas WHERE id = p_turma_id;

  SELECT COUNT(*) INTO v_enrolled
  FROM public.turma_alunos
  WHERE turma_id = p_turma_id AND status = 'active';

  IF v_enrolled >= v_capacity THEN
    RETURN;
  END IF;

  SELECT * INTO v_next
  FROM public.lista_espera
  WHERE turma_id = p_turma_id
    AND status = 'waiting'
  ORDER BY position ASC
  LIMIT 1;

  IF v_next IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.lista_espera
  SET status = 'notified',
      notified_at = now(),
      expires_at = now() + interval '24 hours'
  WHERE id = v_next.id;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (
    v_next.student_id,
    'Vaga disponível!',
    'Abriu uma vaga na turma que você está na lista de espera. Você tem 24h para aceitar.',
    'waitlist',
    jsonb_build_object('turma_id', p_turma_id, 'waitlist_id', v_next.id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.handle_presence_declined()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confirmation = 'declined' AND (OLD.confirmation IS NULL OR OLD.confirmation != 'declined') THEN
    PERFORM public.advance_waitlist(
      (SELECT turma_id FROM public.aulas WHERE id = NEW.aula_id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_presence_declined ON public.presencas;
CREATE TRIGGER on_presence_declined
  AFTER INSERT OR UPDATE ON public.presencas
  FOR EACH ROW EXECUTE FUNCTION public.handle_presence_declined();
