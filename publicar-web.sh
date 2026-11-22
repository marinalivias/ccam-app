#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

SITE="${1:-../ccam}"
DESTINO="$SITE/src/main/resources/static/app"

if [ ! -d "$SITE/src/main/resources/static" ]; then
  echo "Pasta do site nao encontrada: $SITE"
  echo "Uso: ./publicar-web.sh caminho/da/pasta/do/site"
  exit 1
fi

flutter build web --base-href /app/ --release
rm -rf "$DESTINO"
mkdir -p "$DESTINO"
(cd build/web && tar --exclude=./canvaskit -cf - .) | (cd "$DESTINO" && tar -xf -)
echo "Versao web copiada para $DESTINO"
