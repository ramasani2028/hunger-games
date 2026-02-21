extends Interactable
class_name Generator

@export var required_items : Array = ["Metal"]
@export var single_use := true

var repaired := false

func interact(player):
	if repaired:
		print("Generator Already Repaired")
		return
	
	super.interact(player)
	
	if GameManager.TaskManager:
		GameManager.TaskManager.attempt_task(player.player_id)

func mark_repaired():
	repaired = true
	
	if single_use:
		interaction_enabled = false
