# CCAM App

App do aluno do CCAM, feito em Flutter. Depende do site: https://github.com/marinalivias/ccam

Login de teste: `bruno.costa@exemplo.com` / `teste123`

O aluno vê a ficha de treino do dia, registra as séries, acompanha o calendário do mês, lê o mural,
paga a mensalidade por Pix, vê a loja da academia (com desconto no dia do aniversário) e acompanha a
frequência e a evolução da carga no perfil.

O sininho da tela inicial junta pagamentos, avisos novos, mudanças no treino e a promoção de aniversário.
No Android essas novidades e o fim do descanso também chegam como notificação com o app fechado.

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

Os alunos cadastrados no site entram com o e-mail e, no primeiro acesso, com o CPF como senha.
A senha pode ser trocada no perfil.
