@tool
class_name LPCSpritesheet_Importer extends Node

@export_dir var resources_folder: String = "res://addons/lpc_spritesheet/resources"

@export var default_fps := 10
@export_dir var scan_dir: String: set = _process_folder

const directions = ["up", "left", "down", "right"]

const _cell_size := Vector2(64, 64)

func _process_folder(folder: String):
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "png":
			import_spritesheet(load(folder+"/"+file))
	for sub_folder in DirAccess.get_directories_at(folder):
		_process_folder(folder+"/"+sub_folder)

func import_spritesheet(texture: Texture2D):
	var sprite_frames_path = texture.resource_path.replace(".png", ".tres")
	var sprite_frames: SpriteFrames = ResourceLoader.load(sprite_frames_path) if FileAccess.file_exists(sprite_frames_path) else SpriteFrames.new()
	sprite_frames.clear_all()
	
	var _current_line := 0
	for animation in ["spellcast", "thrust", "walk", "slash", "shoot"]:
		for d in directions:
			_add_animation(sprite_frames, texture, animation+"_"+d, _current_line, _get_range(animation))
			_current_line += 1

	_add_animation(sprite_frames, texture, "hurt_down", _current_line, _get_range("hurt"))
	_current_line += 1
	_add_animation(sprite_frames, texture, "climb_up", _current_line, _get_range("climb"))
	_current_line += 1
	
	for d in directions:
		for animation in ["idle", "combat_idle"]:
			_add_animation(sprite_frames, texture, animation+"_"+d, _current_line, _get_range(animation))
		_current_line += 1

	for animation in ["jump", "sit", "run"]:
		for d in directions:
			_add_animation(sprite_frames, texture, animation+"_"+d, _current_line, _get_range(animation))
			_current_line += 1
	
	sprite_frames.take_over_path(sprite_frames_path)
	ResourceSaver.save(sprite_frames, sprite_frames_path, ResourceSaver.FLAG_CHANGE_PATH)

func _add_animation(sprite_frames: SpriteFrames, texture: Texture2D, animation_name: String, line: int, frames_cols: Array):
	sprite_frames.add_animation(animation_name)
	
	for col in frames_cols:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(_cell_size * Vector2(col, line), _cell_size)
		sprite_frames.add_frame(animation_name, atlas_texture)

func _get_range(animation: String) -> Array:
	match(animation):
		"spellcast": return range(7)
		"thrust": return range(8)
		"walk": return range(1, 9)
		"slash": return range(6)
		"shoot": return range(13)
		"hurt": return range(6)
		"climb": return range(6)
		"idle": return range(2)
		"combat_idle": return range(2, 4)
		"jump": return range(5)
		"sit": return range(3)
		"emote": return range(3, 6)
		"run": return range(8)
		"backslash": return range(8)
		"run": return range(8)
		_: return range(0)
	
