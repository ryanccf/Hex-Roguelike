extends Node2D

onready var _animated_sprite = $AnimatedSprite

var Speed = 600
var velocity = Vector2()
var target_point = Vector2()
var path = []

enum{
	Idle
	Move
}
var state = Idle

func _physics_process(delta):
	match state:
		Idle:
			_animated_sprite.play("Stop")
		Move:
			var arrivednextpoint = move_to(target_point,delta)
			_animated_sprite.play("Walk")
			if arrivednextpoint:
				path.remove(0)
				if len(path) == 0:
					state = Idle
				else:
					target_point = path[0]

func move_to(target_pos,delta):
	var Mass = 5
	var ArriveDistance = 10
	var target_velocity = (target_pos - position).normalized() * Speed
	var steering = target_velocity - velocity
	velocity += steering/Mass
	position += velocity*delta
	rotation = velocity.angle() + deg2rad(90)
	return position.distance_to(target_pos) < ArriveDistance
