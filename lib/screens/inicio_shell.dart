import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';

import '../models.dart';
import '../notificacoes.dart';
import '../social_store.dart';
import '../treino_store.dart';
import '../widgets/comum.dart';
import 'calendario_screen.dart';
import 'financeiro_screen.dart';
import 'hoje_screen.dart';
import 'loja_screen.dart';
import 'mural_screen.dart';
import 'perfil_screen.dart';

class InicioShell extends StatefulWidget {
  final Aluno aluno;

  const InicioShell({super.key, required this.aluno});

  @override
  State<InicioShell> createState() => _InicioShellState();
}

class _InicioShellState extends State<InicioShell> with WidgetsBindingObserver {
  final _store = TreinoStore();
  final _social = SocialStore();
  int _aba = 0;

  @override
  void initState() {
    super.initState();
    _store.aluno = widget.aluno;
    _store.carregar();
    _social.carregar();
    Notificacoes.aoEntrar();
    WidgetsBinding.instance.addObserver(this);
    _sincronizar();
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) {
      if (Api.instancia.pendentes.value > 0 || Api.instancia.semConexao.value) _sincronizar();
    });
  }

  Timer? _relogio;

  Future<void> _sincronizar() async {
    if (await Api.instancia.sincronizar()) {
      await _store.carregar();
      if (mounted) mostrarMensagem(context, 'Conexão de volta: seus registros foram enviados.');
    } else if (Api.instancia.semConexao.value && Api.instancia.pendentes.value == 0) {
      try {
        await Api.instancia.getSemCache('/frequencia');
      } on ApiException {
        return;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _social.carregarNotificacoes();
      _sincronizar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _relogio?.cancel();
    _store.dispose();
    _social.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _social,
      builder: (context, _) {
        final temLoja = _social.loja?.ativa == true;
        final abas = <(Widget, NavigationDestination)>[
          (
            HojeScreen(
              aluno: widget.aluno,
              store: _store,
              social: _social,
              irParaSemana: () => setState(() => _aba = 1),
              abrirNotificacao: (tipo) => setState(() {
                _aba = switch (tipo) {
                  'treino' => 1,
                  'aviso' => 2,
                  'pagamento' => 3,
                  'aniversario' when temLoja => 4,
                  _ => _aba,
                };
              }),
            ),
            const NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Hoje'),
          ),
          (
            CalendarioScreen(store: _store),
            const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          ),
          (
            const MuralScreen(),
            const NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Mural'),
          ),
          (
            const FinanceiroScreen(),
            const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Financeiro'),
          ),
          if (temLoja)
            (
              LojaScreen(social: _social),
              const NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: 'Loja'),
            ),
          (
            PerfilScreen(aluno: widget.aluno, store: _store),
            const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
          ),
        ];
        final aba = _aba.clamp(0, abas.length - 1);

        return Scaffold(
          body: Fundo(
            child: Column(
              children: [
                const _AvisoConexao(),
                Expanded(child: IndexedStack(index: aba, children: [for (final a in abas) a.$1])),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: aba,
            labelBehavior: abas.length > 5 ? NavigationDestinationLabelBehavior.onlyShowSelected : null,
            onDestinationSelected: (i) => setState(() => _aba = i),
            destinations: [for (final a in abas) a.$2],
          ),
        );
      },
    );
  }
}

class _AvisoConexao extends StatelessWidget {
  const _AvisoConexao();

  @override
  Widget build(BuildContext context) {
    final api = Api.instancia;
    return ListenableBuilder(
      listenable: Listenable.merge([api.semConexao, api.pendentes]),
      builder: (context, _) {
        final offline = api.semConexao.value;
        final n = api.pendentes.value;
        if (!offline && n == 0) return const SizedBox.shrink();
        final texto = offline
            ? (n > 0
                ? 'Sem internet. $n ${n == 1 ? 'registro aguardando' : 'registros aguardando'} envio.'
                : 'Sem internet. Mostrando os últimos dados salvos.')
            : 'Enviando $n ${n == 1 ? 'registro salvo' : 'registros salvos'} no celular...';
        return SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Cores.amarelo.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Cores.amarelo.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_upload_rounded, size: 18, color: Cores.amareloClaro),
                const SizedBox(width: 10),
                Expanded(child: Text(texto, style: const TextStyle(fontSize: 12.5, color: Cores.amareloClaro, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        );
      },
    );
  }
}
