import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';
import '../widgets/exercicio_widgets.dart';
import 'minha_ficha_screen.dart';

class SemanaScreen extends StatefulWidget {
  final TreinoStore store;

  const SemanaScreen({super.key, required this.store});

  @override
  State<SemanaScreen> createState() => _SemanaScreenState();
}

class _SemanaScreenState extends State<SemanaScreen> {
  late DateTime _segunda = Helpers.segundaDaSemana(DateTime.now());
  late DateTime _selecionado = Helpers.soData(DateTime.now());
  bool _carregandoSemana = false;

  TreinoStore get store => widget.store;
  DateTime get _hoje => Helpers.soData(DateTime.now());

  Future<void> _mudarSemana(int delta) async {
    final nova = _segunda.add(Duration(days: 7 * delta));
    setState(() {
      _segunda = nova;
      _selecionado = Helpers.mesmoDia(Helpers.segundaDaSemana(_hoje), nova) ? _hoje : nova;
      _carregandoSemana = true;
    });
    try {
      final fim = nova.add(const Duration(days: 6));
      await store.carregarPeriodo(nova, fim.isAfter(_hoje) ? _hoje : fim);
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _carregandoSemana = false);
    }
  }

  bool _podeMarcar(DateTime d) => !d.isAfter(_hoje) && !d.isBefore(_hoje.subtract(const Duration(days: 30)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final fim = _segunda.add(const Duration(days: 6));
        final lista = store.doDia(_selecionado);
        final feitos = store.feitosEm(_selecionado);
        final realizado = store.realizadoEm(_selecionado);
        final futuro = _selecionado.isAfter(_hoje);
        final mesmoMes = _segunda.month == fim.month;
        final titulo = mesmoMes
            ? '${_segunda.day} a ${fim.day} de ${Helpers.meses[fim.month - 1]}'
            : '${Helpers.dataPorExtenso(_segunda)} a ${Helpers.dataPorExtenso(fim)}';

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _mudarSemana(0),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Agenda da semana', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MinhaFichaScreen(store: store))),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Minha ficha'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Toque em um dia para ver o treino e registrar o que fez.',
                    style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
                const SizedBox(height: 18),
                Cartao(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(tooltip: 'Semana anterior', onPressed: () => _mudarSemana(-1), icon: const Icon(Icons.chevron_left_rounded)),
                          Expanded(
                            child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          IconButton(tooltip: 'Próxima semana', onPressed: () => _mudarSemana(1), icon: const Icon(Icons.chevron_right_rounded)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(7, (i) {
                          final d = _segunda.add(Duration(days: i));
                          return Expanded(child: _Dia(data: d, store: store, selecionado: Helpers.mesmoDia(d, _selecionado), hoje: Helpers.mesmoDia(d, _hoje), onTap: () => setState(() => _selecionado = d)));
                        }),
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _Legenda(cor: Cores.verde, texto: 'Completo'),
                          _Legenda(cor: Cores.amarelo, texto: 'Parcial'),
                          _Legenda(cor: Cores.bordaForte, texto: 'Previsto'),
                        ],
                      ),
                    ],
                  ),
                ),
                TituloSecao(
                  '${Helpers.obterDiaAtual(_selecionado.weekday)}, ${Helpers.dataPorExtenso(_selecionado)}',
                  acao: TextButton.icon(
                    onPressed: () => abrirFormulario(context, store, diaInicial: Helpers.obterDiaAtual(_selecionado.weekday)),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ),
                if (_carregandoSemana)
                  const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
                else if (lista.isEmpty)
                  const Cartao(
                    child: Vazio(icone: Icons.self_improvement_rounded, titulo: 'Sem treino neste dia', texto: 'Dia livre para descansar.'),
                  )
                else ...[
                  if (!futuro) ...[
                    Builder(builder: (_) {
                      final (feitas, total) = store.progressoSeries(_selecionado);
                      return Cartao(child: BarraProgresso(feitos: feitas, total: total));
                    }),
                    const SizedBox(height: 12),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('Treino previsto. Você pode marcar quando o dia chegar.', style: TextStyle(color: Cores.textoFraco, fontSize: 13)),
                    ),
                  for (final ex in lista)
                    LinhaExercicio(
                      exercicio: ex,
                      gif: store.gifDe(ex),
                      seriesFeitas: store.seriesFeitas(_selecionado, ex),
                      iniciado: store.registroDe(_selecionado, ex.id) != null,
                      feito: feitos.contains(ex.id),
                      podeMarcar: _podeMarcar(_selecionado),
                      onMarcar: () async {
                        try {
                          await store.alternar(_selecionado, ex.id);
                        } on ApiException catch (e) {
                          if (context.mounted) mostrarMensagem(context, e.mensagem, erro: true);
                        }
                      },
                      onAbrir: () => abrirDetalhes(context, store, ex, data: _selecionado),
                    ),
                  if (realizado?.observacao != null)
                    Cartao(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Cores.lilas),
                          const SizedBox(width: 10),
                          Expanded(child: Text(realizado!.observacao!, style: const TextStyle(color: Cores.textoSuave))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dia extends StatelessWidget {
  final DateTime data;
  final TreinoStore store;
  final bool selecionado;
  final bool hoje;
  final VoidCallback onTap;

  const _Dia({required this.data, required this.store, required this.selecionado, required this.hoje, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = store.realizadoEm(data);
    final qtd = store.doDia(data).length;
    Color? marca;
    if (r != null) {
      marca = r.concluido ? Cores.verde : Cores.amarelo;
    } else if (qtd > 0) {
      marca = Cores.bordaForte;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selecionado ? Cores.marca.withValues(alpha: 0.3) : Colors.transparent,
          border: Border.all(color: selecionado ? const Color(0x99A78BFA) : (hoje ? Cores.bordaForte : Colors.transparent)),
        ),
        child: Column(
          children: [
            Text(Helpers.diasCurtos[data.weekday - 1],
                style: TextStyle(fontSize: 11.5, color: selecionado ? Cores.texto : Cores.textoFraco, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${data.day}', style: TextStyle(fontSize: 17, fontWeight: hoje || selecionado ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: marca ?? Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const _Legenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12, color: Cores.textoSuave)),
      ],
    );
  }
}
