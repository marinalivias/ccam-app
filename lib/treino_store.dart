import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';
import 'utils/helpers.dart';

class TreinoStore extends ChangeNotifier {
  final _api = Api.instancia;

  List<Exercicio> ficha = [];
  List<ItemCatalogo> catalogo = [];
  Map<String, ItemCatalogo> _porNome = {};
  final Map<String, TreinoRealizado> _realizados = {};
  Frequencia? frequencia;
  bool carregando = false;
  String? erro;

  List<Exercicio> doDia(DateTime data) {
    final dia = Helpers.obterDiaAtual(data.weekday);
    return ficha.where((e) => e.diaSemana == dia || e.diaSemana == Helpers.rotativo).toList();
  }

  TreinoRealizado? realizadoEm(DateTime data) => _realizados[Helpers.isoData(data)];

  List<TreinoRealizado> realizadosEntre(DateTime de, DateTime ate) =>
      _realizados.values.where((t) => !t.data.isBefore(de) && !t.data.isAfter(ate)).toList()..sort((a, b) => a.data.compareTo(b.data));

  Exercicio? exercicioPorId(String id) {
    for (final e in ficha) {
      if (e.id == id) return e;
    }
    return null;
  }

  Set<String> feitosEm(DateTime data) => realizadoEm(data)?.idsFeitos ?? {};

  Registro? registroDe(DateTime data, String exercicioId) => realizadoEm(data)?.registros[exercicioId];

  ItemCatalogo? doCatalogo(String nome) => _porNome[nome.trim().toLowerCase()];

  String? gifDe(Exercicio ex) => ex.imagemUrl ?? doCatalogo(ex.nome)?.imagemUrl;

  int seriesFeitas(DateTime data, Exercicio ex) {
    final r = registroDe(data, ex.id);
    if (r == null) return feitosEm(data).contains(ex.id) ? ex.totalSeries : 0;
    final meta = ex.alvoReps ?? 1;
    return r.reps.where((v) => v >= meta).length;
  }

  (int, int) progressoSeries(DateTime data) {
    var feitas = 0;
    var total = 0;
    for (final ex in doDia(data)) {
      total += ex.totalSeries;
      feitas += seriesFeitas(data, ex);
    }
    return (feitas, total);
  }

  Future<void> carregarCatalogo() async {
    if (catalogo.isNotEmpty) return;
    final lista = await _api.get('/catalogo') as List;
    catalogo = lista.map((e) => ItemCatalogo.fromJson(e)).toList();
    _porNome = {for (final c in catalogo) c.nome.toLowerCase(): c};
    notifyListeners();
  }

  Future<void> registrar(DateTime data, String exercicioId, List<int> reps, String? carga) async {
    final chave = Helpers.isoData(data);
    final resp = await _api.put('/treinos-realizados/$chave/exercicios/$exercicioId', {'reps': reps, 'carga': carga});
    if (resp is Map<String, dynamic>) {
      _realizados[chave] = TreinoRealizado.fromJson(resp);
    } else {
      _realizados.remove(chave);
    }
    await carregarFrequencia(avisar: false);
    notifyListeners();
  }

  Future<void> limparFicha() async {
    await _api.delete('/treino');
    ficha = [];
    await carregarFrequencia(avisar: false);
    notifyListeners();
  }

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final lista = await _api.get('/treino') as List;
      ficha = lista.map((e) => Exercicio.fromJson(e)).toList();
      final hoje = Helpers.soData(DateTime.now());
      try {
        await carregarCatalogo();
      } on ApiException {
        catalogo = [];
      }
      await carregarPeriodo(Helpers.segundaDaSemana(hoje).subtract(const Duration(days: 35)), hoje, avisar: false);
      await carregarFrequencia(avisar: false);
    } on ApiException catch (e) {
      erro = e.mensagem;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> carregarPeriodo(DateTime de, DateTime ate, {bool avisar = true}) async {
    final lista = await _api.get('/treinos-realizados?de=${Helpers.isoData(de)}&ate=${Helpers.isoData(ate)}') as List;
    for (var d = de; !d.isAfter(ate); d = d.add(const Duration(days: 1))) {
      _realizados.remove(Helpers.isoData(d));
    }
    for (final item in lista) {
      final t = TreinoRealizado.fromJson(item);
      _realizados[Helpers.isoData(t.data)] = t;
    }
    if (avisar) notifyListeners();
  }

  Future<void> carregarFrequencia({bool avisar = true}) async {
    frequencia = Frequencia.fromJson(await _api.get('/frequencia'));
    if (avisar) notifyListeners();
  }

  Future<void> alternar(DateTime data, String exercicioId, {String? observacao}) async {
    final atuais = {...feitosEm(data)};
    if (!atuais.remove(exercicioId)) atuais.add(exercicioId);
    await salvarDia(data, atuais, observacao: observacao ?? realizadoEm(data)?.observacao);
  }

  Future<void> marcarTodos(DateTime data, bool feito) async {
    final ids = feito ? doDia(data).map((e) => e.id).toSet() : <String>{};
    await salvarDia(data, ids, observacao: realizadoEm(data)?.observacao);
  }

  Future<void> salvarDia(DateTime data, Set<String> ids, {String? observacao}) async {
    final chave = Helpers.isoData(data);
    final anterior = _realizados[chave];
    _realizados[chave] = TreinoRealizado(
      data: data,
      previstos: doDia(data).length,
      feitos: ids.length,
      concluido: ids.length >= doDia(data).length && ids.isNotEmpty,
      idsFeitos: ids,
      observacao: observacao,
      registros: anterior?.registros ?? const {},
    );
    if (ids.isEmpty) _realizados.remove(chave);
    notifyListeners();

    try {
      final resp = await _api.put('/treinos-realizados/$chave', {
        'idsFeitos': ids.toList(),
        'observacao': observacao,
      });
      if (resp is Map<String, dynamic>) {
        _realizados[chave] = TreinoRealizado.fromJson(resp);
      } else {
        _realizados.remove(chave);
      }
      await carregarFrequencia(avisar: false);
    } catch (e) {
      if (anterior != null) {
        _realizados[chave] = anterior;
      } else {
        _realizados.remove(chave);
      }
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> adicionar(int? catalogoId, Map<String, String?> dados) async {
    final novo = await _api.post('/treino', {'catalogoId': catalogoId, ...dados});
    ficha = [...ficha, Exercicio.fromJson(novo)];
    await carregarFrequencia(avisar: false);
    notifyListeners();
  }

  Future<void> editar(String id, Map<String, String?> dados) async {
    final salvo = Exercicio.fromJson(await _api.put('/treino/$id', dados));
    ficha = ficha.map((e) => e.id == id ? salvo : e).toList();
    await carregarFrequencia(avisar: false);
    notifyListeners();
  }

  Future<void> remover(String id) async {
    await _api.delete('/treino/$id');
    ficha = ficha.where((e) => e.id != id).toList();
    await carregarFrequencia(avisar: false);
    notifyListeners();
  }
}
