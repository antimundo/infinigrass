extends Node2D

signal instantiated

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

func _ready() -> void:
	$Sprite2D.texture = sprite_on_idle

func _process(delta):
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
			instantiated.emit()
		else:
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
					get_viewport().set_input_as_handled()
			LaborStates.DONE:
				ResourcesManager.add_resource(amount, resource)
				state = LaborStates.IDLE
				$Sprite2D.texture = sprite_on_idle
				$AnimatedSprite2D.play("idle")
				$CPUParticles2D.emitting = true
				get_viewport().set_input_as_handled()

func is_mouse_inside():
	return $Sprite2D.get_rect().has_point(to_local(get_global_mouse_position()))

func is_left_click(event: InputEvent):
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed

func _on_timer_timeout() -> void:
	state = LaborStates.DONE
	$Sprite2D.texture = sprite_on_done
	$AnimatedSprite2D.play("done")

func can_be_placed():
	if position.x > 775 or position.x < 25\
		or position.y > 620 or position.y < 30:
		return false
	return true
