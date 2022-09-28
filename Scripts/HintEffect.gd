extends Node2D

onready var this_sprite: = $Sprite
onready var sizeTween: = $SizeTween
onready var colorTween: = $ColorTween

func _ready():
	setup(this_sprite.texture)
#	print(this_sprite.texture)


func setup(new_sprite: StreamTexture) -> void:
#	print("new_sprite: ", new_sprite)
	this_sprite.texture = new_sprite
#	print("setup texture: ", this_sprite.texture)
	resize()
	dim()


func resize() -> void:
	sizeTween.interpolate_property(this_sprite, "scale", Vector2(1,1), Vector2(1.2,1.2), 1, Tween.TRANS_SINE, Tween.EASE_OUT)
	sizeTween.start()


func dim() -> void:
	colorTween.interpolate_property(this_sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.1), 1, Tween.TRANS_SINE, Tween.EASE_OUT)
	colorTween.start()


func _on_SizeTween_tween_completed(object, key):
	resize()


func _on_ColorTween_tween_completed(object, key):
	dim()
