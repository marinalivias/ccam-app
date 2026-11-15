class Validators {
  static String? validaEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Digite um e-mail válido';
    }
    return null;
  }

  static String? validaSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }
    return null;
  }
}
