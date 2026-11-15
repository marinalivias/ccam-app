import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navegacao.dart';
import 'notificacoes.dart';
import 'theme.dart';

class Descanso extends ChangeNotifier {
  Descanso._();

  static final instancia = Descanso._();

  Timer? _timer;
  int restante = 0;
  int total = 0;

  bool get ativo => restante > 0;

  void iniciar(int segundos) {
    _timer?.cancel();
    restante = segundos;
    total = segundos;
    notifyListeners();
    Notificacoes.iniciarDescanso(segundos);
    final fim = DateTime.now().add(Duration(seconds: segundos));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final falta = fim.difference(DateTime.now()).inMilliseconds;
      restante = falta <= 0 ? 0 : (falta / 1000).ceil();
      notifyListeners();
      if (restante == 0) {
        t.cancel();
        _terminou();
      }
    });
  }

  void parar() {
    _timer?.cancel();
    Notificacoes.pararDescanso();
    restante = 0;
    notifyListeners();
  }

  void _terminou() {
    final naTela = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    Notificacoes.descansoTerminou(emPrimeiroPlano: naTela);
    if (naTela) _avisar();
  }

  Future<void> _avisar() async {
    final contexto = navegador.currentState?.overlay?.context;
    if (contexto == null) return;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: contexto,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.timer_off_rounded, color: Cores.verde, size: 40),
        title: const Text(
          'Descanso terminou',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Hora da próxima série!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Cores.textoSuave),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.fitness_center_rounded, size: 18),
            label: const Text('Bora treinar'),
          ),
        ],
      ),
    );
  }
}
