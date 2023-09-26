extends Node

@export var rock_scene : PackedScene
@export var player_scene : PackedScene
@export var enemey_scene : PackedScene

var screensize = Vector2.ZERO
var level = 0
var score = 0
var playing = false
var enemy_timer = 0.5

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
	level += 1
	$HUD.show_message("Wave %s" % level)
	$Player.set_freeze_enabled(false)
	for i in level:
		spawn_rock(i+1)
	enemy_timer = enemy_timer * 0.95
		
func _input(event):
	if event.is_action_pressed("esc") and playing:
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
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
			$EnemyTimer.start()
			$Player/ShieldRechargeDelay.start()
	if event.is_action_pressed("quit"):
		get_tree().quit()
		
func game_over():
	playing = false
	$HUD.game_over()
	$EnemyTimer.stop()
	
	
func _process(delta):
	if not playing:	
		return
	elif get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()
	$HUD.update_score(score)

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
	
