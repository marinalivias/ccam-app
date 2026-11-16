import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../models.dart';
import '../pdfs.dart';
import '../theme.dart';
import '../utils/helpers.dart';
import '../widgets/comum.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  List<Mensalidade>? _lista;
  String? _erro;
  int? _diaPix;
  bool _pixAtivo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final lista = (await Api.instancia.get('/financeiro') as List).map((e) => Mensalidade.fromJson(e)).toList();
      try {
        final config = await Api.instancia.get('/financeiro/config') as Map<String, dynamic>;
        _pixAtivo = config['pixAtivo'] == true;
        _diaPix = (config['diaPixDisponivel'] as num?)?.toInt();
      } on ApiException {
        _pixAtivo = false;
      }
      if (mounted) setState(() => _lista = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  Future<void> _boleto(Mensalidade m) async {
    final informado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PagamentoBoleto(mensalidade: m),
    );
    if (informado == true) {
      await _carregar();
      if (mounted) mostrarMensagem(context, 'Pagamento informado. A academia vai confirmar em breve.');
    }
  }

  Future<void> _pagar(Mensalidade m) async {
    final informado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PagamentoPix(mensalidade: m),
    );
    if (informado == true) {
      await _carregar();
      if (mounted) mostrarMensagem(context, 'Pagamento informado. A academia vai confirmar em breve.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista ?? [];
    final hoje = Helpers.soData(DateTime.now());
    final abertas = lista.where((m) => !m.paga).toList();
    final emAberto = abertas.fold<double>(0, (t, m) => t + m.valor);
    final vencidas = abertas.where((m) => !m.informada && m.vencimento.isBefore(hoje)).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Financeiro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('Acompanhe suas mensalidades e pague por Pix.', style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
            const SizedBox(height: 18),
            if (_erro != null)
              Erro(mensagem: _erro!, onTentar: _carregar)
            else if (_lista == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else ...[
              Cartao(
                child: Row(
                  children: [
                    IconeChip(Icons.account_balance_wallet_rounded, cor: vencidas > 0 ? Cores.vermelho : Cores.verde),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(abertas.isEmpty ? 'Tudo em dia' : 'Em aberto', style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                          Text(abertas.isEmpty ? 'Nenhuma mensalidade pendente' : Helpers.moeda(emAberto),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        ],
                      ),
                    ),
                    if (vencidas > 0) Selo('$vencidas ${vencidas == 1 ? 'vencida' : 'vencidas'}', tipo: TipoSelo.perigo),
                  ],
                ),
              ),
              const TituloSecao('Mensalidades'),
              if (lista.isEmpty)
                const Cartao(child: Vazio(icone: Icons.account_balance_wallet_outlined, titulo: 'Nenhuma mensalidade lançada'))
              else
                for (final m in lista) _CartaoMensalidade(m: m, hoje: hoje, onPagar: () => _pagar(m), onBoleto: () => _boleto(m)),
              const SizedBox(height: 8),
              if (_pixAtivo && _diaPix != null) ...[
                Text('O Pix da mensalidade fica disponível a partir do dia $_diaPix de cada mês. Você recebe um aviso quando liberar.',
                    style: const TextStyle(color: Cores.textoFraco, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 6),
              ],
              const Text('Dúvidas sobre pagamentos? Fale com a recepção.', style: TextStyle(color: Cores.textoFraco, fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoMensalidade extends StatelessWidget {
  final Mensalidade m;
  final DateTime hoje;
  final VoidCallback onPagar;
  final VoidCallback onBoleto;

  const _CartaoMensalidade({required this.m, required this.hoje, required this.onPagar, required this.onBoleto});

  @override
  Widget build(BuildContext context) {
    final vencida = !m.paga && !m.informada && m.vencimento.isBefore(hoje);
    final (String rotulo, TipoSelo tipo, String detalhe) = m.paga
        ? ('Pago', TipoSelo.ok, m.dataPagamento != null ? 'Pago em ${Helpers.dataCurta(m.dataPagamento!)}' : 'Pagamento confirmado')
        : m.informada
            ? ('Aguardando confirmação', TipoSelo.azul, 'Você informou o pagamento em ${Helpers.dataCurta(m.pagamentoInformadoEm!)}')
            : vencida
                ? ('Vencida', TipoSelo.perigo, 'Venceu em ${Helpers.dataCurta(m.vencimento)}')
                : ('A pagar', TipoSelo.aviso, 'Vence em ${Helpers.dataCurta(m.vencimento)}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Cartao(
        corBorda: vencida ? const Color(0x61EF4444) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Helpers.moeda(m.valor), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(detalhe, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                    ],
                  ),
                ),
                Selo(rotulo, tipo: tipo),
              ],
            ),
            if (m.paga) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      final dados = await Api.instancia.get('/financeiro/${m.id}/comprovante') as Map<String, dynamic>;
                      await gerarComprovante(dados);
                    } on ApiException catch (e) {
                      if (context.mounted) mostrarMensagem(context, e.mensagem, erro: true);
                    }
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Baixar comprovante'),
                ),
              ),
            ],
            if (!m.paga && !m.informada) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Cores.verde.withValues(alpha: 0.18),
                        foregroundColor: Cores.verdeClaro,
                        side: const BorderSide(color: Color(0x6122C55E)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onPagar,
                      icon: const Icon(Icons.pix_rounded, size: 20),
                      label: const Text('Pix'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Cores.marca.withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFFDDD6FE),
                        side: const BorderSide(color: Color(0x66A78BFA)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onBoleto,
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: const Text('Boleto'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PagamentoPix extends StatefulWidget {
  final Mensalidade mensalidade;

  const _PagamentoPix({required this.mensalidade});

  @override
  State<_PagamentoPix> createState() => _PagamentoPixState();
}

class _PagamentoPixState extends State<_PagamentoPix> {
  Map<String, dynamic>? _pix;
  String? _erro;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await Api.instancia.get('/financeiro/${widget.mensalidade.id}/pix') as Map<String, dynamic>;
      if (mounted) setState(() => _pix = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _pix!['copiaECola'].toString()));
    if (mounted) mostrarMensagem(context, 'Código Pix copiado. Cole no app do seu banco.');
  }

  Future<void> _jaPaguei() async {
    final ok = await confirmar(
      context,
      titulo: 'Já fez o Pix?',
      mensagem: 'A academia vai conferir o pagamento de ${Helpers.moeda(widget.mensalidade.valor)} e confirmar.',
      botao: 'Sim, já paguei',
    );
    if (!ok) return;
    setState(() => _enviando = true);
    try {
      await Api.instancia.post('/financeiro/${widget.mensalidade.id}/informar-pagamento');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarMensagem(context, e.mensagem, erro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mensalidade;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pagar com Pix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Mensalidade de ${Helpers.moeda(m.valor)} com vencimento em ${Helpers.dataCurta(m.vencimento)}',
                style: const TextStyle(color: Cores.textoSuave)),
            const SizedBox(height: 18),
            if (_erro != null)
              Cartao(child: Vazio(icone: Icons.info_outline_rounded, titulo: 'Pix indisponível', texto: _erro))
            else if (_pix == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: QrImageView(data: _pix!['copiaECola'].toString(), size: 210, backgroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text('Para ${_pix!['recebedor']}', textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoSuave)),
              const SizedBox(height: 16),
              const Text('Pix copia e cola', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Cartao(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _pix!['copiaECola'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Cores.textoSuave, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _copiar, icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('Copiar código Pix')),
              const SizedBox(height: 16),
              const Text('1. Abra o app do seu banco e escolha pagar com Pix.\n2. Leia o QR code ou cole o código.\n3. Depois de pagar, toque em "Já paguei".',
                  style: TextStyle(color: Cores.textoFraco, fontSize: 13, height: 1.5)),
              const SizedBox(height: 18),
              BotaoMarca(texto: 'Já paguei', icone: Icons.check_rounded, carregando: _enviando, onPressed: _jaPaguei),
            ],
          ],
        ),
      ),
    );
  }
}

class _PagamentoBoleto extends StatefulWidget {
  final Mensalidade mensalidade;

  const _PagamentoBoleto({required this.mensalidade});

  @override
  State<_PagamentoBoleto> createState() => _PagamentoBoletoState();
}

class _PagamentoBoletoState extends State<_PagamentoBoleto> {
  Map<String, dynamic>? _boleto;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _gerar();
  }

  Future<void> _gerar() async {
    try {
      final r = await Api.instancia.post('/financeiro/${widget.mensalidade.id}/boleto') as Map<String, dynamic>;
      if (mounted) setState(() => _boleto = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _boleto!['linhaDigitavel'].toString()));
    if (mounted) mostrarMensagem(context, 'Código de barras copiado. Cole no app do seu banco.');
  }

  Future<void> _abrir() async {
    final url = Uri.tryParse(_boleto?['url']?.toString() ?? '');
    if (url == null || !await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) mostrarMensagem(context, 'Não foi possível abrir o boleto.', erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mensalidade;
    final linha = _boleto?['linhaDigitavel']?.toString();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pagar com boleto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Mensalidade de ${Helpers.moeda(m.valor)} com vencimento em ${Helpers.dataCurta(m.vencimento)}',
                style: const TextStyle(color: Cores.textoSuave)),
            const SizedBox(height: 18),
            if (_erro != null)
              Cartao(child: Vazio(icone: Icons.info_outline_rounded, titulo: 'Boleto indisponível', texto: _erro))
            else if (_boleto == null)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Gerando o boleto...', style: TextStyle(color: Cores.textoSuave)),
                  ],
                ),
              )
            else ...[
              if (linha != null && linha.isNotEmpty) ...[
                const Text('Código de barras', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Cartao(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(linha, style: const TextStyle(fontSize: 13, color: Cores.textoSuave, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: _copiar, icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('Copiar código de barras')),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(onPressed: _abrir, icon: const Icon(Icons.picture_as_pdf_outlined, size: 18), label: const Text('Abrir boleto em PDF')),
              const SizedBox(height: 16),
              const Text(
                'O boleto pode levar até 3 dias úteis para compensar. Quando o banco confirmar, a academia é avisada e confirma o pagamento.',
                style: TextStyle(color: Cores.textoFraco, fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
