import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';
import 'notificacoes.dart';

class SocialStore extends ChangeNotifier {
  static const _chaveVisto = 'notificacoes_vistas_em';
  static const _chaveLidas = 'notificacoes_lidas';

  final _api = Api.instancia;

  Loja? loja;
  List<Notificacao> notificacoes = [];
  Set<String> _lidas = {};

  int get naoLidas => notificacoes.where((n) => !_lidas.contains(n.id)).length;

  bool lida(Notificacao n) => _lidas.contains(n.id);

  Future<void> carregar() => Future.wait([carregarLoja(), carregarNotificacoes()]);

  Future<void> carregarLoja() async {
    try {
      loja = Loja.fromJson(await _api.get('/loja'));
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> carregarNotificacoes() async {
    try {
      final lista = await _api.get('/notificacoes') as List;
      notificacoes = lista.map((e) => Notificacao.fromJson(e)).toList();
      final prefs = await SharedPreferences.getInstance();
      final salvas = prefs.getStringList(_chaveLidas);
      if (salvas != null) {
        _lidas = salvas.toSet();
      } else {
        final vistasEm = DateTime.tryParse(prefs.getString(_chaveVisto) ?? '');
        _lidas = {for (final n in notificacoes) if (vistasEm != null && !n.data.isAfter(vistasEm)) n.id};
      }
      await Notificacoes.marcarAvisadas(notificacoes);
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> marcarLida(Notificacao n, {bool lida = true}) async {
    if (lida) {
      _lidas.add(n.id);
    } else {
      _lidas.remove(n.id);
    }
    await _salvarLidas();
  }

  Future<void> marcarTodasLidas() async {
    _lidas.addAll(notificacoes.map((n) => n.id));
    await _salvarLidas();
  }

  Future<void> _salvarLidas() async {
    notifyListeners();
    final atuais = notificacoes.map((n) => n.id).toSet();
    _lidas = _lidas.where(atuais.contains).toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chaveLidas, _lidas.toList());
    await prefs.remove(_chaveVisto);
  }
}
