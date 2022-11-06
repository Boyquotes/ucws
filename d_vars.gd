extends Node

onready var Player = get_tree().get_root().find_node("Player")

export var max_speed: float = 5 # Meters per second
export var max_air_speed: float = 0.6
export var accel: float = 10 # or max_speed * 10 : Reach max speed in 1 / 10th of a second
export var friction: float = 10 # Higher friction = less slippery. In quake-based games, usually between 1 and 5


export var mouse_sensitivity: float = 0.01
export var fov: float = 95
export var fov_scale_multiplier: float = 0.035
export var fov_scale_threshold: float = 4
export var fov_scale_weight: float = 0.1
export var fov_scale_max: float = 340
export var camera_max_angle: float = 87

export var camera_emote_distance: float = 4
export var camera_emote_weight: float = 0.03
export var camera_emote_weight_back: float = 0.4

export var wall_time: float  = 0.65
export var wall_lerp: float  = 0.02
export var koyori_time: float  = 0.1
export var sprint_grace: float = 0.7

export var sprint_multiplier: float = 2.3
export var crouch_multiplier: float = 0.4
export var crouch_weight: float = 0.1
export var slide_speed:float = 6
export var max_slide_speed:float = 7.5
export var slide_accel:float = 1

export var bob_multiplier: float = 0.04
export var bob_weight: float = 0.1
export var gravity: float = 27.5

export var jump_impulse: float = 8
export var terminal_velocity: float = gravity * -5 # When this is reached, we stop increasing falling speed

export var player_damage: float = 50
export var player_damage_multiplier: float = 1.3

var auto_jump: bool = false # Auto bunnyhopping


## Called when the node enters the scene tree for the first time.
#func _ready():
#	
#	var a = Console.add_command('setf', self, 'var_set')\
#		.set_description('set a float var')
#	a.add_argument('variable', TYPE_STRING)
#	a.add_argument('value', TYPE_REAL).register()
#	
#	a = Console.add_command('setb', self, 'var_set')\
#		.set_description('set a bool var')
#	a.add_argument('variable', TYPE_STRING)
#	a.add_argument('value', TYPE_BOOL).register()
#	
#	a = Console.add_command('seti', self, 'var_set')\
#		.set_description('set an int var')
#	a.add_argument('variable', TYPE_STRING)
#	a.add_argument('value', TYPE_INT).register()
#	
#	a = Console.add_command('sets', self, 'var_set')\
#		.set_description('set a string var')
#	a.add_argument('variable', TYPE_STRING)
#	a.add_argument('value', TYPE_STRING).register()
#
#	a = Console.add_command('timescale', self, 'timescale')\
#		.set_description('change the speed')
#	a.add_argument('scale', TYPE_REAL).register()
#
#func var_set(alpha, beta) -> void:
#	self.set(alpha, beta)
#
#func timescale(scale: float) -> void:
#	Engine.time_scale = scale
#