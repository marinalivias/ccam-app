import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
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
  List<Mensalidade>? _mensalidades;
  String? _erroFin;

  @override
  void initState() {
    super.initState();
    _carregarFinanceiro();
  }

  Future<void> _carregarFinanceiro() async {
    setState(() => _erroFin = null);
    try {
      final lista = await Api.instancia.get('/financeiro') as List;
      if (mounted) setState(() => _mensalidades = lista.map((e) => Mensalidade.fromJson(e)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _erroFin = e.mensagem);
    }
  }

  Future<void> _sair() async {
    final ok = await confirmar(context, titulo: 'Sair da conta?', mensagem: 'Você vai precisar do e-mail e do CPF para entrar de novo.', botao: 'Sair');
    if (!ok) return;
    try {
      await Api.instancia.post('/logout');
    } catch (_) {}
    await Api.instancia.limparToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aluno;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([widget.store.carregarFrequencia(), _carregarFinanceiro()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Cartao(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Cores.marca, Cores.verde], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Text(
                      a.nome.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Colors.white),
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
            const TituloSecao('Mensalidades'),
            if (_erroFin != null)
              Erro(mensagem: _erroFin!, onTentar: _carregarFinanceiro)
            else if (_mensalidades == null)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_mensalidades!.isEmpty)
              const Cartao(child: Vazio(icone: Icons.account_balance_wallet_outlined, titulo: 'Nenhuma mensalidade lançada'))
            else
              Cartao(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < _mensalidades!.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _LinhaMensalidade(m: _mensalidades![i]),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text('Dúvidas sobre pagamentos? Fale com a recepção.', style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
            const SizedBox(height: 24),
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

class _LinhaMensalidade extends StatelessWidget {
  final Mensalidade m;

  const _LinhaMensalidade({required this.m});

  @override
  Widget build(BuildContext context) {
    final hoje = Helpers.soData(DateTime.now());
    final atrasada = !m.paga && m.vencimento.isBefore(hoje);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Helpers.moeda(m.valor), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('Vence em ${Helpers.dataCurta(m.vencimento)}', style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
              ],
            ),
          ),
          Selo(
            m.paga ? 'Pago' : (atrasada ? 'Atrasada' : 'Pendente'),
            tipo: m.paga ? TipoSelo.ok : (atrasada ? TipoSelo.perigo : TipoSelo.aviso),
          ),
        ],
      ),
    );
  }
}
