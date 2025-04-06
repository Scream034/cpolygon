extends Object
class_name EditorCBaseButton

var scene_path: StringName
var button: BaseButton
var active: bool = false

func _enter_tree() -> void:
	var scene: PackedScene = ResourceLoader.load(EditorPluginCPolygon.PATH.path_join(scene_path), "PackedScene")
	if scene == null:
		push_error("Could not load scene: " + scene_path + "!")
		return
	
	button = scene.instantiate() as BaseButton
	if button == null:
		push_error("Could not create button from scene: " + scene_path + "!")
		return

	button.hide()
	button.set_pressed_no_signal(false)

	EditorPluginCPolygon.instance.add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, button)

func _exit_tree() -> void:
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		EditorPluginCPolygon.instance.remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, button)

func _make_visible(visible: bool) -> void:
	active = visible

	if visible and len(EditorPluginCPolygon.selections) <= 2:
		show()
	else:
		hide()

func _on_editor_selection_changed() -> void:
	if len(EditorPluginCPolygon.selections) > 2:
		hide()
	else:
		if active:
			show()

static func _handles(object: Object) -> bool:
	return object.get("polygon") is PackedVector2Array

## Show button
func show() -> void:
	button.show()

## Hide button
func hide() -> void:
	button.hide()
	button.set_pressed_no_signal(false)