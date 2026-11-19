extends RefCounted


static func build_links(skeleton: Skeleton3D) -> PackedInt32Array:
	var links := PackedInt32Array()
	var body_bones: Dictionary[int, bool] = {}
	for index in skeleton.get_bone_count():
		var bone := String(skeleton.get_bone_name(index))
		if bone.begins_with("Spine_") or bone.begins_with("Leg_") or bone.begins_with("Arm_") \
				or bone.begins_with("Shoulder_") or bone.begins_with("Hand_") \
				or bone.begins_with("Foot_") or bone in ["Neck", "Head"]:
			body_bones[index] = true
	for index: int in body_bones:
		var parent := skeleton.get_bone_parent(index)
		while parent >= 0 and not body_bones.has(parent):
			parent = skeleton.get_bone_parent(parent)
		if parent >= 0:
			links.append(parent)
			links.append(index)
	return links


static func project_links(skeleton: Skeleton3D, links: PackedInt32Array, camera: Camera3D) -> PackedVector2Array:
	var points := PackedVector2Array()
	var projected: Dictionary[int, Vector2] = {}
	var transform_3d := skeleton.global_transform
	var behind := Vector2(INF, INF)
	for index in links:
		if not projected.has(index):
			var world := transform_3d * skeleton.get_bone_global_pose(index).origin
			projected[index] = behind if camera.is_position_behind(world) else camera.unproject_position(world)
	for index in range(0, links.size(), 2):
		var start := projected[links[index]]
		var finish := projected[links[index + 1]]
		if start != behind and finish != behind:
			points.append(start)
			points.append(finish)
	return points
