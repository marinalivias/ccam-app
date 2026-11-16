# CCAM App

App do aluno do CCAM, feito em Flutter. Depende do site: https://github.com/marinalivias/ccam

Login de teste: `bruno.costa@exemplo.com` / `teste123`

## O que o aluno faz

- Hoje: treino do dia com GIF e registro por série, já preenchendo a carga usada da última vez. Tocando em
  outro dia da semana, aparece o treino daquele dia.
- Agenda: calendário do mês com os treinos feitos, parciais e previstos, e a Minha ficha para montar o treino.
- Mural: avisos da academia.
- Financeiro: mensalidades, pagamento por Pix ou boleto e comprovante em PDF das mensalidades pagas.
- Loja: produtos da academia com pesquisa, filtro por categoria e desconto no dia do aniversário.
- Perfil: foto opcional, frequência, gráficos de evolução e troca de senha.

## Notificações

O sininho da tela inicial junta pagamentos, avisos novos, mudanças no treino feitas pelo professor, a promoção de
aniversário e o lembrete de quem está há muitos dias sem treinar. Cada notificação pode ser marcada como lida ou
não lida. No Android elas também chegam com o app fechado, verificadas a cada 15 minutos.

## Sem internet

O app mostra os últimos dados salvos no celular e guarda os registros de treino para enviar sozinho quando a
conexão voltar.

## Senha

O aluno entra com o e-mail e, no primeiro acesso, com o CPF como senha. Depois pode trocar a senha no perfil.
Quem esquece pede pelo app em "Esqueci minha senha" e a recepção redefine pelo site.

## Como rodar

1. Suba o site (porta 8081).
2. Nesta pasta:

```
./testar-no-emulador.sh
```

Ou rode pelo Android Studio. O Flutter precisa usar o Java 21:

```
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
```

Para testar no navegador:

```
flutter build web --dart-define=API_URL=http://localhost:8081/api
```

O logo do app fica na pasta `marca`.
