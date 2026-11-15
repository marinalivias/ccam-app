import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class GraficoBarras extends StatelessWidget {
  final List<double> valores;
  final List<String> rotulos;
  final double? meta;
  final Color cor;

  const GraficoBarras({super.key, required this.valores, required this.rotulos, this.meta, this.cor = Cores.marcaClara});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(painter: _PintorBarras(valores: valores, meta: meta, cor: cor)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final r in rotulos)
              Expanded(child: Text(r, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Cores.textoFraco))),
          ],
        ),
      ],
    );
  }
}

class _PintorBarras extends CustomPainter {
  final List<double> valores;
  final double? meta;
  final Color cor;

  _PintorBarras({required this.valores, required this.meta, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final topo = math.max(valores.fold<double>(0, math.max), meta ?? 0);
    final maximo = topo <= 0 ? 1.0 : topo;
    final alturaUtil = size.height - 18;
    final largura = size.width / valores.length;
    final barra = math.min(26.0, largura * 0.56);

    for (var i = 0; i < valores.length; i++) {
      final v = valores[i];
      final h = v <= 0 ? 3.0 : math.max(3.0, alturaUtil * v / maximo);
      final x = largura * i + (largura - barra) / 2;
      final ultimo = i == valores.length - 1;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - h, barra, h),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      );
      canvas.drawRRect(rect, Paint()..color = v <= 0 ? Cores.superficie2 : (ultimo ? cor : cor.withValues(alpha: 0.55)));
      if (v > 0) {
        final texto = TextPainter(
          text: TextSpan(text: _formatar(v), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Cores.textoSuave)),
          textDirection: TextDirection.ltr,
        )..layout();
        texto.paint(canvas, Offset(x + barra / 2 - texto.width / 2, size.height - h - texto.height - 2));
      }
    }

    if (meta != null && meta! > 0) {
      final y = size.height - alturaUtil * meta! / maximo;
      final tracejado = Paint()
        ..color = Cores.verde.withValues(alpha: 0.7)
        ..strokeWidth = 1.4;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), tracejado);
      }
    }
  }

  static String _formatar(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

  @override
  bool shouldRepaint(_PintorBarras old) => old.valores != valores || old.meta != meta || old.cor != cor;
}

class GraficoLinha extends StatelessWidget {
  final List<double> valores;
  final List<String> rotulos;
  final String unidade;

  const GraficoLinha({super.key, required this.valores, required this.rotulos, this.unidade = ''});

  @override
  Widget build(BuildContext context) {
    final indices = <int>{0, valores.length - 1, (valores.length - 1) ~/ 2};
    return Column(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(painter: _PintorLinha(valores: valores, unidade: unidade)),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final i in indices.toList()..sort())
              Text(rotulos[i], style: const TextStyle(fontSize: 10.5, color: Cores.textoFraco)),
          ],
        ),
      ],
    );
  }
}

class _PintorLinha extends CustomPainter {
  final List<double> valores;
  final String unidade;

  _PintorLinha({required this.valores, required this.unidade});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;
    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);
    final faixa = maximo - minimo == 0 ? 1.0 : maximo - minimo;
    const margemTopo = 22.0;
    const margemBase = 8.0;
    const margemLado = 8.0;
    final alturaUtil = size.height - margemTopo - margemBase;
    final passo = (size.width - margemLado * 2) / (valores.length - 1);

    Offset ponto(int i) => Offset(
          margemLado + passo * i,
          margemTopo + alturaUtil * (1 - (valores[i] - minimo) / faixa),
        );

    final grade = Paint()
      ..color = Cores.borda
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final y = margemTopo + alturaUtil * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }

    final caminho = Path()..moveTo(ponto(0).dx, ponto(0).dy);
    for (var i = 1; i < valores.length; i++) {
      caminho.lineTo(ponto(i).dx, ponto(i).dy);
    }
    final area = Path.from(caminho)
      ..lineTo(ponto(valores.length - 1).dx, size.height)
      ..lineTo(ponto(0).dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Cores.verde.withValues(alpha: 0.28), Cores.verde.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      caminho,
      Paint()
        ..color = Cores.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < valores.length; i++) {
      canvas.drawCircle(ponto(i), 3.6, Paint()..color = Cores.fundo);
      canvas.drawCircle(
        ponto(i),
        3.6,
        Paint()
          ..color = Cores.verde
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final ultimo = ponto(valores.length - 1);
    final texto = TextPainter(
      text: TextSpan(
        text: '${_formatar(valores.last)}$unidade',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Cores.verdeClaro),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = math.min(ultimo.dx - texto.width / 2, size.width - texto.width);
    texto.paint(canvas, Offset(x, math.max(0, ultimo.dy - texto.height - 6)));
  }

  static String _formatar(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

  @override
  bool shouldRepaint(_PintorLinha old) => old.valores != valores || old.unidade != unidade;
}

class BarraHorizontal extends StatelessWidget {
  final String rotulo;
  final double valor;
  final double maximo;
  final String texto;
  final Color cor;

  const BarraHorizontal({super.key, required this.rotulo, required this.valor, required this.maximo, required this.texto, this.cor = Cores.azul});

  @override
  Widget build(BuildContext context) {
    final fracao = maximo <= 0 ? 0.0 : (valor / maximo).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 82, child: Text(rotulo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Cores.textoSuave))),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Stack(
                children: [
                  Container(height: 10, color: Cores.superficie2),
                  FractionallySizedBox(widthFactor: fracao, child: Container(height: 10, color: cor)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 62, child: Text(texto, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
