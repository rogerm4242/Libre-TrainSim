extends Spatial

var player: LTSPlayer
onready var wagon: Spatial = get_parent()

export (AudioStream) var engine_idle: AudioStream = preload("res://Resources/Sounds/EngineIdle.ogg")
export (AudioStream) var acceleration_1: AudioStream = preload("res://Resources/Sounds/Acceleration5.ogg")
export (AudioStream) var acceleration_2: AudioStream = preload("res://Resources/Sounds/Acceleration6.ogg")
export (AudioStream) var acceleration_transition: AudioStream = preload("res://Resources/Sounds/AccelerationTransition2.ogg")

export (float) var acceleration_transititon_at_speed: float = 10
export (float) var acceleration_transition_length_in_ms: float = 1200
export (float) var acceleration_transition_1_delta_length_in_ms: float = 400
export (float) var acceleration_transition_2_delta_length_in_ms: float = 400

var acceleration_sound_index = 1 # 0: Transistion from 1 to 2. 1: accleration1. 2: acceleration2

func _ready() -> void:
	$Idle.stream = engine_idle
	$Acceleration1.stream = acceleration_1
	$Acceleration2.stream = acceleration_2
	$AccelerationTransition.stream = acceleration_transition

	$Idle.unit_db = -50
	$Acceleration1.unit_db = -50
	$Acceleration2.unit_db = -50

	$AccelerationTransition.stream.loop = false


var acceleration_timer: float = 0.0
func _process(delta) -> void:
	if player == null:
		player = get_parent().player
		return

	if Input.is_key_pressed(KEY_K):
		$AccelerationTransition.play(0)

	## Idle Engine:
	if player.engine:
		$Idle.unit_db = lerp(0, $Idle.unit_db, delta*2)
	else:
		$Idle.unit_db = lerp(-50, $Idle.unit_db, delta*2)

	## Accleration
	### Main Volume of accleration
	var sollAcceleration = -50
	if player.engine and player.speed != 0:
		if  Math.speedToKmH(player.speed) < 60:
			sollAcceleration = -30 + abs(player.command*30)
		else:
			sollAcceleration = -30 + abs(player.command*30) - (Math.speedToKmH(player.speed)-60)/10.0
#		if player.command < 0:
#			sollAcceleration = sollAcceleration - 10.0

	### Control acceleration_sound_index
	var speed = Math.speedToKmH(player.speed)
	if speed > 10 and acceleration_sound_index == 1:
		acceleration_sound_index = 0
		acceleration_timer = 0.0
	if speed < 9 and acceleration_sound_index == 2:
		acceleration_sound_index = 1

	### Acceleration Mixing:
	if acceleration_sound_index == 1:
		$Acceleration1.unit_db = lerp(0, $Acceleration1.unit_db, delta*2)
		$Acceleration2.unit_db = lerp(-50, $Acceleration2.unit_db, delta*2)
	if acceleration_sound_index == 2:
		$Acceleration1.unit_db = lerp(-50, $Acceleration1.unit_db, delta*2)
		$Acceleration2.unit_db = lerp(0, $Acceleration2.unit_db, delta*2)
	if acceleration_sound_index == 0: # Transistion from 1 to 2:
		if acceleration_timer == 0.0:
			$AccelerationTransition.play(0)
		if acceleration_timer > acceleration_transition_1_delta_length_in_ms/1000.0: # Set acceleration 1 down
			$Acceleration1.unit_db = lerp(-50, $Acceleration1.unit_db, delta*4)
			$Acceleration2.unit_db = lerp(-50, $Acceleration2.unit_db, delta*4) # just to be safe, that this is off. (normally that should be the case)
		if acceleration_timer > acceleration_transition_length_in_ms/1000.0 - acceleration_transition_2_delta_length_in_ms/1000.0: # Set acceleration 2 uo
			$Acceleration2.unit_db = lerp(0, $Acceleration2.unit_db, delta*4)
		if acceleration_timer > acceleration_transition_length_in_ms/1000.0 + acceleration_transition_2_delta_length_in_ms/1000.0:
			acceleration_sound_index = 2
		acceleration_timer += delta

	$Acceleration1.unit_db = min(lerp(sollAcceleration, $Acceleration1.unit_db, delta*4), $Acceleration1.unit_db)
	$Acceleration2.unit_db = min(sollAcceleration, $Acceleration2.unit_db)
	$AccelerationTransition.unit_db = sollAcceleration

	### Pitching:
	$Acceleration2.pitch_scale = 1.0 + (Math.speedToKmH(player.speed)-10.0)/300.0

	$Idle.stream_paused = not wagon.visible or get_tree().paused
	$Acceleration1.stream_paused = not wagon.visible or get_tree().paused
	$Acceleration2.stream_paused = not wagon.visible or get_tree().paused
	$AccelerationTransition.stream_paused = not wagon.visible or get_tree().paused

#
#
### sollCurveSound:
#	if wagon.currentRail.radius == 0 or Math.speedToKmH(player.speed) < 35:
#		sollCurveSound = -50
#	else:
#		sollCurveSound = -25.0 + (Math.speedToKmH(player.speed)/80.0 * abs(300.0/wagon.currentRail.radius))*5
#
##	print(sollCurveSound)
#	$CurveSound.unit_db = lerp(sollCurveSound, $CurveSound.unit_db, delta)
##	$CurveSound.unit_db = 10
#
#	## Drive Sound:
#	$DriveSound.pitch_scale = 0.5 + Math.speedToKmH(player.speed)/200.0
#	var driveSoundDb = -20.0 + Math.speedToKmH(player.speed)/2.0
#	if driveSoundDb > 10:
#		driveSoundDb = 10
#	if player.speed == 0:
#		driveSoundDb = -50.0
#	$DriveSound.unit_db = lerp(driveSoundDb, $DriveSound.unit_db, delta)
#
#	var sollBreakSound = -50.0
#	if not (player.speed >= 5 or player.command >= 0 or player.speed == 0):
#		sollBreakSound = -20.0 -player.command * 5.0/player.speed
#		if sollBreakSound > 10:
#			sollBreakSound = 10
#	$BrakeSound.unit_db = lerp(sollBreakSound, $BrakeSound.unit_db, delta)
