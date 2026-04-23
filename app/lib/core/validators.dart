import 'package:flutter/services.dart';

/// RFC-ish email validation (não é perfeita, mas bloqueia `@@@`, `abc`, `ana@`).
final _emailRegex = RegExp(
  r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
);

String? validateEmail(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Informe o e-mail';
  if (!_emailRegex.hasMatch(value)) return 'E-mail inválido';
  return null;
}

/// Valida telefone BR (10 ou 11 dígitos após remover máscara). Opcional — null/vazio passa.
String? validatePhoneBR(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 11) {
    return 'Telefone inválido (use DDD + número)';
  }
  return null;
}

/// Formata dígitos brutos em (XX) XXXXX-XXXX ou (XX) XXXX-XXXX.
String formatPhoneBR(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return '';
  final buf = StringBuffer('(');
  for (var i = 0; i < d.length && i < 11; i++) {
    buf.write(d[i]);
    if (i == 1) buf.write(') ');
    if (d.length == 11 && i == 6) buf.write('-');
    if (d.length <= 10 && i == 5) buf.write('-');
  }
  return buf.toString();
}

/// TextInputFormatter pra aplicar a máscara enquanto digita.
class PhoneBRFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = formatPhoneBR(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String? validatePasswordStrength(String? raw) {
  final value = raw ?? '';
  if (value.isEmpty) return 'Crie uma senha';
  if (value.length < 6) return 'Senha precisa ter pelo menos 6 caracteres';
  return null;
}

String? validatePasswordsMatch(String? a, String? b) {
  if ((a ?? '') != (b ?? '')) return 'As senhas não conferem';
  return null;
}

/// Parse de DD/MM/AAAA. Retorna null se inválido.
DateTime? parseBirthDateBR(String? raw) {
  final value = raw?.trim() ?? '';
  final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;
  final d = DateTime(year, month, day);
  // Garante que não "rolou" (ex: 31/02 → 03/03)
  if (d.day != day || d.month != month || d.year != year) return null;
  return d;
}

String formatBirthDateBR(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}
