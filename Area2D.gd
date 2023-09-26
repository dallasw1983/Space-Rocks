extends Area2D

@export var speed = 2000

signal bullet_contact

var velocity = Vector2.ZERO

func start(_transform):
	transform = _transform
	velocity = transform.x * speed
	
func _process(delta):
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("hittable") and not body.is_in_group("player"):
		body.explode()
		queue_free()
		bullet_contact.emit()

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(1)
		queue_free()
