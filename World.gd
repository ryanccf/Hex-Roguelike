extends Node2D


func _input(event):
	if event.is_action_released("leftclick"):
		var path = $TileMap.PathFind($Player.position,get_global_mouse_position())
		if path: # return true if path exists
			$Player.path = path
			$Player.state = $Player.Move
