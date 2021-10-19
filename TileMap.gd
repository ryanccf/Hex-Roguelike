extends TileMap

		### Useful things
#	print(cell_size)
#	print(tile_set.tile_get_texture(0).get_size())
#	print(get_used_cells())
#	print(get_used_cells_by_id(0))
#	print(get_cellv(Vector2(0,0)))

var FinalPath = []
var AlternativeRoutes = []
var AdjacentAdjustedCell = [Vector2(1,0),Vector2(0,1), Vector2(1,-1), Vector2(0,-1), Vector2(-1,0), Vector2(-1,1)]
onready var CentreHex = tile_set.tile_get_texture(0).get_size()/2
const OverLayTile = preload("res://OverLayTile.tscn")

func _ready():
	position -= CentreHex

func LayTile(Cell):
	var OverLay = OverLayTile.instance()
	OverLay.position = map_to_world(Cell)
	OverLay.modulate = Color(0.5,0.5,0.5,0.5)
	add_child(OverLay)

func FindCell(Mousepos):
	var LeftHand = true
	var Cell = world_to_map(Mousepos)
	var DangerRows = tile_set.tile_get_texture(0).get_size().y - cell_size.y
	var LocalMousepos = Mousepos - map_to_world(Cell)
	if LocalMousepos.y < DangerRows:
		var TopMiddleofCell = cell_size.x/2
		var GradientofDangerLine = DangerRows/TopMiddleofCell
		var XPostoCheck = LocalMousepos.x
		if XPostoCheck > TopMiddleofCell:
			XPostoCheck = cell_size.x - XPostoCheck
			LeftHand = false
		# y > kx
		if (DangerRows - LocalMousepos.y) > GradientofDangerLine*XPostoCheck: # we have the wrong cell
			if LeftHand:
				if fmod(Cell.y,2) == 0: # on even row
					Cell += Vector2(-1,-1)
				else:
					Cell += Vector2(0,-1)
			else:
				if fmod(Cell.y,2) == 0: # on even row
					Cell += Vector2(0,-1)
				else:
					Cell += Vector2(1,-1)
	return Cell


func AdjustCell(Input):
	Input.x -= floor(Input.y/2)
	return Input

func UnAdjustCell(Input):
	Input.x += floor(Input.y/2)
	return Input

func DistanceMetric(startpos,endpos):
	var Dist = 0
	var dx = endpos.x - startpos.x
	var dy = endpos.y - startpos.y
	if sign(dx) == sign(dy):
		Dist = abs(dx + dy)
	else:
		Dist = max(abs(dx),abs(dy))
	return Dist

func PathFind(Currentpos,Mousepos):
	for _i in range(get_child_count()):
		remove_child(get_child(0))
	Mousepos += CentreHex
	var Cell = FindCell(Mousepos)
	Currentpos += CentreHex
	Currentpos = FindCell(Currentpos)
	if get_cellv(Cell) != 1:
		var AdjustedCell = AdjustCell(Cell)
		var DisttoGoal = DistanceMetric(AdjustCell(Currentpos),AdjustedCell)
		var ShortestRoute = DisttoGoal + 1 # +1 for the start square
		var ListofCellsChecked = [Currentpos]
		FinalPath = [Currentpos]
		AlternativeRoutes = [Vector2()]
		var AlternativeRoutesCheck = false
		var Countback = -2
		var SkippedCell = []
		while DisttoGoal > 0:
			Currentpos = AdjustCell(Currentpos)
			var ClosestSquare = FindNextStep(Currentpos, AdjustedCell, ListofCellsChecked)
			if ClosestSquare.x != INF:
				var NextPath = UnAdjustCell(Currentpos + AdjacentAdjustedCell[ClosestSquare.y])
				if ClosestSquare.z != -1:
					AlternativeRoutes.append(UnAdjustCell(Currentpos + AdjacentAdjustedCell[ClosestSquare.z]))
					AlternativeRoutesCheck = true
				else:
					AlternativeRoutes.append(Vector2())
				DisttoGoal = ClosestSquare.x
				Currentpos = NextPath
				ListofCellsChecked.append(Currentpos)
				FinalPath.append(Currentpos)
				Countback = -2
			else:
				Currentpos = ListofCellsChecked[Countback]
				Countback -= 1
				SkippedCell.append(FinalPath[-1])
				FinalPath.remove(FinalPath.size()-1)#
				AlternativeRoutes.remove(AlternativeRoutes.size()-1)
				if FinalPath.size() == 0:
					break
		
		ShortcutCheck()
		
		if AlternativeRoutesCheck && ShortestRoute != FinalPath.size():
			var CheckForAltRoutes = true
			while CheckForAltRoutes:
				CheckForAltRoutes = false
				for i in range(AlternativeRoutes.size()-2):
					if AlternativeRoutes[i] != Vector2():
						var AltListofTilesChecked = FinalPath.slice(0,i+1,1,false)
						var AltListofAltRoutes = AlternativeRoutes.slice(0,i-1,1,false)
						var TilestoRemove = 2
						for j in range(SkippedCell.size()):
							AltListofTilesChecked.append(SkippedCell[j])
							TilestoRemove += 1
						Currentpos = AltListofTilesChecked[i-1]
						DisttoGoal = DistanceMetric(AdjustCell(Currentpos),AdjustedCell)
						var OldLength = FinalPath.size()
						var NewLength = i
						while DisttoGoal > 0 && NewLength < OldLength - 1:
							Currentpos = AdjustCell(Currentpos)
							var ClosestSquare = FindNextStep(Currentpos, AdjustedCell, AltListofTilesChecked)
							if ClosestSquare.x != INF:
								var NextPath = UnAdjustCell(Currentpos + AdjacentAdjustedCell[ClosestSquare.y])
								if ClosestSquare.z != -1:
									AltListofAltRoutes.append(UnAdjustCell(Currentpos + AdjacentAdjustedCell[ClosestSquare.z]))
								else:
									AltListofAltRoutes.append(Vector2())
								DisttoGoal = ClosestSquare.x
								Currentpos = NextPath
								AltListofTilesChecked.append(Currentpos)
								NewLength += 1
							else:
								break
						if DisttoGoal == 0: # we found a new route
							CheckForAltRoutes = true
							for _i in range(TilestoRemove):
								AltListofTilesChecked.remove(i)
							AlternativeRoutes = AltListofAltRoutes
							FinalPath = AltListofTilesChecked
							ShortcutCheck()
							break
		var path = []
		for i in range(FinalPath.size()):
			LayTile(FinalPath[i])
			path.append(map_to_world(FinalPath[i]))
		return path

func ShortcutCheck():
	var ii = 0
	while true:
		if FinalPath.size() - ii <= 2:
			break
		else:
			if DistanceMetric(AdjustCell(FinalPath[ii]),AdjustCell(FinalPath[ii+2])) == 1:
				FinalPath.remove(ii+1)
				AlternativeRoutes.remove(ii+1)
			else:
				ii += 1

func FindNextStep(Currentpos, TargetPos, ListofCellsChecked):
	var ClosestSquare = Vector3(INF,INF,-1)
	var AlreadyChecked = false
	var TempDist = INF
	var NextPos = Vector2()
	var DistFromCell = 0
	for i in range(AdjacentAdjustedCell.size()):
		NextPos = Currentpos + AdjacentAdjustedCell[i]
		var NextPosUnAdjusted = UnAdjustCell(NextPos)
		for j in range(ListofCellsChecked.size()):
			if NextPosUnAdjusted == ListofCellsChecked[j]:
				AlreadyChecked = true
				break
		if get_cellv(NextPosUnAdjusted) == 1: # is an obstacle
			AlreadyChecked = true
		if AlreadyChecked == true:
			AlreadyChecked = false
		else:
			DistFromCell = DistanceMetric(NextPos,TargetPos)
			if DistFromCell < ClosestSquare.x:
				ClosestSquare.x = DistFromCell
				ClosestSquare.y = i
			elif DistFromCell == ClosestSquare.x:
				TempDist = DistFromCell
				ClosestSquare.z = i
	if ClosestSquare.z != -1:
		if TempDist != ClosestSquare.x:
			ClosestSquare.z = -1
	return ClosestSquare
