import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final String mensagem;
  final int status;
  final bool semRede;

  ApiException(this.mensagem, [this.status = 0, this.semRede = false]);

  @override
  String toString() => mensagem;
}

class Api {
  Api._();

  static final Api instancia = Api._();
  static const _chaveToken = 'ccam_token';
  static const _chaveFila = 'fila_offline';
  static const _prefixoCache = 'cache:';
  static const _comCache = ['/me', '/treino', '/catalogo', '/treinos-realizados', '/frequencia', '/mural', '/financeiro', '/loja', '/notificacoes'];

  String? _token;
  void Function()? aoExpirar;
  final semConexao = ValueNotifier<bool>(false);
  final pendentes = ValueNotifier<int>(0);
  bool _sincronizando = false;

  bool get logado => _token != null;

  Future<void> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_chaveToken);
    pendentes.value = (prefs.getStringList(_chaveFila) ?? const []).length;
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
    await prefs.remove(_chaveFila);
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefixoCache)).toList()) {
      await prefs.remove(k);
    }
    pendentes.value = 0;
  }

  bool _usaCache(String caminho) {
    if (caminho.contains('/pix') || caminho.contains('/comprovante')) return false;
    return _comCache.any((p) => caminho == p || caminho.startsWith('$p?') || caminho.startsWith('$p/'));
  }

  Future<dynamic> get(String caminho) async {
    try {
      final dados = await _enviar('GET', caminho);
      if (_usaCache(caminho)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_prefixoCache$caminho', jsonEncode(dados));
      }
      return dados;
    } on ApiException catch (e) {
      if (!e.semRede || !_usaCache(caminho)) rethrow;
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString('$_prefixoCache$caminho');
      if (salvo == null) rethrow;
      return jsonDecode(salvo);
    }
  }

  Future<dynamic> putOuGuardar(String caminho, Object corpo) async {
    try {
      return await _enviar('PUT', caminho, corpo);
    } on ApiException catch (e) {
      if (!e.semRede) rethrow;
      final prefs = await SharedPreferences.getInstance();
      final fila = (prefs.getStringList(_chaveFila) ?? [])
          .where((item) => (jsonDecode(item) as Map)['caminho'] != caminho)
          .toList()
        ..add(jsonEncode({'caminho': caminho, 'corpo': corpo}));
      await prefs.setStringList(_chaveFila, fila);
      pendentes.value = fila.length;
      rethrow;
    }
  }

  Future<bool> sincronizar() async {
    if (_sincronizando || _token == null) return false;
    _sincronizando = true;
    var enviou = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      var fila = prefs.getStringList(_chaveFila) ?? [];
      while (fila.isNotEmpty) {
        final item = jsonDecode(fila.first) as Map<String, dynamic>;
        try {
          await _enviar('PUT', item['caminho'].toString(), item['corpo']);
        } on ApiException catch (e) {
          if (e.semRede) break;
        }
        fila = fila.sublist(1);
        await prefs.setStringList(_chaveFila, fila);
        pendentes.value = fila.length;
        enviou = true;
      }
    } finally {
      _sincronizando = false;
    }
    return enviou;
  }

  Future<dynamic> getSemCache(String caminho) => _enviar('GET', caminho);
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
      semConexao.value = true;
      throw ApiException('O servidor demorou para responder. Tente de novo.', 0, true);
    } catch (_) {
      semConexao.value = true;
      throw ApiException('Sem conexão com o servidor. Confira sua internet.', 0, true);
    }
    semConexao.value = false;

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
