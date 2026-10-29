# Migracja be:Safe: Scaleway VPS -> serwer domowy ("serwer")

Stan na 2026-10-29 22:03 (Europe/Warsaw): **przelaczone**. besafe.org.pl i www to proxied CNAME na tunel "serwer";
backend na Scaleway (`be-safe-backend-1`) zatrzymany, reszta Scaleway bez zmian.
Stare rekordy (do wycofania): `A besafe.org.pl 151.115.167.237` i `A www.besafe.org.pl 151.115.167.237`, DNS only, TTL auto.

## Co gdzie

| | Stary (Scaleway) | Nowy (serwer domowy) |
|---|---|---|
| Host | `ubuntu@151.115.167.237` (scw-epic-dijkstra) | `root@100.98.231.98` (Tailscale) / 192.168.1.37 |
| Katalog | `/opt/be-safe` | `/srv/besafe` (`source/` = kopia `/opt/be-safe` bez `mobile/`, `node_modules`) |
| Web | `next dev` jako root, systemd `besafe-web-dev.service`, 0.0.0.0:8080 | kontener `besafe_web_1` (Next.js standalone, `next build`), **127.0.0.1:8310** |
| Backend | kontener `be-safe-backend-1`, 0.0.0.0:8081 (publicznie, Docker omija UFW) | `besafe_backend_1`, **127.0.0.1:8311** |
| Postgres | `be-safe-postgres-1`, 0.0.0.0:5433 (publicznie) | `besafe_postgres_1`, **bez portu na hoscie** (tylko sieć podmana) |
| Proxy / TLS | nginx + Let's Encrypt | Cloudflare Tunnel "serwer" -> Caddy `http://besafe.org.pl` (`deploy/serwer/Caddyfile.besafe`) |
| Dane | wolumeny `be-safe_besafe_postgres_data`, `be-safe_besafe_uploads` | `/srv/besafe/data/pgdata`, `/srv/besafe/data/uploads` |
| Pliki | `AlertMap.apk` w obrazie backendu, `/var/www/besafe-local-sync.tgz` | `/srv/besafe/files/AlertMap.apk` (mount ro), `/srv/besafe/static/besafe-local-sync.tgz` |

Sekrety: `/srv/besafe/.env` (chmod 600, ten sam co na Scaleway - ten sam JWT_SECRET, wiec tokeny aplikacji dzialaja dalej)
i `/srv/besafe/secrets/firebase-admin.json`. Nie trzymac w repo.

Serwer domowy jest za CGNAT - jedyna droga z internetu to Cloudflare Tunnel (jak plane.ooxo.pl i reszta).

Start / aktualizacja: `cd /srv/besafe && podman-compose up -d --build` (compose: `deploy/serwer/compose.yaml`).
Po restarcie maszyny kontenery wstaja przez `podman-restart.service` (restart: always).

## Test bez zmiany DNS

    curl -H "Host: besafe.org.pl" http://100.98.231.98/landing        # przez Tailscale
    curl --resolve besafe.org.pl:80:100.98.231.98 http://besafe.org.pl/api/health

Nigdy nie uruchamiac backendu jednoczesnie na obu serwerach - podwojne powiadomienia push (timery w `backend/src/index.js`).

## Kopie bazy

`deploy/serwer/besafe-backup.sh` -> `/usr/local/sbin/besafe-backup.sh`, uruchamiany przez `besafe-backup.timer`
codziennie o 03:30 (+ do 10 min). Pliki `/srv/besafe/backups/besafe-RRRR-MM-DD-GGMM.dump` (pg_dump -Fc, chmod 600),
retencja 14 dni, kontrola `pg_restore --list`. Recznie: `systemctl start besafe-backup.service`; log: `journalctl -u besafe-backup`.
Odtworzenie: jak w `resync-db.sh` (dropdb/createdb -T template0, `pg_restore --no-owner --exit-on-error`).
Kopie leza na tym samym dysku - warto dorzucic kopie poza serwer.

## Przelaczenie (wymaga zgody wlasciciela)

1. Okno ~10 min. Z laptopa: `deploy/serwer/resync-db.sh` (stop starego backendu, swiezy pg_dump, restore, uploady, start nowego backendu).
2. Sprawdz: `curl -H "Host: besafe.org.pl" http://100.98.231.98/api/health` -> `{"status":"ok"}`.
3. Cloudflare (konto hi@oioo.pl):
   - Tunel `serwer` (df565e6a-b518-4a74-896d-21f1cc678b09) -> Public hostnames: dodaj `besafe.org.pl` i `www.besafe.org.pl`,
     service `http://localhost:80`, HTTP Host Header = ta sama nazwa (jak pozostale wpisy).
   - DNS strefy besafe.org.pl: rekordy A `besafe.org.pl` i `www` (151.115.167.237, DNS only) zamien na
     `CNAME df565e6a-b518-4a74-896d-21f1cc678b09.cfargotunnel.com`, **Proxied**.
   - SSL/TLS -> Edge Certificates: wlacz **Always Use HTTPS** (Caddy serwuje tylko HTTP z tunelu). Certyfikat brzegowy (Universal, LE) jest juz aktywny.
4. Weryfikacja: `curl -sI https://besafe.org.pl` (naglowek `server: cloudflare`), strony, `/api/health`, logowanie w aplikacji, socket.io.
5. Na Scaleway zostaje wszystko jak bylo (zatrzymany tylko backend). Po tygodniu spokoju, za zgoda: wylaczyc `besafe-web-dev.service`,
   kontenery be-safe-*, blok nginx `besafe`; certbot dla besafe.org.pl przestanie sie odnawiac (to OK). Kontenerow mg-* NIE ruszac.

## Wycofanie

1. Cloudflare DNS: przywroc `A besafe.org.pl 151.115.167.237` i `A www.besafe.org.pl 151.115.167.237`, **DNS only**, TTL auto.
2. Scaleway: `sudo docker start be-safe-backend-1` (web dev dziala caly czas).
3. Serwer domowy: `podman stop besafe_backend_1`.
4. Jesli w miedzyczasie byly zapisy na nowej bazie, zrob odwrotny pg_dump (serwer domowy -> Scaleway) przed startem starego backendu.
5. Caddy: kopie `/etc/caddy/Caddyfile.bak-besafe-*`; tunel - usun dwa wpisy public hostname.
