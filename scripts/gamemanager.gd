extends Node
class_name GameManager

# =========================
# SIGNALS (GLOBAL EVENTS)
# =========================
signal level_started(level_id)
signal level_completed(level_id)

signal timer_updated(time_left)
signal timer_ended

signal player_eliminated(player_id)
signal item_collected(player_id, item_type)
signal player_noise_emitted(player_id, location, intensity)

signal objective_updated(text)
signal difficulty_increased(level)
signal game_over(reason)
signal clue_found(player_id)

# =========================
# GAME STATE
# =========================
var current_level : int = 0
var difficulty_level : int = 1

var players : Dictionary = {}    # { player_id : Player }
var allowed_actions : Dictionary = {}

var level_duration : float = 0
var time_left : float = 0
var timer_running := false

var timer_update_rate : float = 0.2
var update_timer : Timer

# =========================
# SNATCH / KILL CONFIG
# =========================
@export var snatch_enabled := true
@export var kill_enabled := true

@export var snatch_cooldown : float = 5.0
@export var kill_cooldown : float = 10.0

var snatch_timers : Dictionary = {}   # { player_id : time_left }
var kill_timers : Dictionary = {}     # { player_id : time_left }

# =========================
# NOISE CONFIG
# =========================
@export var noise_decay_rate : float = 0.25
@export var noise_warning_threshold : float = 3.0
@export var noise_danger_threshold : float = 6.0
@export var noise_critical_threshold : float = 10.0

var player_noise_levels : Dictionary = {}   # { player_id : noise_value }

# =========================
# NOISE CONSEQUENCE CONFIG
# =========================
@export var detection_noise_threshold : float = 5.0
@export var sabotage_noise_threshold : float = 7.5
@export var hazard_noise_threshold : float = 10.0

@export var noise_detection_penalty_step : float = 0.15
@export var noise_sabotage_boost_step : float = 0.20

var player_detection_penalty : Dictionary = {}   # { player_id : penalty }
var player_sabotage_risk : Dictionary = {}       # { player_id : risk }

# =========================
# OBJECTIVE SYSTEM
# =========================
var real_objective : String = ""
var fake_objective : String = ""

@export var fake_objective_enabled := true
@export var fake_objective_chance : float = 0.35

# =========================
# DIFFICULTY CONFIG
# =========================
@export var difficulty_scaling_enabled := true

@export var timer_reduction_step : float = 10.0
@export var noise_multiplier_step : float = 0.15
@export var ai_lie_boost_step : float = 0.10
@export var bomb_speed_step : float = 0.20

var noise_multiplier : float = 1.0
var bomb_speed_multiplier : float = 1.0

# =========================
# INITIALIZATION
# =========================
func _ready():
	print("GameManager Initialized")
	initialize_allowed_actions()

# =========================
# ACTION PERMISSIONS
# =========================
func initialize_allowed_actions():
	allowed_actions = {
		"MOVE": true,
		"COLLECT": true,
		"INTERACT": true,
		"SNATCH": false,
		"KILL": false,
		"HIDE": true
	}

func enable_action(action_type : String):
	allowed_actions[action_type] = true

func disable_action(action_type : String):
	allowed_actions[action_type] = false

func is_action_allowed(action_type : String) -> bool:
	if not allowed_actions.has(action_type):
		return false
	return allowed_actions[action_type]

# =========================
# PLAYER REGISTRY
# =========================
func register_player(player):
	players[player.player_id] = player
	player.action_requested.connect(_on_action_requested)

func remove_player(player_id):
	players.erase(player_id)

func get_player(player_id):
	return players.get(player_id, null)

func get_all_players() -> Array:
	return players.values()

# =========================
# LEVEL FLOW
# =========================
func start_game():
	current_level = 1
	start_level(current_level)

func start_level(level_id : int):
	current_level = level_id
	
	print("Starting Level:", level_id)
	emit_signal("level_started", level_id)
	start_level_timer_for_level()

func notify_player_completed(player_id):
	print("Player Completed Objective:", player_id)

func complete_level(level_id):
	print("Level Completed:", level_id)
	emit_signal("level_completed", level_id)
	increase_difficulty()

func increase_difficulty():
	difficulty_level += 1
	
	emit_signal("difficulty_increased", difficulty_level)
	apply_difficulty_modifiers()
	maybe_trigger_fake_objective()

# =========================
# TIMER SYSTEM
# =========================
func start_level_timer(duration : float):
	level_duration = duration
	time_left = duration
	timer_running = true
	
	if update_timer:
		update_timer.queue_free()
	
	update_timer = Timer.new()
	update_timer.wait_time = timer_update_rate
	update_timer.one_shot = false
	
	add_child(update_timer)
	update_timer.timeout.connect(_on_timer_update)
	update_timer.start()


# =========================
# DELTA TIMER LOOP
# =========================
func _process(delta):
	_update_timer_logic(delta)
	_update_cooldowns(delta)
	_update_noise_decay(delta)

func _update_timer_logic(delta):
	if not timer_running:
		return
	
	time_left -= delta
	
	if time_left <= 0:
		time_left = 0
		timer_running = false
		
		if update_timer:
			update_timer.stop()
		
		emit_signal("timer_updated", time_left)
		emit_signal("timer_ended")

func _update_cooldowns(delta):
	for player_id in snatch_timers.keys():
		snatch_timers[player_id] -= delta
		if snatch_timers[player_id] <= 0:
			snatch_timers.erase(player_id)
	
	for player_id in kill_timers.keys():
		kill_timers[player_id] -= delta
		if kill_timers[player_id] <= 0:
			kill_timers.erase(player_id)


# =========================
# UI UPDATE TICK
# =========================
func _on_timer_update():
	emit_signal("timer_updated", time_left)


# =========================
# PAUSE / RESUME
# =========================
func pause_timer():
	timer_running = false
	
	if update_timer:
		update_timer.stop()


func resume_timer():
	timer_running = true
	
	if update_timer:
		update_timer.start()


# =========================
# LEVEL TIMER ENTRY POINT
# =========================
func start_level_timer_for_level():
	match current_level:
		1:
			start_level_timer(240.0)
		2:
			start_level_timer(120.0)
		_:
			start_level_timer(180.0)

# =========================
# ACTION VALIDATION
# =========================
func _on_action_requested(player_id, action_type, data):
	if not is_action_allowed(action_type):
		print("Action Blocked:", action_type)
		return
	
	match action_type:
		"COLLECT":
			validate_collect(player_id, data)
		
		"INTERACT":
			validate_interact(player_id, data)
		
		"SNATCH":
			validate_snatch(player_id, data)
		
		"KILL":
			validate_kill(player_id, data)
		
		"HIDE":
			validate_hide(player_id)

# =========================
# COLLECT VALIDATION
# =========================
func validate_collect(player_id, item):
	var player = get_player(player_id)
	if not player:
		return
	
	if player.inventory.is_full():
		print("Inventory Full")
		return
	
	player.add_item(item.item_type)
	emit_signal("item_collected", player_id, item.item_type)

# =========================
# INTERACTION VALIDATION
# =========================
func validate_interact(player_id, target):
	if not target:
		return
	
	if target.has_method("interact"):
		target.interact(get_player(player_id))

# =========================
# SNATCH VALIDATION
# =========================
func validate_snatch(player_id, target_player):
	if not snatch_enabled:
		print("Snatch Disabled")
		return
	
	if snatch_timers.has(player_id):
		print("Snatch Cooldown Active")
		return
	
	var thief = get_player(player_id)
	var victim = target_player
	
	if not thief or not victim:
		return
	
	if not victim.is_player_alive():
		print("Cannot snatch dead player")
		return
	
	var stolen = victim.inventory.steal_random_item()
	
	if stolen != "":
		thief.add_item(stolen)
		snatch_timers[player_id] = snatch_cooldown
		
		emit_noise(player_id, thief.global_position, 0.4)

# =========================
# KILL VALIDATION
# =========================
func validate_kill(player_id, target_player):
	if not kill_enabled:
		print("Kill Disabled")
		return
	
	if kill_timers.has(player_id):
		print("Kill Cooldown Active")
		return
	
	var attacker = get_player(player_id)
	var victim = target_player
	
	if not attacker or not victim:
		return
	
	if not victim.is_player_alive():
		print("Target already dead")
		return
	
	victim.eliminate("KILLED")
	kill_timers[player_id] = kill_cooldown
	
	emit_noise(player_id, attacker.global_position, 1.0)

# =========================
# HIDE VALIDATION
# =========================
func validate_hide(player_id):
	var player = get_player(player_id)
	if not player:
		return
	
	player.set_state("HIDDEN")

# =========================
# NOISE SYSTEM
# =========================
func emit_noise(player_id, location, intensity):
	if not player_noise_levels.has(player_id):
		player_noise_levels[player_id] = 0.0
	
	player_noise_levels[player_id] += intensity * noise_multiplier
	
	emit_signal("player_noise_emitted", player_id, location, intensity)
	_check_noise_thresholds(player_id)


# =========================
# DIFFICULTY MODIFIERS
# =========================
func apply_difficulty_modifiers():
	if not difficulty_scaling_enabled:
		return
	
	print("Applying Difficulty Modifiers → Level:", difficulty_level)
	
	_apply_timer_modifier()
	_apply_noise_modifier()
	_apply_ai_modifier()
	_apply_bomb_modifier()


func _apply_timer_modifier():
	var reduction = difficulty_level * timer_reduction_step
	
	level_duration = max(30.0, level_duration - reduction)
	time_left = min(time_left, level_duration)
	
	print("Timer Reduced → New Duration:", level_duration)


func _apply_noise_modifier():
	noise_multiplier = 1.0 + (difficulty_level * noise_multiplier_step)
	
	print("Noise Multiplier:", noise_multiplier)


func _apply_ai_modifier():
	fake_objective_chance += ai_lie_boost_step
	
	print("AI Lie Frequency:", fake_objective_chance)


func _apply_bomb_modifier():
	bomb_speed_multiplier = 1.0 + (difficulty_level * bomb_speed_step)
	
	print("Bomb Speed Multiplier:", bomb_speed_multiplier)


# =========================
# NOISE DECAY
# =========================
func _update_noise_decay(delta):
	for player_id in player_noise_levels.keys():
		player_noise_levels[player_id] -= noise_decay_rate * delta
		
		if player_noise_levels[player_id] <= 0:
			player_noise_levels[player_id] = 0.0
		
		# Decay penalties slowly
		if player_detection_penalty.has(player_id):
			player_detection_penalty[player_id] = max(
				0.0,
				player_detection_penalty[player_id] - delta * 0.05
			)
		
		if player_sabotage_risk.has(player_id):
			player_sabotage_risk[player_id] = max(
				0.0,
				player_sabotage_risk[player_id] - delta * 0.05
			)


# =========================
# NOISE THRESHOLD LOGIC
# =========================
func _check_noise_thresholds(player_id):
	var noise = player_noise_levels[player_id]
	
	if noise >= hazard_noise_threshold:
		_handle_hazard_noise(player_id)
	
	elif noise >= sabotage_noise_threshold:
		_handle_sabotage_noise(player_id)
	
	elif noise >= detection_noise_threshold:
		_handle_detection_noise(player_id)
	
	elif noise >= noise_warning_threshold:
		_handle_warning_noise(player_id)


func _handle_warning_noise(player_id):
	AIMaster.speak_warning()


# =========================
# DETECTION CONSEQUENCE
# =========================
func _handle_detection_noise(player_id):
	if not player_detection_penalty.has(player_id):
		player_detection_penalty[player_id] = 0.0
	
	player_detection_penalty[player_id] += noise_detection_penalty_step
	
	var player = get_player(player_id)
	if player:
		player.set_state("EXPOSED")
	
	AIMaster.speak_warning()


# =========================
# SABOTAGE CONSEQUENCE
# =========================
func _handle_sabotage_noise(player_id):
	if not player_sabotage_risk.has(player_id):
		player_sabotage_risk[player_id] = 0.0
	
	player_sabotage_risk[player_id] += noise_sabotage_boost_step
	
	AIMaster.request_sabotage(player_id)
	AIMaster.escalate_behavior()


func _handle_danger_noise(player_id):
	AIMaster.escalate_behavior()
	AIMaster.request_sabotage(player_id)
	maybe_trigger_fake_objective()


# =========================
# HAZARD CONSEQUENCE
# =========================
func _handle_hazard_noise(player_id):
	AIMaster.speak_mysterious()
	AIMaster.request_sabotage(player_id)
	
	# Severe penalty
	var player = get_player(player_id)
	if player:
		player.set_state("EXPOSED")


# =========================
# NOISE QUERY FUNCTIONS
# =========================
func get_noise_level(player_id) -> float:
	return player_noise_levels.get(player_id, 0.0)


func reset_noise(player_id):
	player_noise_levels[player_id] = 0.0


func get_detection_penalty(player_id) -> float:
	return player_detection_penalty.get(player_id, 0.0)


func get_sabotage_risk(player_id) -> float:
	return player_sabotage_risk.get(player_id, 0.0)

# =========================
# OBJECTIVE MANAGEMENT
# =========================
func set_real_objective(text : String):
	real_objective = text
	emit_signal("objective_updated", real_objective)


func generate_fake_objective() -> String:
	var pool = [
		"Fix the secondary generator",
		"Search lockers for override key",
		"Disable ventilation system",
		"Restore power to control room",
		"Secure hidden supply cache"
	]
	
	return pool[randi() % pool.size()]


func maybe_trigger_fake_objective():
	if not fake_objective_enabled:
		return
	
	if randf() > fake_objective_chance:
		return
	
	fake_objective = generate_fake_objective()
	AIMaster.speak_lie()
	
	emit_signal("objective_updated", fake_objective)


# =========================
# PLAYER-SPECIFIC LIES
# =========================
func trigger_fake_objective_for_player(player_id):
	if not fake_objective_enabled:
		return
	
	var fake = generate_fake_objective()
	AIMaster.request_fake_objective(player_id)
	
	# Only mislead that player (UI layer later can filter)
	print("Fake Objective for Player", player_id, ":", fake)


# =========================
# OBJECTIVE VALIDATION
# =========================
func is_objective_real(text : String) -> bool:
	return text == real_objective


# =========================
# CLUE COUNTERPLAY HOOK
# =========================
func reveal_real_objective():
	emit_signal("objective_updated", real_objective)
	AIMaster.speak_mysterious()

# =========================
# CLUE SYSTEM CONFIG
# =========================
@export var clues_enabled := true
@export var auto_reveal_objective_on_clues := true
@export var clues_needed_for_reveal : int = 2

var player_clues : Dictionary = {}     # { player_id : [clues] }


# =========================
# CLUE REGISTRATION
# =========================
func register_clue(player_id, clue_data):
	if not clues_enabled:
		return
	
	if not player_clues.has(player_id):
		player_clues[player_id] = []
	
	player_clues[player_id].append(clue_data)
	
	emit_signal("clue_found", player_id)
	_check_clue_threshold(player_id)


# =========================
# CLUE THRESHOLD LOGIC
# =========================
func _check_clue_threshold(player_id):
	var clues = player_clues[player_id]
	
	if clues.size() >= clues_needed_for_reveal:
		_handle_clue_advantage(player_id)


func _handle_clue_advantage(player_id):
	print("Player", player_id, "has clue advantage")
	
	if auto_reveal_objective_on_clues:
		reveal_real_objective()


# =========================
# CLUE QUERY FUNCTIONS
# =========================
func get_player_clues(player_id) -> Array:
	return player_clues.get(player_id, [])


func get_clue_count(player_id) -> int:
	return player_clues.get(player_id, []).size()


func has_clue(player_id, clue_id) -> bool:
	if not player_clues.has(player_id):
		return false
	
	for clue in player_clues[player_id]:
		if clue == clue_id:
			return true
	
	return false


# =========================
# CLUE CONSUMPTION
# =========================
func consume_clue(player_id, clue_id):
	if not player_clues.has(player_id):
		return
	
	player_clues[player_id].erase(clue_id)


# =========================
# CLUE RESET / CLEANUP
# =========================
func reset_player_clues(player_id):
	player_clues[player_id] = []


func reset_all_clues():
	player_clues.clear()


# =========================
# TRUTH VALIDATION HOOK
# =========================
func can_detect_fake_objective(player_id) -> bool:
	return get_clue_count(player_id) >= clues_needed_for_reveal

# =========================
# ELIMINATION SYSTEM
# =========================
func eliminate_player(player_id, reason := "UNKNOWN"):
	print("Eliminating Player:", player_id, "Reason:", reason)
	emit_signal("player_eliminated", player_id)
	check_game_over()

func check_game_over():
	var alive_players := 0
	
	for player in players.values():
		if player.is_player_alive():
			alive_players += 1
	
	if alive_players <= 0:
		emit_signal("game_over", "ALL_PLAYERS_ELIMINATED")
