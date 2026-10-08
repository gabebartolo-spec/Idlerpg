# Earned trail chest loop

Trail completion now secures its final gold and any unowned route appearance in a saved chest. Cache gold still enters the wallet along the trail and is retained on failure/abort. Opening a chest pays its final contents once. The total route rewards and timing are unchanged; the completion payout moves to the opening action. Existing saves retain their previously banked gold and owned appearances, with no invented retroactive chest.

The reveal uses an original scalable vector chest, an opening lift and restrained rays, actual gold totals, matching earned-look icons and a direct Wear action. Reduced motion reveals instantly. Independent sound preferences still apply. Closing during a reveal cannot repay it: the receipt is consumed and ownership/gold settle before an event can trigger a save. The ordinary atomic save contains wallet, inbox and appearance ownership together.

Chests appear under More → Rewards, in expedition Results, and as an action in the return report when ready. New completed trails are explicit player selections; there is no additional login task or attendance timer. Contents are fixed when earned and saved. This first loop is deterministic, not marketed as a random rare-item draw; randomized useful loot and deeper pursuits remain future work toward the full playtest target.

`reward_chests` stores a monotonically increasing expedition-run cursor, pending receipts and the last opened receipt. Repeated completion issuance and repeated opens are idempotent. An appearance pending in one receipt is not promised again in another. Multiple unopened chests survive subsequent adventures and reload. Only explicit trail completions append receipts; normal autonomous quest cycles do not grow this inbox. Save format 20 migrates all previous formats while preserving prior progress.

These are local reward receipts, not trusted multiplayer entitlements. Online rewards must be issued/claimed transactionally by the future server service and reconciled by the client. See [full playtest target](PLAYTEST_TARGET.md).

Verification covers fixed contents after reload, completion/claim replay, event-time checkpoints, old-save preservation, direct wear, malformed optional data, portrait action placement and reduced motion. Existing watched/offline tests now cover unopened receipts and subsequent claims. Actual phone feel/desirability remain unproven until playtested.
