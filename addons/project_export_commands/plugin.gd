@tool
@icon("res://addons/project_export_commands/icon.svg")
extends EditorPlugin

var __current_inst:ProjectExportCommands = null

func _get_plugin_icon():
	return preload("res://addons/project_export_commands/icon.svg")

func _get_plugin_name():
	return ProjectExportCommands.PLUGIN_NAME

func _enter_tree():
	__init_plugin()

func _enable_plugin():
	__init_plugin()

func _disable_plugin():
	__deinit_plugin()

func _exit_tree():
	__deinit_plugin()

## Export a command file.[br]
## Path is selected with the editor file selector.
static func export_project_commands():
	var fileselect := EditorFileDialog.new()
	
	var onopen := func ():
		var content := {
			"pre" : ProjectExportCommands.get_project_export_commands(
					ProjectExportCommands.ExportCommandPhase.PRE),
			"post" : ProjectExportCommands.get_project_export_commands(
					ProjectExportCommands.ExportCommandPhase.POST),
			"stay_open" : ProjectSettings.get_setting(
					ProjectExportCommands.PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH, true),
		}
		
		var f := FileAccess.open(fileselect.current_path, FileAccess.WRITE)
		f.store_line(JSON.stringify(content))
		f.close()
	
	fileselect.access = EditorFileDialog.ACCESS_FILESYSTEM
	fileselect.dialog_hide_on_ok = true
	fileselect.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	fileselect.title = "Import Commands"
	fileselect.position = Vector2.ONE * 100
	fileselect.set_filters(PackedStringArray(["*.json ; JSON files","*.txt ; Plain Text Files"]))
	fileselect.confirmed.connect(onopen)
	EditorInterface.popup_dialog(fileselect)
	await fileselect.visibility_changed
	fileselect.queue_free()

## Import a user selected command file.[br]
## Path is selected with the editor file selector.
static func import_project_commands():
	var fileselect := EditorFileDialog.new()
	
	var onopen := func ():
		var content = JSON.parse_string(FileAccess.get_file_as_string(fileselect.current_path))
		assert (content != null and content is Dictionary and content.size() >= 1)
		
		for key in content.keys():
			match (key):
				"pre":
					ProjectSettings.set(
							ProjectExportCommands.PROJECT_EXPORT_COMMANDS_PATHS[ProjectExportCommands.ExportCommandPhase.PRE],
							content[key]
							)
				"post":
					ProjectSettings.set(
							ProjectExportCommands.PROJECT_EXPORT_COMMANDS_PATHS[ProjectExportCommands.ExportCommandPhase.POST],
							content[key]
							)
				"stay_open":
					ProjectSettings.set(
							ProjectExportCommands.PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH,
							content[key]
							)
	
	fileselect.access = EditorFileDialog.ACCESS_FILESYSTEM
	fileselect.dialog_hide_on_ok = true
	fileselect.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	fileselect.title = "Import Commands"
	fileselect.position = Vector2.ONE * 100
	fileselect.set_filters(PackedStringArray(["*.json ; JSON files","*.txt ; Plain Text Files"]))
	fileselect.confirmed.connect(onopen)
	EditorInterface.popup_dialog(fileselect)
	await fileselect.visibility_changed
	fileselect.queue_free()

func __init_plugin():
	ProjectExportCommands.init_project_export_commands()
	add_tool_menu_item("Import Project Commands...", import_project_commands)
	add_tool_menu_item("Export Project Commands...", export_project_commands)
	if __current_inst == null and EditorInterface.is_plugin_enabled(ProjectExportCommands.PLUGIN_NAME):
		__current_inst = ProjectExportCommands.new()
		add_export_plugin(__current_inst)

func __deinit_plugin():
	remove_tool_menu_item("Import Project Commands...")
	remove_tool_menu_item("Export Project Commands...")
	if __current_inst != null:
		remove_export_plugin(__current_inst)
		__current_inst = null
