extends SceneTree
const Practice = preload("res://src/state/practice_dungeon.gd")
func _init() -> void:
	var lines: Array[String] = ["# Practice role trials", "", "Controlled free-build fixtures using the actual local encounter controller. These are deterministic counterfactuals, not player or spending-cohort evidence.", "", "| Attack | Hero HP | Prepared stew | Role | Won | Turns | Remaining party HP | Blocked by hero | Healed by hero |", "|---:|---:|---|---|---|---:|---:|---:|---:|"]
	for stats in [[6, 36], [7, 40], [8, 44], [9, 48], [10, 52]]:
		for prepared in [false, true]:
			for role in Practice.Catalog.ROLES:
				var run := Practice.new()
				run.selected_role = role
				run.start(stats[0], stats[1], prepared)
				run.advance(60.0)
				lines.append("| %d | %d | %s | %s | %s | %d | %d | %d | %d |" % [stats[0], stats[1], "yes" if prepared else "no", role, "yes" if run.recap["won"] else "no", run.turn, run.hp, run.contributions["hero_block"], run.contributions["hero_heal"]])
	var file := FileAccess.open("res://docs/economy/practice_role_trials.md", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("\n".join(lines))
	quit()
