import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../models.dart';
import '../notificacoes.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import '../widgets/graficos.dart';
import '../widgets/comum.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Aluno aluno;
  final TreinoStore store;

  const PerfilScreen({super.key, required this.aluno, required this.store});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Uint8List? _foto;
  bool _enviandoFoto = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
    if (widget.aluno.temFoto) _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    try {
      final r = await Api.instancia.get('/foto');
      if (r is Map && r['base64'] != null && mounted) setState(() => _foto = base64Decode(r['base64'].toString()));
    } on ApiException {
      return;
    }
  }

  Future<void> _escolherFoto() async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Escolher da galeria'), onTap: () => Navigator.pop(ctx, 'galeria')),
            if (!kIsWeb)
              ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Tirar foto'), onTap: () => Navigator.pop(ctx, 'camera')),
            if (_foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Cores.vermelhoClaro),
                title: const Text('Remover foto', style: TextStyle(color: Cores.vermelhoClaro)),
                onTap: () => Navigator.pop(ctx, 'remover'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (acao == null) return;
    setState(() => _enviandoFoto = true);
    try {
      if (acao == 'remover') {
        await Api.instancia.delete('/foto');
        if (mounted) setState(() => _foto = null);
        return;
      }
      final arquivo = await ImagePicker().pickImage(
        source: acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      final nome = arquivo.name.toLowerCase();
      final tipo = nome.endsWith('.png') ? 'image/png' : nome.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
      await Api.instancia.put('/foto', {'tipo': arquivo.mimeType ?? tipo, 'base64': base64Encode(bytes)});
      if (mounted) {
        setState(() => _foto = bytes);
        mostrarMensagem(context, 'Foto atualizada.');
      }
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _carregarHistorico() async {
    final hoje = Helpers.soData(DateTime.now());
    try {
      await widget.store.carregarPeriodo(Helpers.segundaDaSemana(hoje).subtract(const Duration(days: 49)), hoje);
    } on ApiException {
      return;
    }
  }

  Future<void> _sair() async {
    final ok = await confirmar(context, titulo: 'Sair da conta?', mensagem: 'Você vai precisar do e-mail e da senha para entrar de novo.', botao: 'Sair');
    if (!ok) return;
    try {
      await Api.instancia.post('/logout');
    } catch (_) {}
    await Notificacoes.aoSair();
    await Api.instancia.limparToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _trocarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final chave = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Form(
          key: chave,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual', helperText: 'Se nunca trocou, é o seu CPF'),
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nova,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => (v ?? '').length < 6 ? 'Use pelo menos 6 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (chave.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.instancia.put('/senha', {'atual': atual.text, 'nova': nova.text});
      if (mounted) mostrarMensagem(context, 'Senha alterada.');
    } on ApiException catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aluno;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await widget.store.carregarFrequencia();
          await _carregarHistorico();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Cartao(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _enviandoFoto ? null : _escolherFoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Cores.marca, Cores.verde], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            image: _foto == null ? null : DecorationImage(image: MemoryImage(_foto!), fit: BoxFit.cover),
                          ),
                          child: _enviandoFoto
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : _foto != null
                                  ? null
                                  : Text(
                                      a.nome.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: Colors.white),
                                    ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Cores.superficieSolida,
                              shape: BoxShape.circle,
                              border: Border.all(color: Cores.bordaForte),
                            ),
                            child: const Icon(Icons.photo_camera_rounded, size: 14, color: Cores.lilas),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        Text(a.email, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                        if (a.academia != null) ...[const SizedBox(height: 6), Selo(a.academia!, tipo: TipoSelo.marca)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const TituloSecao('Frequência na academia'),
            ListenableBuilder(listenable: widget.store, builder: (_, _) => _Frequencia(f: widget.store.frequencia)),
            const TituloSecao('Sua evolução'),
            ListenableBuilder(listenable: widget.store, builder: (_, _) => _Evolucao(store: widget.store)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _trocarSenha,
              icon: const Icon(Icons.key_rounded, size: 20),
              label: const Text('Alterar senha'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Cores.vermelhoClaro,
                side: const BorderSide(color: Color(0x61EF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _sair,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Frequencia extends StatelessWidget {
  final Frequencia? f;

  const _Frequencia({required this.f});

  @override
  Widget build(BuildContext context) {
    if (f == null) {
      return const Cartao(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())));
    }
    final freq = f!;
    final cor = freq.percentual >= 75 ? Cores.verde : freq.percentual >= 40 ? Cores.amarelo : Cores.vermelho;
    final frase = freq.diasPorSemana == 0
        ? 'Sua ficha ainda não tem dias definidos.'
        : freq.percentual >= 75
            ? 'Ótima constância. Continue assim!'
            : freq.percentual >= 40
                ? 'Bom ritmo. Dá para subir mais um pouco.'
                : 'Bora retomar? Cada treino conta.';

    return Cartao(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _Anel(valor: freq.percentual / 100, cor: cor),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${freq.percentual}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const Text('no mês', style: TextStyle(fontSize: 11, color: Cores.textoFraco)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(frase, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(
                      '${freq.treinos30Dias} de ${freq.previstos30Dias} treinos previstos nos últimos 28 dias.',
                      style: const TextStyle(color: Cores.textoSuave, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Numero(valor: '${freq.treinosSemana}/${freq.diasPorSemana}', rotulo: 'Nesta semana'),
              _Numero(valor: '${freq.semanasSeguidas}', rotulo: freq.semanasSeguidas == 1 ? 'Semana seguida' : 'Semanas seguidas'),
              _Numero(valor: freq.ultimoTreino == null ? '--' : '${freq.ultimoTreino!.day}/${freq.ultimoTreino!.month}', rotulo: 'Último treino'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Evolucao extends StatefulWidget {
  final TreinoStore store;

  const _Evolucao({required this.store});

  @override
  State<_Evolucao> createState() => _EvolucaoState();
}

class _EvolucaoState extends State<_Evolucao> {
  String? _exercicio;

  static double? _numero(String? carga) {
    if (carga == null) return null;
    final m = RegExp(r'\d+([.,]\d+)?').firstMatch(carga);
    return m == null ? null : double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }

  static String _dia(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final hoje = Helpers.soData(DateTime.now());
    final segunda = Helpers.segundaDaSemana(hoje);
    final inicio30 = hoje.subtract(const Duration(days: 29));
    final ultimos30 = store.realizadosEntre(inicio30, hoje).where((t) => t.feitos > 0 || t.seriesFeitas > 0).toList();

    var series = 0;
    var repeticoes = 0;
    final porGrupo = <String, int>{};
    for (final t in ultimos30) {
      series += t.seriesFeitas;
      for (final r in t.registros.values) {
        final ex = store.exercicioPorId(r.exercicioId);
        final meta = ex?.alvoReps ?? 1;
        repeticoes += r.reps.fold(0, (a, b) => a + b);
        final feitas = r.reps.where((v) => v >= meta).length;
        if (feitas > 0) porGrupo.update(ex?.grupoMuscular ?? 'Outros', (v) => v + feitas, ifAbsent: () => feitas);
      }
    }
    final grupos = porGrupo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final semanas = <double>[];
    final rotulos = <String>[];
    for (var w = 7; w >= 0; w--) {
      final ini = segunda.subtract(Duration(days: 7 * w));
      final fim = ini.add(const Duration(days: 6));
      semanas.add(store.realizadosEntre(ini, fim).where((t) => t.feitos > 0 || t.seriesFeitas > 0).length.toDouble());
      rotulos.add(w == 0 ? 'Atual' : _dia(ini));
    }

    final cargas = <String, List<(DateTime, double)>>{};
    for (final t in store.realizadosEntre(segunda.subtract(const Duration(days: 49)), hoje)) {
      for (final r in t.registros.values) {
        final v = _numero(r.carga);
        final ex = store.exercicioPorId(r.exercicioId);
        if (v == null || ex == null) continue;
        cargas.putIfAbsent(ex.id, () => []).add((t.data, v));
      }
    }
    cargas.removeWhere((_, l) => l.length < 2);
    final opcoes = cargas.keys.toList()..sort((a, b) => (store.exercicioPorId(a)?.nome ?? '').compareTo(store.exercicioPorId(b)?.nome ?? ''));
    final escolhido = opcoes.contains(_exercicio) ? _exercicio : (opcoes.isEmpty ? null : opcoes.first);
    final pontos = escolhido == null ? <(DateTime, double)>[] : cargas[escolhido]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Numero(valor: '${ultimos30.length}', rotulo: 'Treinos em 30 dias'),
            _Numero(valor: '$series', rotulo: 'Séries feitas'),
            _Numero(valor: repeticoes >= 1000 ? '${(repeticoes / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil' : '$repeticoes', rotulo: 'Repetições'),
          ],
        ),
        const SizedBox(height: 12),
        Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Treinos por semana', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                store.frequencia != null && store.frequencia!.diasPorSemana > 0
                    ? 'Últimas 8 semanas. A linha verde é a sua meta de ${store.frequencia!.diasPorSemana} por semana.'
                    : 'Últimas 8 semanas.',
                style: const TextStyle(color: Cores.textoFraco, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              GraficoBarras(valores: semanas, rotulos: rotulos, meta: store.frequencia?.diasPorSemana.toDouble()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Músculos mais treinados', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Séries completas nos últimos 30 dias.', style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
              const SizedBox(height: 10),
              if (grupos.isEmpty)
                const Text('Registre seus treinos para ver este gráfico.', style: TextStyle(color: Cores.textoSuave, fontSize: 13))
              else
                for (final g in grupos.take(6))
                  BarraHorizontal(rotulo: g.key, valor: g.value.toDouble(), maximo: grupos.first.value.toDouble(), texto: '${g.value} séries'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Evolução da carga', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('A carga usada em cada treino registrado.', style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
              const SizedBox(height: 10),
              if (pontos.isEmpty)
                const Text('Informe a carga ao registrar os exercícios para acompanhar sua evolução.',
                    style: TextStyle(color: Cores.textoSuave, fontSize: 13, height: 1.4))
              else ...[
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final id in opcoes)
                        BotaoFiltro(
                          rotulo: store.exercicioPorId(id)?.nome ?? '',
                          selecionado: id == escolhido,
                          onTap: () => setState(() => _exercicio = id),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GraficoLinha(valores: [for (final p in pontos) p.$2], rotulos: [for (final p in pontos) _dia(p.$1)], unidade: ' kg'),
                const SizedBox(height: 10),
                Builder(builder: (_) {
                  final primeiro = pontos.first.$2;
                  final ultimo = pontos.last.$2;
                  final dif = ultimo - primeiro;
                  String fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');
                  final pct = primeiro > 0 ? (dif * 100 / primeiro).round() : 0;
                  final texto = dif > 0
                      ? 'Você saiu de ${fmt(primeiro)} kg para ${fmt(ultimo)} kg (+$pct%). Mandou bem!'
                      : dif < 0
                          ? 'Carga caiu de ${fmt(primeiro)} kg para ${fmt(ultimo)} kg.'
                          : 'Carga mantida em ${fmt(ultimo)} kg.';
                  return Text(texto, style: TextStyle(color: dif > 0 ? Cores.verdeClaro : Cores.textoSuave, fontSize: 13, fontWeight: FontWeight.w600));
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Numero({required this.valor, required this.rotulo});

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

class _Anel extends CustomPainter {
  final double valor;
  final Color cor;

  _Anel({required this.valor, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.width / 2 - 6;
    final fundo = Paint()
      ..color = Cores.superficie2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    final arco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, raio, fundo);
    if (valor > 0) {
      canvas.drawArc(Rect.fromCircle(center: centro, radius: raio), -math.pi / 2, 2 * math.pi * valor.clamp(0, 1), false, arco);
    }
  }

  @override
  bool shouldRepaint(_Anel old) => old.valor != valor || old.cor != cor;
}
