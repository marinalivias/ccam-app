import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../social_store.dart';
import '../theme.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';

class TurmaScreen extends StatefulWidget {
  final SocialStore social;

  const TurmaScreen({super.key, required this.social});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  List<Aniversariante>? _lista;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _lista = null;
      _erro = null;
    });
    try {
      final mes = '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}';
      final resp = await Api.instancia.get('/aniversariantes?mes=$mes') as List;
      if (mounted) setState(() => _lista = resp.map((e) => Aniversariante.fromJson(e)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  Future<void> _parabens(Aniversariante a) async {
    try {
      final msg = await widget.social.mandarParabens(a.id);
      if (mounted) mostrarMensagem(context, msg);
      _carregar();
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  void _mudarMes(int delta) {
    _mes = DateTime(_mes.year, _mes.month + delta);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final nomeMes = Helpers.meses[_mes.month - 1];
    final lista = _lista ?? [];
    final deHoje = lista.where((a) => a.hoje).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Aniversariantes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('Quem treina com você e faz aniversário no mês.', style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
            const SizedBox(height: 18),
            Cartao(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(tooltip: 'Mês anterior', onPressed: () => _mudarMes(-1), icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(
                    child: Text(
                      '${nomeMes[0].toUpperCase()}${nomeMes.substring(1)} de ${_mes.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(tooltip: 'Próximo mês', onPressed: () => _mudarMes(1), icon: const Icon(Icons.chevron_right_rounded)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (deHoje.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Cartao(
                  corBorda: const Color(0x6122C55E),
                  child: Row(
                    children: [
                      const IconeChip(Icons.celebration_rounded, cor: Cores.verde),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          deHoje.any((a) => a.voce)
                              ? 'Hoje é o seu aniversário. Parabéns! A academia toda deseja um ótimo dia.'
                              : 'Hoje é aniversário de ${deHoje.map((a) => a.nome).join(', ')}. Dê os parabéns no treino!',
                          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_erro != null)
              Erro(mensagem: _erro!, onTentar: _carregar)
            else if (_lista == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (lista.isEmpty)
              Cartao(child: Vazio(icone: Icons.cake_outlined, titulo: 'Ninguém faz aniversário em $nomeMes'))
            else
              Cartao(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < lista.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _Linha(
                        item: lista[i],
                        passou: _mes.year == hoje.year && _mes.month == hoje.month && lista[i].dia < hoje.day,
                        onParabens: () => _parabens(lista[i]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final Aniversariante item;
  final bool passou;
  final VoidCallback onParabens;

  const _Linha({required this.item, required this.passou, required this.onParabens});

  @override
  Widget build(BuildContext context) {
    final iniciais = item.nome.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase();
    return Opacity(
      opacity: passou ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Cores.marca, Cores.verde], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Text(iniciais, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.voce ? '${item.nome} (você)' : item.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Dia ${item.dia.toString().padLeft(2, '0')}', style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                ],
              ),
            ),
            if (item.hoje && !item.voce)
              item.parabensEnviado
                  ? const Selo('Parabéns enviado', tipo: TipoSelo.ok)
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Cores.verde.withValues(alpha: 0.2),
                        foregroundColor: Cores.verdeClaro,
                        side: const BorderSide(color: Color(0x6122C55E)),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onParabens,
                      icon: const Icon(Icons.celebration_rounded, size: 18),
                      label: const Text('Parabéns'),
                    )
            else if (item.hoje)
              const Selo('Hoje', tipo: TipoSelo.ok)
            else if (item.voce)
              const Selo('Você', tipo: TipoSelo.marca),
          ],
        ),
      ),
    );
  }
}
