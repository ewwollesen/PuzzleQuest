extends Node2D

export (String) var type

var matched: bool = false

onready var moveTween: = $MoveTween
onready var sprite: = $Sprite

func move(target: Vector2) -> void:
	moveTween.interpolate_property(self, "position", position, target, .3,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
	moveTween.start()
	
func dim():
	sprite.modulate.a = .5
