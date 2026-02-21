extends CharacterBody3D
class_name Player

# =========================
# CONFIGURATION
# =========================
@export var player_id : int = 0
@export var move_speed : float = 5.0
@export var noise_on_move : float = 0.1

var inventory : Inventory
var is_alive := true

@onready var state_machine : PlayerState = $PlayerState

# =========================
# SIGNALS
# =========================
signal action_requested(player_id, action_type, data)
signal player_eliminated(player_id)

# =========================
# LIFECYCLE
# =========================
func _ready():
	inventory = Inventory.new()
	GameManager.player_eliminated.connect(_on_eliminated)

func _physics_process(delta):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	handle_movement(delta)

# =========================
# MOVEMENT
# =========================
func handle_movement(delta):
	if state_machine.get_state() == PlayerState.States.INTERACTING:
		return
	
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	if direction != Vector3.ZERO:
		move(direction.normalized())
	else:
		stop_movement()

func move(direction : Vector3):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	state_machine.set_state(PlayerState.States.MOVING)
	
	velocity = direction * move_speed
	move_and_slide()
	
	if noise_on_move > 0:
		GameManager.emit_noise(player_id, global_position, noise_on_move)

func stop_movement():
	if state_machine.get_state() != PlayerState.States.DEAD:
		state_machine.set_state(PlayerState.States.IDLE)
	
	velocity = Vector3.ZERO

# =========================
# ACTION REQUESTS
# =========================
func request_collect(item):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	emit_signal("action_requested", player_id, "COLLECT", item)

func request_interact(target):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	state_machine.set_state(PlayerState.States.INTERACTING)
	emit_signal("action_requested", player_id, "INTERACT", target)

func request_snatch(target_player):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	emit_signal("action_requested", player_id, "SNATCH", target_player)

func request_kill(target_player):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	emit_signal("action_requested", player_id, "KILL", target_player)

func request_hide():
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	state_machine.set_state(PlayerState.States.HIDING)
	emit_signal("action_requested", player_id, "HIDE", null)

# =========================
# INVENTORY INTERFACE
# =========================
func add_item(item_type : String):
	inventory.add_item(item_type)

func remove_item(item_type : String):
	inventory.remove_item(item_type)

func has_required_items(required_list : Array) -> bool:
	return inventory.has_required_items(required_list)

func get_inventory() -> Inventory:
	return inventory

# =========================
# STATE HELPERS
# =========================
func set_state(new_state : String):
	match new_state:
		"HIDDEN":
			state_machine.set_state(PlayerState.States.HIDING)
		
		"EXPOSED":
			state_machine.force_exposed()

func is_player_alive() -> bool:
	return state_machine.get_state() != PlayerState.States.DEAD

# =========================
# ELIMINATION
# =========================
func eliminate(reason := "UNKNOWN"):
	if state_machine.get_state() == PlayerState.States.DEAD:
		return
	
	state_machine.force_dead()
	is_alive = false
	
	emit_signal("player_eliminated", player_id)

func _on_eliminated(id):
	if id == player_id:
		eliminate()
