extends Node3D
class_name Bomb

@export var countdown_time : float = 120.0

var time_left : float
var active := false
var owner_player_id : int

signal bomb_exploded(player_id)
signal bomb_diffused(player_id)

func _ready():
	time_left = countdown_time

func start(player_id):
	owner_player_id = player_id
	time_left = countdown_time
	active = true

func _process(delta):
	if not active:
		return
	
	time_left -= delta
	
	if time_left <= 0:
		explode()

func diffuse():
	if not active:
		return
	
	active = false
	emit_signal("bomb_diffused", owner_player_id)

func explode():
	if not active:
		return
	
	active = false
	emit_signal("bomb_exploded", owner_player_id)
	GameManager.eliminate_player(owner_player_id, "BOMB_EXPLOSION")
