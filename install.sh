#!/bin/bash
# Kosmos Monitor · instalador de un solo comando.
#
#   curl -fsSL https://raw.githubusercontent.com/FedericoSecchi/kosmos-monitor-releases/main/install.sh | bash
#
# Descarga la última versión, la verifica, la instala (o la actualiza) y la abre. No pide contraseña y no toca tus
# datos ni tus preferencias: solo reemplaza la app.
#
# Para pruebas:
#   KOSMOS_DEST=<carpeta>   instala ahí (nunca toca /Applications ni ~/Applications ni la app que esté abierta)
#   KOSMOS_NO_OPEN=1        no abre la app al terminar
#   KOSMOS_URL=<url>        otro .zip (solo para probar una actualización antes de publicarla)
#
# Todo va dentro de main() y se llama en la última línea: con «curl … | bash» el script entero se lee antes de
# ejecutar nada (una conexión cortada a la mitad no puede dejar una instalación a medias).
set -euo pipefail

main() {
  local url="${KOSMOS_URL:-https://github.com/FedericoSecchi/kosmos-monitor-releases/releases/latest/download/KosmosMonitor.zip}"
  local app="Kosmos Monitor.app"
  local bundle_id="com.kosmos.monitor"

  say ""
  say "Kosmos Monitor · instalador"
  say "---------------------------"

  # 1. ¿Mac con chip de Apple? (sysctl dice la verdad aunque la Terminal corra con Rosetta; uname no)
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" != "1" ]; then
    fail "Esta Mac tiene procesador Intel. Kosmos Monitor solo funciona en Macs con chip de Apple (M1, M2, M3, M4…)."
  fi

  # 2. ¿macOS 13 o más nuevo?
  local ver major
  ver="$(sw_vers -productVersion)"
  major="${ver%%.*}"
  if [ "$major" -lt 13 ]; then
    fail "Esta Mac tiene macOS $ver. Kosmos Monitor necesita macOS 13 (Ventura) o más nuevo. Se actualiza en  › Configuración del Sistema › General › Actualización de software."
  fi
  ok "Mac con chip de Apple y macOS $ver"

  # 3. ¿Dónde está (o dónde va)? Si ya está instalada, se reemplaza ahí; si no, en tu carpeta Aplicaciones personal
  #    (~/Applications), que no pide contraseña.
  local target="" mode="instalación" oldver=""
  if [ -n "${KOSMOS_DEST:-}" ]; then
    mkdir -p "$KOSMOS_DEST"
    target="$KOSMOS_DEST/$app"
  elif [ -d "/Applications/$app" ]; then
    target="/Applications/$app"
  else
    target="$HOME/Applications/$app"
  fi
  if [ -d "$target" ]; then
    mode="actualización"
    oldver="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$target/Contents/Info.plist" 2>/dev/null || echo "?")"
    if [ ! -w "$(dirname "$target")" ] || [ ! -w "$target" ]; then
      fail "Kosmos Monitor está en $(dirname "$target") pero tu usuario no puede modificarla. Arrastrala a la Papelera y volvé a correr el comando: se instala en tu carpeta personal sin pedir contraseña."
    fi
  fi

  # 4. Descargar a una carpeta temporal (se borra siempre al terminar, salga bien o mal)
  # global (no local): el trap de salida corre después de que main() terminó
  KOSMOS_TMP="$(mktemp -d "${TMPDIR:-/tmp}/kosmos-instalar.XXXXXX")"
  trap 'rm -rf "${KOSMOS_TMP:-}"' EXIT
  local tmp="$KOSMOS_TMP"
  say "→ Descargando la última versión…"
  if ! curl -fsSL --retry 2 --connect-timeout 15 -o "$tmp/KosmosMonitor.zip" "$url"; then
    fail "No se pudo descargar Kosmos Monitor. Revisá que haya internet y volvé a correr el mismo comando."
  fi

  # 5. Descomprimir con ditto (conserva la firma) y verificar la firma antes de instalar nada
  if ! ditto -x -k "$tmp/KosmosMonitor.zip" "$tmp/x" 2>/dev/null || [ ! -d "$tmp/x/$app" ]; then
    fail "El archivo descargado está incompleto o dañado. Volvé a correr el comando."
  fi
  if ! codesign --verify --deep --strict "$tmp/x/$app" 2>/dev/null; then
    fail "La app descargada no pasó la verificación de su firma: no la instalo. Avisale a quien te pasó el comando."
  fi
  local newid newver
  newid="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$tmp/x/$app/Contents/Info.plist" 2>/dev/null || echo "")"
  newver="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$tmp/x/$app/Contents/Info.plist" 2>/dev/null || echo "?")"
  [ "$newid" = "$bundle_id" ] || fail "El archivo descargado no es Kosmos Monitor. No lo instalo."
  ok "Descargada y verificada (versión $newver)"

  # 6. Cerrar la app si está abierta (solo la copia que se va a reemplazar)
  close_app "$target"

  # 7. Reemplazar: se copia al lado y se cambia de un saque (si algo falla, la app anterior queda como estaba)
  local dir staging
  dir="$(dirname "$target")"
  mkdir -p "$dir"
  staging="$dir/.kosmos-nueva-$$"
  rm -rf "$staging"
  ditto "$tmp/x/$app" "$staging/$app"
  rm -rf "$target"
  mv "$staging/$app" "$target"
  rm -rf "$staging"
  # por las dudas: sin cuarentena, macOS no la bloquea al abrirla (curl no la marca, pero un proxy o un navegador sí)
  xattr -dr com.apple.quarantine "$target" 2>/dev/null || true
  ok "Copiada en $target"

  # 8. Abrir
  if [ "${KOSMOS_NO_OPEN:-}" != "1" ]; then
    open "$target"
    ok "Abierta: buscala arriba a la derecha, en la barra de menú"
  fi

  say ""
  if [ "$mode" = "actualización" ]; then
    say "✓ Listo: actualización de Kosmos Monitor $oldver a $newver."
  else
    say "✓ Listo: instalación de Kosmos Monitor $newver."
    say "  La primera vez se abre una bienvenida que explica todo. No hace falta configurar nada."
  fi
  say ""
}

say() { printf '%s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
fail() { printf '\n✗ %s\n\n' "$*" >&2; exit 1; }

# Cierra las instancias de Kosmos Monitor que corren desde la app que se va a reemplazar. Con KOSMOS_DEST, solo esas
# (nunca la app real de quien prueba); en una instalación normal, todas (es la misma app).
close_app() {
  local target="$1" pid path pids=""
  for pid in $(pgrep -x "Kosmos Monitor" 2>/dev/null || true); do
    path="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
    if [ -z "${KOSMOS_DEST:-}" ] || [[ "$path" == "$target/"* ]]; then pids="$pids $pid"; fi
  done
  [ -n "$pids" ] || return 0
  say "→ Cerrando Kosmos Monitor para reemplazarla…"
  # shellcheck disable=SC2086  # lista de pids separada por espacios, a propósito
  kill $pids 2>/dev/null || true
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    local alive=""
    for pid in $pids; do kill -0 "$pid" 2>/dev/null && alive="$alive $pid"; done
    [ -z "$alive" ] && return 0
    # shellcheck disable=SC2086  # lista de pids, a propósito sin comillas
    [ "$i" = 10 ] && { kill -9 $alive 2>/dev/null || true; return 0; }
    sleep 0.5
  done
}

main "$@"
