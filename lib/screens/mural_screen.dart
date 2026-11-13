import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';

class MuralScreen extends StatefulWidget {
  const MuralScreen({super.key});

  @override
  State<MuralScreen> createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {
  final List<Aviso> _avisos = [];
  int _pagina = 0;
  int _totalPaginas = 1;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar(reiniciar: true);
  }

  Future<void> _carregar({bool reiniciar = false}) async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pagina = reiniciar ? 0 : _pagina + 1;
      final resp = await Api.instancia.get('/mural?pagina=$pagina&tamanho=10');
      final itens = (resp['itens'] as List).map((e) => Aviso.fromJson(e)).toList();
      setState(() {
        if (reiniciar) _avisos.clear();
        _avisos.addAll(itens);
        _pagina = pagina;
        _totalPaginas = (resp['totalPaginas'] as num).toInt();
      });
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _carregar(reiniciar: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Mural de avisos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('Novidades e comunicados da academia.', style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
            const SizedBox(height: 18),
            if (_erro != null && _avisos.isEmpty)
              Erro(mensagem: _erro!, onTentar: () => _carregar(reiniciar: true))
            else if (_avisos.isEmpty && _carregando)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_avisos.isEmpty)
              const Cartao(child: Vazio(icone: Icons.campaign_outlined, titulo: 'Nenhum aviso por enquanto', texto: 'Os comunicados da academia aparecem aqui.'))
            else ...[
              for (final a in _avisos) _CartaoAviso(aviso: a),
              if (_pagina + 1 < _totalPaginas)
                Center(
                  child: _carregando
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Ver avisos anteriores'),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoAviso extends StatelessWidget {
  final Aviso aviso;

  const _CartaoAviso({required this.aviso});

  @override
  Widget build(BuildContext context) {
    final data = aviso.publicadoEm;
    final novo = data != null && DateTime.now().difference(data).inDays < 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Cartao(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconeChip(Icons.campaign_rounded, cor: Cores.azul),
                const SizedBox(width: 12),
                Expanded(child: Text(aviso.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                if (novo) const Selo('Novo', tipo: TipoSelo.ok),
              ],
            ),
            if (aviso.mensagem.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(aviso.mensagem, style: const TextStyle(color: Cores.textoSuave, height: 1.5)),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 15, color: Cores.textoFraco),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (data != null) Helpers.dataPorExtenso(data),
                      if (aviso.autor != null) 'por ${aviso.autor}',
                      if (aviso.editadoEm != null) 'editado',
                    ].join(' · '),
                    style: const TextStyle(color: Cores.textoFraco, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
