extends Node
class_name TaskManager

var player_tasks : Dictionary = {}   # { player_id : task_data }

signal task_completed(player_id)
signal task_failed(player_id)

# =========================
# TASK ASSIGNMENT
# =========================
func assign_task(player):
	var role = player.inventory.calculate_role()
	
	var task = generate_task_for_role(role)
	player_tasks[player.player_id] = task

func generate_task_for_role(role : String) -> Dictionary:
	match role:
		"Mechanic":
			return {
				"type": "GENERATOR_FIX",
				"required_items": ["Metal"]
			}
		
		"Electrician":
			return {
				"type": "WIRING_FIX",
				"required_items": ["Wire"]
			}
		
		"Carpenter":
			return {
				"type": "STRUCTURE_REPAIR",
				"required_items": ["Wood"]
			}
		
		_:
			return {
				"type": "GENERIC_TASK",
				"required_items": []
			}

# =========================
# TASK VALIDATION
# =========================
func attempt_task(player_id):
	if not player_tasks.has(player_id):
		return
	
	var player = GameManager.get_player(player_id)
	var task = player_tasks[player_id]
	
	if player.has_required_items(task["required_items"]):
		complete_task(player_id)
	else:
		fail_task(player_id)

func complete_task(player_id):
	emit_signal("task_completed", player_id)
	player_tasks.erase(player_id)
	
	# Mark generator repaired (if exists)
	var generators = get_tree().get_nodes_in_group("generators")
	
	for gen in generators:
		gen.mark_repaired()

func fail_task(player_id):
	emit_signal("task_failed", player_id)
