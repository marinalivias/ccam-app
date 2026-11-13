# CCAM App

App do aluno do CCAM, feito em Flutter. Usa a mesma API do sistema web: https://github.com/marinalivias/ccam

## O que o aluno faz no app

- Vê o treino do dia e marca cada exercício conforme vai fazendo
- Vê a agenda da semana e marca treinos dos últimos 30 dias
- Adiciona, edita e remove exercícios da própria ficha (o professor vê tudo no histórico do site)
- Lê o mural de avisos da academia
- Vê quem faz aniversário no mês
- Acompanha a frequência e as mensalidades

## Como rodar

1. Suba o sistema web (na pasta do site: `./mvnw spring-boot:run`).
2. Nesta pasta, rode:

```
./testar-no-emulador.sh
```

O script gera o APK com o emulador desligado, liga o emulador com pouca memória e abre o app. Em PC com
pouca RAM, não rode o build e o emulador ao mesmo tempo, e feche o IntelliJ e o Android Studio antes.

Também dá para rodar pelo Android Studio ou com `flutter run`. O Flutter precisa usar o Java 21
(`flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64`), porque o Gradle do projeto não aceita o Java 25.

No emulador o app acessa a API em `http://10.0.2.2:8081/api`. Para usar outro endereço:

```
flutter run --dart-define=API_URL=https://seu-servidor.com/api
```

## Login de exemplo

| E-mail | CPF |
|---|---|
| beatriz.martins@exemplo.com | 03186265940 |
