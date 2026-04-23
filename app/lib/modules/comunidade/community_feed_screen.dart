import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/community_service.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Conversas',
            onPressed: () => context.push('/chat'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newPost(context, ref),
        child: const Icon(Icons.edit),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 48,
                      color: FavoColors.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text('A comunidade está quieta...',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Seja a primeira a postar!',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(communityFeedProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: posts.length,
              itemBuilder: (context, index) =>
                  _PostCard(post: posts[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _newPost(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const _NewPostScreen(),
      ),
    );
    ref.invalidate(communityFeedProvider);
  }
}

/// Tela fullscreen pra criar um post — substitui o AlertDialog apertado
/// (que tinha preview quebrado no web por usar Image.network de blob url).
class _NewPostScreen extends ConsumerStatefulWidget {
  const _NewPostScreen();

  @override
  ConsumerState<_NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<_NewPostScreen> {
  final _ctrl = TextEditingController();
  final List<XFile> _photos = [];
  bool _publishing = false;

  static const _maxChars = 500;
  static const _maxPhotos = 4;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final available = _maxPhotos - _photos.length;
    if (available <= 0) return;
    final imgs = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 82,
      limit: available,
    );
    if (imgs.isEmpty) return;
    setState(() => _photos.addAll(imgs.take(available)));
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= _maxPhotos) return;
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (img == null) return;
    setState(() => _photos.add(img));
  }

  Future<void> _publish() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _photos.isEmpty) return;
    setState(() => _publishing = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final imageUrls = <String>[];
      int failedUploads = 0;
      for (final photo in _photos) {
        try {
          final bytes = kIsWeb ? await photo.readAsBytes() : null;
          final url =
              await ref.read(communityServiceProvider).uploadPostPhoto(
                    filename: photo.name,
                    bytes: bytes,
                    file: kIsWeb ? null : File(photo.path),
                  );
          imageUrls.add(url);
        } catch (_) {
          failedUploads++;
        }
      }

      final result = await ref.read(communityServiceProvider).createPost(
            text.isNotEmpty ? text : 'Foto',
            imageUrls: imageUrls.isEmpty ? null : imageUrls,
          );

      if (!mounted) return;

      if (!result.approved) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Publicação não aprovada'),
            content: Text(result.friendlyMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(failedUploads > 0
              ? 'Publicação no ar — mas $failedUploads foto(s) falharam.'
              : 'Publicação no ar!'),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _publishing = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_publishing && (_ctrl.text.trim().isNotEmpty || _photos.isNotEmpty);
    final charCount = _ctrl.text.characters.length;
    final canAddPhoto = _photos.length < _maxPhotos && !_publishing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova publicação'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _publishing ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: canSubmit ? _publish : null,
              child: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _ctrl,
                    maxLines: null,
                    minLines: 4,
                    maxLength: _maxChars,
                    enabled: !_publishing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Compartilhe algo com o ateliê…\n'
                          'A peça que saiu hoje, uma dica, uma dúvida.',
                      border: InputBorder.none,
                      counterText: '$charCount/$_maxChars',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PhotoGrid(
                      photos: _photos,
                      onRemove: _publishing
                          ? null
                          : (i) => setState(() => _photos.removeAt(i)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_publishing)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FavoColors.primaryContainer.withAlpha(40),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Publicando e passando pela moderação…',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: FavoColors.outlineVariant.withAlpha(80)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: canAddPhoto ? _pickFromGallery : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    tooltip: 'Galeria',
                  ),
                  IconButton(
                    onPressed: canAddPhoto ? _pickFromCamera : null,
                    icon: const Icon(Icons.photo_camera_outlined),
                    tooltip: 'Câmera',
                  ),
                  const Spacer(),
                  Text(
                    '${_photos.length}/$_maxPhotos fotos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: FavoColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<XFile> photos;
  final void Function(int)? onRemove;

  const _PhotoGrid({required this.photos, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final p = photos[i];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: p.readAsBytes(),
                        builder: (_, snap) => snap.hasData
                            ? Image.memory(snap.data!, fit: BoxFit.cover)
                            : Container(color: FavoColors.surfaceContainerLow),
                      )
                    : Image.file(File(p.path), fit: BoxFit.cover),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => onRemove!(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FavoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          InkWell(
            onTap: () => context.push('/profile/${post.authorId}'),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: post.authorAvatar,
                  name: post.authorName,
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        DateFormat('dd MMM · HH:mm', 'pt_BR')
                            .format(post.createdAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content
          if (post.content != null)
            Text(post.content!, style: Theme.of(context).textTheme.bodyLarge),

          // Images
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrls.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: FavoColors.surfaceContainerLow,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: FavoColors.surfaceContainerLow,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: FavoColors.outline, size: 36),
                  ),
                ),
              ),
            ),
          ],

          if (post.moderationStatus == ModerationStatus.pending) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: FavoColors.primaryContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Aguardando moderação',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FavoColors.primary,
                    ),
              ),
            ),
          ] else if (post.moderationStatus == ModerationStatus.rejected) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: FavoColors.error.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Publicação rejeitada pela moderação',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FavoColors.error,
                    ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await ref
                      .read(communityServiceProvider)
                      .toggleLike(post.id);
                  ref.invalidate(communityFeedProvider);
                },
                child: Row(
                  children: [
                    Icon(
                      post.likedByMe
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: post.likedByMe
                          ? FavoColors.error
                          : FavoColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showComments(context, ref, post.id),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: FavoColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showComments(
      BuildContext context, WidgetRef ref, String postId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CommentsSheet(postId: postId),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  XFile? _attached;
  bool _sending = false;
  Future<List<CommunityComment>>? _commentsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _commentsFuture =
        ref.read(communityServiceProvider).getComments(widget.postId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (img != null) setState(() => _attached = img);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _attached == null) return;
    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (_attached != null) {
        final bytes = kIsWeb ? await _attached!.readAsBytes() : null;
        imageUrl = await ref.read(communityServiceProvider).uploadCommentPhoto(
              filename: _attached!.name,
              bytes: bytes,
              file: kIsWeb ? null : File(_attached!.path),
            );
      }
      await ref.read(communityServiceProvider).addComment(
            widget.postId,
            text.isEmpty ? '📷' : text,
            imageUrl: imageUrl,
          );
      _ctrl.clear();
      if (mounted) {
        setState(() {
          _attached = null;
          _reload();
        });
        ref.invalidate(communityFeedProvider);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Comentários',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: FutureBuilder<List<CommunityComment>>(
              future: _commentsFuture,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snap.data!;
                if (comments.isEmpty) {
                  return const Center(
                      child: Text('Seja a primeira a comentar'));
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (ctx, i) => _CommentTile(c: comments[i]),
                );
              },
            ),
          ),
          if (_attached != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _attached!.readAsBytes(),
                            builder: (_, snap) {
                              if (!snap.hasData) {
                                return const SizedBox(width: 60, height: 60);
                              }
                              return Image.memory(snap.data!,
                                  width: 60, height: 60, fit: BoxFit.cover);
                            },
                          )
                        : Image.file(File(_attached!.path),
                            width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _attached = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_outlined,
                      color: FavoColors.onSurfaceVariant),
                  onPressed: _sending ? null : _pick,
                  tooltip: 'Anexar foto',
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário...',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: FavoColors.primary),
                  onPressed: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityComment c;
  const _CommentTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${c.authorId}'),
            child: UserAvatar(
              avatarUrl: c.authorAvatar,
              name: c.authorName,
              radius: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile/${c.authorId}'),
                  child: Text(c.authorName,
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                if (c.content.isNotEmpty)
                  Text(c.content,
                      style: Theme.of(context).textTheme.bodyMedium),
                if (c.imageUrl != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      c.imageUrl!,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 180,
                        height: 120,
                        color: FavoColors.surfaceContainerLow,
                        child: const Icon(Icons.broken_image_outlined,
                            color: FavoColors.outline),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
