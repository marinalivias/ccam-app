import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
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
    if (url == null || url!.isEmpty) return vazio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url!, width: tamanho, height: tamanho, fit: BoxFit.cover, errorBuilder: (_, _, _) => vazio),
    );
  }
}

class LinhaExercicio extends StatelessWidget {
  final Exercicio exercicio;
  final bool feito;
  final bool podeMarcar;
  final VoidCallback onMarcar;
  final VoidCallback onAbrir;

  const LinhaExercicio({
    super.key,
    required this.exercicio,
    required this.feito,
    required this.podeMarcar,
    required this.onMarcar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Cartao(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        corBorda: feito ? const Color(0x6122C55E) : null,
        onTap: onAbrir,
        child: Row(
          children: [
            Miniatura(exercicio.imagemUrl),
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
                  if (exercicio.grupoMuscular != null) ...[
                    const SizedBox(height: 2),
                    Text(exercicio.grupoMuscular!, style: const TextStyle(color: Cores.textoFraco, fontSize: 12)),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: feito ? 'Desmarcar' : 'Marcar como feito',
              onPressed: podeMarcar ? onMarcar : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  feito ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(feito),
                  size: 30,
                  color: feito ? Cores.verde : (podeMarcar ? Cores.textoFraco : Cores.borda),
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

  const BarraProgresso({super.key, required this.feitos, required this.total});

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
              completo ? 'Treino completo!' : '$feitos de $total exercícios feitos',
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

Future<void> abrirDetalhes(BuildContext context, TreinoStore store, Exercicio ex) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ex.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (ex.grupoMuscular != null)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(ex.grupoMuscular!, style: const TextStyle(color: Cores.textoSuave))),
            const SizedBox(height: 16),
            if (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ex.imagemUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, p) => p == null ? child : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (_, _, _) => const SizedBox(height: 60, child: Center(child: Text('Demonstração indisponível', style: TextStyle(color: Cores.textoFraco)))),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Dado('Séries', ex.series),
                _Dado('Repetições', ex.repeticoes),
                _Dado('Carga', (ex.carga ?? '').isEmpty ? 'Livre' : ex.carga!),
              ],
            ),
            const SizedBox(height: 10),
            Cartao(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 18, color: Cores.lilas),
                  const SizedBox(width: 10),
                  Text(ex.diaSemana, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Cores.vermelhoClaro,
                      side: const BorderSide(color: Color(0x61EF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final ok = await confirmar(ctx,
                          titulo: 'Remover exercício?',
                          mensagem: '${ex.nome} sai da sua ficha. Seu professor vê essa alteração no histórico.',
                          botao: 'Remover',
                          perigo: true);
                      if (!ok || !ctx.mounted) return;
                      try {
                        await store.remover(ex.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) mostrarMensagem(context, 'Exercício removido da ficha.');
                      } on ApiException catch (e) {
                        if (ctx.mounted) mostrarMensagem(ctx, e.mensagem, erro: true);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Remover'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BotaoMarca(
                    texto: 'Editar',
                    icone: Icons.edit_rounded,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await abrirFormulario(context, store, exercicio: ex);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Dado extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Dado(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Cores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Cores.borda),
        ),
        child: Column(
          children: [
            Text(rotulo.toUpperCase(), style: const TextStyle(color: Cores.textoFraco, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(valor, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
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
  late String _dia = widget.exercicio?.diaSemana ?? widget.diaInicial ?? Helpers.obterDiaAtual(DateTime.now().weekday);
  ItemCatalogo? _escolhido;
  bool _salvando = false;

  bool get _editando => widget.exercicio != null;

  @override
  void dispose() {
    _series.dispose();
    _reps.dispose();
    _carga.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (!_editando && _escolhido == null) {
      mostrarMensagem(context, 'Escolha um exercício do catálogo.', erro: true);
      return;
    }
    setState(() => _salvando = true);
    final dados = {
      'diaSemana': _dia,
      'series': _series.text.trim(),
      'repeticoes': _reps.text.trim(),
      'carga': _carga.text.trim().isEmpty ? null : _carga.text.trim(),
    };
    try {
      if (_editando) {
        await widget.store.editar(widget.exercicio!.id, dados);
      } else {
        await widget.store.adicionar(_escolhido!.id, dados);
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

  Future<void> _escolher() async {
    final item = await showModalBottomSheet<ItemCatalogo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _Catalogo(),
    );
    if (item != null) setState(() => _escolhido = item);
  }

  @override
  Widget build(BuildContext context) {
    final dias = [...Helpers.dias, Helpers.rotativo];
    if (!dias.contains(_dia)) dias.add(_dia);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editando ? 'Editar exercício' : 'Adicionar exercício',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                _editando ? widget.exercicio!.nome : 'Escolha no catálogo da academia e ajuste do seu jeito.',
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
                      Miniatura(_escolhido?.imagemUrl, tamanho: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_escolhido?.nome ?? 'Escolher exercício', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(_escolhido?.grupoMuscular ?? 'Toque para abrir o catálogo',
                                style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Cores.textoFraco),
                    ],
                  ),
                ),
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
                      decoration: const InputDecoration(labelText: 'Repetições'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _carga,
                decoration: const InputDecoration(labelText: 'Carga (opcional)', hintText: 'Ex: 20kg'),
              ),
              const SizedBox(height: 10),
              const Text('Seu professor vê no histórico tudo o que você mudar na ficha.',
                  style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
              const SizedBox(height: 18),
              BotaoMarca(
                texto: _editando ? 'Salvar alterações' : 'Adicionar à ficha',
                icone: Icons.check_rounded,
                carregando: _salvando,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Catalogo extends StatefulWidget {
  const _Catalogo();

  @override
  State<_Catalogo> createState() => _CatalogoState();
}

class _CatalogoState extends State<_Catalogo> {
  List<ItemCatalogo>? _itens;
  String? _erro;
  String _busca = '';
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final lista = await Api.instancia.get('/catalogo') as List;
      setState(() => _itens = lista.map((e) => ItemCatalogo.fromJson(e)).toList());
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = (_itens ?? [])
        .where((i) => _busca.isEmpty || i.nome.toLowerCase().contains(_busca) || i.grupoMuscular.toLowerCase().contains(_busca))
        .toList();
    final grupos = <String, List<ItemCatalogo>>{};
    for (final i in filtrados) {
      grupos.putIfAbsent(i.grupoMuscular, () => []).add(i);
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(hintText: 'Buscar exercício ou grupo muscular', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) {
                _espera?.cancel();
                _espera = Timer(const Duration(milliseconds: 250), () => setState(() => _busca = v.trim().toLowerCase()));
              },
            ),
          ),
          Expanded(
            child: _erro != null
                ? Erro(mensagem: _erro!, onTentar: () {
                    setState(() => _erro = null);
                    _carregar();
                  })
                : _itens == null
                    ? const Center(child: CircularProgressIndicator())
                    : filtrados.isEmpty
                        ? const Vazio(icone: Icons.search_off_rounded, titulo: 'Nada encontrado')
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              for (final g in grupos.entries) ...[
                                TituloSecao(g.key),
                                for (final item in g.value)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Cartao(
                                      padding: const EdgeInsets.all(10),
                                      onTap: () => Navigator.pop(context, item),
                                      child: Row(
                                        children: [
                                          Miniatura(item.imagemUrl, tamanho: 40),
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
