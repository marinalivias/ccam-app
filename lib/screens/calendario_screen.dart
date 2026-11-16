import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';
import '../widgets/exercicio_widgets.dart';
import 'minha_ficha_screen.dart';

class CalendarioScreen extends StatefulWidget {
  final TreinoStore store;

  const CalendarioScreen({super.key, required this.store});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selecionado = Helpers.soData(DateTime.now());
  bool _carregandoMes = false;

  TreinoStore get store => widget.store;
  DateTime get _hoje => Helpers.soData(DateTime.now());

  @override
  void initState() {
    super.initState();
    _mudarMes(0);
  }

  Future<void> _mudarMes(int delta) async {
    final novo = DateTime(_mes.year, _mes.month + delta);
    final mesAtual = novo.year == _hoje.year && novo.month == _hoje.month;
    setState(() {
      _mes = novo;
      if (delta != 0) _selecionado = mesAtual ? _hoje : novo;
      _carregandoMes = true;
    });
    try {
      final ultimo = DateTime(novo.year, novo.month + 1, 0);
      if (!novo.isAfter(_hoje)) await store.carregarPeriodo(novo, ultimo.isAfter(_hoje) ? _hoje : ultimo);
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _carregandoMes = false);
    }
  }

  bool _podeMarcar(DateTime d) => !d.isAfter(_hoje) && !d.isBefore(_hoje.subtract(const Duration(days: 30)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final lista = store.doDia(_selecionado);
        final feitos = store.feitosEm(_selecionado);
        final realizado = store.realizadoEm(_selecionado);
        final futuro = _selecionado.isAfter(_hoje);
        final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
        final vazios = DateTime(_mes.year, _mes.month, 1).weekday - 1;
        final celulas = ((vazios + diasNoMes) / 7).ceil() * 7;
        var treinosMes = 0;
        var completosMes = 0;
        var previstosMes = 0;
        for (var d = 1; d <= diasNoMes; d++) {
          final data = DateTime(_mes.year, _mes.month, d);
          final r = store.realizadoEm(data);
          if (r != null) {
            treinosMes++;
            if (r.concluido) completosMes++;
          }
          if (!data.isAfter(_hoje) && store.doDia(data).isNotEmpty) previstosMes++;
        }
        final nomeMes = Helpers.meses[_mes.month - 1];
        final titulo = '${nomeMes[0].toUpperCase()}${nomeMes.substring(1)} de ${_mes.year}';

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _mudarMes(0),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Calendário', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ),
                    BotaoPilula(
                      texto: 'Minha ficha',
                      icone: Icons.edit_note_rounded,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MinhaFichaScreen(store: store))),
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
                          IconButton(tooltip: 'Mês anterior', onPressed: () => _mudarMes(-1), icon: const Icon(Icons.chevron_left_rounded)),
                          Expanded(
                            child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                          ),
                          IconButton(tooltip: 'Próximo mês', onPressed: () => _mudarMes(1), icon: const Icon(Icons.chevron_right_rounded)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final d in Helpers.diasCurtos)
                            Expanded(
                              child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: Cores.textoFraco, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (var linha = 0; linha < celulas ~/ 7; linha++)
                        Row(
                          children: List.generate(7, (col) {
                            final n = linha * 7 + col - vazios + 1;
                            if (n < 1 || n > diasNoMes) return const Expanded(child: SizedBox(height: 46));
                            final d = DateTime(_mes.year, _mes.month, n);
                            return Expanded(
                              child: _Dia(
                                data: d,
                                store: store,
                                selecionado: Helpers.mesmoDia(d, _selecionado),
                                hoje: Helpers.mesmoDia(d, _hoje),
                                onTap: () => setState(() => _selecionado = d),
                              ),
                            );
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Resumo(valor: '$treinosMes', rotulo: treinosMes == 1 ? 'Treino no mês' : 'Treinos no mês'),
                    _Resumo(valor: '$completosMes', rotulo: completosMes == 1 ? 'Completo' : 'Completos'),
                    _Resumo(valor: previstosMes == 0 ? '--' : '${(treinosMes * 100 / previstosMes).round().clamp(0, 100)}%', rotulo: 'Dos previstos'),
                  ],
                ),
                TituloSecao('${Helpers.obterDiaAtual(_selecionado.weekday)}, ${Helpers.dataPorExtenso(_selecionado)}'),
                if (_carregandoMes)
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
                      onMarcar: () => abrirRegistro(context, store, ex, _selecionado),
                      onAbrir: () => abrirDemonstracao(context, store, ex),
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selecionado ? Cores.marca.withValues(alpha: 0.3) : Colors.transparent,
          border: Border.all(color: selecionado ? const Color(0x99A78BFA) : (hoje ? Cores.bordaForte : Colors.transparent)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${data.day}', style: TextStyle(fontSize: 15, fontWeight: hoje || selecionado ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: marca ?? Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Resumo({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Cores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Cores.borda),
        ),
        child: Column(
          children: [
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(rotulo, textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoFraco, fontSize: 11.5)),
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
