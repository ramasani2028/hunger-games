extends Node3D

@export var level_container : Node3D
@export var player_container : Node3D

func _ready():
	print("MainScene Ready")
	_initialize_game_world()

func _initialize_game_world():
	_register_players()
	_connect_global_signals()

func _register_players():
	if not player_container:
		return
	
	for player in player_container.get_children():
		if player is Player:
			GameManager.register_player(player)

func _connect_global_signals():
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)

func _on_level_started(level_id):
	print("MainScene → Level Started:", level_id)

func _on_level_completed(level_id):
	print("MainScene → Level Completed:", level_id)
