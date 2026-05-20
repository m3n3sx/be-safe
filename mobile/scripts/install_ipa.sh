#!/usr/bin/env bash
# install_ipa.sh — podpisz i zainstaluj unsigned IPA z be:Safe CI na iPhone z Linuxa (Fedora).
#
# Wymaga:
#   sudo dnf install ideviceinstaller libimobiledevice usbmuxd ifuse libplist-utils openssl-devel
#   Dadoum/Sideloader (CLI build z dub) — lub SideStore-Setup z sidestore.io
#
# Użycie:
#   bash install_ipa.sh [IPA_PATH]
#   bash install_ipa.sh --download <gh_run_id>    # pobierz z GH Actions
#
# Zakłada że iPhone jest podłączony kablem USB + Developer Mode włączony.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IPA_PATH=""
DOWNLOAD_RUN=""

usage() {
  cat <<EOF
$0 [IPA_PATH]
$0 --download <gh_run_id>
$0 --latest                  # pobierz z najnowszego zielonego runu

Examples:
  $0 ~/Downloads/AlertMap-unsigned.ipa
  $0 --download 26148456819
  $0 --latest
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --download) DOWNLOAD_RUN="$2"; shift 2 ;;
    --latest)   DOWNLOAD_RUN="latest"; shift ;;
    -h|--help)  usage ;;
    *)          IPA_PATH="$1"; shift ;;
  esac
done

# 1. PRE-CHECKS
echo "=== Pre-checks ==="
for cmd in idevice_id ideviceinstaller; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "BRAK: $cmd. Zainstaluj: sudo dnf install libimobiledevice ideviceinstaller"; exit 1; }
done

# Wykrywanie iPhone
UDID=$(idevice_id -l | head -1 || true)
if [[ -z "$UDID" ]]; then
  echo "Nie wykryto iPhone. Sprawdź:"
  echo "  - kabel USB"
  echo "  - usbmuxd jest uruchomiony: sudo systemctl status usbmuxd"
  echo "  - 'Zaufaj temu komputerowi' na telefonie"
  exit 1
fi
echo "iPhone UDID: $UDID"
ideviceinfo -u "$UDID" -k DeviceName || true
ideviceinfo -u "$UDID" -k ProductVersion || true

# 2. POBIERANIE IPA z GH (opcjonalne)
if [[ -n "$DOWNLOAD_RUN" ]]; then
  command -v gh >/dev/null 2>&1 || { echo "Zainstaluj gh CLI: sudo dnf install gh"; exit 1; }

  if [[ "$DOWNLOAD_RUN" == "latest" ]]; then
    DOWNLOAD_RUN=$(gh run list --workflow build-ios.yml --status success --limit 1 --json databaseId --jq '.[0].databaseId')
    [[ -n "$DOWNLOAD_RUN" ]] || { echo "Brak zielonych runów build-ios.yml"; exit 1; }
    echo "Najnowszy run: $DOWNLOAD_RUN"
  fi

  TMPDIR=$(mktemp -d)
  echo "Pobieram artefakt do $TMPDIR..."
  gh run download "$DOWNLOAD_RUN" -n beSafe-ios-ipa -D "$TMPDIR"
  IPA_PATH=$(find "$TMPDIR" -name '*.ipa' | head -1)
  [[ -f "$IPA_PATH" ]] || { echo "Nie znaleziono IPA w artefakcie"; exit 1; }
  echo "IPA: $IPA_PATH"
fi

[[ -f "$IPA_PATH" ]] || { echo "Brak IPA. Użyj: $0 <plik.ipa> lub $0 --latest"; usage; }

# 3. PODPISYWANIE
# Sideloader CLI od Dadoum — jeśli zainstalowany, podpisuje + instaluje w jednym kroku.
# Inaczej proponujemy alternatywę.
if command -v sideloader >/dev/null 2>&1; then
  echo ""
  echo "=== Sideloader: install + sign ==="
  echo "Podaj Apple ID + hasło (app-specific password jeśli 2FA)"
  sideloader install "$IPA_PATH"
  echo ""
  echo "✅ Zainstalowane. Na iPhone:"
  echo "   Ustawienia → Ogólne → VPN i Zarządzanie urządzeniami → twój Apple ID → Zaufaj"
  exit 0
fi

# 4. FALLBACK: instrukcje
cat <<EOF

⚠️  Brak narzędzia 'sideloader'. Wybierz jedną z opcji:

OPCJA A) Zainstaluj SIDELOADER (Dadoum) — najlepsze dla Linux
  sudo dnf install gcc dub ldc libplist-devel libimobiledevice-devel openssl-devel
  git clone https://github.com/Dadoum/Sideloader /tmp/sideloader-src
  cd /tmp/sideloader-src && dub build -b release --config=cli
  sudo install -m 755 bin/sideloader /usr/local/bin/
  cd - && bash $0 "$IPA_PATH"

OPCJA B) Zainstaluj SIDESTORE na telefonie (rekomendowane long-term)
  1. Pobierz SideStore.ipa: https://github.com/SideStore/SideStore/releases
  2. Zainstaluj SideStore raz przez sideloader (opcja A): sideloader install SideStore.ipa -i
  3. Wireguard z App Store + config z https://sidestore.io
  4. W SideStore na iPhone: + → wybierz $IPA_PATH (przez Files / AirDrop)
  5. SideStore odnowi cert automatycznie co 7 dni

OPCJA C) Instalacja BEZ podpisu (TYLKO z TrollStore / jailbreak)
  ideviceinstaller -u $UDID -i $IPA_PATH

IPA gotowy w: $IPA_PATH
EOF
