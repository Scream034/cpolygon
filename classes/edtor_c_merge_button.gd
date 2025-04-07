extends EditorCBaseButton
class_name EditorCMergeButton

var merged_nodes: Array

func _init() -> void:
	scene_path = "scenes/merge_button.tscn"

func _enter_tree() -> void:
	super._enter_tree()
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	EditorPluginCPolygon.l("Merge: ", EditorPluginCPolygon.selections)
	
	if len(EditorPluginCPolygon.selections) == 0: return
	elif merged_nodes != null and merged_nodes.filter(is_instance_valid).size() > 0:
		OS.alert("Wait for previous merge to finish", "Error!")
		for merged_node in merged_nodes:
			EditorPluginCPolygon.editor_selection.add_node(merged_node)
		return

	var target = EditorPluginCPolygon.selections[0] as Polygon2D
	var x_merged_nodes = EditorPluginCPolygon.selections.slice(1) if len(EditorPluginCPolygon.selections) > 1 else null
	if !is_instance_valid(target): return
	
	# if we have merged node then we don't need to wait create new merged node
	if x_merged_nodes != null && len(x_merged_nodes) > 0:
		merged_nodes = x_merged_nodes
		merge(target)
		return
	# else we need to wait for create new merged node

	var wait_polygon = EditorWaitPolygon2D.new(target.get_path())
	var success = await wait_polygon.wait_create_async()

	if success:
		merged_nodes = [wait_polygon.node]
		merge(target)
	else:
		EditorPluginCPolygon.l("Failed merge")

func merge(target: Polygon2D) -> void:
	EditorPluginCPolygon.l("Merge polygons")

	for merged_node in merged_nodes:
		if !is_instance_valid(target): continue

		var target_path = target.get_path()
		var merged_data = EditorPolygon2DUndoRedoData.new(merged_node)

		EditorPluginCPolygon.editor_undo_redo.create_action("Merge polygon: %s" % target.name)
		EditorPluginCPolygon.editor_undo_redo.add_do_method(self, "_apply_merge", target_path, merged_data)
		EditorPluginCPolygon.editor_undo_redo.add_undo_method(self, "_undo_merge", target_path, target.polygon, merged_data)
		EditorPluginCPolygon.editor_undo_redo.commit_action()
	
	merged_nodes = []

func _apply_merge(path: String, merged_data: EditorPolygon2DUndoRedoData) -> void:
	var target = EditorPluginCPolygon.root.get_node_or_null(path) as Polygon2D
	if !is_instance_valid(target):
		push_error("Failed to apply merge: not found target")
		return

	# if merged is avaliable then we can clear and remove it
	var merged = EditorPluginCPolygon.root.get_node_or_null(merged_data.path) as Polygon2D
	if is_instance_valid(merged):
		var id = EditorPluginCPolygon.editor_undo_redo.get_object_history_id(merged)
		if id == 0:
			push_error(merged.name + " not found in history")
			return

		var merged_history = EditorPluginCPolygon.editor_undo_redo.get_history_undo_redo(id)
		if merged_history == null:
			push_error("History not found")
			return
		
		merged_history.clear_history(false)

		merged.get_parent().remove_child(merged)
		merged.set_process(false)
		merged_data._older_node = merged

	# just apply merge
	merged_data.result = Geometry2D.merge_polygons(target.polygon, merged_data.original_polygon)
	var first = merged_data.result.pop_back()
	if first == null:
		push_error("Failed to apply knife: no result")
		return

	EditorPluginCPolygon.l("First result: ", first)
	target.polygon = first

	EditorPluginCPolygon.editor_selection.clear()

	# try to create merged nodes (when multiple merge)
	var merged_data_size = merged_data.result.size()
	EditorPluginCPolygon.l("Merged data size: ", merged_data_size, " ", len(merged_data.result))
	if (merged_data_size > 0):
		merged_data._result_nodes = []
		var instance = target.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Polygon2D

		# remove children
		for child in instance.get_children():
			instance.remove_child(child)
			child = null
			child.queue_free()

		for index in merged_data_size:
			var polygon = merged_data.result.get(index)
			var node = instance.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Polygon2D
			node.polygon = polygon
			node.global_position = target.global_position
			node.name = target.name + "_" + str(index)

			target.add_child(node)
			node.owner = target.owner
			merged_data._result_nodes.push_back(node)

			EditorPluginCPolygon.editor_selection.add_node(node)
			EditorPluginCPolygon.l("Created merged node: ", node.name, " [", polygon, "]")

	EditorPluginCPolygon.editor_selection.add_node(target)

func _undo_merge(path: String, target_polygon: PackedVector2Array, merged_data: EditorPolygon2DUndoRedoData) -> void:
	var target = EditorPluginCPolygon.root.get_node_or_null(path) as Polygon2D
	if !is_instance_valid(target):
		push_warning("Failed to undo merge")
		return

	target.polygon = target_polygon

	var older_node_parent = EditorPluginCPolygon.root.get_node_or_null(merged_data.path.slice(0, merged_data.path.get_name_count() - 1))
	if is_instance_valid(older_node_parent):
		merged_data._older_node.set_process(true)
		older_node_parent.add_child(merged_data._older_node)
		merged_data._older_node.owner = older_node_parent.owner

		# free
		merged_data._older_node = null
		merged_data._older_scene_root = null

	# remove all merged nodes
	if merged_data._result_nodes != null:
		for node in merged_data._result_nodes:
			EditorPluginCPolygon.l("Remove merged node: ", node.name)
			node.get_parent().remove_child(node)
			node.owner = null
			node.queue_free()

#---------- Clear condition of maximum 2 selected nodes ----------#

func _make_visible(visible: bool) -> void:
	active = visible

	if visible:
		show()
	else:
		hide()

func _on_editor_selection_changed() -> void:
	pass