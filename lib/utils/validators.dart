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

  static String? validaCpf(String? value) {
    final numeros = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) {
      return 'Informe seu CPF';
    }
    if (numeros.length != 11) {
      return 'O CPF tem 11 números';
    }
    return null;
  }
}
