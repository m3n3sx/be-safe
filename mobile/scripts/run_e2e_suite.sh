#!/usr/bin/env bash
# Uruchamia wszystkie suity E2E (smoke + P1-P4) na wybranym urządzeniu
# i zbiera metryki z logcat.
#
# Użycie:
#   scripts/run_e2e_suite.sh ZY32HKMT45     # Moto
#   scripts/run_e2e_suite.sh SK4D5X7P45ZTGIIR  # Realme
#
# Po zakończeniu: pliki JSON w /tmp/be_safe_metrics/<device>/

set -u

DEVICE="${1:-ZY32HKMT45}"
RUN_TS=$(date +%Y%m%d_%H%M%S)
OUT_DIR="/tmp/be_safe_metrics/${DEVICE}_${RUN_TS}"
mkdir -p "$OUT_DIR"

export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk
export PATH=/home/ooxo/flutter/bin:/home/ooxo/.pub-cache/bin:$PATH
export ANDROID_HOME=/home/ooxo/Android/Sdk
SECRET=$(cat /tmp/test_reset_secret.txt)

cd /home/ooxo/alert/mobile

SUITES=(
  "integration_test/personas/_smoke_login_test.dart:smoke"
  "integration_test/personas/p1_parent_tech_test.dart:p1"
  "integration_test/personas/p2_parent_easy_test.dart:p2"
  "integration_test/personas/p3_kid_anna_test.dart:p3"
  "integration_test/personas/p4_senior_jadwiga_test.dart:p4"
)

echo "[$(date +%H:%M:%S)] === Uruchamianie suit E2E na ${DEVICE} ==="
echo "[$(date +%H:%M:%S)] Wyniki w: ${OUT_DIR}"

for entry in "${SUITES[@]}"; do
  target="${entry%%:*}"
  name="${entry##*:}"
  log="${OUT_DIR}/${name}.log"
  echo ""
  echo "[$(date +%H:%M:%S)] >>> ${name} (${target})"

  patrol test \
    --target "$target" \
    --dart-define=TEST_RESET_SECRET="$SECRET" \
    --dart-define=RUN_ID="${name}_${RUN_TS}" \
    -d "$DEVICE" \
    > "$log" 2>&1 || true

  # Zlicz pass/fail z logu Patrol
  ok=$(grep -oE "Successful: [0-9]+" "$log" | head -1)
  fail=$(grep -oE "Failed: [0-9]+" "$log" | head -1)
  echo "[$(date +%H:%M:%S)]   $ok  $fail"

  # Pobierz metryki z backendu (zapisane przez TestMetrics.flushAll)
  json="${OUT_DIR}/${name}.json"
  curl -sS -H "X-Test-Secret: $SECRET" \
    "https://besafe.org.pl/api/v1/test/metrics/${name}_${RUN_TS}" \
    -o "$json" 2>/dev/null || true
  if [ -s "$json" ] && ! grep -q '"error"' "$json"; then
    echo "[$(date +%H:%M:%S)]   ✅ metryki: $json ($(wc -c < "$json") B)"
  else
    echo "[$(date +%H:%M:%S)]   ⚠️  brak metryk dla ${name}_${RUN_TS}"
  fi
done

echo ""
echo "[$(date +%H:%M:%S)] === Koniec ==="
echo "Wyniki w: ${OUT_DIR}"
ls -lh "${OUT_DIR}"/*.json 2>/dev/null || true
