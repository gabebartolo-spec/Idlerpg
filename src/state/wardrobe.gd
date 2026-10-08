extends RefCounted

const Catalog = preload("res://src/data/appearance_catalog.gd")
const VERSION := 1
var owned: Dictionary = {}
var equipped: Dictionary = {}

func acquire_item(item: String) -> bool:
	var id := Catalog.for_item(item)
	return grant(id, "gear:" + item) if not id.is_empty() else false

func grant(id: String, provenance: String) -> bool:
	if not Catalog.LOOKS.has(id) or provenance.strip_edges().is_empty():
		return false
	provenance = provenance.strip_edges().left(128)
	var first := not owned.has(id)
	var sources: Array = owned.get(id, {}).get("sources", []).duplicate()
	if provenance not in sources and sources.size() < 16:
		sources.append(provenance)
		sources.sort()
		owned[id] = {"sources": sources}
	return first

func wear(id: String) -> bool:
	if not owned.has(id) or not Catalog.LOOKS.has(id):
		return false
	equipped[Catalog.LOOKS[id]["slot"]] = id
	return true

func clear(slot: String) -> void:
	if slot in Catalog.SLOTS:
		equipped.erase(slot)

func visible_item(slot: String, functional_item: String) -> String:
	var id := str(equipped.get(slot, ""))
	if owned.has(id) and Catalog.LOOKS.has(id) and Catalog.LOOKS[id]["slot"] == slot:
		return str(Catalog.LOOKS[id]["item"])
	return functional_item

# Local merge fixtures support future restoration without replacing earned
# ownership or the player's chosen outfit. This is not a billing verifier.
func merge_ownership(raw: Variant) -> void:
	if not raw is Dictionary:
		return
	for id in raw:
		if not Catalog.LOOKS.has(str(id)) or not raw[id] is Dictionary:
			continue
		var sources: Variant = raw[id].get("sources", [])
		if not sources is Array:
			continue
		for source in sources:
			if source is String:
				grant(str(id), source)

func seed_legacy(inventory: Dictionary, discoveries: Dictionary) -> void:
	for entry in Catalog.LOOKS.values():
		var item: String = entry["item"]
		if int(inventory.get(item, 0)) > 0 or bool(discoveries.get(item, false)):
			acquire_item(item)

func to_save_dict() -> Dictionary:
	return {"version": VERSION, "owned": owned.duplicate(true), "equipped": equipped.duplicate()}

func load_save_dict(raw: Variant) -> void:
	owned.clear()
	equipped.clear()
	if not raw is Dictionary or int(raw.get("version", VERSION)) != VERSION:
		return
	merge_ownership(raw.get("owned", {}))
	var selected: Variant = raw.get("equipped", {})
	if not selected is Dictionary:
		return
	for slot in selected:
		var id := str(selected[slot])
		if owned.has(id) and Catalog.LOOKS.has(id) and Catalog.LOOKS[id]["slot"] == str(slot):
			wear(id)
