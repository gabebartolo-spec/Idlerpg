extends SceneTree

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)

	var base_attack: int = sim.effective_attack()
	var base_hp: int = sim.effective_max_hp()

	_check(not sim.equip_gear("Iron Sword"), "cannot equip gear that is not owned")
	_check(sim.add_gear("Iron Sword"), "known gear can be added")
	_check(sim.equip_gear("Iron Sword"), "owned weapon can be equipped")
	_check(sim.equipped_item("weapon") == "Iron Sword", "weapon slot records equipped item")
	_check(sim.effective_attack() == base_attack + 2, "equipped weapon changes combat attack")
	_check(sim.unequip_gear("Iron Sword"), "equipped gear can be deliberately unequipped")
	_check(sim.equipped_item("weapon").is_empty(), "unequip clears the slot")
	_check(sim.effective_attack() == base_attack, "unequip restores base combat attack")
	_check(sim.equip_gear("Iron Sword"), "gear can be equipped again after unequipping")

	_check(sim.add_gear("Knight Mail"), "armour can be added")
	_check(sim.equip_gear("Knight Mail"), "owned armour can be equipped")
	_check(sim.equipped_item("chest") == "Knight Mail", "chest slot records equipped armour")
	_check(sim.effective_max_hp() == base_hp + 9, "equipped armour changes max health")

	for item_name in ["Rough Trousers", "Hide Gloves", "Trail Boots", "Copper Ring"]:
		_check(sim.add_gear(item_name), "%s can be owned" % item_name)
		_check(sim.equip_gear(item_name), "%s can be equipped in its slot" % item_name)
		_check(sim.equipped_item(GearCatalogScript.slot(item_name)) == item_name, "%s lands in the correct slot" % item_name)

	_check(not sim.can_dispose_gear("Iron Sword"), "last equipped copy cannot be disposed")
	_check(sim.add_gear("Iron Sword"), "duplicate equipped gear can be owned")
	_check(sim.can_dispose_gear("Iron Sword"), "duplicate beyond equipped copy can be disposed")

	var gold_before: int = sim.gold
	var sold: Dictionary = sim.sell_gear("Iron Sword")
	_check(bool(sold.get("ok", false)), "duplicate gear can be sold")
	_check(sim.gold == gold_before + GearCatalogScript.sell_value("Iron Sword"), "selling grants rarity-based gold")
	_check(sim.gear_count("Iron Sword") == 1, "selling removes exactly one copy")
	_check(sim.equipped_item("weapon") == "Iron Sword", "selling duplicate never unequips kept copy")

	_check(sim.add_gear("Knight Mail"), "second armour copy can be added")
	var salvaged: Dictionary = sim.salvage_gear("Knight Mail")
	_check(bool(salvaged.get("ok", false)), "duplicate gear can be salvaged")
	_check(int(salvaged.get("tokens", 0)) == GearCatalogScript.salvage_tokens("Knight Mail"), "salvage returns rarity-based existing gacha tokens")
	_check(sim.gear_count("Knight Mail") == 1, "salvage removes exactly one copy")
	_check(sim.equipped_item("chest") == "Knight Mail", "salvaging duplicate never unequips kept copy")

	var saved: Dictionary = sim.to_save_dict()
	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(saved)
	_check(restored.equipped_item("weapon") == "Iron Sword", "equipped weapon survives save/load")
	_check(restored.equipped_item("chest") == "Knight Mail", "equipped armour survives save/load")
	_check(restored.equipped_item("legs") == "Rough Trousers", "new core equipment slots survive save/load")
	_check(restored.effective_attack() == sim.effective_attack(), "restored gear preserves effective attack")
	_check(restored.effective_max_hp() == sim.effective_max_hp(), "restored gear preserves effective health")

	var compare := GearCatalogScript.comparison("Crownblade", "Iron Sword")
	_check(compare.contains("ATK"), "comparison exposes relevant stat change without a stat dump")

	var quest_sim: Node = AdventurerSimScript.new()
	root.add_child(quest_sim)
	var elapsed := 0.0
	while quest_sim.quest_cycles_completed < 1 and elapsed < 180.0:
		quest_sim.advance(0.1)
		elapsed += 0.1

	_check(int(quest_sim.gear_inventory.get("Goblin Cleaver", 0)) == 1, "first quest guarantees a world-drop weapon")
	_check(int(quest_sim.gear_inventory.get("Wolfskin Hood", 0)) == 1, "first quest guarantees a world-drop armour piece")
	_check(quest_sim.equipped_item("weapon").is_empty(), "world drops never auto-equip themselves")

	print("Gear tests complete: %d failure(s)" % failures)
	quit(failures)
