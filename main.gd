extends Node

@export var rock_scene : PackedScene
@export var player_scene : PackedScene
@export var enemey_scene : PackedScene

var screensize = Vector2.ZERO
var level = 0
var past_level = 0
var score = 0
var playing = false
var enemy_timer = 0.5
var quit_ready = false
var choose_upgrade_active = false
var debug = false

signal upgrade_weapons_call
signal upgrade_movement_call
signal upgrade_defence_call

func _ready():
	$Player.hide()
	$Player.reset()
	screensize = get_viewport().get_visible_rect().size

func new_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().call_group("rocks", "queue_free")
	get_tree().call_group("enemies", "queue_free")
	level = 0
	score = 0
	enemy_timer = 0.5
	$HUD.show_message("Get Ready!")
	$Player.reset()
	$Player.show()
	await $HUD/Timer.timeout
	playing = true
	if not debug:
		$EnemyTimer.start(randf_range(5, 10))
	new_level()
	
func new_level():
	if past_level == level:
		level += 1
		$Player.set_freeze_enabled(false)
		$EnemyTimer.stop()
		enemy_timer = enemy_timer * 0.95
		$Player.set_energy(200)
		$Player.set_shield(200)
		$HUD.show_message("Wave %s" % level)
		await get_tree().create_timer(3).timeout
		var s = 0
		for i in level:
#			if not debug:
			spawn_rock(s + 1)
			spawn_rock(s + 1)
			if i > 2:
				spawn_rock(s + 2)
			if i > 4:
				spawn_rock(s + 3)
			if i > 6:
				s+=1
				spawn_rock(s + 4)
		if not debug:
			$EnemyTimer.start()
		past_level = level
		
func _input(event):
	if event.is_action_pressed("esc"):
		if playing:
			pause_game_play()
		if not playing and quit_ready:
			pause_game_play()
			var message = $HUD/VBoxContainer/Message
			message.text = "Space Rocks!"
			message.show()
			quit_ready = false
	if event.is_action_pressed("quit"):
		if not quit_ready:
			quit_confirm()
		else:
			get_tree().quit()
	if Input.is_action_pressed("game_over"):
		$Player.set_lives(0)
		
func game_over():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	playing = false
	$HUD.game_over()
	$EnemyTimer.stop()
	past_level = 0
	choose_upgrade_active = false
	
func pause_timers():
	$EnemyTimer.stop()
	
func resume_timers():
	if $EnemyTimer.time_left:
		$EnemyTimer.start()
	
	
func pause_game_play():
	get_tree().paused = not get_tree().paused
	var message = $HUD/VBoxContainer/Message
	quit_ready = false
	if get_tree().paused:	
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		message.text = "Paused"
		message.show()
		get_tree().call_group("hittable", "pause_tree")
		$EnemyTimer.stop()
		$Player/ShieldRechargeDelay.stop()
		
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		message.text = ""
		message.hide()	
		get_tree().call_group("hittable", "pause_tree")
		if $EnemyTimer.time_left:
			$EnemyTimer.start()
		$Player/ShieldRechargeDelay.start()
			
func quit_confirm():
	pause_game_play()
	var message = $HUD/VBoxContainer/Message
	message.hide()
	message.text = "Press CTRL-Q to quit or ESC to resume"
	message.show()
	quit_ready = !quit_ready
	
func _process(delta):
	if get_tree().get_nodes_in_group("rocks").size() == 0 \
		and get_tree().get_nodes_in_group("enemies").size() == 0 \
		and playing:
		if not choose_upgrade_active:
			new_level()
		if choose_upgrade_active:
			upgrade_choose()
	if debug:
		choose_upgrade_active = true
	if get_tree().get_nodes_in_group("rocks").size() > 0 \
		and playing:
		choose_upgrade_active = true
		
			
	$HUD.update_score(score)
	$HUD.update_wave(level)
	$HUD.update_energy_bar($Player.get_energy() / $Player.get_energy_max())

func upgrade_choose():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pause_timers()
	$UI_UpGrade.show_upgrade_ui()
	
func upgrade_ui_close():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	resume_timers()
	$UI_UpGrade.hide_upgrade_ui()
	choose_upgrade_active = false

func upgrade_weapon():
	print("upgrade weapons")
	upgrade_weapons_call.emit()
	upgrade_ui_close()
	
func upgrade_defence():
	print("upgrade defence")
	upgrade_defence_call.emit()
	upgrade_ui_close()
	
func upgrade_movement():
	print("upgrade movement")
	upgrade_movement_call.emit()
	upgrade_ui_close()

func spawn_rock(size, pos=null, vel=null, minv=50, maxv=500):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(minv, maxv)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded)
 
func _on_rock_exploded(size, radius, pos, vel):
	score += 1
	if size <= 1:
		return
	for offset in [-1, 1]:
		var dir = $Player.position.direction_to(pos).orthogonal()*offset
		var newpos = pos + dir * radius
		var newvel = dir *vel.length() * 1.1
		spawn_rock(size -1, newpos, newvel)

func _on_enemy_timer_timeout():
	var e = enemey_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20.0,40.0))
	$Enemy/GunCoolDown.start(enemy_timer)
	e.enemy_dead.connect(self.enemy_exploded)
	
func enemy_exploded():
	score += 10 + (level * 2)
	
