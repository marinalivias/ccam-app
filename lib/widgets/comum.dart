import 'package:flutter/material.dart';

import '../theme.dart';

class Fundo extends StatelessWidget {
  final Widget child;

  const Fundo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Cores.fundo),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -1.0),
                  radius: 1.2,
                  colors: [Color(0x577C3AED), Color(0x007C3AED)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.1, -0.3),
                  radius: 1.0,
                  colors: [Color(0x3322C55E), Color(0x0022C55E)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1, 1.1),
                  radius: 1.0,
                  colors: [Color(0x2938BDF8), Color(0x0038BDF8)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final double tamanho;

  const Logo({super.key, this.tamanho = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamanho * 0.29),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.marca, Cores.verde],
        ),
        boxShadow: [BoxShadow(color: Cores.marca.withValues(alpha: 0.32), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tamanho * 0.29),
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 0.5,
            colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? corBorda;

  const Cartao({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap, this.corBorda});

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: raio,
          border: Border.all(color: corBorda ?? Cores.borda),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x0FFFFFFF), Color(0x09FFFFFF)],
          ),
        ),
        child: InkWell(
          borderRadius: raio,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum TipoSelo { ok, aviso, perigo, marca, azul, neutro }

class Selo extends StatelessWidget {
  final String texto;
  final TipoSelo tipo;

  const Selo(this.texto, {super.key, this.tipo = TipoSelo.neutro});

  @override
  Widget build(BuildContext context) {
    final (Color fundo, Color borda, Color cor) = switch (tipo) {
      TipoSelo.ok => (const Color(0x2122C55E), const Color(0x6122C55E), Cores.verdeClaro),
      TipoSelo.aviso => (const Color(0x1FF59E0B), const Color(0x61F59E0B), Cores.amareloClaro),
      TipoSelo.perigo => (const Color(0x1FEF4444), const Color(0x61EF4444), Cores.vermelhoClaro),
      TipoSelo.marca => (const Color(0x2E7C3AED), const Color(0x6BA78BFA), const Color(0xFFDDD6FE)),
      TipoSelo.azul => (const Color(0x1F38BDF8), const Color(0x6138BDF8), Cores.azulClaro),
      TipoSelo.neutro => (Cores.superficie2, Cores.bordaForte, Cores.textoSuave),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borda),
      ),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class IconeChip extends StatelessWidget {
  final IconData icone;
  final Color cor;

  const IconeChip(this.icone, {super.key, this.cor = Cores.lilas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.32)),
      ),
      child: Icon(icone, color: cor, size: 20),
    );
  }
}

class TituloSecao extends StatelessWidget {
  final String texto;
  final Widget? acao;

  const TituloSecao(this.texto, {super.key, this.acao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto.toUpperCase(),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Cores.textoFraco),
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}

class Vazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? texto;
  final Widget? acao;

  const Vazio({super.key, required this.icone, required this.titulo, this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconeChip(icone),
          const SizedBox(height: 12),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (texto != null) ...[
            const SizedBox(height: 4),
            Text(texto!, textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
          ],
          if (acao != null) ...[const SizedBox(height: 14), acao!],
        ],
      ),
    );
  }
}

class BotaoMarca extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;
  final bool carregando;

  const BotaoMarca({super.key, required this.texto, this.icone, this.onPressed, this.carregando = false});

  @override
  Widget build(BuildContext context) {
    final ativo = onPressed != null && !carregando;
    return Opacity(
      opacity: ativo || carregando ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Cores.marcaClara, Cores.marcaEscura],
          ),
          boxShadow: [BoxShadow(color: Cores.marca.withValues(alpha: 0.38), blurRadius: 26, offset: const Offset(0, 10))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: ativo ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (carregando)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else ...[
                    if (icone != null) ...[Icon(icone, size: 18, color: Colors.white), const SizedBox(width: 8)],
                    Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Erro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentar;

  const Erro({super.key, required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return Vazio(
      icone: Icons.wifi_off_rounded,
      titulo: 'Não foi possível carregar',
      texto: mensagem,
      acao: OutlinedButton.icon(
        onPressed: onTentar,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Tentar de novo'),
      ),
    );
  }
}

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(erro ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: erro ? Cores.vermelhoClaro : Cores.verdeClaro, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
}

Future<bool> confirmar(BuildContext context, {required String titulo, required String mensagem, String botao = 'Confirmar', bool perigo = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      content: Text(mensagem, style: const TextStyle(color: Cores.textoSuave)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: perigo ? Cores.vermelho : Cores.marca),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(botao),
        ),
      ],
    ),
  );
  return r == true;
}

class BotaoFiltro extends StatelessWidget {
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  const BotaoFiltro({super.key, required this.rotulo, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selecionado ? Cores.marca.withValues(alpha: 0.3) : Cores.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selecionado ? const Color(0x99A78BFA) : Cores.borda),
          ),
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              color: selecionado ? Cores.texto : Cores.textoSuave,
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoPilula extends StatelessWidget {
  final String texto;
  final IconData icone;
  final VoidCallback? onPressed;
  final bool perigo;

  const BotaoPilula({super.key, required this.texto, required this.icone, required this.onPressed, this.perigo = false});

  @override
  Widget build(BuildContext context) {
    final cor = perigo ? Cores.vermelho : Cores.marca;
    final corTexto = perigo ? Cores.vermelhoClaro : const Color(0xFFDDD6FE);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: perigo ? 0.12 : 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: perigo ? const Color(0x61EF4444) : const Color(0x66A78BFA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 17, color: corTexto),
            const SizedBox(width: 6),
            Text(texto, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: corTexto)),
          ],
        ),
      ),
    );
  }
}
