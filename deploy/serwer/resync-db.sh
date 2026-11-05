#!/usr/bin/env bash
# Ostatnia synchronizacja bazy Scaleway -> serwer domowy, tuz przed przelaczeniem DNS.
# Uruchamiac z laptopa (ma klucze do obu maszyn). Nie wypisuje sekretow.
# UWAGA: zatrzymuje backend na Scaleway (koniec zapisow) - tylko w oknie przelaczenia.
set -euo pipefail
SRC="ssh -o BatchMode=yes ubuntu@151.115.167.237"
DST="ssh -o BatchMode=yes -i $HOME/.ssh/serwer root@100.98.231.98"
TS=$(date +%F-%H%M)

echo "1/5 Stop backendu na Scaleway (koniec zapisow)"
$SRC 'sudo docker stop be-safe-backend-1'

echo "2/5 Stop backendu na serwerze domowym"
$DST 'podman stop besafe_backend_1 || true'

echo "3/5 Zrzut bazy ze Scaleway -> /srv/besafe/dumps/besafe-final-$TS.dump"
$SRC 'sudo docker exec be-safe-postgres-1 sh -c "pg_dump -U \$POSTGRES_USER -d \$POSTGRES_DB -Fc"' \
  | $DST "umask 077; cat > /srv/besafe/dumps/besafe-final-$TS.dump"

echo "4/5 Kopia biezacej bazy na serwerze domowym i odtworzenie zrzutu"
$DST "set -e; podman exec besafe_postgres_1 sh -c 'pg_dump -U \$POSTGRES_USER -d \$POSTGRES_DB -Fc' > /srv/besafe/dumps/besafe-pre-final-$TS.dump
podman exec besafe_postgres_1 sh -c 'dropdb -U \$POSTGRES_USER --maintenance-db=postgres \$POSTGRES_DB && createdb -U \$POSTGRES_USER --maintenance-db=postgres -T template0 -O \$POSTGRES_USER \$POSTGRES_DB'
podman exec -i besafe_postgres_1 sh -c 'pg_restore -U \$POSTGRES_USER -d \$POSTGRES_DB --no-owner --exit-on-error' < /srv/besafe/dumps/besafe-final-$TS.dump"

echo "   Uploady (wolumen be-safe_besafe_uploads)"
$SRC 'sudo tar -C /var/lib/docker/volumes/be-safe_besafe_uploads/_data -cf - .' | $DST 'tar -C /srv/besafe/data/uploads -xf -'

echo "5/5 Start backendu na serwerze domowym"
$DST 'podman start besafe_backend_1 && sleep 5 && curl -s -H "Host: besafe.org.pl" http://127.0.0.1/api/health'
echo
echo "Gotowe. Teraz przelacz DNS/tunel (docs/MIGRACJA_SERWER_DOMOWY.md, krok 3)."
