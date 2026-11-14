#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ADB="$SDK/platform-tools/adb"
EMULADOR="$SDK/emulator/emulator"
AVD="${1:-Medium_Phone}"
APK=build/app/outputs/flutter-apk/app-debug.apk

if ! curl -s -o /dev/null http://localhost:8081/login.html; then
  echo "Aviso: o site nao esta rodando. Na pasta do site rode: ./mvnw spring-boot:run"
  echo "O app vai abrir, mas so consegue entrar depois que o site subir."
fi

if "$ADB" devices | grep -q '^emulator'; then
  echo "Emulador ja esta ligado."
  if [ ! -f "$APK" ]; then
    echo "O APK ainda nao foi gerado. Feche o emulador e rode este script de novo."
    exit 1
  fi
  if [ -n "$(find lib pubspec.yaml -newer "$APK" -print -quit)" ]; then
    echo "O codigo mudou desde o ultimo APK. Feche o emulador e rode este script de novo para atualizar."
    exit 1
  fi
else
  echo "Gerando o APK com o emulador desligado..."
  flutter build apk --debug
  (cd android && ./gradlew --stop >/dev/null 2>&1) || true

  echo "Ligando o emulador $AVD..."
  nohup "$EMULADOR" -avd "$AVD" -memory 1536 -no-snapshot-save -no-boot-anim -no-audio >/dev/null 2>&1 &
  "$ADB" wait-for-device
  until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 2
  done
fi

echo "Instalando o app..."
"$ADB" install -r "$APK" >/dev/null
"$ADB" shell monkey -p com.ccam.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "Pronto. O CCAM esta aberto no emulador."
