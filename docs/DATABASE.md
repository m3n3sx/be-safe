# AlertMap — Schemat bazy danych

## Diagram relacji

```
users ──1:N── alerts
users ──1:N── alert_votes
users ──N:M── family_groups (przez family_members)
family_groups ──1:N── geofences
users ──1:N── location_history
alerts ──1:N── alert_notifications ──N:1── users
```

## Tabele

### `users`
Konta użytkowników (rodzice i dzieci).
- `last_location` — ostatnia znana pozycja (GEOGRAPHY POINT), indeks GIST dla zapytań proximity
- `alert_radius_m` — promień w metrach, w którym użytkownik chce dostawać alerty
- `reputation_score` — spada przy fałszywych zgłoszeniach
- `is_child` — flaga konta dziecka

### `alerts`
Zgłoszenia zagrożeń na mapie.
- `category` — ENUM z 18 kategoriami (13 ogólnych + 5 dla dzieci)
- `location` — punkt na mapie z indeksem GIST
- `radius_m` — promień zagrożenia
- `status` — active / expired / hidden / removed
- `expires_at` — automatyczne wygasanie

### `alert_votes`
Potwierdzenia i odrzucenia zgłoszeń przez community.
- UNIQUE(alert_id, user_id) — jeden głos na użytkownika
- Trigger automatycznie ukrywa alert po >3 odrzuceniach

### `alert_notifications`
Deduplikacja powiadomień — zapobiega wielokrotnemu wysyłaniu tego samego alertu.
- UNIQUE(alert_id, user_id)

### `family_groups`
Grupy rodzinne tworzone przez rodzica.
- `invite_code` — 8-znakowy kod do dołączenia

### `family_members`
Członkowie grup rodzinnych.
- `role` — parent / child
- `tracking_enabled` — rodzic może włączyć/wyłączyć śledzenie

### `geofences`
Bezpieczne strefy ustawiane przez rodzica.
- `center` + `radius_m` — okrąg na mapie
- Alert gdy dziecko opuści strefę

### `location_history`
Historia lokalizacji (głównie dzieci).
- Indeks na (user_id, recorded_at DESC) dla szybkiego pobierania ostatnich pozycji

## Kluczowe funkcje SQL

- `find_alerts_nearby(lat, lng, radius_m)` — zwraca aktywne alerty w promieniu od punktu
- `check_alert_denies()` — trigger auto-ukrywający alerty z >3 odrzuceniami
- `expire_old_alerts()` — do wywołania przez cron, wygasza przeterminowane alerty
