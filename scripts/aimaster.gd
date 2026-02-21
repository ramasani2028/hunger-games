extends Node
class_name AIMaster

# =========================
# CONFIGURATION
# =========================
@export var intro_lines : Array[String] = [
	"Welcome, contestants.",
	"Survival requires obedience.",
	"Collect what is assigned."
]

@export var mysterious_lines : Array[String] = [
	"Not everything is as it seems.",
	"Someone is watching you.",
	"The walls remember."
]

@export var warning_lines : Array[String] = [
	"Time is slipping away.",
	"Failure is inevitable.",
	"You cannot hide forever."
]

@export var lie_lines : Array[String] = [
	"Trust your allies.",
	"There are no threats nearby.",
	"You are safe."
]

# =========================
# STATE
# =========================
var current_phase := 1
var corruption_level := 0

# =========================
# SABOTAGE CONFIG
# =========================
@export var sabotage_enabled := true
@export var sabotage_intensity : float = 1.0

var sabotage_cooldowns : Dictionary = {}   # { player_id : time_left }

@export var sabotage_cooldown_time : float = 8.0

# =========================
# SIGNALS
# =========================
signal ai_spoke(text)
signal sabotage_requested(player_id, type)
signal fake_objective_requested(player_id)

# =========================
# LIFECYCLE
# =========================
func _ready():
	connect_signals()

# =========================
# SIGNAL WIRING
# =========================
func connect_signals():
	GameManager.level_started.connect(_on_level_started)
	GameManager.player_noise_emitted.connect(_on_player_noise)
	GameManager.player_eliminated.connect(_on_player_eliminated)
	GameManager.clue_found.connect(_on_clue_found)
	GameManager.difficulty_increased.connect(_on_difficulty_increase)

# =========================
# DIALOGUE SYSTEM
# =========================
func speak_intro():
	_emit_random_line(intro_lines)

func speak_mysterious():
	_emit_random_line(mysterious_lines)

func speak_warning():
	_emit_random_line(warning_lines)

func speak_lie():
	_emit_random_line(lie_lines)

func _emit_random_line(pool : Array[String]):
	if pool.is_empty():
		return
	
	var line = pool[randi() % pool.size()]
	emit_signal("ai_spoke", line)

# =========================
# PHASE / BEHAVIOR CONTROL
# =========================
func set_phase(phase : int):
	current_phase = phase

func escalate_behavior():
	corruption_level += 1
	
	match corruption_level:
		1:
			speak_mysterious()
		2:
			speak_warning()
		3:
			speak_lie()
		_:
			speak_warning()

# =========================
# SABOTAGE ENTRY POINT
# =========================
func request_sabotage(player_id):
	if not sabotage_enabled:
		return
	
	if sabotage_cooldowns.has(player_id):
		return
	
	var sabotage = _choose_sabotage_type(player_id)
	_execute_sabotage(player_id, sabotage)
	
	sabotage_cooldowns[player_id] = sabotage_cooldown_time


# =========================
# SABOTAGE SELECTION
# =========================
func _choose_sabotage_type(player_id) -> String:
	var pool = [
		"FAKE_NOISE",
		"CONTROL_GLITCH",
		"OBJECTIVE_DISTORTION",
		"SENSOR_DISTORTION"
	]
	
	return pool[randi() % pool.size()]


# =========================
# SABOTAGE EXECUTION
# =========================
func _execute_sabotage(player_id, sabotage_type):
	match sabotage_type:
		
		"FAKE_NOISE":
			_fake_noise(player_id)
		
		"CONTROL_GLITCH":
			_control_glitch(player_id)
		
		"OBJECTIVE_DISTORTION":
			_objective_distortion(player_id)
		
		"SENSOR_DISTORTION":
			_sensor_distortion(player_id)


# =========================
# FAKE NOISE
# =========================
func _fake_noise(player_id):
	var player = GameManager.get_player(player_id)
	if not player:
		return
	
	GameManager.emit_noise(player_id, player.global_position, 2.5)
	speak_lie()


# =========================
# CONTROL GLITCH
# =========================
func _control_glitch(player_id):
	var player = GameManager.get_player(player_id)
	if not player:
		return
	
	player.set_state("EXPOSED")
	speak_mysterious()


# =========================
# OBJECTIVE DISTORTION
# =========================
func _objective_distortion(player_id):
	GameManager.maybe_trigger_fake_objective()
	speak_lie()


# =========================
# SENSOR DISTORTION
# =========================
func _sensor_distortion(player_id):
	speak_mysterious()

func request_fake_objective(player_id):
	emit_signal("fake_objective_requested", player_id)


# =========================
# SABOTAGE COOLDOWN DECAY
# =========================
func _process(delta):
	for player_id in sabotage_cooldowns.keys():
		sabotage_cooldowns[player_id] -= delta
		
		if sabotage_cooldowns[player_id] <= 0:
			sabotage_cooldowns.erase(player_id)

# =========================
# EVENT REACTIONS
# =========================
func _on_level_started(level_id):
	if level_id == 1:
		speak_intro()
	else:
		speak_mysterious()

func _on_player_noise(player_id, location, intensity):
	if intensity > 0.5:
		speak_warning()

func _on_player_eliminated(player_id):
	speak_mysterious()
	escalate_behavior()

func _on_clue_found(player_id):
	speak_mysterious()

func _on_difficulty_increase(level):
	escalate_behavior()
