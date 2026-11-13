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

class TreinoRealizado {
  final DateTime data;
  final int previstos;
  final int feitos;
  final bool concluido;
  final Set<String> idsFeitos;
  final String? observacao;

  TreinoRealizado({
    required this.data,
    required this.previstos,
    required this.feitos,
    required this.concluido,
    required this.idsFeitos,
    this.observacao,
  });

  factory TreinoRealizado.fromJson(Map<String, dynamic> j) => TreinoRealizado(
        data: DateTime.parse(j['data']),
        previstos: (j['exerciciosPrevistos'] as num?)?.toInt() ?? 0,
        feitos: (j['exerciciosFeitos'] as num?)?.toInt() ?? 0,
        concluido: j['concluido'] == true,
        idsFeitos: ((j['idsFeitos'] as List?) ?? []).map((e) => e.toString()).toSet(),
        observacao: j['observacao']?.toString(),
      );
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

class Aniversariante {
  final String nome;
  final int dia;
  final int mes;
  final bool hoje;
  final bool voce;

  Aniversariante({
    required this.nome,
    required this.dia,
    required this.mes,
    required this.hoje,
    required this.voce,
  });

  factory Aniversariante.fromJson(Map<String, dynamic> j) => Aniversariante(
        nome: (j['nome'] ?? '').toString(),
        dia: (j['dia'] as num).toInt(),
        mes: (j['mes'] as num).toInt(),
        hoje: j['hoje'] == true,
        voce: j['voce'] == true,
      );
}

class Mensalidade {
  final String id;
  final DateTime vencimento;
  final double valor;
  final String status;

  Mensalidade({required this.id, required this.vencimento, required this.valor, required this.status});

  bool get paga => status == 'Pago';

  factory Mensalidade.fromJson(Map<String, dynamic> j) => Mensalidade(
        id: j['id'].toString(),
        vencimento: DateTime.parse(j['vencimento']),
        valor: (j['valor'] as num).toDouble(),
        status: (j['status'] ?? '').toString(),
      );
}

class ItemCatalogo {
  final int id;
  final String nome;
  final String grupoMuscular;
  final String? imagemUrl;

  ItemCatalogo({required this.id, required this.nome, required this.grupoMuscular, this.imagemUrl});

  factory ItemCatalogo.fromJson(Map<String, dynamic> j) => ItemCatalogo(
        id: (j['id'] as num).toInt(),
        nome: (j['nome'] ?? '').toString(),
        grupoMuscular: (j['grupoMuscular'] ?? 'Geral').toString(),
        imagemUrl: j['imagemUrl']?.toString(),
      );
}
