extends CharacterBody2D

const MOTION_SPEED = 150
const STOP_DISTANCE = 5
const TAN30DEG = tan(deg_to_rad(30))

var tilemap : TileMap
var fogTileMap : TileMap
var Indicator : Sprite2D
var astar = AStar2D.new()
var path = []
var current_path_index = 0
var pending_destination_cell = null
var previous_destination = Vector2i(0,0)
var has_pending_click = false
var isExplored = TileData

# Define your tile IDs clearly:
const TILE_WATER_ID = 32  # Replace with your actual TileWater Source ID

func _ready():
	tilemap = get_parent().get_node("TileMap")
	fogTileMap = get_parent().get_node("FogTileMap")
	Indicator = get_parent().get_node("Indicator")
	setup_astar()
	update_tiles_around(global_position)

func is_path_clear(start_pos: Vector2, end_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func setup_astar():
	astar.clear()
	var used_cells = tilemap.get_used_cells(0)

	for cell in used_cells:
		var tile_id = tilemap.get_cell_source_id(0, cell)
		if tile_id != TILE_WATER_ID and tile_id != -1:
			astar.add_point(cell_to_id(cell), tilemap.map_to_local(cell))

	# Connect points clearly
	for cell in used_cells:
		var tile_id = tilemap.get_cell_source_id(0, cell)
		if tile_id == TILE_WATER_ID or tile_id == -1:
			continue

		var neighbors = tilemap.get_surrounding_cells(cell)
		for neighbor in neighbors:
			if astar.has_point(cell_to_id(neighbor)):
				astar.connect_points(cell_to_id(cell), cell_to_id(neighbor))

func cell_to_id(cell: Vector2i) -> int:
	return int(cell.x) + int(cell.y) * 1000

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pending_destination_cell = tilemap.local_to_map(get_global_mouse_position())
		
		isExplored = fogTileMap.get_cell_tile_data(0, pending_destination_cell)
		var tilemap_tile_id = tilemap.get_cell_source_id(0, pending_destination_cell)
		if isExplored != null:
			if previous_destination != pending_destination_cell:
				has_pending_click = true
				previous_destination = pending_destination_cell
		else:
			if tilemap_tile_id != TILE_WATER_ID and tilemap_tile_id != -1:
				if previous_destination != pending_destination_cell:
					has_pending_click = true
					previous_destination = pending_destination_cell

func _physics_process(delta):
	if has_pending_click:
		has_pending_click = false  # Reset flag after processing click.
		
		var destination_cell = pending_destination_cell
		var start_cell = tilemap.local_to_map(global_position)
		
		var fog_tile_data = fogTileMap.get_cell_tile_data(0, destination_cell)
		var tilemap_tile_id = tilemap.get_cell_source_id(0, destination_cell)

		var final_destination_cell = destination_cell
		
		if fog_tile_data != null:
			# Tile is hidden: Find nearest reachable non-water tile.
			final_destination_cell = find_nearest_reachable_tile(destination_cell)
		elif tilemap_tile_id == TILE_WATER_ID or tilemap_tile_id == -1:
			# Tile is visible but water or invalid; don't move.
			path = []
			Indicator.visible = false
			return

		if final_destination_cell and astar.has_point(cell_to_id(final_destination_cell)):
			path = astar.get_point_path(cell_to_id(start_cell), cell_to_id(final_destination_cell))
			current_path_index = 0
			
			# Correctly position indicator at tile center
			var tile_data = tilemap.get_cell_tile_data(0, destination_cell)
			if tile_data:
				Indicator.global_position = tilemap.map_to_local(destination_cell) + Vector2(tile_data.texture_origin)
				Indicator.visible = true
		else:
			path = []
			Indicator.visible = false

	if current_path_index < path.size():
		var target_position = path[current_path_index]
		var direction = target_position - global_position

		if direction.length() < STOP_DISTANCE:
			current_path_index += 1
		else:
			direction.y *= TAN30DEG
			velocity = direction.normalized() * MOTION_SPEED
			move_and_slide()

		update_tiles_around(global_position)
	else:
		velocity = Vector2.ZERO
		Indicator.visible = false
		move_and_slide()

# Helper function: Finds the nearest reachable non-water tile around the clicked tile.
func find_nearest_reachable_tile(cell: Vector2i):
	var queue = [cell]
	var visited = {cell: true}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		var tile_id = tilemap.get_cell_source_id(0, current)
		if tile_id != TILE_WATER_ID and tile_id != -1 and astar.has_point(cell_to_id(current)):
			return current  # Found nearest reachable non-water tile
		
		for neighbor in tilemap.get_surrounding_cells(current):
			if neighbor not in visited:
				visited[neighbor] = true
				queue.append(neighbor)
	
	return null  # No reachable tile found

func update_tiles_around(position):
	var tile_pos = tilemap.local_to_map(position)

	reveal_fog_tile(tile_pos)
	for neighbor in tilemap.get_surrounding_cells(tile_pos):
		reveal_fog_tile(neighbor)

func reveal_fog_tile(tile_pos):
	fogTileMap.erase_cell(0, tile_pos)
