@tool
extends EditorPlugin
class_name EditorPluginCPolygon

## Path to the addon (where the `plugin.gd` file is located)
const PATH: String = "res://addons/cpolygon"

## General plugin name
const PLUGIN_NAME: String = "cpolygon"

## Do you want to see debug messages?
const DEBUG: bool = true

## Singleton
static var instance: EditorPluginCPolygon

## Path to get_tree().root
static var root: Window

## Edtor interface cache
static var editor_interface: EditorInterface

## Edtor undo_redo cache
static var editor_undo_redo: EditorUndoRedoManager

## Edtor selection cache
static var editor_selection: EditorSelection

## Array of selected nodes
static var selections: Array[Node]

## Just buttons to show
var BUTTONS: Array[EditorCBaseButton] = [
	EditorCKnifeButton.new(),
	EditorCCutButton.new()
]

func _init() -> void:
	if not DirAccess.dir_exists_absolute(PATH):
		push_error("Addon not found: " + PATH + "\n\tPlease, set addon path in \"cpolygon/plugin.gd\"")
	
	EditorPluginCPolygon.instance = self
	EditorPluginCPolygon.editor_interface = instance.get_editor_interface()
	EditorPluginCPolygon.editor_undo_redo = editor_interface.get_editor_undo_redo()
	EditorPluginCPolygon.editor_selection = editor_interface.get_selection()

func _enter_tree() -> void:
	EditorPluginCPolygon.root = instance.get_tree().root

	editor_selection.selection_changed.connect(_on_editor_selection_changed)

	for button in BUTTONS: # Initialize
		button._enter_tree()

func _exit_tree() -> void:
	for button in BUTTONS: # Safe exit
		button._exit_tree()
		if is_instance_valid(button):
			button.free()

func _make_visible(visible: bool) -> void:
	for button in BUTTONS:
		button._make_visible(visible)

func _handles(object: Object) -> bool:
	return EditorCBaseButton._handles(object)

func _on_editor_selection_changed() -> void:
	selections = editor_selection.get_selected_nodes()

	for button in BUTTONS:
		button._on_editor_selection_changed()

## logger
static func l(arg1, arg2 = null, arg3 = null, arg4 = null, arg5 = null) -> void:
	if EditorPluginCPolygon.DEBUG:
		var args = [arg1, arg2, arg3, arg4, arg5].filter(func(arg): return arg != null)
		print(" ".join(args))
