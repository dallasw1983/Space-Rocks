extends RigidBody2D

@onready var col : CollisionShape2D = $CollisionShape2D
@onready var gun_cool_down = $GunCoolDown

@export var bullet_scene : PackedScene

enum { INIT, ALIVE, INVULNERABLE, DEAD }

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
	engine_power += 100
	spin_power += 800
	brake_power += 1

var engine_power = 200
var spin_power = 2000
var brake_power : float = 1.0

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
	thurst = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thurst") and not paused:
		thurst = transform.x * engine_power * 150
		$Exhaust.emitting = true
		if not $EngineSound.playing:
			$EngineSound.play()
		else:
			$EngineSound.stop()
	else:
		$Exhaust.emitting = false
	if Input.is_action_pressed("ui_down"):
		thurst = transform.x * -engine_power * 150
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
#	$Muzzle.transform.rotation = 0.0
#	$Muzzle.set_rotation_degrees(0)
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

func _physics_process(delta):
	constant_force = thurst
	constant_torque = rotation_dir * spin_power * 150

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false
	
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
			engine_power = 200
			spin_power = 2000
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
