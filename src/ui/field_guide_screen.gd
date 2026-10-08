extends "res://src/ui/sheet.gd"

# Deliberately reached through the journal, rather than the play navigation.
const Trails = preload("res://src/data/expedition_catalog.gd")
const Practice = preload("res://src/data/practice_catalog.gd")
var sim: Node
var chapter: String = "trails"
var tabs: Dictionary
var list: Control
var away_notes: String = ""

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Field guide", 0.22)
	subtitle_label.text = "Stories and how things work"
	tabs = add_tabs(column, [["trails", "Trails"], ["practice", "Practice"], ["fishing", "Fishing"], ["away", "Away"]], func(id: String) -> void:
		chapter = id
		refresh()
		list.scroll_to(0.0))
	list = add_list(column)
	refresh()

func words(text: String, heading: bool = false) -> void:
	var label := Style.label(text, 28 if heading else 24, Style.ACCENT if heading else Style.TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(label)

func refresh() -> void:
	mark_tabs(tabs, chapter)
	clear_list(list)
	match chapter:
		"away":
			words("Your latest return", true)
			words(away_notes if not away_notes.is_empty() else "Your next return report will appear here.")
		"trails":
			if not sim.expedition.recap.is_empty():
				var result: Dictionary = sim.expedition.recap
				words("Your last journey", true)
				words("%s · %d/5 stages · %d gold kept" % [Trails.ROUTES[result["route"]]["name"], result["nodes"], result["gold"]])
				for line in result.get("log", []):
					words(str(line))
			words("Trail notes", true)
			words("Current adventure: " + sim.current_quest_text() + "\n" + sim.policy_reason())
			words("Expeditions last 5, 15 or 30 minutes, with five encounters each. They start after your current outing. Attack, health and thorn protection are fixed when you leave. Lantern Hollow opens after Gentle Greenway; Keeper's Rise opens after Hollow and Causeway.")
			for route in Trails.ROUTES.values():
				words(route["name"], true)
				words(route["clue"])
				words("First safe return: %d final gold. Later returns: %d final gold. Cache gold is kept even if you leave early; the trail screen includes it in the advertised total." % [route["first_gold"], route["repeat_gold"]])
				if route.has("look"):
					words("First clear permanently unlocks " + str(preload("res://src/data/appearance_catalog.gd").LOOKS[route["look"]]["name"]) + " in Wardrobe. No combat stats; no appearance is equipped automatically.")
				for node in route["nodes"]:
					var entry: Dictionary = Trails.ENCOUNTERS[node]
					words(entry["name"] + ": " + entry["text"])
			words("Bridge: 10 damage. Wolves: at least 4 damage, reduced by attack. Thorn guardian: 24 damage, or 12 with Thornward. One prepared stew restores 12 health when it fits; unused stew stays in your pack.")
			words("Lantern moths: max(6, 24 − attack) damage. Root keeper: max(14, 38 − attack). Elder keeper: max(22, 66 − attack). Thornward halves keeper and tunnel damage. Briar tunnel: 16 damage. Mooncaps restore 8 health. Lamplighter cache: 12 gold.")
		"practice":
			words("Meet your allies", true)
			words("Bran and Iris are NPC allies. Bran has 36 health, deals 3 damage and blocks 2 each turn. Iris has 24 health, deals 2 damage and heals 3 every third turn. Your combined health forms one party pool.")
			for role in Practice.ROLES.values():
				words(role["name"] + ": " + role["description"])
			words("Three rooms", true)
			for room in Practice.ROOMS:
				words("%s: %d health, %d damage." % [room["enemy"], room["hp"], room["damage"]])
			words("The Sentinel strikes twice as hard every fourth turn. Roles and your build are fixed at entry. One stew can heal 12 party health. Your first victory awards 25 gold; retries are free and don't repeat that reward.")
			if not sim.practice.recap.is_empty():
				words("Last practice: contributions", true)
				var counts: Dictionary = sim.practice.recap.get("contributions", {})
				for key in ["hero_damage", "bran_damage", "iris_damage", "hero_block", "bran_block", "hero_heal", "iris_heal", "stew_heal"]:
					words("%s: %d" % [str(key).replace("_", " ").capitalize(), counts.get(key, 0)])
				for line in sim.practice.recap.get("log", []):
					words(str(line))
		"fishing":
			words("A quiet moment by the pond", true)
			words("Fishing begins after your current outing. A catch arrives every 15 seconds, even while you're away. Perch, carp and herbs cycle in that order; fishing never interrupts your passive gold income.")
			words("Reeling is optional", true)
			words("Tap once per cast when the bar turns green, between 7 and 9 seconds. Ten successful reels add one bonus perch. A missed tap never loses your passive catch. Leaving preserves a partial cast.")
			words("Pond Stew", true)
			words("Prepare one stew from 2 perch, 1 carp and 1 herb. It restores 12 health during a practice or expedition when all 12 points fit. Each journey uses at most one; unused stew stays in your pack.")
