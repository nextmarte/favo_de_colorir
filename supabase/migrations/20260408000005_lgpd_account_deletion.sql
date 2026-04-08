-- ============================================
-- LGPD: função para exclusão completa de conta
-- Remove todos os dados do usuário (cascading)
-- ============================================

CREATE OR REPLACE FUNCTION public.delete_user_account(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Deletar fotos do feed (storage deve ser limpo separadamente)
  DELETE FROM public.feed_photos
  WHERE feed_entry_id IN (
    SELECT id FROM public.feed_entries WHERE student_id = p_user_id
  );

  -- Deletar entries do feed
  DELETE FROM public.feed_entries WHERE student_id = p_user_id;

  -- Deletar registros de materiais
  DELETE FROM public.registros_argila WHERE student_id = p_user_id;
  DELETE FROM public.pecas WHERE student_id = p_user_id;

  -- Deletar cobranças e itens
  DELETE FROM public.cobranca_itens
  WHERE cobranca_id IN (
    SELECT id FROM public.cobrancas WHERE student_id = p_user_id
  );
  DELETE FROM public.cobrancas WHERE student_id = p_user_id;

  -- Deletar assinaturas
  DELETE FROM public.assinaturas WHERE student_id = p_user_id;

  -- Deletar presenças e reposições
  DELETE FROM public.presencas WHERE student_id = p_user_id;
  DELETE FROM public.reposicoes WHERE student_id = p_user_id;

  -- Deletar lista de espera
  DELETE FROM public.lista_espera WHERE student_id = p_user_id;

  -- Deletar matrículas
  DELETE FROM public.turma_alunos WHERE student_id = p_user_id;

  -- Deletar notificações e tokens
  DELETE FROM public.notifications WHERE user_id = p_user_id;
  DELETE FROM public.fcm_tokens WHERE user_id = p_user_id;

  -- Deletar aceites de políticas
  DELETE FROM public.policy_acceptances WHERE user_id = p_user_id;

  -- Deletar perfil (cascade do auth.users vai deletar automaticamente)
  DELETE FROM public.profiles WHERE id = p_user_id;

  -- Deletar do auth (requer service_role)
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
