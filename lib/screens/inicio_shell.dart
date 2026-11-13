import 'package:flutter/material.dart';

import '../models.dart';
import '../treino_store.dart';
import '../widgets/comum.dart';
import 'hoje_screen.dart';
import 'mural_screen.dart';
import 'perfil_screen.dart';
import 'semana_screen.dart';
import 'turma_screen.dart';

class InicioShell extends StatefulWidget {
  final Aluno aluno;

  const InicioShell({super.key, required this.aluno});

  @override
  State<InicioShell> createState() => _InicioShellState();
}

class _InicioShellState extends State<InicioShell> {
  final _store = TreinoStore();
  int _aba = 0;

  @override
  void initState() {
    super.initState();
    _store.carregar();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      HojeScreen(aluno: widget.aluno, store: _store, irParaSemana: () => setState(() => _aba = 1)),
      SemanaScreen(store: _store),
      const MuralScreen(),
      const TurmaScreen(),
      PerfilScreen(aluno: widget.aluno, store: _store),
    ];

    return Scaffold(
      body: Fundo(child: IndexedStack(index: _aba, children: telas)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Hoje'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Semana'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Mural'),
          NavigationDestination(icon: Icon(Icons.cake_outlined), selectedIcon: Icon(Icons.cake), label: 'Turma'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
