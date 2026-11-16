class Helpers {
  static const dias = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  static const rotativo = 'Rotativo (Ficha)';
  static const diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String getSaudacao(int hora) {
    if (hora < 5) return 'Boa noite';
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String obterDiaAtual(int diaDaSemana) {
    if (diaDaSemana < 1 || diaDaSemana > 7) return dias.first;
    return dias[diaDaSemana - 1];
  }

  static DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime segundaDaSemana(DateTime d) => soData(d).subtract(Duration(days: d.weekday - 1));

  static String isoData(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String dataCurta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String dataPorExtenso(DateTime d) => '${d.day} de ${meses[d.month - 1]}';

  static String moeda(double v) {
    final partes = v.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return 'R\$ $inteiro,${partes[1]}';
  }

  static bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
