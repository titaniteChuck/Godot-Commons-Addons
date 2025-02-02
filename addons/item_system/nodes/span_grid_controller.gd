@tool
class_name SpanGridController extends Node

@export var grid_node: Container

@export var columns : int = 1 :
	set(value):
		if columns != value:
			columns = value
			_refresh()

@export_group("Theme Override Constants","theme_")
@export_range(0,1024) var theme_h_separation = 5:
	set(value):
		if value != theme_h_separation:
			theme_h_separation = value
			_refresh()
@export_range(0,1024) var theme_v_separation = 5:
	set(value):
		if value != theme_v_separation:
			theme_v_separation = value
			_refresh()
@export_group("")


func _refresh():
	if grid_node:
		grid_node.queue_sort()
		grid_node.update_minimum_size()

# Hook into the sort child notification to place the child controls during sorting.
func _notification(what):
	match what:
		Container.NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()


# Perform the shorting of the children of this control
func _handle_sort_children():
	_init_table_cell()

	var theme_separation: Vector2i = Vector2i(theme_h_separation, theme_v_separation)

	## 1. Consider the custom_size hardcoded.
	## 2. Consider the borders
	var inner_margins: Vector2 = theme_separation * Vector2i(maxi(grid_cols() - 1, 0), maxi(grid_rows() - 1, 0))
	var known_min_size: Vector2 = theme_separation * Vector2i(maxi(grid_cols() - 1, 0), maxi(grid_rows() - 1, 0))
	known_min_size.x = grid_spancols.reduce(func(min_size, col: SpanCol): return min_size + col.minw if not col.has_expand_flag else 0,      0)
	known_min_size.y = grid_spanrows.reduce(func(min_size, row: SpanRow): return min_size + row.minh if not row.has_expand_flag else 0,      0)
	var remaining_space: Vector2i = grid_node.get_size() - known_min_size - inner_margins

	## 3. Ne reste que les colonnes qui ont flag = expand et qui vont se partager le reste de l'espace
	## Si une cellule avait demandé en custom_min_size + que ce qu'elle va recevoir,
	## 			=> on ne considère plus qu'elle est expand
	## 			=> on applique son custom_min_size
	var expanded_cols: Array[SpanCol] = grid_spancols.filter(func(col: SpanCol): return col.has_expand_flag)
	var expanded_rows: Array[SpanRow] = grid_spanrows.filter(func(row: SpanRow): return row.has_expand_flag)
	var expanded_cell_size: Vector2i = Vector2i.ZERO

	if expanded_cols.size() > 0:
		expanded_cell_size.x = remaining_space.x / expanded_cols.size()
		while expanded_cols.any(func(col: SpanCol): return col.minw > expanded_cell_size.x):
			var largest_col: SpanCol = expanded_cols.reduce(func(largest: SpanCol, col: SpanCol): return largest if largest and largest.minw > col.minw else col)
			remaining_space.x -= largest_col.minw
			largest_col.expand_is_ignored = true
			expanded_cols.erase(largest_col)
			expanded_cell_size = remaining_space / Vector2i(expanded_cols.size(), expanded_rows.size())

	if expanded_rows.size() > 0:
		expanded_cell_size.y = remaining_space.y / expanded_rows.size()
		while expanded_rows.any(func(row: SpanRow): return row.minh > expanded_cell_size.y):
			var largest_row: SpanRow = expanded_rows.reduce(func(largest: SpanRow, row: SpanRow): return largest if largest and largest.minh > row.minh else row)
			remaining_space.y -= largest_row.minh
			largest_row.expand_is_ignored = true
			expanded_rows.erase(largest_row)
			expanded_cell_size = remaining_space / Vector2i(expanded_cols.size(), expanded_rows.size())

	## 4. expanded_size: size shared over all the expanded cells
	##	   size_remaining_pixel: le reste de la division entière de expanded_size
	var remaining_pixels_after_expand: Vector2i = remaining_space - expanded_cell_size * Vector2i(expanded_cols.size(), expanded_rows.size())
	# we split because of https://github.com/godotengine/godot-proposals/issues/2085
	var rx: int = remaining_pixels_after_expand.x
	var ry: int = remaining_pixels_after_expand.y
	for i in rx:
		expanded_cols[i].computed_width += 1
	for i in ry:
		expanded_rows[i].computed_height += 1


	## 5. Définir les positions et tailles des colonnes / lignes + Répartir les pixels en trop
	## Pour chacune des colonnes
	##		=> si c'est une colonne "expand": size_expand + 1 pixel en trop
	## 		=> si c'est une colonne "min_size": min_size
	## BUG: RIGHT TO LEFT marche pô
	var col_position: int = 0
	for col in grid_spancols:
		if col.minw > 0:
			if col.has_expand_flag and not col.expand_is_ignored:
				col.computed_width += expanded_cell_size.x # += because expanded columns have already received the remaining pixels
			else:
				col.computed_width = col.minw
		elif col.has_expand_flag:
			col.computed_width += expanded_cell_size.x # += because expanded columns have already received the remaining pixels
		else:
			col.computed_width = 0

		for col_cells in col.cells:
			col_cells.computed_size.x = col.computed_width
			col_cells.computed_position.x = col_position

		col_position += col.computed_width + theme_h_separation

	var row_position: int = 0
	for row in grid_spanrows:
		if row.minh > 0:
			if row.has_expand_flag and not row.expand_is_ignored:
				row.computed_height += expanded_cell_size.y # += because expanded columns have already received the remaining pixels
			else:
				row.computed_height = row.minh
		elif row.has_expand_flag:
			row.computed_height += expanded_cell_size.y # += because expanded columns have already received the remaining pixels
		else:
			row.computed_height = 0

		for row_cells in row.cells:
			row_cells.computed_size.y = row.computed_height
			row_cells.computed_position.y = row_position

		row_position = row_position + row.computed_height + theme_v_separation

	## 6. On place les éléments
	for cell in grid:
		if cell.content and cell.is_origin:
			var spanned_size: Vector2 = cell.computed_size
			for ci in range(1, cell.col_span):
				spanned_size.x += get_cell(Vector2i(cell.col_index + ci, cell.row_index)).computed_size.x + theme_h_separation
			for ri in range(1, cell.row_span):
				spanned_size.y += get_cell(Vector2i(cell.col_index, cell.row_index + ri)).computed_size.y + theme_v_separation
			grid_node.fit_child_in_rect(cell.content, Rect2(cell.computed_position, spanned_size))



# Calculate the minimum size for this control
func _get_minimum_size() -> Vector2:
	_init_table_cell()

	var min_size : Vector2 = Vector2(theme_h_separation * (grid_cols() - 1), theme_v_separation * (grid_rows() - 1) )
	for w in _get_minw_by_col().values():
		min_size.x += w
	for h in _get_minh_by_row().values():
		min_size.y += h

	return min_size


####################################################################################################################################
####################################################################################################################################
####################################################################################################################################


func _get_minw_by_col() -> Dictionary:
	var output: Dictionary = {}
	for ci in grid_cols():
		for ri in grid_rows():
			var cell: SpanCell = get_cell(Vector2i(ci, ri))
			if cell:
				if output.has(ci):
					output[ci] = maxi(output[ci], cell.minimum_size.x)
				else:
					output[ci] = cell.minimum_size.x
	return output

func _get_minh_by_row() -> Dictionary:
	var output: Dictionary = {}
	for ri in grid_rows():
		for ci in grid_cols():
			var cell: SpanCell = get_cell(Vector2i(ci, ri))
			if cell:
				if output.has(ri):
					output[ri] = maxi(output[ri], cell.minimum_size.y)
				else:
					output[ri] = cell.minimum_size.y
	return output

var grid: Array[SpanCell] = []
var cells: Array[SpanCell] = []

func _init_table_cell():
	grid.clear()
	grid_spancols.clear()
	grid_spanrows.clear()
	var cells = grid_node.get_children().filter(_child_is_resizable).map(SpanCell.new)
	var children = grid_node.get_children()
	var _current_pos := Vector2i.ZERO
	var _current_insert_index = 0
	for cell in cells:
		if cell:
			while _insert_in_array(_current_insert_index, cell) != OK:
				_current_insert_index += 1

	for i in range(_current_insert_index % columns, columns):
		_insert_in_array(_current_insert_index, SpanCell.new(null))
		_current_insert_index += 1

func _child_is_resizable(node: Node) -> bool:
	# Child should be of control type, to be able to adjust positions
	var control_child = node as Control
	if control_child == null:
		return false
	if not control_child.is_visible_in_tree() || control_child.is_set_as_top_level():
		return false
	return true

func _insert_in_array(index: int, value: SpanCell, array: Array[SpanCell] = grid) -> Error:
	return _insert_in_grid(_index_to_coords(index), value, array)

func _index_to_coords(index: int) -> Vector2i:
	var col = index % columns
	var row = index / columns
	return Vector2i(col, row)

func _insert_in_grid(pos: Vector2i, value: SpanCell, array: Array[SpanCell] = grid) -> Error:
	if pos.x + value.col_span > columns:
		return ERR_PARAMETER_RANGE_ERROR

	for ci in value.col_span:
		for ri in value.row_span:
			if get_cell(pos + Vector2i(ci, ri), array):
				return ERR_ALREADY_IN_USE

	for ci in value.col_span:
		for ri in value.row_span:
			value = value.duplicate()
			value.is_origin = (ci == 0 and ri == 0)
			_set_cell(pos + Vector2i(ci, ri), value, array)

	return OK

func get_cell(pos: Vector2i, array: Array[SpanCell] = grid) -> SpanCell:
	var index = pos.y * columns + pos.x
	return array[index] if index < array.size() else null

func has_cell(pos: Vector2i, array: Array[SpanCell] = grid) -> bool:
	return pos.y * columns + pos.x < array.size()

func _set_cell(pos: Vector2i, value: SpanCell, array: Array[SpanCell] = grid) -> void:
	# Update the cell with its new coordinates
	value.col_index = pos.x
	value.row_index = pos.y
	var index = pos.y * columns + pos.x
	if array.size() <= index:
		array.resize(index + 1)
	# save the cell in the array
	array[index] = value

	# Update grid data
	if grid_spancols.size() <= value.col_index:
		grid_spancols.resize(value.col_index + 1)
		grid_spancols[value.col_index] = SpanCol.new(self)
		grid_spancols[value.col_index].index = value.col_index

	if grid_spanrows.size() <= value.row_index:
		grid_spanrows.resize(value.row_index + 1)
		grid_spanrows[value.row_index] = SpanRow.new(self)
		grid_spanrows[value.row_index].index = value.row_index

	# save a reference to the cell
	value.span_col = grid_spancols[value.col_index]
	value.span_row = grid_spanrows[value.row_index]

var grid_spancols: Array[SpanCol] = []
var grid_spanrows: Array[SpanRow] = []

func grid_rows() -> int:
	return grid.size() / columns

func grid_cols() -> int:
	return min(grid.size(), columns)

class SpanRow:
	var grid: SpanGridController
	var index: int = 0
	var minh: int:
		get: return cells.reduce(func(minh, cell): return max(minh, cell.minimum_size.y), 0)
	var has_expand_flag: bool:
		get: return cells.any(func(cell): return cell and cell.is_v_expanded)
	var cells: Array[SpanCell]:
		get:
			var output: Array[SpanCell] = []
			output.append_array(range(grid.grid_cols()).map(func(ci): return grid.get_cell(Vector2i(ci, index))))
			return output

	var expand_is_ignored: bool = false
	var computed_height: int = 0

	func _init(grid: SpanGridController) -> void:
		self.grid = grid

class SpanCol:
	var grid: SpanGridController
	var index: int = 0
	var minw: int:
		get: return cells.reduce(func(minw, cell): return max(minw, cell.minimum_size.x if cell else 0), 0)
	var has_expand_flag: bool:
		get: return cells.any(func(cell): return cell and cell.is_h_expanded)
	var cells: Array[SpanCell]:
		get:
			var output: Array[SpanCell] = []
			output.append_array(range(grid.grid_rows()).map(func(ri): return grid.get_cell(Vector2i(index, ri))))
			return output

	var expand_is_ignored: bool = false
	var computed_width: int = 0

	func _init(grid: SpanGridController) -> void:
		self.grid = grid

class SpanCell:
	var content: Control
	var minimum_size: Vector2:
		get: return content.get_combined_minimum_size() / Vector2(col_span, row_span) if content else  Vector2.ZERO
	var is_spanned: bool:
		get: return col_span != 1 or row_span != 1
	var col_span: int:
		get: return content.col_span if content and "col_span" in content else 1
	var row_span: int:
		get: return content.row_span if content and "row_span" in content else 1
	var is_h_expanded: bool:
		get: return content.get_h_size_flags() & Container.SIZE_EXPAND if content else true
	var is_v_expanded: bool:
		get: return content.get_v_size_flags() & Container.SIZE_EXPAND if content else false

	var row_index: int = -1
	var col_index: int = -1
	var span_row: SpanRow
	var span_col: SpanCol

	var computed_size: Vector2 = Vector2.ZERO
	var computed_position: Vector2 = Vector2.ZERO

	var is_origin := true

	func _init(content: Control):
		self.content = content

	func _to_string() -> String:
		return "[(%s,%s); is_origin: %s ; col_span: %s ; row_span: %s ; child: %s]" % [col_index, row_index, is_origin, col_span, row_span, content.name]

	func duplicate() -> SpanCell:
		var output = SpanCell.new(content)
		output.row_index = row_index
		output.col_index = col_index
		output.is_origin = is_origin
		return output

	func equals(other: Variant) -> bool:
		if not other:
			return false
		if other is not SpanCell:
			return false
		return content == other.content and row_index == other.row_index and col_index == other.col_index and is_origin == other.is_origin
