extends RefCounted
## Soldiers on each rank keep their horizontal order while responding to threats.

const Actor := preload("res://scripts/survivor/actor.gd")
const Field := preload("res://scripts/survivor/battlefield.gd")
const ROWS := [335.0, 425.0, 515.0]
const SOCKETS := [354.0, 428.0, 502.0, 603.0, 677.0, 778.0, 852.0, 926.0]
const GAP := 74.0
const LEFT := 342.0
const RIGHT := 938.0
const REVIEW_SECONDS := 1.15


static func pressure(enemies: Array[Actor]) -> Array[float]:
	var values: Array[float] = [0.35, 0.45, 0.35]
	for foe in enemies:
		if foe.hp <= 0:
			continue
		var progress := clampf(foe.position.y / Field.REAR_LINE_Y, 0.0, 1.0)
		var strength := 0.6 + 2.0 * progress
		if foe.kind == "boss":
			strength += 3.0
		values[foe.enemy_lane] += strength
	return values


static func arrival(row: int, army: Array[Actor], threats: Array[float]) -> Vector2:
	var preferred: float = Field.LANES[threats.find(threats.max())]
	var soldiers := _rank(army, row)
	var count := soldiers.size()
	var best := INF
	var chosen := preferred
	var positions: Array[float] = []
	for index in count + 1:
		# Reserve enough space for the troops on both sides of the arrival.
		var x := clampf(preferred, LEFT + index * GAP, RIGHT - (count - index) * GAP)
		var open_left := LEFT if index == 0 else soldiers[index - 1].position.x + GAP
		var open_right := RIGHT if index == count else soldiers[index].position.x - GAP
		if open_left <= open_right:
			x = clampf(preferred, open_left, open_right)
		var candidate: Array[float] = []
		var score := absf(x - preferred)
		for i in count:
			var current := soldiers[i].position.x
			var next := minf(current, x - (index - i) * GAP) if i < index else (
				maxf(current, x + (i - index + 1) * GAP))
			candidate.append(next)
			score += 2.0 * absf(next - current)
		if score < best:
			best = score
			chosen = x
			positions = candidate
	# Hold this rank until the next review so old paths cannot cross the recruit.
	for i in count:
		soldiers[i].position.x = positions[i]
		soldiers[i].goal_x = positions[i]
	return Vector2(chosen, ROWS[row])


static func _rank(army: Array[Actor], row: int) -> Array[Actor]:
	var soldiers: Array[Actor] = []
	for soldier in army:
		if is_instance_valid(soldier) and soldier.formation_row == row:
			soldiers.append(soldier)
	soldiers.sort_custom(func(a: Actor, b: Actor): return a.position.x < b.position.x)
	return soldiers


static func plan(army: Array[Actor], threats: Array[float]) -> Dictionary:
	var reinforcements := {}
	for row in ROWS.size():
		var soldiers := _rank(army, row)
		if soldiers.is_empty():
			continue
		var choice := _choose_slots(soldiers, threats, row)
		for i in soldiers.size():
			var soldier := soldiers[i]
			var socket := choice[i]
			var column := _socket_lane(socket)
			if soldier.assigned_lane != column and threats[column] >= 1.5:
				reinforcements[column] = true
			soldier.goal_x = SOCKETS[socket]
			soldier.assigned_lane = column
	return reinforcements


static func _socket_lane(socket: int) -> int:
	var lane_width := 2.0 * Field.LANE_HALF_WIDTH
	return floori((SOCKETS[socket] - (Field.LANES[0] - Field.LANE_HALF_WIDTH)) / lane_width)


static func _choose_slots(soldiers: Array[Actor], threats: Array[float], row: int) -> Array[int]:
	var best := -INF
	var chosen: Array[int] = []
	# Enumerating the eight socket combinations
	# preserves X order and penalizes doubling up before covering a lane.
	for mask in range(1, 1 << SOCKETS.size()):
		var sockets: Array[int] = []
		for i in SOCKETS.size():
			if mask & (1 << i):
				sockets.append(i)
		if sockets.size() != soldiers.size():
			continue
		var counts := [0, 0, 0]
		var score := 0.0
		for i in sockets.size():
			var id := sockets[i]
			var column := _socket_lane(id)
			var soldier := soldiers[i]
			var priority := threats[column]
			if row > 0:
				# Bow, magic and healing can reach adjacent lanes.
				priority += 0.48 * (threats[column - 1] if column > 0 else 0.0)
				priority += 0.48 * (threats[column + 1] if column < 2 else 0.0)
			score += priority / (1.0 + 1.05 * counts[column])
			score -= absf(soldier.position.x - SOCKETS[id]) / 220.0 * 0.43
			if column == soldier.assigned_lane:
				score += 0.62
			counts[column] += 1
		if score > best:
			best = score
			chosen = sockets
	return chosen
