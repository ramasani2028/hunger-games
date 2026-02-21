extends Node3D
class_name Level1

# =========================
# CONFIGURATION
# =========================
@export var level_duration : float = 240.0   # 4 minutes
@export var total_items_to_spawn : int = 20

@export var item_scene : PackedScene
@export var spawn_points : Array[Node3D]

# =========================
# STATE
# =========================
var required_items : Dictionary = {}   # { player_id : [items] }
var collected_items : Dictionary = {}  # { player_id : [items] }

var level_timer : Timer

# =========================
# LIFECYCLE
# =========================
func _ready():
	start_level()

# =========================
# LEVEL FLOW
# =========================
func start_level():
	print("Level 1 Started")
	
	setup_timer()
	assign_required_items()
	spawn_items()
	connect_signals()

func end_level():
	print("Level 1 Ended")
	
	if level_timer:
		level_timer.stop()

# =========================
# TIMER MANAGEMENT
# =========================
func setup_timer():
	level_timer = Timer.new()
	level_timer.wait_time = level_duration
	level_timer.one_shot = true
	
	add_child(level_timer)
	level_timer.timeout.connect(_on_timer_end)
	level_timer.start()

func _on_timer_end():
	print("Level Timer Ended")
	check_all_players_completion()

# =========================
# ITEM SPAWNING
# =========================
func spawn_items():
	if not item_scene:
		push_error("Item Scene not assigned!")
		return
	
	if spawn_points.is_empty():
		push_error("No spawn points assigned!")
		return
	
	for i in total_items_to_spawn:
		var item = item_scene.instantiate()
		
		var random_spawn = spawn_points[randi() % spawn_points.size()]
		item.global_position = random_spawn.global_position
		
		add_child(item)

# =========================
# REQUIRED ITEMS ASSIGNMENT
# =========================
func assign_required_items():
	var players = GameManager.get_all_players()
	
	for player in players:
		var player_id = player.player_id
		
		var count = randi_range(2, 4)
		required_items[player_id] = generate_required_items(count)
		collected_items[player_id] = []

func generate_required_items(count : int) -> Array:
	var pool = ["Wood", "Metal", "Wire", "Rope", "Stone"]
	var assigned := []
	
	for i in count:
		assigned.append(pool[randi() % pool.size()])
	
	return assigned

# =========================
# SIGNAL CONNECTIONS
# =========================
func connect_signals():
	GameManager.item_collected.connect(_on_item_collected)

# =========================
# COLLECTION TRACKING
# =========================
func _on_item_collected(player_id, item_type):
	if not required_items.has(player_id):
		return
	
	collected_items[player_id].append(item_type)
	check_player_completion(player_id)

func check_player_completion(player_id):
	var required = required_items[player_id]
	var collected = collected_items[player_id]
	
	if collected.size() >= required.size():
		print("Player %d completed objective" % player_id)
		GameManager.notify_player_completed(player_id)

# =========================
# FINAL COMPLETION CHECK
# =========================
func check_all_players_completion():
	var players = GameManager.get_all_players()
	
	for player in players:
		var player_id = player.player_id
		
		if not has_player_completed(player_id):
			eliminate_player(player_id, "INCOMPLETE_OBJECTIVE")
	
	complete_level()

func has_player_completed(player_id) -> bool:
	var required = required_items[player_id]
	var collected = collected_items[player_id]
	
	return collected.size() >= required.size()

# =========================
# ELIMINATION
# =========================
func eliminate_player(player_id, reason):
	print("Eliminating Player %d → %s" % [player_id, reason])
	GameManager.eliminate_player(player_id, reason)

# =========================
# LEVEL COMPLETION
# =========================
func complete_level():
	print("Level 1 Complete")
	GameManager.level_completed(1)
