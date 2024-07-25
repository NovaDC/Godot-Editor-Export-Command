@tool
@icon("res://addons/editor_export_command/icon.svg")
class_name EditorExportCommand
extends EditorExportPlugin

## A tool for running CLI commands during exporting of projects.
##
## Intended to be used as an abstract base for extentions that run commands before and after export.
## Please note that all extending plugins require the base "EditorExportCommand" plugin to be
## enabled in the editor in order for the extending plugin's commands to run.

## This is simply manually mirroring the name set in the plugin.cfg,
## since its not queryable in engine (at the time of writing this).
const EEC_PLUGIN_NAME := "EditorExportCommand"

var __is_exporting := false

var __current_export_features := PackedStringArray()
var __current_export_is_debug := false
var __current_export_path := ""
var __current_export_flags := 0

# Intended to be a sealed method.
func _export_begin(features, is_debug, path, flags):
	__is_exporting = true

	if EditorInterface.is_plugin_enabled(EEC_PLUGIN_NAME):
		__current_export_features = features
		__current_export_is_debug = is_debug
		__current_export_path = path
		__current_export_flags = flags
		_export_begin_command(__current_export_features,
							  __current_export_is_debug,
							  __current_export_path,
							  __current_export_flags)

# Intended to be a sealed method.
func _export_end():
	if EditorInterface.is_plugin_enabled(EEC_PLUGIN_NAME):
		_export_end_command(__current_export_features,
							__current_export_is_debug,
							__current_export_path,
							__current_export_flags)
	__is_exporting = false

## Tries to launch a given executable in a terminal window.
## Defaults to running it invisibly in the backround if it is not possible on to make the terminal
## visible on the exporting platform.
## As this function explicitly attempts to run the command in the system's command terminal window,
## it makes the available commands in certian environments include
## those beyond just executable paths.[br]
## [br]
## Returns a [Dictionary] with the following keys:[br]
## - [code]"pid"[/code] : an [int] returning the command's process id
## (like the return value of [method OS.create_process]).[br]
## - [code]"stdout"[/code] : (currently) a [String] containing the stdout output of the command,
## or an empty string if retrieving it was impossible.[br]
## - [code]"stderr"[/code] : (currently) a [String] containing the stderr output of the command,
## or an empty string if retrieving it was impossible.[br]
## [br]
## NOTE: As of version 1.0.0.0, this method will always return
## an empty [String] for [code]"stdout"[/code] and [code]"stderr"[/code],
## however, future versions may instead return pipes to/from the command as well,
## once [method OS.execute_with_pipe] is made available in a stable release of Godot.[br]
## @experimental
static func launch_external_command(command:String, args := [], stay_open := true) -> Dictionary:
	var new_args:Array = []
	if OS.get_name() == "Windows":
		new_args = ["/k" if stay_open else "/c", command] + args
		command = "cmd.exe"
	elif OS.get_name() == "Linux" or OS.get_name().ends_with("BSD"):
		new_args = ["-hold"] if stay_open else [] + ["-e", command] + args
		command = "xterm"
	elif OS.get_name() == "MacOS" or OS.get_name() == "Darwin":
		push_warning("BE AWARE: The EditorExportCommand Plugin is not properly tested on\
					  MacOS/Darwin platforms! The commands may not run during export!")
		new_args = ['open', '-n', 'Terminal.app', command]
		new_args += (['--args'] if args.size() > 0 else [])
		new_args += args
	
	var pid := OS.create_process(command, new_args, true)
	var stdout:String = ""
	var stderr:String = ""
	
	return {"pid" : pid, "stdout" : stdout, "stderr" : stderr}

## Used to check if a project is currently being exported.
func is_exporting() -> bool:
	return __is_exporting

## INTENDED TO BE VIRTUAL[br]
## Called when the pre export commands should be run.
## Used as a replacement for [method _export_begin].[br]
## [param features], [param is_debug], [param path] and [param flags] all corlate to the paramiters
## given to [method _export_begin].
func _export_begin_command(features:PackedStringArray, is_debug:bool, path:String, flags:int):
	pass

## INTENDED TO BE VIRTUAL[br]
## Called when the post export commands should be run.
## Used as a replacement for [method _export_end].[br]
## [param features], [param is_debug], [param path] and [param flags] all corlate to the paramiters
## given to [method _export_begin].
func _export_end_command(features:PackedStringArray, is_debug:bool, path:String, flags:int):
	pass
