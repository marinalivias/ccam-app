import 'package:flutter/material.dart';

import '../models.dart';
import '../social_store.dart';
import '../theme.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';

class LojaScreen extends StatelessWidget {
  final SocialStore social;

  const LojaScreen({super.key, required this.social});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: social,
      builder: (context, _) {
        final loja = social.loja;
        final grupos = <String, List<Produto>>{};
        for (final p in loja?.produtos ?? <Produto>[]) {
          grupos.putIfAbsent(p.categoria ?? 'Outros', () => []).add(p);
        }

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: social.carregarLoja,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text('Loja da academia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                const Text('Veja os produtos e compre na recepção.', style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
                const SizedBox(height: 18),
                if (loja == null)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                else ...[
                  if (loja.aniversarioHoje && loja.descontoAniversario > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Cartao(
                        corBorda: const Color(0x6122C55E),
                        child: Row(
                          children: [
                            const IconeChip(Icons.celebration_rounded, cor: Cores.verde),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Feliz aniversário! Hoje você tem ${loja.descontoAniversario}% de desconto nos produtos marcados.',
                                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (loja.descontoAniversario > 0 && loja.produtos.any((p) => p.descontoAniversario))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Cartao(
                        child: Row(
                          children: [
                            const IconeChip(Icons.cake_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No dia do seu aniversário você ganha ${loja.descontoAniversario}% de desconto nos produtos marcados.',
                                style: const TextStyle(color: Cores.textoSuave, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (loja.produtos.isEmpty)
                    const Cartao(child: Vazio(icone: Icons.shopping_bag_outlined, titulo: 'Nenhum produto por enquanto'))
                  else
                    for (final g in grupos.entries) ...[
                      TituloSecao(g.key),
                      for (final p in g.value) _CartaoProduto(produto: p, desconto: loja.descontoAniversario),
                    ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartaoProduto extends StatelessWidget {
  final Produto produto;
  final int desconto;

  const _CartaoProduto({required this.produto, required this.desconto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Cartao(
        padding: const EdgeInsets.all(14),
        corBorda: produto.comDesconto ? const Color(0x6122C55E) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconeChip(Icons.shopping_bag_rounded, cor: Cores.azul),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (produto.descricao != null) ...[
                    const SizedBox(height: 3),
                    Text(produto.descricao!, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                  ],
                  if (produto.descontoAniversario && !produto.comDesconto && desconto > 0) ...[
                    const SizedBox(height: 8),
                    Selo('$desconto% off no seu aniversário', tipo: TipoSelo.marca),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (produto.comDesconto)
                  Text(
                    Helpers.moeda(produto.preco),
                    style: const TextStyle(color: Cores.textoFraco, fontSize: 12.5, decoration: TextDecoration.lineThrough, decorationColor: Cores.textoFraco),
                  ),
                Text(
                  Helpers.moeda(produto.precoFinal),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: produto.comDesconto ? Cores.verdeClaro : Cores.texto),
                ),
                if (produto.comDesconto) ...[
                  const SizedBox(height: 4),
                  Selo('-$desconto%', tipo: TipoSelo.ok),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
