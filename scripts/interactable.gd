extends Node3D
class_name Interactable

@export var interaction_enabled := true
@export var noise_on_interact : float = 0.3

signal interacted(player_id)

func interact(player):
	if not interaction_enabled:
		print("Interaction Disabled")
		return
	
	if not player.is_player_alive():
		return
	
	emit_signal("interacted", player.player_id)
	
	if noise_on_interact > 0:
		GameManager.emit_noise(player.player_id, global_position, noise_on_interact)
