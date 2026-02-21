extends Area3D
class_name Item

# =========================
# CONFIGURATION
# =========================
@export var item_type : String = "Wood"
@export var can_be_collected : bool = true
@export var noise_on_collect : float = 1.0

var collected := false

# =========================
# SIGNALS
# =========================
signal item_collected(player_id, item_type)

# =========================
# LIFECYCLE
# =========================
func _ready():
	body_entered.connect(_on_body_entered)

# =========================
# PLAYER DETECTION
# =========================
func _on_body_entered(body):
	if collected:
		return
	
	if not can_be_collected:
		return
	
	if not body.has_method("request_collect"):
		return
	
	collect(body)

# =========================
# COLLECTION LOGIC
# =========================
func collect(player):
	if collected:
		return
	
	collected = true
	
	var player_id = player.player_id
	
	# Ask player → player asks GameManager
	player.request_collect(self)
	
	emit_signal("item_collected", player_id, item_type)
	
	# Noise trigger (AI / stealth system)
	if noise_on_collect > 0:
		GameManager.emit_noise(player_id, global_position, noise_on_collect)
	
	destroy()

# =========================
# STATE CONTROL
# =========================
func enable_collection():
	can_be_collected = true


func disable_collection():
	can_be_collected = false

# =========================
# CLEANUP
# =========================
func destroy():
	queue_free()
