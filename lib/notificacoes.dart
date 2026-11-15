import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'models.dart';

@pragma('vm:entry-point')
void tarefaEmSegundoPlano() {
  Workmanager().executeTask((tarefa, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Notificacoes.iniciar();
      await Notificacoes.verificarNovas();
    } catch (_) {}
    return true;
  });
}

class Notificacoes {
  Notificacoes._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _pronto = false;

  static const _idDescanso = 1;
  static const _idNovidades = 100;
  static const _tarefa = 'ccam_novidades';
  static const _chaveAvisadas = 'notificacoes_avisadas';

  static bool get suportado => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<bool> iniciar() async {
    if (!suportado) return false;
    if (_pronto) return true;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_launcher_frente')));
    _pronto = true;
    return true;
  }

  static Future<void> aoEntrar() async {
    if (!await iniciar()) return;
    await _android?.requestNotificationsPermission();
    await Workmanager().initialize(tarefaEmSegundoPlano);
    await Workmanager().registerPeriodicTask(
      _tarefa,
      _tarefa,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> aoSair() async {
    if (!await iniciar()) return;
    await Workmanager().cancelByUniqueName(_tarefa);
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveAvisadas);
  }

  static NotificationDetails _detalhes(String canal, String nome, String descricao) => NotificationDetails(
        android: AndroidNotificationDetails(
          canal,
          nome,
          channelDescription: descricao,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_launcher_frente',
        ),
      );

  static final _canalDescanso = _detalhes('descanso', 'Descanso', 'Avisa quando o tempo de descanso termina');
  static final _canalFinanceiro = _detalhes('financeiro', 'Mensalidades', 'Vencimentos, Pix e pagamentos confirmados');
  static final _canalNovidades = _detalhes('novidades', 'Novidades', 'Avisos do mural, alterações no treino e promoções');

  static Future<AndroidScheduleMode> _modo() async {
    final exato = await _android?.canScheduleExactNotifications() ?? false;
    return exato ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static Future<void> iniciarDescanso(int segundos) async {
    if (!await iniciar()) return;
    await _plugin.cancel(id: _idDescanso);
    await _plugin.zonedSchedule(
      id: _idDescanso,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: segundos)),
      notificationDetails: _canalDescanso,
      androidScheduleMode: await _modo(),
      title: 'Descanso terminou',
      body: 'Hora da próxima série!',
    );
  }

  static Future<void> descansoTerminou({required bool emPrimeiroPlano}) async {
    if (!await iniciar()) return;
    if (emPrimeiroPlano) {
      await _plugin.cancel(id: _idDescanso);
      return;
    }
    final pendentes = await _plugin.pendingNotificationRequests();
    if (!pendentes.any((p) => p.id == _idDescanso)) return;
    await _plugin.cancel(id: _idDescanso);
    await _plugin.show(id: _idDescanso, title: 'Descanso terminou', body: 'Hora da próxima série!', notificationDetails: _canalDescanso);
  }

  static Future<void> pararDescanso() async {
    if (!await iniciar()) return;
    await _plugin.cancel(id: _idDescanso);
  }

  static Future<void> marcarAvisadas(List<Notificacao> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final avisadas = {...?prefs.getStringList(_chaveAvisadas), ...lista.map((n) => n.id)};
    await prefs.setStringList(_chaveAvisadas, _limitar(avisadas, lista));
  }

  static Future<void> verificarNovas() async {
    await Api.instancia.carregarToken();
    if (!Api.instancia.logado) return;
    final lista = (await Api.instancia.get('/notificacoes') as List).map((e) => Notificacao.fromJson(e)).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final anteriores = prefs.getStringList(_chaveAvisadas);
    await prefs.setStringList(_chaveAvisadas, _limitar({...?anteriores, ...lista.map((n) => n.id)}, lista));
    if (anteriores == null) return;
    final novas = lista.where((n) => !anteriores.contains(n.id)).toList();
    for (final n in novas.take(4)) {
      await _plugin.show(
        id: _idNovidades + (n.id.hashCode & 0xFFFF),
        title: n.titulo,
        body: n.texto,
        notificationDetails: n.tipo == 'pagamento' ? _canalFinanceiro : _canalNovidades,
      );
    }
  }

  static List<String> _limitar(Set<String> ids, List<Notificacao> atuais) {
    final atuaisIds = atuais.map((n) => n.id).toSet();
    final antigos = ids.where((id) => !atuaisIds.contains(id)).toList();
    final excesso = antigos.length - 150;
    return [...atuaisIds, ...antigos.skip(excesso > 0 ? excesso : 0)];
  }

}
