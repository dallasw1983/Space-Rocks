extends Control

func _ready():
	$MarginContainer/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Defence.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Attack.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Movement.hide()

signal DefenceUpgrade
signal AttackUpgrade
signal MovementUpgrade

func _on_defence_pressed():
	DefenceUpgrade.emit()

func _on_attack_pressed():
	AttackUpgrade.emit()

func _on_movement_pressed():
	MovementUpgrade.emit()

func show_upgrade_ui():
	$MarginContainer/VBoxContainer/Title.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/Title.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/Title.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/Title.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/HBoxContainer/Description.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/HBoxContainer/Description.show()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/HBoxContainer/Description.show()
	$MarginContainer/VBoxContainer/ButtonContainer/Defence.show()
	$MarginContainer/VBoxContainer/ButtonContainer/Attack.show()
	$MarginContainer/VBoxContainer/ButtonContainer/Movement.show()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func hide_upgrade_ui():
	$MarginContainer/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/Title.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Attack/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Defence/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/HBoxContainer/Movement/VBoxContainer/HBoxContainer/Description.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Defence.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Attack.hide()
	$MarginContainer/VBoxContainer/ButtonContainer/Movement.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
