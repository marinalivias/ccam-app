class Aluno {
  final String id;
  final String nome;
  final String email;
  final String? academia;
  final DateTime? dataNascimento;
  final double? peso;
  final double? altura;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    this.academia,
    this.dataNascimento,
    this.peso,
    this.altura,
  });

  String get primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  factory Aluno.fromJson(Map<String, dynamic> j) => Aluno(
        id: j['id'].toString(),
        nome: (j['nome'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        academia: j['academia']?.toString(),
        dataNascimento: j['dataNascimento'] != null ? DateTime.tryParse(j['dataNascimento']) : null,
        peso: (j['peso'] as num?)?.toDouble(),
        altura: (j['altura'] as num?)?.toDouble(),
      );
}

class Exercicio {
  final String id;
  final String nome;
  final String? grupoMuscular;
  final String diaSemana;
  final String series;
  final String repeticoes;
  final String? carga;
  final String? imagemUrl;

  Exercicio({
    required this.id,
    required this.nome,
    this.grupoMuscular,
    required this.diaSemana,
    required this.series,
    required this.repeticoes,
    this.carga,
    this.imagemUrl,
  });

  int get totalSeries {
    final m = RegExp(r'\d+').firstMatch(series);
    final n = m == null ? 1 : int.parse(m.group(0)!);
    return n.clamp(1, 20);
  }

  int? get alvoReps {
    final r = repeticoes.toLowerCase();
    if (r.contains('seg') || r.contains('min') || r.contains('"')) return null;
    final m = RegExp(r'\d+').firstMatch(r);
    return m == null ? null : int.parse(m.group(0)!);
  }

  String get resumo {
    final c = (carga ?? '').isNotEmpty ? '  ·  $carga' : '';
    return '$series x $repeticoes$c';
  }

  factory Exercicio.fromJson(Map<String, dynamic> j) => Exercicio(
        id: j['id'].toString(),
        nome: (j['nomeExercicio'] ?? j['nome'] ?? 'Exercício').toString(),
        grupoMuscular: j['grupoMuscular']?.toString(),
        diaSemana: (j['diaSemana'] ?? '').toString(),
        series: (j['series'] ?? '').toString(),
        repeticoes: (j['repeticoes'] ?? '').toString(),
        carga: j['carga']?.toString(),
        imagemUrl: j['imagemUrl']?.toString(),
      );
}

class Registro {
  final String exercicioId;
  final List<int> reps;
  final String? carga;
  final bool completo;

  Registro({required this.exercicioId, required this.reps, this.carga, required this.completo});

  factory Registro.fromJson(Map<String, dynamic> j) => Registro(
        exercicioId: j['exercicioId'].toString(),
        reps: ((j['reps'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        carga: j['carga']?.toString(),
        completo: j['completo'] == true,
      );
}

class TreinoRealizado {
  final DateTime data;
  final int previstos;
  final int feitos;
  final int seriesPrevistas;
  final int seriesFeitas;
  final bool concluido;
  final Set<String> idsFeitos;
  final String? observacao;
  final Map<String, Registro> registros;

  TreinoRealizado({
    required this.data,
    required this.previstos,
    required this.feitos,
    this.seriesPrevistas = 0,
    this.seriesFeitas = 0,
    required this.concluido,
    required this.idsFeitos,
    this.observacao,
    this.registros = const {},
  });

  factory TreinoRealizado.fromJson(Map<String, dynamic> j) {
    final regs = ((j['exercicios'] as List?) ?? []).map((e) => Registro.fromJson(e)).toList();
    return TreinoRealizado(
      data: DateTime.parse(j['data']),
      previstos: (j['exerciciosPrevistos'] as num?)?.toInt() ?? 0,
      feitos: (j['exerciciosFeitos'] as num?)?.toInt() ?? 0,
      seriesPrevistas: (j['seriesPrevistas'] as num?)?.toInt() ?? 0,
      seriesFeitas: (j['seriesFeitas'] as num?)?.toInt() ?? 0,
      concluido: j['concluido'] == true,
      idsFeitos: ((j['idsFeitos'] as List?) ?? []).map((e) => e.toString()).toSet(),
      observacao: j['observacao']?.toString(),
      registros: {for (final r in regs) r.exercicioId: r},
    );
  }
}

class Frequencia {
  final int diasPorSemana;
  final int treinosSemana;
  final int treinos30Dias;
  final int previstos30Dias;
  final int percentual;
  final int semanasSeguidas;
  final DateTime? ultimoTreino;

  Frequencia({
    required this.diasPorSemana,
    required this.treinosSemana,
    required this.treinos30Dias,
    required this.previstos30Dias,
    required this.percentual,
    required this.semanasSeguidas,
    this.ultimoTreino,
  });

  factory Frequencia.fromJson(Map<String, dynamic> j) => Frequencia(
        diasPorSemana: (j['diasPorSemana'] as num?)?.toInt() ?? 0,
        treinosSemana: (j['treinosSemana'] as num?)?.toInt() ?? 0,
        treinos30Dias: (j['treinos30Dias'] as num?)?.toInt() ?? 0,
        previstos30Dias: (j['previstos30Dias'] as num?)?.toInt() ?? 0,
        percentual: (j['percentual'] as num?)?.toInt() ?? 0,
        semanasSeguidas: (j['semanasSeguidas'] as num?)?.toInt() ?? 0,
        ultimoTreino: j['ultimoTreino'] != null ? DateTime.tryParse(j['ultimoTreino']) : null,
      );
}

class Aviso {
  final String id;
  final String titulo;
  final String mensagem;
  final DateTime? publicadoEm;
  final DateTime? editadoEm;
  final String? autor;

  Aviso({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.publicadoEm,
    this.editadoEm,
    this.autor,
  });

  factory Aviso.fromJson(Map<String, dynamic> j) => Aviso(
        id: j['id'].toString(),
        titulo: (j['titulo'] ?? '').toString(),
        mensagem: (j['mensagem'] ?? '').toString(),
        publicadoEm: j['dataPublicacao'] != null ? DateTime.tryParse(j['dataPublicacao']) : null,
        editadoEm: j['dataAtualizacao'] != null ? DateTime.tryParse(j['dataAtualizacao']) : null,
        autor: j['autorNome']?.toString(),
      );
}

class Produto {
  final String id;
  final String nome;
  final String? descricao;
  final String? categoria;
  final double preco;
  final double precoFinal;
  final bool descontoAniversario;

  Produto({
    required this.id,
    required this.nome,
    this.descricao,
    this.categoria,
    required this.preco,
    required this.precoFinal,
    required this.descontoAniversario,
  });

  bool get comDesconto => precoFinal < preco;

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: j['id'].toString(),
        nome: (j['nome'] ?? '').toString(),
        descricao: j['descricao']?.toString(),
        categoria: j['categoria']?.toString(),
        preco: (j['preco'] as num).toDouble(),
        precoFinal: (j['precoFinal'] as num).toDouble(),
        descontoAniversario: j['descontoAniversario'] == true,
      );
}

class Loja {
  final bool ativa;
  final int descontoAniversario;
  final bool aniversarioHoje;
  final List<Produto> produtos;

  Loja({required this.ativa, required this.descontoAniversario, required this.aniversarioHoje, required this.produtos});

  factory Loja.fromJson(Map<String, dynamic> j) => Loja(
        ativa: j['ativa'] == true,
        descontoAniversario: (j['descontoAniversario'] as num?)?.toInt() ?? 0,
        aniversarioHoje: j['aniversarioHoje'] == true,
        produtos: ((j['produtos'] as List?) ?? []).map((e) => Produto.fromJson(e)).toList(),
      );
}

class Mensalidade {
  final String id;
  final DateTime vencimento;
  final double valor;
  final String status;
  final DateTime? dataPagamento;
  final DateTime? pagamentoInformadoEm;

  Mensalidade({
    required this.id,
    required this.vencimento,
    required this.valor,
    required this.status,
    this.dataPagamento,
    this.pagamentoInformadoEm,
  });

  bool get paga => status == 'Pago';
  bool get informada => !paga && pagamentoInformadoEm != null;

  factory Mensalidade.fromJson(Map<String, dynamic> j) => Mensalidade(
        id: j['id'].toString(),
        vencimento: DateTime.parse(j['vencimento']),
        valor: (j['valor'] as num).toDouble(),
        status: (j['status'] ?? '').toString(),
        dataPagamento: j['dataPagamento'] != null ? DateTime.tryParse(j['dataPagamento']) : null,
        pagamentoInformadoEm: j['pagamentoInformadoEm'] != null ? DateTime.tryParse(j['pagamentoInformadoEm']) : null,
      );
}

class ItemCatalogo {
  final int id;
  final String nome;
  final String grupoMuscular;
  final String? imagemUrl;
  final String? instrucoes;

  ItemCatalogo({required this.id, required this.nome, required this.grupoMuscular, this.imagemUrl, this.instrucoes});

  List<String> get passos => (instrucoes ?? '').split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  factory ItemCatalogo.fromJson(Map<String, dynamic> j) => ItemCatalogo(
        id: (j['id'] as num).toInt(),
        nome: (j['nome'] ?? '').toString(),
        grupoMuscular: (j['grupoMuscular'] ?? 'Geral').toString(),
        imagemUrl: j['imagemUrl']?.toString(),
        instrucoes: j['instrucoes']?.toString(),
      );
}

class Notificacao {
  final String id;
  final String tipo;
  final String titulo;
  final String texto;
  final DateTime data;

  Notificacao({required this.id, required this.tipo, required this.titulo, required this.texto, required this.data});

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'].toString(),
        tipo: (j['tipo'] ?? '').toString(),
        titulo: (j['titulo'] ?? '').toString(),
        texto: (j['texto'] ?? '').toString(),
        data: DateTime.tryParse((j['data'] ?? '').toString()) ?? DateTime.now(),
      );
}
