extends Node2D

export (String) var type

onready var moveTween: = $MoveTween

func move(target: Vector2) -> void:
	moveTween.interpolate_property(self, "position", position, target, .3,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
	moveTween.start()
	
