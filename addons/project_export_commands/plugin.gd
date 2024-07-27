@tool
@icon("res://addons/project_export_commands/icon.svg")
extends EditorPlugin

var __current_inst:ProjectExportCommands = null

func _get_plugin_icon():
	return preload("res://addons/project_export_commands/icon.svg")

func _get_plugin_name():
	return ProjectExportCommands.PLUGIN_NAME

func _enter_tree():
	init_plugin()

func _enable_plugin():
	init_plugin()

func _disable_plugin():
	deinit_plugin()

func _exit_tree():
	deinit_plugin()

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

## This method is safe to be called multiple times, and even when the plugin is not enabled, as it checks this internally
## This method is mostly for convenience, making it easy to ensure the plugin is initialised wherever its reasonably possible
## This is not expected to be usefull outside of its own script, as this behaviour is already registered to be handled on load / enable
func init_plugin():
	ProjectExportCommands.init_project_export_commands()
	add_tool_menu_item("Import Project Commands...", import_project_commands)
	add_tool_menu_item("Export Project Commands...", export_project_commands)
	if __current_inst == null and EditorInterface.is_plugin_enabled(ProjectExportCommands.PLUGIN_NAME):
		__current_inst = ProjectExportCommands.new()
		add_export_plugin(__current_inst)
	if not EditorInterface.is_plugin_enabled(EditorExportCommand.EEC_PLUGIN_NAME):
		push_warning("In order for the %s plugin to work, you must import and enable %s plugin first." % [ProjectExportCommands.PLUGIN_NAME, EditorExportCommand.EEC_PLUGIN_NAME])

## This method is safe to be called multiple times, and even when the plugin is not enabled, though it will deregister the export plugin regardless of the plugins enable state. NOTE this behaviour, as it is explicitly divergent from [[init_export_plugin]] in this specific sense! 
## This method is mostly for convenience, making it easy to ensure the plugin is destroyed wherever its reasonably possible
## This is not expected to be usefull outside of its own script, as this behaviour is already registered to be handled on unload / disable
func deinit_plugin():
	remove_tool_menu_item("Import Project Commands...")
	remove_tool_menu_item("Export Project Commands...")
	if __current_inst != null:
		remove_export_plugin(__current_inst)
		__current_inst = null
