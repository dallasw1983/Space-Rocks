extends Sprite2D



func _on_animation_player_animation_started(anim_name):
	if anim_name == "explosion":
		$ExplosionSound.play()
