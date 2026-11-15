import 'package:flutter/material.dart';

import '../models.dart';
import '../social_store.dart';
import '../theme.dart';
import 'comum.dart';

class BotaoNotificacoes extends StatelessWidget {
  final SocialStore social;
  final void Function(String tipo) abrir;

  const BotaoNotificacoes({super.key, required this.social, required this.abrir});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: social,
      builder: (context, _) {
        final n = social.naoLidas;
        return IconButton(
          tooltip: 'Notificações',
          onPressed: () => abrirNotificacoes(context, social, abrir),
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n > 9 ? '9+' : '$n'),
            backgroundColor: Cores.vermelho,
            child: Icon(n > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded, size: 26),
          ),
        );
      },
    );
  }
}

Future<void> abrirNotificacoes(BuildContext context, SocialStore social, void Function(String tipo) abrir) async {
  final novas = {for (final n in social.notificacoes) if (social.novidade(n)) n.id};
  social.marcarLidas();
  final escolhida = await showModalBottomSheet<Notificacao>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Notificações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                  IconButton(tooltip: 'Fechar', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            if (social.notificacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Vazio(icone: Icons.notifications_none_rounded, titulo: 'Nada por aqui', texto: 'Pagamentos, avisos e mudanças no treino aparecem aqui.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: social.notificacoes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = social.notificacoes[i];
                    return _Item(n: n, nova: novas.contains(n.id), onTap: () => Navigator.pop(ctx, n));
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (escolhida != null) abrir(escolhida.tipo);
}

class _Item extends StatelessWidget {
  final Notificacao n;
  final bool nova;
  final VoidCallback onTap;

  const _Item({required this.n, required this.nova, required this.onTap});

  (IconData, Color) get _visual => switch (n.tipo) {
        'pagamento' => (
            Icons.account_balance_wallet_rounded,
            n.titulo.contains('vencida') ? Cores.vermelho : (n.titulo.contains('confirmado') ? Cores.verde : Cores.amarelo)
          ),
        'aniversario' => (Icons.cake_rounded, Cores.marcaClara),
        'treino' => (Icons.fitness_center_rounded, Cores.lilas),
        _ => (Icons.campaign_rounded, Cores.azul),
      };

  static String _quando(DateTime d) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(d.year, d.month, d.day);
    final diff = agora.difference(d);
    if (dia == hoje) {
      if (diff.isNegative || diff.inHours >= 6) return 'Hoje';
      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      return 'Há ${diff.inHours} h';
    }
    if (hoje.difference(dia).inDays == 1) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = _visual;
    return Material(
      color: nova ? Cores.marca.withValues(alpha: 0.12) : Cores.superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: nova ? const Color(0x66A78BFA) : Cores.borda),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeChip(icone, cor: cor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                        const SizedBox(width: 8),
                        Text(_quando(n.data), style: const TextStyle(color: Cores.textoFraco, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(n.texto, style: const TextStyle(color: Cores.textoSuave, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
