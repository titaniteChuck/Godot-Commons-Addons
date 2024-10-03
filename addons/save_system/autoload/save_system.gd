# ResourceSaver.FLAG_BUNDLE_RESOURCES leads to error when loading. 
# So we save duplicates that will not replace those in cache once loaded
# But will be used by the caller as they please
class_name Save_System extends Node

signal save_requested
signal load_requested

@export var encryption_key := "abcdefg1234567"
@export var use_encryption := false
@export var save_on_exit := true
# TODO automatic save

var base_folder := "user://saves"
var default_file_path : String:
	get: return "%s/save_file.tres" % [base_folder]
var save_object: SaveSystem_SaveFile

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and save_on_exit:
		save()
		
#region ##################### Public Save/Load Methods ############################
func save_entity(id: String, what: Variant):
	if what is Array:
		var new_array = what.duplicate(true)
		for index in what.size():
			new_array[index] = what[index].duplicate(true)
		what = new_array

	save_object.dictionary[id] = what.duplicate(true)

func load_entity(id: String) -> Variant:
	var output = save_object.dictionary.get(id)
	return output

func save(file_path : String = default_file_path) -> Error:
	DirAccess.make_dir_recursive_absolute(base_folder)
	save_object = SaveSystem_SaveFile.new()
	save_requested.emit()
	var successful: Error = ResourceSaver.save(save_object, file_path)
	assert(successful == OK)
	if successful == OK:
		#fixBundledResource(file_path)
		if use_encryption:
			_encrypt_file(file_path)
			DirAccess.remove_absolute(file_path)
	save_object = null
	return successful

func load_savefile(file_path : String = default_file_path):
	if use_encryption:
		_decrypt_file(file_path)
	save_object = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	if use_encryption:
		DirAccess.remove_absolute(file_path)
	if save_object:
		load_requested.emit()
	else:
		assert(save_object)
	save_object = null
#endregion
		
#region ##################### Encryption utils ############################
func _encrypt_file(filepath: String):
	var encrypted_filepath = _get_encrypted_file_name(filepath)
	var cleartext_file : FileAccess = FileAccess.open(filepath, FileAccess.READ)
	var encrypted_file: FileAccess = FileAccess.open_encrypted_with_pass(encrypted_filepath, FileAccess.WRITE, encryption_key)
	encrypted_file.store_string(cleartext_file.get_as_text())
	
	cleartext_file.close()
	encrypted_file.close()

func _decrypt_file(filepath: String):
	var encrypted_filepath = _get_encrypted_file_name(filepath)
	var cleartext_file : FileAccess = FileAccess.open(filepath, FileAccess.WRITE)
	var encrypted_file: FileAccess = FileAccess.open_encrypted_with_pass(encrypted_filepath, FileAccess.READ, encryption_key)
	cleartext_file.store_string(encrypted_file.get_as_text())
	
	cleartext_file.close()
	encrypted_file.close()

func _get_encrypted_file_name(cleartext_filepath: String) -> String:
	# TODO can be improved with Regex
	var filename_with_extension = cleartext_filepath.split("/")
	filename_with_extension = filename_with_extension[filename_with_extension.size() - 1] as String
	var prefix = cleartext_filepath.replace(filename_with_extension, "")
	var filename_without_extension = filename_with_extension.split(".")[0]
	var extension = filename_with_extension.replace(filename_without_extension, "")
	# TODO: also encrypt save name
	var encrypted_filepath = prefix + filename_without_extension + ".crypt" + extension
	return encrypted_filepath
#endregion

# Ref: https://forum.godotengine.org/t/how-to-load-and-save-things-with-godot-a-complete-tutorial-about-serialization/44515
#region ##################### Save / load INI ############################
var save_path_ini := "user://player_data.ini"

func save_ini() -> void:
	var config_file := ConfigFile.new()
	var object: Label = Label.new()

	config_file.set_value("<Section_name>", "text", object.text)
	
	var error := config_file.save(save_path_ini)
	if error:
		print("An error happened while saving data: ", error)

func load_ini() -> void:
	var config_file := ConfigFile.new()
	var error := config_file.load(save_path_ini)

	if error:
		print("An error happened while loading data: ", error)
		return

	var object = Label.new()
	object.text = config_file.get_value("<Section_name>", "text", "1")
#endregion

# Workaround to use ResourceSaver.FLAG_BUNDLE_RESOURCES
func fixBundledResource(file_path) -> Error:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if !file:
		return ERR_CANT_OPEN
	
	var lines := file.get_as_text().split("\n")
	file.close()
	
	var skip := false
	var current_class := ""
	var match_class = RegEx.create_from_string("class_name (\\w+)")
	var skipped_lines: PackedStringArray = []
	
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if !file:
		return ERR_CANT_OPEN
	
	for line in lines:
		if line.begins_with("script/source"):
			skip = true
		if skip:
			skipped_lines.append(line)
			var class_match = match_class.search(line)
			if class_match: current_class = class_match.get_string(1)
			if line == '"':
				skip = false
				if current_class != "":
					file.store_line('script/source = "extends %s' % current_class)
					file.store_line('"')
					current_class = ""
				else:
					for skipped in skipped_lines:
						file.store_line(skipped)
				skipped_lines = []
		else:
			file.store_line(line)
	file.close()
	return OK
