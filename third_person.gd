extends CharacterBody3D

const JUMP_VELOCITY = 7.6

var animation_tree = null

var state_machine = null

var animstate = null

# カメラノード
var camera_node: Node3D
var EffecPos: Node3D

# 移動とカメラ回転の速度
var move_speed: float = 10.0
var camera_rotate_speed: float = 2
# 重力をノードのプロパティとして設定
var gravity = Vector3.DOWN * 9.8


# ジョイスティックのデッドゾーン
var deadzone: float = 0.2
var move_direction: Vector3 = Vector3.ZERO
var attack_flag = false;

# ジャンプ力と空中でのジャンプ可能回数
#var jump_force: float = 20.0
#var max_jumps: int = 2 # 2回ジャンプ可能
#var jumps_left: int = max_jumps

func _ready():
	camera_node = get_node("../Camera_Shaft")
	animation_tree = get_node("koishi01godot/Armature/AnimationTree")
	state_machine = animation_tree.get("parameters/playback")
	EffecPos = get_node("koishi01godot/EffecPos")
func _physics_process(delta: float) -> void:
	# ジョイスティックの入力を取得
	var joystick_left_input = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	var joystick_right_input = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)

	# デッドゾーンを適用
	joystick_left_input = Vector2.ZERO if joystick_left_input.length() < deadzone else joystick_left_input
	joystick_right_input = Vector2.ZERO if joystick_right_input.length() < deadzone else joystick_right_input
	var current_position = state_machine.get_current_play_position ( )
	animstate = state_machine.get_current_node() 
	# キャラクターの移動処理
	if joystick_left_input != Vector2.ZERO and is_on_floor():
		move_direction = camera_node.global_transform.basis * Vector3(joystick_left_input.x, 0, joystick_left_input.y).normalized()
		move_direction.y = 0 # Y軸の移動は無視（重力による落下のみ）
		# ジャンプ処理
		#jumps_left = max_jumps # 地面にいる場合はジャンプ回数をリセット
		#velocity += gravity * delta
		if move_direction != Vector3.ZERO:
			var corrected_direction = move_direction.rotated(Vector3.UP, PI)
			animstate = state_machine.get_current_node()
			if animstate != "run" and animstate != "attack":
				state_machine.travel("run")
			look_at(global_transform.origin + corrected_direction, Vector3.UP)
			if animstate != "attack":
				velocity = move_direction * move_speed + gravity * delta
	elif animstate != "jump" and is_on_floor() and animstate != "attack":
		animstate = state_machine.get_current_node()
		if animstate != "idle":
			state_machine.travel("idle")
		velocity = Vector3(0, velocity.y, 0)  + gravity * delta
	elif animstate == "jump" and current_position > 0.85:
		animstate = state_machine.get_current_node()
		if animstate != "falling":
			state_machine.travel("falling")
	else:
		velocity.y = velocity.y + gravity.y * delta
	#print(is_on_floor())
	#print(gravity)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		animstate = state_machine.get_current_node()
		if animstate != "jump":
			state_machine.travel("jump")
		var horizontal_jump = Vector3(move_direction.x, 0, move_direction.z).normalized()
		velocity += (horizontal_jump + Vector3.UP) * JUMP_VELOCITY
		#velocity += (move_direction.normalized() + Vector3.UP).normalized() * JUMP_VELOCITY 
	#print(move_direction)
	#print(Vector3.UP)
	#print(is_on_floor())
	#print(current_position)
	if !is_on_floor():
		animstate = state_machine.get_current_node()
		if animstate != "jump":
			state_machine.travel("falling")
	animstate = state_machine.get_current_node()
	if animstate == "attack" and current_position > 1.5333:
		state_machine.travel("idle")
	if Input.is_action_just_pressed("attack") and is_on_floor() and animstate != "jump" and animstate != "falling" and animstate != "attack":
		state_machine.travel("attack")
		attack_flag = true
	#print(current_position)
	if animstate == "attack":
		velocity = Vector3.ZERO
		if current_position > 0.8 and attack_flag:
			attack_flag = false
			var effect_resource = preload("res://effect/sword02.efkefc")
			var emitter = EffekseerEmitter3D.new()
			emitter.set_effect(effect_resource)
			emitter.transform.origin = EffecPos.transform.origin
			emitter.transform.basis = EffecPos.transform.basis
			emitter.play()
			add_child(emitter)			
	move_and_slide()

	# カメラの回転処理
	if joystick_right_input != Vector2.ZERO:
		camera_node.rotate_x(deg_to_rad(-joystick_right_input.y * camera_rotate_speed))
		camera_node.rotate_y(deg_to_rad(joystick_right_input.x * camera_rotate_speed))
	var camerarot = camera_node.transform.basis.get_euler()
	camera_node.transform.basis = Basis.from_euler(Vector3(camerarot.x,camerarot.y,0))
