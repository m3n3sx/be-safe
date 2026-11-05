# be:Safe alerts, map and QR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship inbox-backed SOS and family signals, collision sheets that keep real coordinates, and confirmed QR/code joins without self-promotion to parent.

**Architecture:** Pure rules live in `backend/src/domain` and are copied for the web bundle. Routes, FCM and sockets apply those rules. Mobile and web only render the server decision.

**Tech Stack:** Node.js tests, Express, PostgreSQL, Flutter, Next.js.

## Global Constraints

- No production access, no real SOS, no sessions for existing users.
- `fcmAccepted` is provider acceptance, never delivery or read.
- Visible SOS copy is be:Safe and does not claim to bypass mute, Focus or a closed browser tab.
- Free iOS sideload cannot promise background push. Do not add a paid Apple capability.
- Invite TTL is 7 days. Legacy codes get 30 days from the migration. Invalid and expired codes share one error.
- Self-join cannot set `parent` or `guardian`.
- Web Push is out of scope.
- Migrate the database before deploying this API.

---

### Task 1: Domain rules

**Files:**
- Create: `backend/src/domain/safetyContracts.js`
- Create: `backend/src/domain/markerCollision.js`
- Test: `backend/test/safetyContracts.test.js`

- [x] **Step 1: Write the failing test** for SOS kind, sender copy, ack versus dismiss, invites, tokens and collision.
- [x] **Step 2: Run** `node --test test/safetyContracts.test.js` and see the missing module fail.
- [x] **Step 3: Implement** the pure functions.
- [x] **Step 4: Run** the same command and see 18 assertions pass.

### Task 2: API, inbox, SOS fan-out, tokens, invites

**Files:**
- Modify: `backend/src/services/fcm.js`
- Modify: `backend/src/routes/alerts.js`
- Modify: `backend/src/routes/family.js`
- Modify: `backend/src/routes/notifications.js`
- Modify: `backend/src/routes/users.js`
- Modify: `backend/src/index.js`
- Create: `db/migrations/2026-11-05_alerts_inbox_invites.sql`

- [x] **Step 1: Apply the tested decisions** in notify, SOS context, ping copy, join preview, token upsert and passive location emit.
- [x] **Step 2: Syntax-check** with `node --check` on each touched file.

### Task 3: Web and mobile presentation

**Files:**
- Modify: `web/src/components/map/MapView.tsx`
- Modify: `web/src/components/map/PlacesMap.tsx`
- Modify: `web/src/contexts/NotificationsContext.tsx`
- Create: `web/src/components/notifications/SignalLayer.tsx`
- Create: `web/src/components/family/JoinGroup.tsx`
- Modify: `mobile/lib/screens/map/map_screen.dart`
- Modify: `mobile/lib/services/socket_service.dart`
- Modify: `mobile/lib/screens/family/family_sos_screen.dart`
- Create: `mobile/lib/screens/family/join_group_screen.dart`

- [x] **Step 1: Render collision sheets, SOS latch, sender copy and join preview** on both clients.
- [ ] **Step 2: Device pass** for camera, notification permission, background FCM and free iOS sideload. Not run here.

### Task 4: Verification before merge

- [x] **Step 1:** `node --test test/safetyContracts.test.js test/aeds.test.js` from `backend/`.
- [ ] **Step 2:** `flutter test` when a Flutter SDK is present. It is not in this environment.
- [ ] **Step 3:** Production migrate and deploy only outside this VM, after review.
