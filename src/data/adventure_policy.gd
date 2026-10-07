extends RefCounted
const DEFAULT := "push"
const POLICIES := {
	"safe": {"name": "Safe farming", "description": "Repeat Greenway goblins and wolves. Return after a fight below 40% health; skip Briarfen rewards and bosses.", "threshold": 0.4},
	"push": {"name": "Push progression", "description": "Clear Briarfen and challenge Old Thornback. More rewards and risk; after a boss loss, wait for a level or build change.", "threshold": 0.0},
	"hunt": {"name": "Targeted hunt", "description": "Pursue the chosen Boss and hunts item. Briarhook runs skip the boss; Carapace runs challenge it. Return after a fight below 25% health.", "threshold": 0.25}
}
static func valid(id: String) -> bool:
	return POLICIES.has(id)
static func reason(id: String, target: String, opening: bool) -> String:
	if opening:
		return "Finish the opening errand first; policy changes take effect next outing."
	match id:
		"safe": return "Greenway farming: avoid the growing Briarfen boss."
		"hunt":
			if target == "briarhook":
				return "Briarlings for Briarhook; return before the boss."
			if target == "carapace":
				return "Old Thornback for Carapace; prepare after a loss."
			return "No hunt selected; farm Greenway until you choose one."
	return "Briarfen progression; challenge the boss when the build is ready."
