import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Extrai mensagem amigável de erros do Supabase
String friendlyError(Object error) {
  if (error is AuthException) {
    return switch (error.message) {
      'Invalid login credentials' => 'E-mail ou senha incorretos',
      'Email not confirmed' => 'Confirme seu e-mail antes de entrar',
      'User already registered' => 'Este e-mail já está cadastrado',
      _ => error.message,
    };
  }

  if (error is PostgrestException) {
    if (error.code == '23505') {
      return 'Este registro já existe';
    }
    if (error.code == '42501') {
      return 'Você não tem permissão para esta ação';
    }
    return error.message;
  }

  final msg = error.toString();
  if (msg.contains('SocketException') || msg.contains('ClientException')) {
    return 'Sem conexão com a internet';
  }

  return 'Erro inesperado. Tente novamente.';
}

/// Mostra snackbar de erro amigável
void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(friendlyError(error)),
      backgroundColor: Colors.red.shade700,
    ),
  );
}

/// Mostra snackbar de sucesso
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
