# CCAM App

App do aluno do CCAM, feito em Flutter. Depende do site: https://github.com/marinalivias/ccam

> **Login para a apresentação:** `aluno@ccam.com` / `11144477735`
>
> No site, use o gestor: `gestor@formulafitness.com` / `gestor123`

O aluno vê a ficha de treino, marca o que treinou, ajusta os exercícios, lê o mural, manda parabéns para
os aniversariantes, vê a loja da academia (com desconto no dia do aniversário) e acompanha a frequência e as
mensalidades.

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

Qualquer aluno cadastrado no site entra com o e-mail e o CPF dele.
