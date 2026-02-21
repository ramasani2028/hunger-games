extends Resource
class_name Inventory

# =========================
# CONFIGURATION
# =========================
@export var max_capacity : int = 5

# Dictionary → { item_type : count }
var items : Dictionary = {}

# =========================
# SIGNALS
# =========================
signal inventory_updated
signal inventory_full
signal item_added(item_type)
signal item_removed(item_type)

# =========================
# INITIALIZATION
# =========================
func _init(capacity := 5):
	max_capacity = capacity
	items.clear()

# =========================
# ITEM MANAGEMENT
# =========================
func add_item(item_type : String) -> bool:
	if is_full():
		emit_signal("inventory_full")
		return false
	
	if not items.has(item_type):
		items[item_type] = 0
	
	items[item_type] += 1
	
	emit_signal("item_added", item_type)
	emit_signal("inventory_updated")
	return true


func remove_item(item_type : String) -> bool:
	if not items.has(item_type):
		return false
	
	items[item_type] -= 1
	
	if items[item_type] <= 0:
		items.erase(item_type)
	
	emit_signal("item_removed", item_type)
	emit_signal("inventory_updated")
	return true


func steal_random_item() -> String:
	if items.is_empty():
		return ""
	
	var keys = items.keys()
	var random_item = keys[randi() % keys.size()]
	remove_item(random_item)
	return random_item

# =========================
# CAPACITY LOGIC
# =========================
func is_full() -> bool:
	return get_total_items() >= max_capacity


func get_total_items() -> int:
	var total := 0
	for count in items.values():
		total += count
	return total

# =========================
# QUERY FUNCTIONS
# =========================
func has_item(item_type : String) -> bool:
	return items.has(item_type)


func get_item_count(item_type : String) -> int:
	if not items.has(item_type):
		return 0
	return items[item_type]


func get_all_items() -> Dictionary:
	return items.duplicate(true)


func clear():
	items.clear()
	emit_signal("inventory_updated")

# =========================
# ROLE CALCULATION
# =========================
func get_dominant_item_type() -> String:
	if items.is_empty():
		return ""
	
	var dominant_type := ""
	var max_count := -1
	
	for item_type in items.keys():
		if items[item_type] > max_count:
			max_count = items[item_type]
			dominant_type = item_type
	
	return dominant_type


func calculate_role() -> String:
	var dominant = get_dominant_item_type()
	
	match dominant:
		"Wood":
			return "Carpenter"
		"Metal":
			return "Mechanic"
		"Wire":
			return "Electrician"
		"Rope":
			return "Rescuer"
		"Stone":
			return "Engineer"
		_:
			return "Neutral"

# =========================
# REQUIRED ITEM CHECK
# =========================
func has_required_items(required_items : Array) -> bool:
	for req in required_items:
		if not items.has(req):
			return false
	return true


func missing_required_items(required_items : Array) -> Array:
	var missing := []
	
	for req in required_items:
		if not items.has(req):
			missing.append(req)
	
	return missing
