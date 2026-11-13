import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final String mensagem;
  final int status;

  ApiException(this.mensagem, [this.status = 0]);

  @override
  String toString() => mensagem;
}

class Api {
  Api._();

  static final Api instancia = Api._();
  static const _chaveToken = 'ccam_token';

  String? _token;
  void Function()? aoExpirar;

  bool get logado => _token != null;

  Future<void> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_chaveToken);
  }

  Future<void> salvarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
  }

  Future<void> limparToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
  }

  Future<dynamic> get(String caminho) => _enviar('GET', caminho);
  Future<dynamic> post(String caminho, [Object? corpo]) => _enviar('POST', caminho, corpo);
  Future<dynamic> put(String caminho, [Object? corpo]) => _enviar('PUT', caminho, corpo);
  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);

  Future<dynamic> _enviar(String metodo, String caminho, [Object? corpo]) async {
    final uri = Uri.parse('$apiUrl/app$caminho');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';

    http.Response resp;
    try {
      final req = http.Request(metodo, uri)..headers.addAll(headers);
      if (corpo != null) req.body = jsonEncode(corpo);
      resp = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 15)));
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente de novo.');
    } catch (_) {
      throw ApiException('Sem conexão com o servidor. Confira sua internet.');
    }

    final texto = utf8.decode(resp.bodyBytes);
    dynamic dados;
    if (texto.isNotEmpty) {
      try {
        dados = jsonDecode(texto);
      } catch (_) {
        dados = null;
      }
    }

    if (resp.statusCode == 401 && _token != null) {
      await limparToken();
      aoExpirar?.call();
      throw ApiException('Sua sessão expirou. Entre novamente.', 401);
    }
    if (resp.statusCode >= 400) {
      final msg = dados is Map && dados['erro'] != null
          ? dados['erro'].toString()
          : 'Algo deu errado (erro ${resp.statusCode}).';
      throw ApiException(msg, resp.statusCode);
    }
    return dados;
  }
}
