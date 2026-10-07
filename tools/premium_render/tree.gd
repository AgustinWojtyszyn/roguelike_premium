extends SceneTree
func _init() -> void:
	var st := GLTFState.new()
	var doc := GLTFDocument.new()
	doc.append_from_file(OS.get_cmdline_user_args()[0], st)
	var root: Node = doc.generate_scene(st)
	_p(root, 0)
	quit()
func _p(n: Node, d: int) -> void:
	var s := "  ".repeat(d) + n.name + " <" + n.get_class() + ">"
	if n is MeshInstance3D:
		var m := n as MeshInstance3D
		s += " aabb=" + str(m.get_aabb().size) + " vis=" + str(m.visible)
	if n is Skeleton3D:
		s += " bones=" + str((n as Skeleton3D).get_bone_count())
	print(s)
	for c in n.get_children():
		_p(c, d + 1)
