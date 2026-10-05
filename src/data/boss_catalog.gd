class_name BossCatalog
extends RefCounted

# Old Thornback's numbers. Each time it is beaten it returns one rank stronger, so it
# stays a real fight however far the adventurer has levelled.
# Rules and reasoning: docs/BOSS_AND_WORLD_ITEMS.md.

const NAME := "Old Thornback"
const BURST_NAME := "Thorn Burst"

const BASE_HP := 60
const HP_PER_RANK := 25
const BASE_DAMAGE := 4
const DAMAGE_PER_RANK := 1
const ATTACK_INTERVAL := 1.55
# Every third attack is the burst. The attack before it is the warning.
const BURST_EVERY := 3
const BURST_MULTIPLIER := 3
const BASE_XP := 40
const XP_PER_RANK := 5

static func max_hp(rank: int) -> int:
	return BASE_HP + HP_PER_RANK * maxi(0, rank)

static func damage(rank: int) -> int:
	return BASE_DAMAGE + DAMAGE_PER_RANK * maxi(0, rank)

static func burst_damage(rank: int) -> int:
	return damage(rank) * BURST_MULTIPLIER

static func xp(rank: int) -> int:
	return BASE_XP + XP_PER_RANK * maxi(0, rank)

# True when the attack with this number (counting from 1) is the burst.
static func is_burst(attack_number: int) -> bool:
	return attack_number > 0 and attack_number % BURST_EVERY == 0

# True when `attacks_made` attacks have landed and the next one is the burst.
static func is_winding_up(attacks_made: int) -> bool:
	return is_burst(attacks_made + 1)
