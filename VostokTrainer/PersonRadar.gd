extends RefCounted

const RADIUS := 77.0
const RING := Color(0.40, 0.62, 0.66, 0.68)

static func project_offset(offset: Vector3, camera_right: Vector3, reach: float) -> Vector2:
	var right := Vector3(camera_right.x, 0.0, camera_right.z).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var forward := Vector3.UP.cross(right)
	return Vector2(offset.dot(right), -offset.dot(forward)) / maxf(reach, 1.0)

static func draw(canvas: Node2D, camera: Camera3D, screen: Rect2, reach: float, targets: Array[Dictionary]) -> void:
	var center := Vector2(screen.position.x + RADIUS + 18.0, screen.end.y - RADIUS - 42.0)
	canvas.draw_circle(center, RADIUS, Color(0.02, 0.05, 0.06, 0.88), true, -1.0, true)
	canvas.draw_circle(center, RADIUS, RING, false, 1.5, true)
	canvas.draw_circle(center, RADIUS * 0.5, RING, false, 1.0, true)
	canvas.draw_line(center - Vector2(0.0, RADIUS), center + Vector2(0.0, RADIUS), RING, 1.0, true)
	canvas.draw_line(center - Vector2(RADIUS, 0.0), center + Vector2(RADIUS, 0.0), RING, 1.0, true)
	var position := camera.global_position
	var right := camera.global_transform.basis.x
	for marker in targets:
		var target: Node3D = marker.target
		if not is_instance_valid(target) or not target.is_visible_in_tree() or target.is_queued_for_deletion():
			continue
		var offset := project_offset(target.global_position - position, right, reach)
		if offset.length_squared() <= 1.0:
			canvas.draw_circle(center + offset * (RADIUS - 4.0), 3.6, marker.color, true, -1.0, true)
	var arrow := PackedVector2Array([center + Vector2(0.0, -7.0), center + Vector2(-4.0, 5.0), center + Vector2(4.0, 5.0)])
	canvas.draw_colored_polygon(arrow, Color.WHITE)
	canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-RADIUS, RADIUS + 19.0), "Radar · %d m" % roundi(reach), HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 13, Color.WHITE)
