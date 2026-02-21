extends Node
class_name PlayerState

enum States {
	IDLE,
	MOVING,
	INTERACTING,
	HIDING,
	EXPOSED,
	DEAD
}

var current_state : States = States.IDLE

signal state_changed(new_state)

# =========================
# STATE CONTROL
# =========================
func set_state(new_state : States):
	if current_state == States.DEAD:
		return
	
	if current_state == new_state:
		return
	
	if not _is_transition_allowed(new_state):
		print("Illegal State Transition:", current_state, "→", new_state)
		return
	
	current_state = new_state
	emit_signal("state_changed", current_state)

func get_state() -> States:
	return current_state

func is_dead() -> bool:
	return current_state == States.DEAD

# =========================
# TRANSITION RULES
# =========================
func _is_transition_allowed(new_state : States) -> bool:
	match current_state:
		States.IDLE:
			return true
		
		States.MOVING:
			return new_state != States.INTERACTING
		
		States.INTERACTING:
			return new_state == States.IDLE or new_state == States.DEAD
		
		States.HIDING:
			return new_state == States.IDLE or new_state == States.EXPOSED
		
		States.EXPOSED:
			return new_state != States.HIDING
		
		States.DEAD:
			return false
	
	return true

# =========================
# FORCE STATES
# =========================
func force_dead():
	current_state = States.DEAD
	emit_signal("state_changed", current_state)

func force_exposed():
	if current_state != States.DEAD:
		current_state = States.EXPOSED
		emit_signal("state_changed", current_state)
