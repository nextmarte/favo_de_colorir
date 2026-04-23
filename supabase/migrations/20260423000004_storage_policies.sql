-- Storage policies pros 6 buckets. Permissões seguem a convenção de path:
-- * avatars/<userId>/avatar.ext → só dono
-- * pecas/<pecaId>/<...> → admin/teacher/assistant ou dono da peça
-- * posts/<userId>/<...> → autenticado insere só nos próprios; todos leem
-- * feed/<userId>/<...> → idem posts
-- * chat/<userId>/<...> → só autenticado vê; admin vê tudo
-- * pagamentos/<userId>/<...> → aluna insere pro próprio cobrança; admin lê tudo

-- ========== AVATARS (public read, owner write) ==========
CREATE POLICY "avatars public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars owner upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

CREATE POLICY "avatars owner update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

CREATE POLICY "avatars owner delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

-- ========== FEED (public read, owner write) ==========
CREATE POLICY "feed public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'feed');

CREATE POLICY "feed owner write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'feed'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

CREATE POLICY "feed owner delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'feed'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.auth_role() IN ('admin', 'teacher')
    )
  );

-- ========== PECAS (public read, admin/teacher/assistant write) ==========
CREATE POLICY "pecas public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'pecas');

CREATE POLICY "pecas staff write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'pecas'
    AND public.auth_role() IN ('admin', 'teacher', 'assistant')
  );

CREATE POLICY "pecas staff delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'pecas'
    AND public.auth_role() IN ('admin', 'teacher', 'assistant')
  );

-- ========== POSTS (public read, owner write) ==========
CREATE POLICY "posts public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

CREATE POLICY "posts owner write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'posts'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

CREATE POLICY "posts owner or admin delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'posts'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.auth_role() IN ('admin', 'teacher')
    )
  );

-- ========== CHAT (authenticated read+write em pastas suas) ==========
-- Bucket privado; leitura só do remetente (signed URL resolve pra receptor).
CREATE POLICY "chat owner read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

CREATE POLICY "chat owner write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );

-- ========== PAGAMENTOS (aluna envia; admin lê) ==========
CREATE POLICY "pagamentos owner or admin read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'pagamentos'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.auth_role() = 'admin'
    )
  );

CREATE POLICY "pagamentos owner write"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'pagamentos'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  );
