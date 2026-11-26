# CCAM App

App do aluno do CCAM, feito em Flutter. Depende do site: https://github.com/marinalivias/ccam

Login de teste: `bruno.costa@exemplo.com` / `teste123`

## O que o aluno faz

- Hoje: treino do dia com GIF e registro por série, já preenchendo a carga usada da última vez. Tocando em
  outro dia da semana, aparece o treino daquele dia.
- Agenda: calendário do mês com os treinos feitos, parciais e previstos, e a Minha ficha para montar o treino.
- Mural: avisos da academia.
- Financeiro: mensalidades, pagamento por Pix e comprovante em PDF das mensalidades pagas.
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

## Instalar no celular

Baixe o `ccam.apk` em https://github.com/marinalivias/ccam-app/releases/latest e instale no Android. Ele já usa o
servidor online. Também dá para abrir pelo navegador em https://ccam.onrender.com/app

## Como rodar no computador

### O que instalar

- Git
- Flutter (vem com o Dart)
- Android Studio, com um emulador criado no Device Manager
- Java 21 para o Flutter gerar o APK:

```bash
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
```

No Windows, aponte para a pasta do Java 21 ou para o `jbr` que vem dentro do Android Studio.

### Passo a passo

1. Baixe o projeto e as dependências:

```bash
git clone https://github.com/marinalivias/ccam-app.git
cd ccam-app
flutter pub get
```

2. Escolha qual servidor o app vai usar.

Usando o servidor online, sem precisar rodar o site:

```bash
flutter run --dart-define=API_URL=https://ccam.onrender.com/api
```

Usando o site rodando no seu computador (veja o README do site), com o emulador aberto:

```bash
flutter run
```

No emulador o app procura o site em `10.0.2.2:8081`, que é o seu computador. No Linux, o
`./testar-no-emulador.sh` gera o APK, abre o emulador e instala o app sozinho.

### Outras tarefas

Gerar o APK de entrega (precisa do `android/key.properties` com a chave de assinatura, que não vai para o GitHub):

```bash
flutter build apk --release --dart-define=API_URL=https://ccam.onrender.com/api
```

Atualizar a versão que roda no navegador dentro do site (com as duas pastas lado a lado):

```bash
./publicar-web.sh ../ccam
```

O logo do app fica na pasta `marca`.
