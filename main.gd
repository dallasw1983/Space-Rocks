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

func _ready():
	$Player.hide()
	$Player.reset()
	screensize = get_viewport().get_visible_rect().size

func new_game():
	get_tree().call_group("rocks", "queue_free")
	level = 0
	score = 0
	enemy_timer = 0.5
	$HUD.show_message("Get Ready!")
	$Player.reset()
	$Player.show()
	await $HUD/Timer.timeout
	playing = true
	$EnemyTimer.start(randf_range(5, 10))
	
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
		for i in level:
			spawn_rock(i+1)
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
		
func game_over():
	playing = false
	$HUD.game_over()
	$EnemyTimer.stop()
	
func pause_game_play():
	get_tree().paused = not get_tree().paused
	var message = $HUD/VBoxContainer/Message
	quit_ready = false
	if get_tree().paused:
		message.text = "Paused"
		message.show()
		get_tree().call_group("hittable", "pause_tree")
		$EnemyTimer.stop()
		$Player/ShieldRechargeDelay.stop()
		# need to be able to pause enemy ship and player shooting
	else:
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
	if not playing:	
		return
	elif get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()
	$HUD.update_score(score)
	$HUD.update_wave(level)
	$HUD.update_energy_bar($Player.get_energy() / $Player.get_energy_max())
	
func spawn_rock(size, pos=null, vel=null, minv=50, maxv=800):
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
	
