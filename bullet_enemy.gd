extends Area2D

@export var speed = 1000
@export var damage = 15

var velocity = Vector2.ZERO

func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()
	velocity = transform.x * speed
	$BulletSound.play()
	
func _process(delta):
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("rocks"):
		body.explode()
		queue_free()
	if body.is_in_group("player"):
		body.shield -= damage
		body.explode_size(0.5)
		queue_free()
