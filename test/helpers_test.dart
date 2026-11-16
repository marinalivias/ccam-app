import 'package:flutter_test/flutter_test.dart';
import 'package:ccam_app/utils/helpers.dart';

void main() {
  group('Testes de Saudação |', () {
    test('Deve retornar Bom dia para horas antes do meio-dia', () {
      expect(Helpers.getSaudacao(9), 'Bom dia');
      expect(Helpers.getSaudacao(11), 'Bom dia');
    });

    test('Deve retornar Boa tarde para horas entre 12h e 17h', () {
      expect(Helpers.getSaudacao(13), 'Boa tarde');
      expect(Helpers.getSaudacao(17), 'Boa tarde');
    });

    test('Deve retornar Boa noite para horas após 18h', () {
      expect(Helpers.getSaudacao(19), 'Boa noite');
      expect(Helpers.getSaudacao(23), 'Boa noite');
    });
  });

  group('Testes de Dia da Semana |', () {
    test('Deve retornar o dia correto baseado no número (1 a 7)', () {
      expect(Helpers.obterDiaAtual(1), 'Segunda-feira');
      expect(Helpers.obterDiaAtual(5), 'Sexta-feira');
      expect(Helpers.obterDiaAtual(7), 'Domingo');
    });
  });

  group('Datas e valores |', () {
    test('Segunda da semana', () {
      expect(Helpers.segundaDaSemana(DateTime(2026, 11, 13)), DateTime(2026, 11, 9));
      expect(Helpers.segundaDaSemana(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
      expect(Helpers.segundaDaSemana(DateTime(2026, 11, 15)), DateTime(2026, 11, 9));
    });

    test('Formato ISO e moeda', () {
      expect(Helpers.isoData(DateTime(2026, 3, 5)), '2026-03-05');
      expect(Helpers.moeda(1299.9), 'R\$ 1.299,90');
      expect(Helpers.moeda(99.9), 'R\$ 99,90');
    });
  });
}
