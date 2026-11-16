import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../treino_store.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';
import '../widgets/exercicio_widgets.dart';

class MinhaFichaScreen extends StatelessWidget {
  final TreinoStore store;

  const MinhaFichaScreen({super.key, required this.store});

  Future<void> _comecarDoZero(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: 'Começar do zero?',
      mensagem: 'Todos os ${store.ficha.length} exercícios da sua ficha serão apagados para você montar a sua. '
          'Seu professor vê essa mudança no histórico.',
      botao: 'Apagar e começar',
      perigo: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await store.limparFicha();
      if (context.mounted) mostrarMensagem(context, 'Ficha apagada. Agora é só adicionar os seus exercícios.');
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Fundo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final dias = [...Helpers.dias, Helpers.rotativo];
              final extras = store.ficha.map((e) => e.diaSemana).where((d) => !dias.contains(d)).toSet();
              final ordem = [...dias, ...extras];
              final porDia = <String, List<Exercicio>>{};
              for (final ex in store.ficha) {
                porDia.putIfAbsent(ex.diaSemana, () => []).add(ex);
              }
              final total = store.ficha.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(
                        child: Text('Minha ficha', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                      ),
                      if (total > 0)
                        BotaoPilula(
                          texto: 'Começar do zero',
                          icone: Icons.restart_alt_rounded,
                          perigo: true,
                          onPressed: () => _comecarDoZero(context),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 14),
                    child: Text(
                      total == 0
                          ? 'Sua ficha está vazia. Monte o seu treino escolhendo os exercícios de cada dia.'
                          : 'Monte o treino do seu jeito: adicione, edite ou remova exercícios em qualquer dia. '
                              'Seu professor acompanha as mudanças.',
                      style: const TextStyle(color: Cores.textoSuave, fontSize: 13.5, height: 1.45),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: BotaoMarca(
                      texto: 'Adicionar exercício',
                      icone: Icons.add_rounded,
                      onPressed: () => abrirFormulario(context, store),
                    ),
                  ),
                  for (final dia in ordem) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TituloSecao(
                        '$dia${porDia[dia] == null ? '' : ' · ${porDia[dia]!.length}'}',
                        acao: TextButton.icon(
                          onPressed: () => abrirFormulario(context, store, diaInicial: dia),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Adicionar'),
                        ),
                      ),
                    ),
                    if (porDia[dia] == null)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 4),
                        child: Text('Descanso', style: TextStyle(color: Cores.textoFraco, fontSize: 13)),
                      )
                    else
                      for (final ex in porDia[dia]!)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Cartao(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                            onTap: () => abrirFormulario(context, store, exercicio: ex),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => abrirDemonstracao(context, store, ex),
                                  child: Miniatura(store.gifDe(ex), tamanho: 48),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(ex.resumo, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => abrirFormulario(context, store, exercicio: ex),
                                  icon: const Icon(Icons.edit_rounded, size: 20, color: Cores.lilas),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
