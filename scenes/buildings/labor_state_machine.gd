extends Node2D

signal instantiated
signal cancel_instantiation

@export_category("Visuals")
@export var sprite_on_idle: Texture2D
@export var sprite_on_working: Texture2D
@export var sprite_on_done: Texture2D
@export_category("Resources generated")
@export var resource: ResourcesManager.GameResourceType
@export var amount: int = 1
@export var time_until_done := 1.0
@export_category("Resources consumed by recharge")
@export var recharge_resource: ResourcesManager.GameResourceType
@export var recharge_amount: int = 1
var is_instantiated := false

enum LaborStates { IDLE, WORKING, DONE}
var state: LaborStates = LaborStates.IDLE
var need_tween: Tween

var shader_script

func _ready() -> void:
	$Sprite2D.texture = sprite_on_idle

func _process(_delta):
	if !is_instantiated:
		var mouse_position = get_viewport().get_mouse_position()
		position = mouse_position
		modulate = Color("ffffff")
		if !can_be_placed():
			modulate = Color("ffa092")

func _input(event: InputEvent) -> void:
	if !is_instantiated and Input.is_action_just_released("click"):
		if can_be_placed():
			is_instantiated = true
			self.modulate = Color("ffffff")
			top_level = false
			z_index = 0
			var shader = ShaderMaterial.new()
			shader.shader = shader_script
			$AnimatedSprite2D.material = shader
			
			instantiated.emit()
			$SpawnSound.play(0)
		else:
			cancel_instantiation.emit()
			queue_free()
	if is_left_click(event) and is_mouse_inside():
		match state:
			LaborStates.IDLE:
				if ResourcesManager.get_resource_quantity(recharge_resource) >= recharge_amount:
					ResourcesManager.subtract_resource(recharge_amount, recharge_resource)
					state = LaborStates.WORKING
					$Timer.start(time_until_done)
					$Sprite2D.texture = sprite_on_working
					$AnimatedSprite2D.play("working")
					hide_need()
					$StartProcessingSound.play(0)
					get_viewport().set_input_as_handled()
				else:
					ResourcesManager.not_enough.emit(recharge_resource)
			LaborStates.DONE:
				ResourcesManager.add_resource(amount, resource)
				state = LaborStates.IDLE
				$Sprite2D.texture = sprite_on_idle
				$AnimatedSprite2D.play("idle")
				$CPUParticles2D.emitting = true
				show_need()
				$CollectResourceSound.play(0)
				$AnimatedSprite2D/AnimationPlayer.stop()
				$AnimatedSprite2D.material.set_shader_parameter("enabled", false)
				get_viewport().set_input_as_handled()

func is_mouse_inside():
	return $Sprite2D.get_rect().has_point(to_local(get_global_mouse_position()))

func is_left_click(event: InputEvent):
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed

func _on_timer_timeout() -> void:
	state = LaborStates.DONE
	$Sprite2D.texture = sprite_on_done
	$AnimatedSprite2D.play("done")
	$FinishedSound.play(0)
	$AnimatedSprite2D.material.set_shader_parameter("enabled", true)
	$AnimatedSprite2D/AnimationPlayer.play("outline_focus")

func can_be_placed():
	if position.x > 775 or position.x < 25\
		or position.y > 620 or position.y < 30:
		return false
	return true

func show_need():
	await get_tree().create_timer(.35).timeout
	if state != LaborStates.IDLE:
		return
	if need_tween != null:
		need_tween.kill()
	need_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	need_tween.tween_property($Need, "scale", Vector2(1, 1), 1)

func hide_need():
	if need_tween != null:
		need_tween.kill()
	need_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	need_tween.tween_property($Need, "scale", Vector2(0, 0), .1)
