extends CanvasLayer

signal start_game

@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label = $MarginContainer/HBoxContainer/VBoxScore/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/HBoxContainer/HBoxContainer/ShieldBar
@onready var energy_bar = $MarginContainer/HBoxContainer/HBoxContainer/GunCoolDown

var bar_textures = {
	"green" = preload("res://assets/bar_green_200.png"),
	"yellow" = preload("res://assets/bar_yellow_200.png"),
	"red" = preload("res://assets/bar_red_200.png")
}
var HUD_Active = true

func _process(delta):
	if Input.is_action_pressed("ui_accept") and HUD_Active:
		_on_start_button_pressed()
	if !$GamePlayMusic.playing:
		$GamePlayMusic.play()
		
func update_shield(value):
	if value >= 0.6:
		shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	if value < 0.6:
		shield_bar.texture_progress = bar_textures["yellow"]
	shield_bar.value = value
	
func update_energy_bar(value):
	if value >= 0.6:
		shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	if value < 0.6:
		shield_bar.texture_progress = bar_textures["yellow"]
	energy_bar.value = value
	
	

func show_message(text):
	message.text = text
	message.show()
	$Timer.start()
	
func update_score(score):
	score_label.text = str(score)
	
func update_lives(lives):
	for item in 3:
		lives_counter[item].visible = lives > item
		
func game_over():
	show_message("You Got Rocked!")
	await $Timer.timeout
	start_button.show()
	message.text = "Space Rocking!"
	message.show()
	HUD_Active = true
	
func _on_start_button_pressed():
	start_button.hide()
	start_game.emit()
	HUD_Active = false

func _on_timer_timeout():
	message.hide()
	message.text = ""
