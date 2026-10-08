# Shared playtest foundation

This provides a runnable account/economy/guild service, asynchronous three-role raid and playable **More → Guild** sheets. Three automated accounts demonstrate persistence, actual screen controls and raid settlement, not recruited people, enjoyment or participant access. Rules: [ASYNC_RAID.md](ASYNC_RAID.md); player/client integration: [GUILD_UI.md](GUILD_UI.md).

## Architecture decision

Use Python 3.14, FastAPI/Uvicorn and SQLite on **one host with a durable local disk** for the ten-player prototype. Each mutation takes an immediate database transaction; grants, debits and idempotent responses commit together. A lost HTTP response can be retried using the same action key. Separate processes/devices never upload balances or stats. The database schema refuses unknown newer versions.

| Option | Suitability for this study | Tradeoff |
|---|---|---|
| Portable HTTP service + SQLite | Chosen: small roster, transactional rewards, easy local verification and recovery | One host; durable disk, TLS, backups and operation required |
| Same API + managed Postgres | Sensible deployment upgrade if multiple service instances are needed | Requires a database provider, schema adapter and provisioning |
| Hosted backend with managed identity | Can reduce identity/hosting operations | Provider configuration, authorization policies and reconciliation still need implementation |
| Local saves or peer-hosted guilds | Useful only for solo progress | Cannot provide durable shared authority or trusted rewards |

FastAPI is served through an ASGI server ([deployment documentation](https://fastapi.tiangolo.com/deployment/manually/)). SQLite transactions are explicit and connections close after every action ([Python sqlite3 documentation](https://docs.python.org/3/library/sqlite3.html)). This choice does not provision a hosting account, spend money or require Vercel.

## Accounts and recovery

`POST /v1/accounts` accepts a short display name. It returns an account ID, bearer session and **one-time displayed recovery key**. Keys and sessions have 256 bits of generated entropy; only SHA-256 hashes are stored. These are machine-generated secrets, not user-chosen passwords. A future password-login feature must use a password hash, not this token scheme.

Keep the account ID and recovery key privately. Recovery accepts both, revokes all prior sessions and issues a new seven-day session. A stolen or lost recovery key needs an explicit rotation/support policy before participant deployment; there is currently no email identity or administrator recovery. Recovery attempts and account creation are limited per direct connecting address. Authenticated action attempts, including failed invite guesses, are limited per account. The deployment proxy also needs request size/rate controls; no forwarded-address header is trusted by this app.

The Godot client uses a separate device-local session file and requires HTTPS except exact loopback development URLs. Recovery display/copy, sign-out and persisted retry/reconnect handling are implemented. Recovery keys are never saved; bearer sessions follow app-private/user-folder protection, not an encrypted vault. Credentials must never enter the solo gameplay save, screenshots, CI outputs or repository.

## Trusted progress and legacy saves

Online state starts separately with zero supply gold and the `trail` build entitlement. The initial online rules are a deliberately small **supply outing**: five server-clock minutes, one outstanding outing, a fixed 20-gold chest. The server records ready time, contents and rules version at issue. Opening commits the grant once even with simultaneous device requests or fresh retry keys. Absence yields the one earned chest; there is no unbounded chain of automatic completions. `thornward` and `keeper` entitlement purchases cost 40 and 60 supply gold and cannot overspend a shared balance. These are initial entitlement records; the complete regional build/loadout and raid mechanics are still to come.

This outing is not a port of the existing single-player expedition simulator. No regional victory, legacy gear or paid currency is inferred from it. Local save version 20, existing items, wardrobe ownership and offline simulation remain untouched. Legacy progress remains available in solo play; migration of cosmetic provenance and any fair online starting allowance require an explicit policy before linking the main UI. Unverifiable local attack/HP/gold are never accepted into the online economy.

Every successful mutation requires an `Idempotency-Key` of 8–80 letters, digits, underscores or hyphens. Retain it with the original request through interruption. Reusing it for a different path/body fails with 409. A replay returns the originally committed response, which can contain an older profile: refresh `/v1/profile` afterward. Errors do not consume the key. A chest is independently protected by its unique ledger event, so changing the key cannot grant it twice.

## Real guild foundation

Create a named guild, share its opaque invite, join a capped roster of ten, inspect the shared roster and leave. Membership is one guild per account. The first remaining member in join-time/account-ID order inherits leadership when the leader leaves; the last departure deletes the guild. Concurrent joins cannot overfill the roster. Supply gold/entitlements survive leaving. Roster members see display names and public account IDs, not another member's wallet, recovery key or sessions. Invite sharing is available to members.

No free-text chat, friends, kick controls, shared project or moderation console is claimed. Names are restricted to short ASCII text for the initial prototype; this is input validation, not moderation. Participant deployment still needs a supported name/report/block/moderation and data-retention policy.

## Run locally

From the repository root (Windows PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r server/requirements.txt
.\.venv\Scripts\python.exe -m uvicorn server.app:create_app --factory --host 127.0.0.1 --port 8765 --workers 1
```

On macOS/Linux, use `.venv/bin/python` instead. Default state is `server/data/playtest.sqlite3` (ignored by Git). Set `IDLE_DATABASE` to an absolute durable path for deployment. `/health` confirms the service and rules version. OpenAPI is available at `/docs` for development; do not paste real secrets into shared captures.

Use a maintained TLS reverse proxy, a persistent single-host volume, request-body limits, backups and restricted operational access before exposing the service. Do not put this SQLite database on ephemeral serverless storage or a shared network filesystem. Do not launch multiple horizontally scaled hosts against separate copies. Public hosting has not been selected or deployed; loopback verification does not establish participant access.

Back up using SQLite's backup API or a database-consistent snapshot, restore to a separate path and verify before switching `IDLE_DATABASE`. Stop writes before switching/replacing the live database. Preserve a pre-upgrade backup and matching code/rules version; never run an older binary over an unknown newer database. Schema 2 adds raid tables transactionally to version 1 without replacing progress.

## Verification

```powershell
.\.venv\Scripts\python.exe -m unittest server.test_service server.test_raids -v
.\.venv\Scripts\python.exe -m server.verify_client --godot C:\path\to\godot.exe --project C:\path\to\isolated-project
```

The ten service scenarios use real HTTP listeners and temporary databases: privacy, credential hashing/recovery/revocation/expiry, failed-attempt limits, forged payload rejection, early/foreign chest denial, restart and 30-day absence, concurrent chest claims, concurrent device spending, durable three-account membership/leadership, concurrent final roster slot and newer-schema refusal. A separate Godot suite creates three independent clients against one real service and checks matching rosters and private profiles. Tests create disposable accounts; they do not read or modify normal local gameplay saves. CI runs both plus the existing Godot suites.

Next: Android delivery, reachable deployment, multi-day regional pursuits/progression and the participant pack. The played guild/raid flow needs physical phone verification and participant evidence before claiming enjoyment or release readiness.
