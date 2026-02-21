extends Node
class_name UIManager

# =========================
# NODE REFERENCES
# =========================
@export var hud : Control
@export var timer_label : Label
@export var objective_label : Label
@export var message_label : Label

# =========================
# LIFECYCLE
# =========================
func _ready():
	connect_signals()

# =========================
# SIGNAL WIRING
# =========================
func connect_signals():
	GameManager.timer_updated.connect(update_timer)
	GameManager.objective_updated.connect(update_objective)
	GameManager.player_eliminated.connect(_on_player_eliminated)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(show_game_over)

# =========================
# HUD CONTROL
# =========================
func show_hud():
	if hud:
		hud.visible = true

func hide_hud():
	if hud:
		hud.visible = false

# =========================
# TIMER UI
# =========================
func update_timer(time_left : float):
	if not timer_label:
		return
	
	timer_label.text = "Time Left: %d" % int(time_left)

# =========================
# OBJECTIVE UI
# =========================
func update_objective(text : String):
	if not objective_label:
		return
	
	objective_label.text = text

# =========================
# INVENTORY UI
# =========================
func update_inventory(player_id, inventory_data : Dictionary):
	# Extend later for inventory panel / icons
	print("Update Inventory UI → Player:", player_id)

# =========================
# MESSAGES / NOTIFICATIONS
# =========================
func show_message(text : String):
	if not message_label:
		return
	
	message_label.text = text
	message_label.visible = true

func show_warning(text : String):
	show_message("⚠ " + text)

func clear_message():
	if not message_label:
		return
	
	message_label.visible = false

# =========================
# GAME EVENTS
# =========================
func _on_player_eliminated(player_id):
	show_warning("Player %d Eliminated" % player_id)

func _on_level_completed(level_id):
	show_message("Level %d Complete" % level_id)

func show_game_over(reason):
	show_message("GAME OVER → " + reason)

# =========================
# LEVEL TRANSITIONS
# =========================
func show_level_start(level_id):
	show_message("Level %d Started" % level_id)

func show_level_objective(text):
	update_objective(text)
