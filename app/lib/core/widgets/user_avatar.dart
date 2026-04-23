import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar circular padrão do app: foto cached com fallback pra inicial.
/// Use em TUDO que mostra avatar de pessoa — resolve erro 404 de foto
/// e cache em 4G (substitui CircleAvatar+NetworkImage espalhados).
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 18,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        FavoColors.primaryContainer.withAlpha(40);
    final fg = foregroundColor ?? FavoColors.primary;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget fallback() => CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          child: Text(
            initial,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8,
            ),
          ),
        );

    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: radius * 2,
          height: radius * 2,
          color: bg,
        ),
        errorWidget: (_, _, _) => fallback(),
      ),
    );
  }
}
