import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

class SocialStore extends ChangeNotifier {
  final _api = Api.instancia;

  Loja? loja;
  List<Notificacao> notificacoes = [];
  int naoLidas = 0;

  Future<void> carregar() async {
    await Future.wait([carregarLoja(), carregarNotificacoes()]);
  }

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
      final resp = await _api.get('/notificacoes');
      notificacoes = ((resp['itens'] as List?) ?? []).map((e) => Notificacao.fromJson(e)).toList();
      naoLidas = (resp['naoLidas'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> marcarLidas() async {
    if (naoLidas == 0) return;
    naoLidas = 0;
    notifyListeners();
    try {
      await _api.post('/notificacoes/lidas');
    } on ApiException {
      return;
    }
  }

  Future<String> mandarParabens(String alunoId) async {
    final resp = await _api.post('/parabens/$alunoId');
    return (resp is Map && resp['mensagem'] != null) ? resp['mensagem'].toString() : 'Parabéns enviado!';
  }
}
