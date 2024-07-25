@tool
@icon("res://addons/editor_export_command/icon.svg")
extends EditorPlugin

func _get_plugin_icon():
	return preload("res://addons/editor_export_command/icon.svg")

func _get_plugin_name():
	return EditorExportCommand.EEC_PLUGIN_NAME
