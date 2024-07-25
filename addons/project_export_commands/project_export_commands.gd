@tool
@icon("res://addons/project_export_commands/icon.svg")
extends EditorExportCommand
class_name ProjectExportCommands

## A plugin using [EditorExportCommand] to provide the ability for CLI commands
## set in the [ProjectSettings] to run during export.

## An enumeration representing what the phase the export is currently.
enum ExportCommandPhase{
	## Just after export starts, before the projects begins to build.
	PRE,
	## After the project is built. Usefull for exported application file manipulations.
	POST,
}
## A mapping of [enum ExportCommandPhase]s to the [ProjectSettings] paths that the command
## [String] [Array]s are located in.
const PROJECT_EXPORT_COMMANDS_PATHS = {
	ExportCommandPhase.PRE : "application/export/other_commands/pre_export",
	ExportCommandPhase.POST : "application/export/other_commands/post_export",
}
## The [ProjectSettings] path that the [code]stay_open[/code] option is at.
const PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH:String = "application/export/other_commands/stay_open"
## This is simply manually mirroring the name set in the plugin.cfg,
## since its not queryable in engine (at the time of writing this).
const PLUGIN_NAME = "ProjectExportCommands"

func _get_name():
	return PLUGIN_NAME

func _supports_platform(platform):
	return true #All platforms

func _get_export_options(platform):
	return [{
		"option" : {
			"name" : "project_export_commands/run_commands",
			"type" : TYPE_BOOL,
		},
		"default_value" : true
	}]

func _export_begin_command(features, is_debug, path, flags):
	__run_project_export_commands(ExportCommandPhase.PRE)

func _export_end_command(features, is_debug, path, flags):
	__run_project_export_commands(ExportCommandPhase.POST)

## Used to initialise the [ProjectSettings]
## with the necessary options if they aren't already existing.[br]
## Safe to be called multiple times, and will not reset any options.
static func init_project_export_commands():
	if not ProjectSettings.has_setting(PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH):
		ProjectSettings.set(PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH, true)
		ProjectSettings.set_initial_value(PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH, true)
	for path in PROJECT_EXPORT_COMMANDS_PATHS.values():
		if not ProjectSettings.has_setting(path):
			ProjectSettings.set(path, [""])
			ProjectSettings.set_initial_value(path, [""])
			ProjectSettings.add_property_info({
											   "name" : path,
											   "type" : TYPE_ARRAY,
											   "hint" : PROPERTY_HINT_TYPE_STRING,
											   "hint_string" : "%d:" % [TYPE_STRING]
											 })
		ProjectSettings.set_as_basic(path, true)
## Gets the command [String] [Array] for the given phase, as set in the [ProjectSettings].
static func get_project_export_commands(phase:ExportCommandPhase) -> Array:
	return ProjectSettings.get_setting(PROJECT_EXPORT_COMMANDS_PATHS[phase], [])

func __run_project_export_commands(phase:ExportCommandPhase):
	assert (is_exporting())
	if not get_option("project_export_commands/run_commands"):
		return
	var stay_open:bool = ProjectSettings.get_setting(PROJECT_EXPORT_COMMANDS_STAY_OPEN_PATH, true)
	for command in get_project_export_commands(phase):
		if command == null or command == "":
			continue
		var command_array:Array = command.split(" ", true)
		launch_external_command(command_array[0], command_array.slice(1), stay_open)
