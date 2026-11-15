import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';
import 'notificacoes.dart';

class SocialStore extends ChangeNotifier {
  static const _chaveVisto = 'notificacoes_vistas_em';

  final _api = Api.instancia;

  Loja? loja;
  List<Notificacao> notificacoes = [];
  DateTime? _vistasEm;

  int get naoLidas => notificacoes.where((n) => _vistasEm == null || n.data.isAfter(_vistasEm!)).length;

  bool novidade(Notificacao n) => _vistasEm == null || n.data.isAfter(_vistasEm!);

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
      _vistasEm = DateTime.tryParse(prefs.getString(_chaveVisto) ?? '');
      await Notificacoes.marcarAvisadas(notificacoes);
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> marcarLidas() async {
    _vistasEm = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveVisto, _vistasEm!.toIso8601String());
    notifyListeners();
  }
}
