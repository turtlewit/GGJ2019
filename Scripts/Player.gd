extends RigidBody2D

# Constants
const JUMP_BUTTON = "player_jump"
enum State {STATE_NO_INPUT, STATE_IN_GAME, STATE_NEAR_GIRL, STATE_DEAD}
enum Expression {EXPRESSION_NEUTRAL, EXPRESSION_SCARED, EXPRESSION_OUCH}

# Exports
export var jump_force = 100
export var right_move_speed = 100
export var right_move_force = 100
export var reset_level_time = 2
export(State) var state = State.STATE_IN_GAME

# Variables
export(Expression) var expression = Expression.EXPRESSION_NEUTRAL
var gamepad_pressed = false
var death_timer : float = 0

onready var sprite = $Sprite
onready var collider = $CollisionShape2D
onready var string_root = $Node2D/String_Root 
onready var animator = sprite.get_node("AnimationPlayer")
#onready var area_danger = $AreaDanger

var enemies_in_view = 0

# Signals
signal on_player_death

# Overrides
func _ready():
	Controller.set_player(self)
	if expression == Expression.EXPRESSION_NEUTRAL:
		animator.play("idle")
	elif expression == Expression.EXPRESSION_SCARED:
		animator.play("scared_idle")

func _process(delta):
	match state:
		State.STATE_IN_GAME:
			#poll_for_input()
			if enemies_in_view > 0 and expression != Expression.EXPRESSION_SCARED:
				expression = Expression.EXPRESSION_SCARED
			if enemies_in_view == 0 and expression != Expression.EXPRESSION_NEUTRAL:
				expression = Expression.EXPRESSION_NEUTRAL
			if expression == Expression.EXPRESSION_SCARED:
				if animator.current_animation == 'idle':
					animator.play('scared_idle')
			elif expression == Expression.EXPRESSION_NEUTRAL:
				if animator.current_animation == 'scared_idle':
					animator.play('idle')
		State.STATE_DEAD:
			death_timer += delta 
			if death_timer >= reset_level_time:
				death_timer = 0
				Controller.reset()


func _physics_process(delta):
	match state:
		State.STATE_IN_GAME:
			move_right()
		State.STATE_NEAR_GIRL:
			linear_velocity.x = lerp(linear_velocity.x, 0, 2 * delta)

func _on_Player_body_entered(body):
	if "Enemy" in body.get_groups():
		die()

func _on_AreaDanger_body_entered(body):
	if "Enemy" in body.get_groups() and not "Trees" in body.get_groups():
		enemies_in_view += 1


# Functions
func jump():
	$SoundJump.play()
	if expression == Expression.EXPRESSION_NEUTRAL:
		animator.play("jump")
	elif expression == Expression.EXPRESSION_SCARED:
		animator.play("scared_jump")
	linear_velocity.y = jump_force

func move_right():
	if linear_velocity.x <= right_move_speed:
		#apply_impulse(global_position, Vector2(right_move_force * delta, 0))
		linear_velocity.x = right_move_force

func poll_for_input():
	if Input.is_action_just_pressed(JUMP_BUTTON):
		jump()

func die():
	$SoundPop.play()
	state = State.STATE_DEAD
	emit_signal("on_player_death")

	$PartsPop.set_emitting(true)
	set_deferred("mode", MODE_STATIC)
	sprite.visible = false
	collider.set_deferred("disabled", true)
	string_root.set_deferred("mode", MODE_RIGID)
	string_root.gravity_scale = 1

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'jump' or anim_name == 'scared_jump':
		if expression == Expression.EXPRESSION_NEUTRAL:
			animator.play("idle")
		elif expression == Expression.EXPRESSION_SCARED:
			animator.play("scared_idle")


func _on_AreaDanger_body_exited(body):
	if "Enemy" in body.get_groups() and not "Trees" in body.get_groups():
		enemies_in_view -= 1

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.is_pressed() and state in [State.STATE_IN_GAME, State.STATE_NEAR_GIRL]:
			jump()
	if ev is InputEventKey:
		if ev.scancode == KEY_ESCAPE:
			Controller.change_scene("res://Scenes/TitleScreen.tscn")
		else:
			if ev.pressed and not ev.echo:
				if state == State.STATE_IN_GAME or state == State.STATE_NEAR_GIRL:
					jump()
				#elif state != State.STATE_NO_INPUT:
					#Controller.reset()
	if ev is InputEventJoypadButton:
		if ev.button_index == JOY_START:
			Controller.change_scene("res://Scenes/TitleScreen.tscn")
		else:
			if ev.pressed and not gamepad_pressed:
				if state == State.STATE_IN_GAME or state == State.STATE_NEAR_GIRL:
					gamepad_pressed = true
					jump()
				#elif state != State.STATE_NO_INPUT:
					#Controller.reset()
		if not ev.pressed:
			gamepad_pressed = false
