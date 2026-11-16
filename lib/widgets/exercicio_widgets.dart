import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import 'comum.dart';

class Miniatura extends StatelessWidget {
  final String? url;
  final double tamanho;

  const Miniatura(this.url, {super.key, this.tamanho = 52});

  @override
  Widget build(BuildContext context) {
    final vazio = Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Cores.marca.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.marca.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.fitness_center_rounded, color: Cores.lilas, size: 22),
    );
    final link = urlImagem(url);
    if (link == null) return vazio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.white,
        child: Image.network(link, width: tamanho, height: tamanho, fit: BoxFit.cover, errorBuilder: (_, _, _) => vazio),
      ),
    );
  }
}

class LinhaExercicio extends StatelessWidget {
  final Exercicio exercicio;
  final String? gif;
  final bool feito;
  final int seriesFeitas;
  final bool iniciado;
  final bool podeMarcar;
  final VoidCallback onMarcar;
  final VoidCallback onAbrir;

  const LinhaExercicio({
    super.key,
    required this.exercicio,
    this.gif,
    required this.feito,
    this.seriesFeitas = 0,
    this.iniciado = false,
    required this.podeMarcar,
    required this.onMarcar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final parcial = !feito && (seriesFeitas > 0 || iniciado);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Cartao(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        corBorda: feito ? const Color(0x6122C55E) : (parcial ? const Color(0x61F59E0B) : null),
        onTap: onAbrir,
        child: Row(
          children: [
            Miniatura(gif ?? exercicio.imagemUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      decoration: feito ? TextDecoration.lineThrough : null,
                      decorationColor: Cores.textoFraco,
                      color: feito ? Cores.textoSuave : Cores.texto,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(exercicio.resumo, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (parcial)
                    Selo('$seriesFeitas de ${exercicio.totalSeries} séries', tipo: TipoSelo.aviso)
                  else
                    Text(
                      'Toque para ver como fazer',
                      style: const TextStyle(color: Cores.textoFraco, fontSize: 12),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: feito ? 'Desmarcar' : 'Marcar tudo como feito',
              onPressed: podeMarcar ? onMarcar : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  feito
                      ? Icons.check_circle_rounded
                      : parcial
                          ? Icons.timelapse_rounded
                          : Icons.radio_button_unchecked_rounded,
                  key: ValueKey('$feito$parcial'),
                  size: 30,
                  color: feito ? Cores.verde : (parcial ? Cores.amarelo : (podeMarcar ? Cores.textoFraco : Cores.borda)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarraProgresso extends StatelessWidget {
  final int feitos;
  final int total;
  final String unidade;

  const BarraProgresso({super.key, required this.feitos, required this.total, this.unidade = 'séries'});

  @override
  Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : (feitos / total).clamp(0.0, 1.0);
    final completo = total > 0 && feitos >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              completo ? 'Treino completo!' : '$feitos de $total $unidade feitas',
              style: TextStyle(fontWeight: FontWeight.w700, color: completo ? Cores.verdeClaro : Cores.texto),
            ),
            const Spacer(),
            Text('${(p * 100).round()}%', style: const TextStyle(color: Cores.textoSuave, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: Cores.superficie2,
            valueColor: AlwaysStoppedAnimation(completo ? Cores.verde : Cores.marcaClara),
          ),
        ),
      ],
    );
  }
}

bool podeRegistrar(DateTime data) {
  final hoje = Helpers.soData(DateTime.now());
  return !data.isAfter(hoje) && !data.isBefore(hoje.subtract(const Duration(days: 30)));
}

Future<void> abrirDemonstracao(BuildContext context, TreinoStore store, Exercicio ex) {
  final gif = urlImagem(store.gifDe(ex));
  final passos = store.doCatalogo(ex.nome)?.passos ?? const <String>[];
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (gif != null)
                Container(
                  color: Colors.white,
                  child: Image.network(
                    gif,
                    fit: BoxFit.contain,
                    loadingBuilder: (c, child, p) => p == null ? child : const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
                    errorBuilder: (_, _, _) => const SizedBox(height: 80, child: Center(child: Text('Demonstração indisponível', style: TextStyle(color: Colors.black54)))),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${ex.resumo}${ex.grupoMuscular != null ? '  ·  ${ex.grupoMuscular}' : ''}', style: const TextStyle(color: Cores.textoSuave)),
                    const SizedBox(height: 14),
                    if (passos.isEmpty)
                      const Text('Sem passo a passo para este exercício.', style: TextStyle(color: Cores.textoFraco))
                    else
                      for (var i = 0; i < passos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Cores.marca.withValues(alpha: 0.25), shape: BoxShape.circle),
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFFDDD6FE))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(passos[i], style: const TextStyle(color: Cores.textoSuave, height: 1.45))),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> abrirRegistro(BuildContext context, TreinoStore store, Exercicio ex, DateTime data) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _Registro(store: store, exercicio: ex, data: data, contextoTela: context),
  );
}

class _Registro extends StatefulWidget {
  final TreinoStore store;
  final Exercicio exercicio;
  final DateTime data;
  final BuildContext contextoTela;

  const _Registro({required this.store, required this.exercicio, required this.data, required this.contextoTela});

  @override
  State<_Registro> createState() => _RegistroState();
}

class _RegistroState extends State<_Registro> {
  late final List<int> _reps;
  late final TextEditingController _carga;
  bool? _completou;
  bool _salvando = false;
  late final bool _jaRegistrado;
  (DateTime, String)? _ultima;

  Exercicio get ex => widget.exercicio;
  int get _meta => ex.alvoReps ?? 1;
  bool get _porTempo => ex.alvoReps == null;

  @override
  void initState() {
    super.initState();
    final r = widget.store.registroDe(widget.data, ex.id);
    final completo = widget.store.feitosEm(widget.data).contains(ex.id);
    _jaRegistrado = r != null || completo;
    _reps = List.generate(ex.totalSeries, (i) {
      if (r != null && i < r.reps.length) return r.reps[i];
      return completo ? _meta : _meta;
    });
    if (_jaRegistrado) _completou = completo || (r != null && r.completo);
    if (_completou == false && r != null) {
      for (var i = 0; i < _reps.length; i++) {
        _reps[i] = i < r.reps.length ? r.reps[i] : 0;
      }
    }
    _ultima = widget.store.ultimaCarga(ex.id, widget.data);
    _carga = TextEditingController(text: r?.carga ?? _ultima?.$2 ?? ex.carga ?? '');
  }

  @override
  void dispose() {
    _carga.dispose();
    super.dispose();
  }

  Future<void> _enviar(List<int> reps, String mensagem) async {
    setState(() => _salvando = true);
    try {
      await widget.store.registrar(widget.data, ex.id, reps, _carga.text.trim().isEmpty ? null : _carga.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      if (widget.contextoTela.mounted) {
        mostrarMensagem(widget.contextoTela, widget.store.guardadoOffline ? 'Sem internet: salvo no celular. Enviamos quando a conexão voltar.' : mensagem);
      }
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _confirmar() {
    if (_completou == true) {
      _enviar(List.filled(_reps.length, _meta), '${ex.nome}: todas as séries feitas!');
      return;
    }
    final feitas = _reps.where((v) => v >= _meta).length;
    if (_reps.every((v) => v == 0)) {
      mostrarMensagem(context, 'Marque pelo menos uma série ou toque em Desmarcar.', erro: true);
      return;
    }
    _enviar(List.of(_reps), '${ex.nome}: $feitas de ${_reps.length} séries completas.');
  }

  Widget _opcao(bool valor, IconData icone, String titulo, String texto, Color cor) {
    final ativo = _completou == valor;
    return Cartao(
      padding: const EdgeInsets.all(14),
      corBorda: ativo ? cor : null,
      onTap: () => setState(() {
        _completou = valor;
        if (!valor && _reps.every((v) => v >= _meta)) {
          for (var i = 0; i < _reps.length; i++) {
            _reps[i] = i < _reps.length - 1 ? _meta : 0;
          }
        }
      }),
      child: Row(
        children: [
          Icon(icone, color: ativo ? cor : Cores.textoFraco, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(texto, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
              ],
            ),
          ),
          Icon(ativo ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: ativo ? cor : Cores.textoFraco),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ex.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(ex.resumo, style: const TextStyle(color: Cores.textoSuave)),
            const SizedBox(height: 16),
            const Text('Você completou todas as séries?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            _opcao(true, Icons.check_circle_rounded, 'Sim, completei todas', '${ex.totalSeries} séries de ${ex.repeticoes}', Cores.verde),
            const SizedBox(height: 8),
            _opcao(false, Icons.timelapse_rounded, 'Não completei todas', 'Marque quanto você fez em cada série', Cores.amarelo),
            if (_completou == false) ...[
              const SizedBox(height: 12),
              Cartao(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Column(
                  children: [
                    for (var i = 0; i < _reps.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _LinhaSerie(
                        numero: i + 1,
                        valor: _reps[i],
                        meta: _meta,
                        porTempo: _porTempo,
                        rotuloMeta: ex.repeticoes,
                        onChanged: (v) => setState(() => _reps[i] = v),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Toque na série para marcar completa ou ajuste as repetições no - e +.',
                    style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
              ),
            ],
            const SizedBox(height: 14),
            TextField(controller: _carga, decoration: const InputDecoration(labelText: 'Carga que você usou', hintText: 'Ex: 20kg')),
            if (_ultima != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: Cores.lilas),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Da última vez (${Helpers.dataCurta(_ultima!.$1).substring(0, 5)}) você usou ${_ultima!.$2}.'
                      '${widget.store.registroDe(widget.data, ex.id)?.carga == null ? ' Já deixamos preenchido.' : ''}'
                      '${ex.carga != null && ex.carga!.trim().isNotEmpty && ex.carga!.trim() != _ultima!.$2 ? ' Na ficha: ${ex.carga}.' : ''}',
                      style: const TextStyle(color: Cores.textoSuave, fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            BotaoMarca(
              texto: 'Confirmar',
              icone: Icons.check_rounded,
              carregando: _salvando,
              onPressed: _completou == null ? null : _confirmar,
            ),
            if (_jaRegistrado)
              TextButton(
                onPressed: _salvando ? null : () => _enviar(List.filled(_reps.length, 0), '${ex.nome}: registro desfeito.'),
                child: const Text('Desmarcar este exercício'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaSerie extends StatelessWidget {
  final int numero;
  final int valor;
  final int meta;
  final bool porTempo;
  final String rotuloMeta;
  final ValueChanged<int> onChanged;

  const _LinhaSerie({
    required this.numero,
    required this.valor,
    required this.meta,
    required this.porTempo,
    required this.rotuloMeta,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final completa = valor >= meta;
    final cor = completa ? Cores.verde : (valor > 0 ? Cores.amarelo : Cores.textoFraco);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(completa ? 0 : meta),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(completa ? Icons.check_circle_rounded : (valor > 0 ? Icons.timelapse_rounded : Icons.circle_outlined), color: cor, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Série $numero', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            porTempo ? rotuloMeta : (valor > 0 && !completa ? 'Fez $valor de $meta reps' : 'Meta: $meta reps'),
                            style: TextStyle(color: valor > 0 && !completa ? Cores.amareloClaro : Cores.textoFraco, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (porTempo)
            Switch(
              value: valor >= 1,
              activeThumbColor: Colors.white,
              activeTrackColor: Cores.verde,
              onChanged: (v) => onChanged(v ? 1 : 0),
            )
          else ...[
            IconButton(
              tooltip: 'Menos uma',
              onPressed: valor > 0 ? () => onChanged(valor - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            SizedBox(
              width: 30,
              child: Text('$valor', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: cor == Cores.textoFraco ? Cores.texto : cor)),
            ),
            IconButton(
              tooltip: 'Mais uma',
              onPressed: () => onChanged(valor + 1),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> abrirFormulario(BuildContext context, TreinoStore store, {Exercicio? exercicio, String? diaInicial}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _FormularioExercicio(store: store, exercicio: exercicio, diaInicial: diaInicial, contextoTela: context),
    ),
  );
}

class _Escolha {
  final ItemCatalogo? item;
  final String? nomeProprio;

  const _Escolha.catalogo(this.item) : nomeProprio = null;
  const _Escolha.proprio(this.nomeProprio) : item = null;
}

class _FormularioExercicio extends StatefulWidget {
  final TreinoStore store;
  final Exercicio? exercicio;
  final String? diaInicial;
  final BuildContext contextoTela;

  const _FormularioExercicio({required this.store, this.exercicio, this.diaInicial, required this.contextoTela});

  @override
  State<_FormularioExercicio> createState() => _FormularioExercicioState();
}

class _FormularioExercicioState extends State<_FormularioExercicio> {
  final _form = GlobalKey<FormState>();
  late final _series = TextEditingController(text: widget.exercicio?.series ?? '3');
  late final _reps = TextEditingController(text: widget.exercicio?.repeticoes ?? '12');
  late final _carga = TextEditingController(text: widget.exercicio?.carga ?? '');
  final _grupo = TextEditingController();
  late String _dia = widget.exercicio?.diaSemana ?? widget.diaInicial ?? Helpers.obterDiaAtual(DateTime.now().weekday);
  _Escolha? _escolhido;
  bool _salvando = false;

  bool get _editando => widget.exercicio != null;

  @override
  void dispose() {
    _series.dispose();
    _reps.dispose();
    _carga.dispose();
    _grupo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (!_editando && _escolhido == null) {
      mostrarMensagem(context, 'Escolha um exercício do catálogo ou crie o seu.', erro: true);
      return;
    }
    setState(() => _salvando = true);
    final dados = <String, String?>{
      'diaSemana': _dia,
      'series': _series.text.trim(),
      'repeticoes': _reps.text.trim(),
      'carga': _carga.text.trim().isEmpty ? null : _carga.text.trim(),
    };
    try {
      if (_editando) {
        await widget.store.editar(widget.exercicio!.id, dados);
      } else if (_escolhido!.item != null) {
        await widget.store.adicionar(_escolhido!.item!.id, dados);
      } else {
        await widget.store.adicionar(null, {
          ...dados,
          'nome': _escolhido!.nomeProprio,
          'grupoMuscular': _grupo.text.trim().isEmpty ? null : _grupo.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      if (widget.contextoTela.mounted) {
        mostrarMensagem(widget.contextoTela, _editando ? 'Exercício atualizado.' : 'Exercício adicionado à ficha.');
      }
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover() async {
    final ex = widget.exercicio!;
    final ok = await confirmar(context,
        titulo: 'Remover exercício?',
        mensagem: '${ex.nome} sai da sua ficha. Seu professor vê essa alteração no histórico.',
        botao: 'Remover',
        perigo: true);
    if (!ok || !mounted) return;
    try {
      await widget.store.remover(ex.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (widget.contextoTela.mounted) mostrarMensagem(widget.contextoTela, 'Exercício removido da ficha.');
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  Future<void> _escolher() async {
    final escolha = await showModalBottomSheet<_Escolha>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _Catalogo(store: widget.store),
    );
    if (escolha != null) setState(() => _escolhido = escolha);
  }

  @override
  Widget build(BuildContext context) {
    final dias = [...Helpers.dias, Helpers.rotativo];
    if (!dias.contains(_dia)) dias.add(_dia);
    final proprio = _escolhido?.nomeProprio != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editando ? 'Editar exercício' : 'Adicionar exercício', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                _editando ? widget.exercicio!.nome : 'Escolha no catálogo da academia ou crie o seu, em qualquer dia da semana.',
                style: const TextStyle(color: Cores.textoSuave),
              ),
              const SizedBox(height: 18),
              if (!_editando) ...[
                Cartao(
                  onTap: _escolher,
                  padding: const EdgeInsets.all(14),
                  corBorda: _escolhido != null ? Cores.marcaClara : null,
                  child: Row(
                    children: [
                      Miniatura(_escolhido?.item?.imagemUrl, tamanho: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_escolhido?.item?.nome ?? _escolhido?.nomeProprio ?? 'Escolher exercício',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              _escolhido?.item?.grupoMuscular ?? (proprio ? 'Exercício criado por você' : 'Toque para abrir o catálogo'),
                              style: const TextStyle(color: Cores.textoSuave, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Cores.textoFraco),
                    ],
                  ),
                ),
                if (proprio) ...[
                  const SizedBox(height: 12),
                  TextFormField(controller: _grupo, decoration: const InputDecoration(labelText: 'Grupo muscular (opcional)', hintText: 'Ex: Cardio')),
                ],
                const SizedBox(height: 14),
              ],
              DropdownButtonFormField<String>(
                initialValue: _dia,
                decoration: const InputDecoration(labelText: 'Dia da semana', prefixIcon: Icon(Icons.event_rounded, size: 20)),
                dropdownColor: const Color(0xFF111A2E),
                items: dias.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _dia = v ?? _dia),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _series,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Séries'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reps,
                      decoration: const InputDecoration(labelText: 'Repetições ou tempo'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _carga, decoration: const InputDecoration(labelText: 'Carga (opcional)', hintText: 'Ex: 20kg')),
              const SizedBox(height: 10),
              const Text('Seu professor vê no histórico tudo o que você mudar na ficha.', style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
              const SizedBox(height: 18),
              BotaoMarca(texto: _editando ? 'Salvar alterações' : 'Adicionar à ficha', icone: Icons.check_rounded, carregando: _salvando, onPressed: _salvar),
              if (_editando)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Cores.vermelhoClaro),
                  onPressed: _salvando ? null : _remover,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Remover da ficha'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Catalogo extends StatefulWidget {
  final TreinoStore store;

  const _Catalogo({required this.store});

  @override
  State<_Catalogo> createState() => _CatalogoState();
}

class _CatalogoState extends State<_Catalogo> {
  String? _erro;
  String _busca = '';
  Timer? _espera;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.store.catalogo.isEmpty) _carregar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await widget.store.carregarCatalogo();
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarProprio() async {
    final ctrl = TextEditingController(text: _busca.isEmpty ? '' : _busca[0].toUpperCase() + _busca.substring(1));
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar exercício', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nome do exercício', hintText: 'Ex: Corrida na esteira')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Usar')),
        ],
      ),
    );
    if (nome != null && nome.isNotEmpty && mounted) Navigator.pop(context, _Escolha.proprio(nome));
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.store.catalogo;
    final filtrados = itens
        .where((i) => _busca.isEmpty || i.nome.toLowerCase().contains(_busca) || i.grupoMuscular.toLowerCase().contains(_busca))
        .toList();
    final grupos = <String, List<ItemCatalogo>>{};
    for (final i in filtrados) {
      grupos.putIfAbsent(i.grupoMuscular, () => []).add(i);
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Buscar exercício ou grupo muscular', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) {
                _espera?.cancel();
                _espera = Timer(const Duration(milliseconds: 250), () => setState(() => _busca = v.trim().toLowerCase()));
              },
            ),
          ),
          Expanded(
            child: _erro != null
                ? Erro(mensagem: _erro!, onTentar: _carregar)
                : _carregando && itens.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          Cartao(
                            padding: const EdgeInsets.all(12),
                            corBorda: Cores.marcaClara,
                            onTap: _criarProprio,
                            child: const Row(
                              children: [
                                IconeChip(Icons.add_rounded),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Criar exercício próprio', style: TextStyle(fontWeight: FontWeight.w700)),
                                      Text('Para algo que não está no catálogo', style: TextStyle(color: Cores.textoSuave, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (filtrados.isEmpty) const Vazio(icone: Icons.search_off_rounded, titulo: 'Nada encontrado no catálogo'),
                          for (final g in grupos.entries) ...[
                            TituloSecao(g.key),
                            for (final item in g.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Cartao(
                                  padding: const EdgeInsets.all(10),
                                  onTap: () => Navigator.pop(context, _Escolha.catalogo(item)),
                                  child: Row(
                                    children: [
                                      Miniatura(item.imagemUrl, tamanho: 48),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      const Icon(Icons.add_circle_outline_rounded, color: Cores.lilas),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
