import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../models.dart';
import '../notificacoes.dart';
import '../social_store.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';
import '../widgets/exercicio_widgets.dart';
import '../widgets/notificacoes_sheet.dart';
import 'minha_ficha_screen.dart';

class HojeScreen extends StatelessWidget {
  final Aluno aluno;
  final TreinoStore store;
  final SocialStore social;
  final VoidCallback irParaSemana;
  final void Function(String tipo) abrirNotificacao;

  const HojeScreen({
    super.key,
    required this.aluno,
    required this.store,
    required this.social,
    required this.irParaSemana,
    required this.abrirNotificacao,
  });

  bool get _aniversarioHoje {
    final d = aluno.dataNascimento;
    final hoje = DateTime.now();
    return d != null && d.month == hoje.month && d.day == hoje.day;
  }

  Future<void> _observacao(BuildContext context, DateTime hoje) async {
    final atual = store.realizadoEm(hoje);
    final ctrl = TextEditingController(text: atual?.observacao ?? '');
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Como foi o treino?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(hintText: 'Ex: aumentei a carga no supino, senti o joelho no agachamento...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (texto == null || atual == null) return;
    try {
      await store.salvarDia(hoje, atual.idsFeitos, observacao: texto.isEmpty ? null : texto);
      if (context.mounted) mostrarMensagem(context, 'Anotação salva.');
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hoje = Helpers.soData(DateTime.now());
        final lista = store.doDia(hoje);
        final feitos = store.feitosEm(hoje);
        final realizado = store.realizadoEm(hoje);

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => Future.wait([store.carregar(), social.carregar()]),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    const Logo(tamanho: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${Helpers.getSaudacao(DateTime.now().hour)},',
                              style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                          Text(aluno.primeiroNome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                        ],
                      ),
                    ),
                    if (aluno.academia != null) Flexible(child: Selo(aluno.academia!, tipo: TipoSelo.marca)),
                    const SizedBox(width: 4),
                    BotaoNotificacoes(social: social, abrir: abrirNotificacao),
                  ],
                ),
                const SizedBox(height: 18),
                if (_aniversarioHoje) ...[
                  _Aniversario(nome: aluno.primeiroNome, social: social),
                  const SizedBox(height: 12),
                ],
                _ResumoSemana(store: store, onTap: irParaSemana),
                const SizedBox(height: 12),
                const CronometroDescanso(),
                TituloSecao(
                  'Treino de ${Helpers.obterDiaAtual(hoje.weekday).toLowerCase()}',
                  acao: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MinhaFichaScreen(store: store))),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Minha ficha'),
                  ),
                ),
                if (store.carregando && store.ficha.isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                else if (store.erro != null)
                  Erro(mensagem: store.erro!, onTentar: store.carregar)
                else if (lista.isEmpty)
                  Cartao(
                    child: Vazio(
                      icone: Icons.self_improvement_rounded,
                      titulo: 'Dia de descanso',
                      texto: store.ficha.isEmpty
                          ? 'Sua ficha ainda está vazia. Fale com seu professor ou adicione exercícios.'
                          : 'Nenhum exercício para hoje. Aproveite para recuperar.',
                      acao: OutlinedButton.icon(
                        onPressed: irParaSemana,
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: const Text('Ver o calendário'),
                      ),
                    ),
                  )
                else ...[
                  Builder(builder: (_) {
                    final (feitas, total) = store.progressoSeries(hoje);
                    return Cartao(child: BarraProgresso(feitos: feitas, total: total));
                  }),
                  const SizedBox(height: 12),
                  for (final ex in lista)
                    LinhaExercicio(
                      exercicio: ex,
                      gif: store.gifDe(ex),
                      feito: feitos.contains(ex.id),
                      seriesFeitas: store.seriesFeitas(hoje, ex),
                      iniciado: store.registroDe(hoje, ex.id) != null,
                      podeMarcar: true,
                      onMarcar: () => abrirRegistro(context, store, ex, hoje),
                      onAbrir: () => abrirDemonstracao(context, store, ex),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: realizado == null ? null : () => _observacao(context, hoje),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: Text(realizado?.observacao == null ? 'Anotar como foi o treino' : 'Ver anotação do treino'),
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

class _Aniversario extends StatelessWidget {
  final String nome;
  final SocialStore social;

  const _Aniversario({required this.nome, required this.social});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: social,
      builder: (context, _) {
        final loja = social.loja;
        final linhas = [
          'A equipe da academia deseja um ótimo dia para você.',
          if (loja != null && loja.ativa && loja.descontoAniversario > 0) 'Hoje você tem ${loja.descontoAniversario}% de desconto na loja.',
        ];
        return Cartao(
          corBorda: const Color(0x6122C55E),
          child: Row(
            children: [
              const IconeChip(Icons.celebration_rounded, cor: Cores.verde),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feliz aniversário, $nome!', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (linhas.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(linhas.join(' '), style: const TextStyle(color: Cores.textoSuave, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResumoSemana extends StatelessWidget {
  final TreinoStore store;
  final VoidCallback onTap;

  const _ResumoSemana({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = store.frequencia;
    final segunda = Helpers.segundaDaSemana(DateTime.now());
    final hoje = Helpers.soData(DateTime.now());
    return Cartao(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconeChip(Icons.local_fire_department_rounded, cor: Cores.amarelo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sua semana', style: TextStyle(color: Cores.textoSuave, fontSize: 13)),
                    Text(
                      f == null
                          ? '...'
                          : f.diasPorSemana == 0
                              ? '${f.treinosSemana} ${f.treinosSemana == 1 ? 'treino' : 'treinos'}'
                              : '${f.treinosSemana} de ${f.diasPorSemana} treinos',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
              ),
              if (f != null) Selo('${f.percentual}% no mês', tipo: f.percentual >= 75 ? TipoSelo.ok : f.percentual >= 40 ? TipoSelo.aviso : TipoSelo.neutro),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (i) {
              final d = segunda.add(Duration(days: i));
              final r = store.realizadoEm(d);
              final previsto = store.doDia(d).isNotEmpty;
              final ehHoje = Helpers.mesmoDia(d, hoje);
              Color cor = Cores.superficie2;
              if (r != null) cor = r.concluido ? Cores.verde : Cores.amarelo;
              return Expanded(
                child: Column(
                  children: [
                    Text(Helpers.diasCurtos[i],
                        style: TextStyle(fontSize: 11.5, color: ehHoje ? Cores.texto : Cores.textoFraco, fontWeight: ehHoje ? FontWeight.w800 : FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r != null ? cor.withValues(alpha: 0.25) : Colors.transparent,
                        border: Border.all(
                          color: r != null ? cor : (previsto ? Cores.bordaForte : Cores.borda),
                          width: ehHoje ? 2 : 1,
                        ),
                      ),
                      child: r != null ? Icon(r.concluido ? Icons.check_rounded : Icons.more_horiz_rounded, size: 15, color: cor) : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CronometroDescanso extends StatefulWidget {
  const CronometroDescanso({super.key});

  @override
  State<CronometroDescanso> createState() => _CronometroDescansoState();
}

class _CronometroDescansoState extends State<CronometroDescanso> {
  Timer? _timer;
  int _restante = 0;
  int _total = 0;

  void _iniciar(int segundos) {
    _timer?.cancel();
    setState(() {
      _restante = segundos;
      _total = segundos;
    });
    Notificacoes.iniciarDescanso(segundos);
    final fim = DateTime.now().add(Duration(seconds: segundos));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final falta = fim.difference(DateTime.now()).inMilliseconds;
      setState(() => _restante = falta <= 0 ? 0 : (falta / 1000).ceil());
      if (_restante == 0) {
        t.cancel();
        final naTela = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        Notificacoes.descansoTerminou(emPrimeiroPlano: naTela);
        if (naTela) _avisarFim();
      }
    });
  }

  Future<void> _avisarFim() async {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.timer_off_rounded, color: Cores.verde, size: 40),
        title: const Text('Descanso terminou', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Hora da próxima série!', textAlign: TextAlign.center, style: TextStyle(color: Cores.textoSuave)),
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

  void _parar() {
    _timer?.cancel();
    Notificacoes.pararDescanso();
    setState(() => _restante = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _restante > 0;
    return Cartao(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: ativo ? Cores.verde : Cores.lilas, size: 22),
              const SizedBox(width: 10),
              Text(
                ativo ? Helpers.formatarTempoDescanso(_restante) : 'Descanso',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: ativo ? 20 : 15, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const Spacer(),
              for (final s in const [60, 90, 120]) ...[
                _BotaoTempo(rotulo: s % 60 == 0 ? '${s ~/ 60}min' : '${s / 60}min'.replaceAll('.', ','), onTap: () => _iniciar(s)),
                const SizedBox(width: 6),
              ],
              if (ativo)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Parar',
                  onPressed: _parar,
                  icon: const Icon(Icons.stop_circle_rounded, color: Cores.vermelhoClaro),
                ),
            ],
          ),
          if (ativo) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _total == 0 ? 0 : _restante / _total,
                minHeight: 5,
                backgroundColor: Cores.superficie2,
                valueColor: const AlwaysStoppedAnimation(Cores.verde),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BotaoTempo extends StatelessWidget {
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoTempo({required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Cores.marca.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Cores.marca.withValues(alpha: 0.4)),
        ),
        child: Text(rotulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFDDD6FE))),
      ),
    );
  }
}
