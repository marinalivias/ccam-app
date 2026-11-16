import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'utils/helpers.dart';

const _roxo = PdfColor.fromInt(0xFF7C3AED);
const _verde = PdfColor.fromInt(0xFF16A34A);
const _cinza = PdfColor.fromInt(0xFF64748B);
const _linha = PdfColor.fromInt(0xFFE2E8F0);

pw.Widget _cabecalho(String titulo, String subtitulo) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _roxo, width: 2))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              gradient: const pw.LinearGradient(colors: [_roxo, PdfColor.fromInt(0xFF22C55E)]),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 10, color: _cinza)),
              ],
            ),
          ),
          pw.Text('CCAM', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _roxo)),
        ],
      ),
    );

Future<void> gerarComprovante(Map<String, dynamic> d) async {
  String data(Object? v) {
    final t = DateTime.tryParse(v?.toString() ?? '');
    return t == null ? '--' : Helpers.dataCurta(t);
  }

  pw.Widget linha(String rotulo, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 140, child: pw.Text(rotulo, style: const pw.TextStyle(color: _cinza, fontSize: 11))),
            pw.Expanded(child: pw.Text(valor, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      );

  final cnpj = (d['cnpj'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
  final cnpjFormatado = cnpj.length == 14
      ? '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}'
      : cnpj;
  final valor = (d['valor'] as num?)?.toDouble() ?? 0;

  final doc = pw.Document(title: 'Comprovante de pagamento', author: d['academia']?.toString() ?? 'CCAM');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _cabecalho('Comprovante de pagamento', 'Nº ${d['numero']}  |  Emitido em ${data(d['emitidoEm'])}'),
          pw.SizedBox(height: 24),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF0FDF4), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Valor pago', style: const pw.TextStyle(color: _cinza, fontSize: 11)),
                pw.Text(Helpers.moeda(valor), style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _verde)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          linha('Aluno', d['aluno']?.toString() ?? ''),
          if ((d['cpf'] ?? '').toString().isNotEmpty) linha('CPF', d['cpf'].toString()),
          linha('Referente a', 'Mensalidade com vencimento em ${data(d['vencimento'])}'),
          linha('Pago em', data(d['dataPagamento'])),
          pw.Divider(color: _linha, height: 28),
          linha('Recebido por', d['academia']?.toString() ?? ''),
          if ((d['razaoSocial'] ?? '').toString().isNotEmpty && d['razaoSocial'] != d['academia']) linha('Razão social', d['razaoSocial'].toString()),
          if (cnpjFormatado.isNotEmpty) linha('CNPJ', cnpjFormatado),
          pw.Spacer(),
          pw.Text(
            'Pagamento confirmado pela academia no sistema CCAM.',
            style: const pw.TextStyle(fontSize: 9, color: _cinza),
          ),
        ],
      ),
    ),
  );
  await Printing.sharePdf(bytes: await doc.save(), filename: 'comprovante-${d['numero']}.pdf');
}
