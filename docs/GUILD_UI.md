# Playable guild and raid sheets

Open **More → Guild**. Normal tabs are Guild, Raid and Supplies. Account/recovery/connection controls live under Account; role explanations are optional Role details. No long recap or architecture copy is forced into a short visit.

For a local developer playtest, start the service as documented in ONLINE_SERVICE.md, then enter `http://127.0.0.1:8765` in Connection. A participant build should instead have its reachable HTTPS URL set in `online/service_url` or supplied with the invitation. Public hosting has not been deployed. Loopback is only for the same desktop, not another phone.

Create an online adventurer, copy the one-time recovery details privately and acknowledge saving them. Recovering uses the account ID/key and revokes older sessions. No email account or password is involved. Create/join a guild using its invite, inspect the shared roster, then prepare a role/build in Raid. Supplies offers server-clock outings and earned build purchases. Returning checks the shared result automatically; a personal chest opens into its actual reward and a direct Wear action.

The Warden lantern is restored from authenticated server ownership into the local wardrobe for offline appearance use. It never changes combat stats; local appearance copies are not uploaded as online entitlements. Existing solo progress/currency stays intact. Supply currency remains a separate trusted guild economy at this prototype stage; full regional online progression is still incomplete.

## Device state and interruption

`user://idle_rpg_online.json` is separate from the normal solo save. It stores the endpoint, short-lived bearer session and one pending action's account/path/body/key. Recovery keys are never persisted. Writes use temporary/backup companions; malformed optional retries are discarded and newer formats are refused. Tokens use app-private storage on Android and inherited user-folder ACLs on desktop. This is a local session file, **not an encrypted credential vault**. No real-money or paid currency feature depends on it.

Before a mutation, save its action key/body. After uncertain network failure keep it across restart; Retry sends that same action. Definitive rejection permits correction. Recovery preserves a retry only for the matching account. Sign-out removes all local credential companions; if offline, remote revocation is unconfirmed and the old session expires normally. Connection changes explicitly clear the old local session. Unknown newer session files are not silently overwritten by ordinary writes.

Solo play continues without a network service. Online screens show Offline and leave uncertain actions retryable. Refresh requests current server state; displayed readiness is server-clock based. No uploaded clock, wallet, equipment stats or result can settle a reward.

## Evidence and remaining gates

The live screen test drives actual create/join/role/open/Wear controls across three independent accounts against a listening service. It verifies recovery-key omission from disk, persisted sessions, restart/reward restore, interrupted-commit replay, a real connection refusal/reconnect and isolation from solo gold. The existing lower-level three-client raid and 20 HTTP/rule checks remain. A separate offline suite verifies session companion recovery, malformed data, newer-file protection and complete credential cleanup.

Actual 405×720 captures show roster, preparation, waiting chest, reveal and owned/equipped lantern. The disposable capture/test server accelerates its own time; production still uses a 24-hour raid. These are automated desktop checks, not physical phone usability, participant enjoyment or reachable-hosting evidence. Android delivery, seven-day content/progression, participant pack and public deployment remain active goal work.
