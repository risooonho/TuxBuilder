extends KinematicBody2D

# Instant speed when starting walk
const WALK_ADD = 120.0
# Speed Tux accelerates per second when walking
const WALK_ACCEL = 350.0
# Speed Tux accelerates per second when running
const RUN_ACCEL = 400.0

# Speed you need to start running
const WALK_MAX = 230.0
# Maximum horizontal speed
const RUN_MAX = 320.0
# Backflip horizontal speed
const BACKFLIP_SPEED = -128

# Acceleration when holding the opposite direction
const TURN_ACCEL = 900.0
# Speed which Tux slows down
const SKID_ACCEL = 950.0
# Speed which Tux skids
const FRICTION = 0.93
# Speed Tux slows down skidding
const SKID_TIME = 12

# Jump velocity
const JUMP_POWER = 580
# Running Jump / Backflip velocity
const RUNJUMP_POWER = 640
# Gravity
const GRAVITY = 20.0

const FLOOR = Vector2(0, -1)

const LEDGE_JUMP = 3 # Amount of frames Tux can still jump after falling off a ledge

var velocity = Vector2()
var on_ground = 0 # Frames Tux has been in air (0 if grounded)
var jumpheld = 0 # Time the jump key has been held
var running = 0 # If horizontal speed is higher than walk max
var skid = 0 # Time skidding
var ducking = false # Ducking
var backflip = 0 # Backflipping
var backflip_rotation = 0 # Backflip rotation

var state = "large" # Tux's power-up state

#=============================================================================
# PHYSICS

func _physics_process(delta):
	
	# Horizontal movement
	if Input.is_action_pressed("move_right") and (ducking == false or on_ground != 0) and backflip == 0:
		$Animation.flip_h = false
		if skid <= 0 and velocity.x >= 0:
			if velocity.x == 0:
				velocity.x += WALK_ADD
			if running == 1:
					velocity.x += RUN_ACCEL / 60
			else: velocity.x += WALK_ACCEL / 60
			
			# Skidding and air turning
		if velocity.x < 0:
			if on_ground == 0:
				velocity.x += SKID_ACCEL / 60
				if skid == 0 and velocity.x <= -WALK_MAX:
					skid = SKID_TIME
			else: velocity.x += TURN_ACCEL / 60
		
	else: if Input.is_action_pressed("move_left") and (ducking == false or on_ground != 0) and backflip == 0:
		$Animation.flip_h = true
		if skid <= 0 and velocity.x <= 0:
			if velocity.x == 0:
				velocity.x -= WALK_ADD
			if running == 1:
					velocity.x -= RUN_ACCEL / 60
			else: velocity.x -= WALK_ACCEL / 60
			
		# Skidding and air turning
		if velocity.x > 0:
			if on_ground == 0:
				velocity.x -= SKID_ACCEL / 60
				if skid == 0 and velocity.x >= WALK_MAX:
					skid = SKID_TIME
			else: velocity.x -= TURN_ACCEL / 60
		
	else: if backflip == 0: velocity.x *= FRICTION
	
	# Speedcap
	if velocity.x >= RUN_MAX:
		velocity.x = RUN_MAX
	if velocity.x <= -RUN_MAX:
		velocity.x = -RUN_MAX
	
	# Don't slide on the ground
	if abs(velocity.x) < 50:
		velocity.x = 0
	
	# Skid
	if skid > 0:
		if skid == SKID_TIME:
			$SFX/Skid.play()
		skid -= 1
	else:
		skid = 0
	
	# Gravity
	velocity.y += GRAVITY
	
	velocity = move_and_slide(velocity, FLOOR)
	
	# Floor check
	if is_on_floor():
		on_ground = 0
		if backflip == 1:
			backflip = 0
			velocity.x = 0
	else:
		on_ground += 1
	
	# Running
	if abs(velocity.x) > WALK_MAX:
		running = 1
	else: running = 0
	
	# Ducking
	if not Input.is_action_pressed("duck"):
		ducking = false
	if on_ground == 0 and Input.is_action_pressed("duck") or ($StandWindow.is_colliding() == true and state != "small"):
			ducking = true
	
	# Jump buffering
	if Input.is_action_pressed("jump"):
			jumpheld += 1
	else:
			jumpheld = 0
	
	# Jumping
	if Input.is_action_pressed("jump"):
		if jumpheld <= 15:
			if on_ground <= LEDGE_JUMP:
				if running == 1 or (state != "small" and Input.is_action_pressed("duck") == true and Input.is_action_pressed("move_left") == false and Input.is_action_pressed("move_right") == false):
					velocity.y = -RUNJUMP_POWER
					if ducking == true:
						backflip = 1
						backflip_rotation = 0
						$SFX/Flip.play()
				else: 
					velocity.y = -JUMP_POWER
				if state == "small":
					$SFX/Jump.play()
				else: $SFX/BigJump.play()
				on_ground = LEDGE_JUMP + 1
			jumpheld = 16
	# Jump cancelling
	if on_ground != 0 and not Input.is_action_pressed("jump") and backflip == 0:
		if velocity.y < 0:
			velocity.y *= 0.5
	
	# Backflip speed and rotation
	$Animation.rotation_degrees = 0
	if backflip == 1:
		if $Animation.flip_h == false:
			velocity.x = BACKFLIP_SPEED
			backflip_rotation -= 15
		else:
			velocity.x = -BACKFLIP_SPEED
			backflip_rotation += 15
		$Animation.rotation_degrees = backflip_rotation
	
	# Animations
	if backflip == 1:
		$Animation.play("backflip")
	elif ducking == true:
		$Animation.play("duck")
	else:
		if on_ground == 0:
			if skid > 0:
				$Animation.play("skid")
			else: if abs(velocity.x) >= 20:
				$Animation.play("walk")
			else: $Animation.play("idle")
		else: $Animation.play("jump")
		
	if ducking == true or state == "small":
		$BigHitbox.disabled = true
		$SmallHitbox.disabled = false
	else:
		$BigHitbox.disabled = false
		$SmallHitbox.disabled = true