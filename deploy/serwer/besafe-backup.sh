#!/usr/bin/env bash
# Codzienna kopia bazy be:Safe (pg_dump -Fc) z kontrola poprawnosci i retencja 14 dni.
# Instalacja: /usr/local/sbin/besafe-backup.sh + besafe-backup.service/.timer w /etc/systemd/system
set -euo pipefail
DIR=${BACKUP_DIR:-/srv/besafe/backups}
KEEP_DAYS=${KEEP_DAYS:-14}
C=${PG_CONTAINER:-besafe_postgres_1}
umask 077
mkdir -p "$DIR"
F="$DIR/besafe-$(date +%F-%H%M).dump"
podman exec "$C" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$F.part"
# kontrola: archiwum musi sie dac odczytac i zawierac dane tabel
N=$(podman exec -i "$C" sh -c 'f=$(mktemp); cat > "$f"; pg_restore --list "$f"; rc=$?; rm -f "$f"; exit $rc' < "$F.part" | grep -c "TABLE DATA" || true)
if [ "${N:-0}" -lt 10 ]; then
  echo "BLAD: kopia $F.part wyglada na niepelna (TABLE DATA: ${N:-0})" >&2
  exit 1
fi
mv "$F.part" "$F"
echo "OK: $F ($(du -h "$F" | cut -f1), tabel z danymi: $N)"
find "$DIR" -maxdepth 1 -name 'besafe-*.dump' -mtime +$((KEEP_DAYS - 1)) -print -delete
find "$DIR" -maxdepth 1 -name 'besafe-*.dump.part' -mtime +1 -print -delete
