extends Node

onready var Player = get_node("../Player")

func _process(_delta: float) -> void:
	$Label.text = "Velocity : %s\nFloor :%s\nSliding :%s\nTiming :%s\nState :%s\nMantling :%s\nAnimating :%s\nKoyori :%s\n" % [
	Player.velocity,
	Player.is_on_floor(),
	Player.sliding,
	Player.koyori_timing(),
	Player.STATE.keys()[Player.State],
	Player.mantling,
	Player.animating,
	Player.koyori_timing()]
	self.visible = false
