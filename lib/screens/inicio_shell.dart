import 'package:flutter/material.dart';

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
    _store.carregar();
    _social.carregar();
    Notificacoes.aoEntrar();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _social.carregarNotificacoes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          body: Fundo(child: IndexedStack(index: aba, children: [for (final a in abas) a.$1])),
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
