extends RigidBody2D

@onready var col : CollisionShape2D = $CollisionShape2D
@onready var gun_cool_down = $GunCoolDown

@export var bullet_scene : PackedScene

enum { INIT, ALIVE, INVULNERABLE, DEAD }

var force = 200.0
var base_torque = 2000.0
var brake_power : float = 1.0
var torque_multiplier = 1000.0

var shield_regen = 5
var max_shield = 75
var shield_recharge_delay : float = 10

var fire_rate : float = 900
var shoot_recoil = 25
var bullet_spread = 0.012
var energy_max = 50
var energy = energy_max
var energy_regen : float = 2.0
var shoot_energy = 5.0

var rotation_dir = 0

signal lives_changed
signal dead
signal shield_changed

var reset_pos = false
var lives = 0: set = set_lives
var shield : float = 0: set = set_shield
var can_shoot : bool = true
var alt_shoot : bool = true
var state = INIT
var screensize = Vector2.ZERO
var thurst = Vector2.ZERO
var ang_damp = get_angular_damp()
var lin_damp = get_linear_damp()
var paused = false
var shield_recharge_ready = false
var shield_last_value : float = 0

func _integrate_forces(state):
	
	var horizontal_input = 0
	var vertical_input = 0
	# Call the default _integrate_forces function
#	_integrate_forces(state)

	if Input.is_action_pressed("move_right"):
		horizontal_input += 1
	if Input.is_action_pressed("move_left"):
		horizontal_input -= 1
	if Input.is_action_pressed("move_down"):
		vertical_input += 1
	if Input.is_action_pressed("move_up"):
		vertical_input -= 1
# Calculate torque based on horizontal input and angular velocity
	var torque_value = horizontal_input * (base_torque + torque_multiplier * abs(angular_velocity))
	apply_torque(torque_value)

	# Apply a constant force for horizontal movement
	var force_direction = Vector2(horizontal_input, 0)
	apply_central_impulse(force_direction * force)

	# Apply a constant force for vertical movement
	var vertical_force_direction = Vector2(0, vertical_input)
	apply_central_impulse(vertical_force_direction * force)

	# Calculate rotation based on linear velocity
	var linear_velocity = get_linear_velocity()
	var rotation_angle = atan2(linear_velocity.y, linear_velocity.x)
	var desired_rotation = rotation_angle - PI / 2  # Adjust for sprite alignment if necessary

	# Calculate torque to align with the desired rotation
	var current_rotation = get_rotation()
	var torque_to_apply = (desired_rotation - current_rotation) * base_torque
	apply_torque(torque_to_apply)
	
	# Update the sprite's rotation angle
	rotation_degrees = rotation_angle * 180 / PI
	
	# Wrap the RigidBody2D when it reaches the edges of the viewport
	var xform = state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	state.transform = xform
	if reset_pos:
		state.transform.origin = screensize / 2
		reset_pos = false

	
func upgrade_weapons():
	fire_rate += 350
	energy_regen += 8.0
	energy_max += 30
	gun_cool_down.start(100/fire_rate)
	
func upgrade_defence():
	shield_regen += 8
	max_shield += 50
	shield_recharge_delay += 15
	
func upgrade_movement():
	force += 100
	base_torque += 800
	brake_power += 1
	
func set_energy(value):
	energy += value
	if energy > energy_max:
		energy = energy_max
		
func get_energy():
	return energy
	
func get_energy_max():
	return energy_max

func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		explode()
		
func set_lives(value):
	lives = value
	shield = max_shield
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)

func pause_tree():
	paused = get_tree().paused
	
func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
	
func _ready():
	change_state(ALIVE)
	screensize = get_viewport_rect().size
	gun_cool_down.wait_time = 0.5
	$Exhaust.emitting = false
	$ShieldRecharge.emitting = false
	
func _process(delta):
	get_input()
	if shield < max_shield and shield_last_value != shield:
		$ShieldRechargeDelay.start(100 / shield_recharge_delay)
	if shield_recharge_ready and not paused:
		shield += shield_regen * delta
		$ShieldRecharge.emitting = true
	if shield == max_shield or not shield_recharge_ready:
		$ShieldRecharge.emitting = false
	if shield < shield_last_value:
		shield_recharge_ready = false	
	shield_last_value = shield
	if energy < energy_max and not paused:
		energy += energy_regen * delta
	
func get_input():
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thurst") and not paused:
		thurst = transform.x * force * 150
		$Exhaust.emitting = true
		if not $EngineSound.playing:
			$EngineSound.play()
		else:
			$EngineSound.stop()
	else:
		$Exhaust.emitting = false
	if Input.is_action_pressed("ui_down"):
		thurst = transform.x * -force * 150
	rotation_dir = Input.get_axis("rotate_left","rotate_right")
	if Input.is_action_pressed("shoot") and can_shoot and not paused:
		shoot()
	if Input.is_action_just_pressed("down"):
		set_angular_damp(brake_power)
		set_linear_damp(brake_power)
	if Input.is_action_just_released("down"):
		set_angular_damp(ang_damp)
		set_linear_damp(lin_damp)
				
func shoot():
	if energy < shoot_energy:
		return
	if state == INVULNERABLE:
		return
	energy -= shoot_energy
	can_shoot = false
	gun_cool_down.start()
	thurst = transform.x * -shoot_recoil * 150
	if alt_shoot:
		var b = bullet_scene.instantiate()
		get_tree().root.add_child(b)
		$Muzzle.set_rotation_degrees(0)
		$Muzzle.rotate(randf_range(-bullet_spread, bullet_spread))
		b.start($Muzzle.global_transform)
		$LaserSound.play()
	else:
		var c = bullet_scene.instantiate()
		get_tree().root.add_child(c)
		$Muzzle2.set_rotation_degrees(0)
		$Muzzle2.rotate(randf_range(-bullet_spread, bullet_spread))
		c.start($Muzzle2.global_transform)
		$LaserSound.play()
	alt_shoot = !alt_shoot

func change_state(new_state):
	match new_state:
		INIT:
			col.set_deferred("disabled",true)
			$Sprite2D.modulate.a = 0.5
		ALIVE:
			col.set_deferred("disabled",false)
			$Sprite2D.modulate.a = 1.0
		INVULNERABLE:
			col.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$INVULNERABLE_Timer.start()
			
		DEAD:
			col.set_deferred("disabled",true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
			force = 200
			base_torque = 2000
			brake_power = 1.0

			shield_regen = 5
			max_shield = 75
			shield_recharge_delay = 10

			fire_rate = 100
			shoot_recoil = 150
			bullet_spread = 0
			energy_max = 50
			energy = energy_max
			energy_regen = 2.0
			shoot_energy = 5.0
			gun_cool_down.start(100/fire_rate)
	state = new_state


func _on_gun_cool_down_timeout():
	can_shoot = true

func _on_body_entered(body):
	if body.is_in_group("rocks"): #or body.is_in_group("bullet_enemy"):
		shield -= body.size * 25
		body.explode()
		
func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()
	
func explode_size(size):
	$Explosion.scale = Vector2.ONE * 0.75 * size
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()

func _on_invulnerable_timer_timeout():
	change_state(ALIVE)

func _on_shield_recharge_delay_timeout():
	shield_recharge_ready = true
