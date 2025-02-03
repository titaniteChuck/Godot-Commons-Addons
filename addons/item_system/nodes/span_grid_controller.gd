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

@export var treat_as_grid: bool = false:
	set(value):
		if value != treat_as_grid:
			treat_as_grid = value
			_refresh()

var grid: Grid

func _refresh():
	if grid_node:
		grid_node.queue_sort()
		grid_node.update_minimum_size()

# Hook into the sort child notification to place the child controls during sorting.
func _notification(what):
	match what:
		Container.NOTIFICATION_SORT_CHILDREN:
			_handle_sort_children()

func _init_table_cell():
	grid = Grid.new(columns)
	for cell in grid_node.get_children().filter(_child_is_resizable).map(Cell.new):
		grid.append(cell)

	# We sanity check for holes
	for ci in grid.columns.size():
		for ri in grid.rows.size():
			if grid.get_cell(Vector2i(ci, ri)) == null:
				grid.insert(Vector2i(ci, ri), Cell.new(null))

func _child_is_resizable(node: Node) -> bool:
	# refactor
	#return node and node is Control and node.is_visible_in_tree() and not node.is_set_as_top_level()
	return node and node is Control and not node.is_set_as_top_level()

func can_insert_at(index: int, node: Node) -> Error:
	return can_insert(Vector2i(index % grid.columns.size(), index / grid.columns.size()), node)

func can_insert(pos: Vector2i, node: Node) -> Error:
	if not _child_is_resizable(node):
		return OK
	if not node:
		return ERR_INVALID_PARAMETER
	return grid.can_insert_cell(pos, Cell.new(node))

func get_spanned_cells(pos: Vector2i) -> Array[Control]:
	return grid.get_spanned_cells(pos).map(func(cell): return cell.control)

####################################################################################################################################
####################################################################################################################################
#region layout methods #############################################################################################################

# Perform the shorting of the children of this control
func _handle_sort_children():
	_init_table_cell()
	var theme_separation := Vector2i(theme_h_separation, theme_v_separation)
	## 1. Compute the min size: borders + min_size elements that do not have the expand flag
	var inner_margins: Vector2 = theme_separation * Vector2i(maxi(grid.columns.size() - 1, 0), maxi(grid.rows.size() - 1, 0))
	var known_min_size: Vector2 = Vector2(
		grid.columns.reduce(func(min_size, col: Column): return min_size + col.min_width if not col.has_expand_flag else 0,      0),
		grid.rows   .reduce(func(min_size, row: Row):    return min_size + row.min_height if not row.has_expand_flag else 0,      0)
	)
	var remaining_space: Vector2i = grid_node.get_size() - known_min_size - inner_margins

	## 2. We are left with either:
	##- cells that did not specify a min_size : those are ignored all the way
	##- cells that only specify the expand_flag : those will share what is left
	##- cells with expand + min_size : if they ask for a bigger size from what they will receive just by sharing, we must consider the min_size
	var expanded_cols: Array[Column] = grid.columns.filter(func(col: Column): return col.has_expand_flag)
	var expanded_rows: Array[Row] = grid.rows.filter(func(row: Row): return row.has_expand_flag)
	var expanded_cell_size: Vector2i = Vector2i.ZERO

	if expanded_cols.size() > 0:
		expanded_cell_size.x = remaining_space.x / expanded_cols.size()
		while expanded_cols.any(func(col: Column): return col.min_width > expanded_cell_size.x):
			var largest_col: Column = expanded_cols.reduce(func(largest: Column, col: Column): return largest if largest and largest.min_width > col.min_width else col)
			remaining_space.x -= max(largest_col.min_width, 0)
			largest_col.expand_is_ignored = true
			expanded_cols.erase(largest_col)
			expanded_cell_size.x = remaining_space.x / expanded_cols.size() if expanded_cols.size() > 0 else 0

	if expanded_rows.size() > 0:
		expanded_cell_size.y = remaining_space.y / expanded_rows.size()
		while expanded_rows.any(func(row: Row): return row.min_height > expanded_cell_size.y):
			var largest_row: Row = expanded_rows.reduce(func(largest: Row, row: Row): return largest if largest and largest.min_height > row.min_height else row)
			remaining_space.y -= max(largest_row.min_height, 0)
			largest_row.expand_is_ignored = true
			expanded_rows.erase(largest_row)
			expanded_cell_size.y = remaining_space.y / expanded_rows.size() if expanded_rows.size() > 0 else 0

	## 3. splitting the size rarely fits perfectly. We give the remaining pixels to the first expand elements in the list
	if not expanded_cols.is_empty() and expanded_cell_size.x > 0:
		for i in remaining_space.x % expanded_cell_size.x:
			expanded_cols[i].width += 1
	if not expanded_rows.is_empty() and expanded_cell_size.y > 0:
		for i in remaining_space.y % expanded_cell_size.y:
			expanded_rows[i].height += 1


	## 4. We compute the size and position of every cell.
	var col_position: int = 0
	for col in grid.columns:
		if col.min_width > 0 and not col.has_expand_flag or col.expand_is_ignored:
			col.width = col.min_width
		elif col.has_expand_flag:
			col.width += expanded_cell_size.x # += because expanded columns have already received the remaining pixels
		col.position = col_position
		col_position += col.width + theme_h_separation

	var row_position: int = 0
	for row in grid.rows:
		if row.min_height > 0 and not row.has_expand_flag or row.expand_is_ignored:
			row.height = row.min_height
		elif row.has_expand_flag:
			row.height += expanded_cell_size.y # += because expanded columns have already received the remaining pixels
		row.position = row_position
		row_position = row_position + row.height + theme_v_separation

	## 6. We place the cells
	for cell in grid.cells:
		if cell and cell.content:
			cell.content.visible = cell.is_origin # refactor
			if cell.is_origin:
				var spanned_size: Vector2 = cell.size
				for ci in range(1, cell.col_span):
					spanned_size.x += grid.get_cell(Vector2i(cell.col_index + ci, cell.row_index)).size.x + theme_h_separation
				for ri in range(1, cell.row_span):
					spanned_size.y += grid.get_cell(Vector2i(cell.col_index, cell.row_index + ri)).size.y + theme_v_separation
				grid_node.fit_child_in_rect(cell.content, Rect2(cell.position, spanned_size))

# Calculate the minimum size for this control
func _get_minimum_size() -> Vector2:
	_init_table_cell()

	var min_size: Vector2 = Vector2(grid.columns[0].min_width, grid.rows[0].min_height)
	for ci in range(1, grid.columns.size()):
		min_size.x += grid.columns[ci].min_width + theme_h_separation
	for ri in range(1, grid.rows.size()):
		min_size.y += grid.rows[ri].min_height + theme_v_separation
	return min_size


#endregion layout methods ##########################################################################################################
####################################################################################################################################
#region inner classes ##############################################################################################################


class Grid:
	var cells: Array[Cell] = []
	var columns: Array[Column] = []
	var rows: Array[Row] = []

	var _last_origin_cell_index: int = 0

	func _init(column_count: int):
		rows = [Row.new(self)]
		for ci in column_count:
			var column: Column = Column.new(self)
			column.index = ci
			columns.append(column)

	func append(value: Cell):
		var index: int = _last_origin_cell_index
		while insert(Vector2i(index % columns.size(), index / columns.size()), value) != OK:
			index += 1

	func insert(pos: Vector2i, value: Cell) -> Error:
		var can_insert: Error = can_insert_cell(pos, value)
		if can_insert != OK:
			return can_insert

		for ci in value.col_span:
			for ri in value.row_span:
				var to_insert = value
				if not(ci == 0 and ri == 0):
					to_insert = value.duplicate()
					to_insert.content = null
					to_insert.span_root = value
				_set_cell(pos + Vector2i(ci, ri), to_insert)

		_last_origin_cell_index = pos.y * columns.size() + pos.x

		return OK

	func can_insert_cell(pos: Vector2i, value: Cell) -> Error:
		if not value:
			return ERR_INVALID_PARAMETER

		if pos.x + value.col_span > columns.size():
			return ERR_PARAMETER_RANGE_ERROR

		for ci in value.col_span:
			for ri in value.row_span:
				var existing: Cell = get_cell(pos + Vector2i(ci, ri))
				if existing and existing.content:
					return ERR_ALREADY_IN_USE

		return OK


	func get_cell(pos: Vector2i) -> Cell:
		var index = pos.y * columns.size() + pos.x
		return cells[index] if index < cells.size() else null

	func get_spanned_cells(pos: Vector2i) -> Array[Cell]:
		var root: Cell = get_cell(pos)
		var output: Array[Cell] = []
		if root.is_origin:
			output.append(root)
			for ci in root.col_span:
				for ri in root.row_span:
					output.append(get_cell(Vector2i(root.col_index + ci, root.row_index + ri)))

		return output

	func _set_cell(pos: Vector2i, value: Cell) -> void:
		var index: int = pos.y * columns.size() + pos.x
		if cells.size() <= index:
			cells.resize(index + 1)
		if cells[index] and not cells[index].content:
			cells[index].content = value.content
		else:
			cells[index] = value

		if rows.size() <= pos.y:
			rows.resize(pos.y + 1)
			rows[pos.y] = Row.new(self)
			rows[pos.y].index = pos.y

		value.col_index = pos.x
		value.row_index = pos.y
		value.column = columns[value.col_index]
		value.row = rows[value.row_index]

class Row:
	var grid: Grid
	var index: int = 0
	var cells: Array[Cell]:
		get: return grid.cells.filter(func(cell): return cell.row_index == index)
	var min_height: int:
		get: return cells.reduce(func(min_height, cell): return max(min_height, cell.minimum_size.y), 0)
	var has_expand_flag: bool:
		get: return cells.any(func(cell): return cell and cell.is_v_expanded)

	var expand_is_ignored: bool = false
	var height: int = 0
	var position: int = 0

	func _init(grid: Grid) -> void:
		self.grid = grid

class Column:
	var grid: Grid
	var index: int = 0
	var cells: Array[Cell]:
		get: return grid.cells.filter(func(cell): return cell.col_index == index)
	var min_width: int:
		get: return cells.reduce(func(min_width, cell): return max(min_width, cell.minimum_size.x if cell else 0), 0)
	var has_expand_flag: bool:
		get: return cells.any(func(cell): return cell and cell.is_h_expanded)

	var expand_is_ignored: bool = false
	var width: int = 0
	var position: int = 0

	func _init(grid: Grid) -> void:
		assert(grid)
		self.grid = grid

class Cell:
	var content: Control
	var minimum_size: Vector2:
		get: return content.get_combined_minimum_size() if content else  Vector2.ZERO
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
	var row: Row
	var column: Column

	var span_root: Cell = self
	var is_origin: bool:
		get: return span_root == self

	var size: Vector2 = Vector2.ZERO:
		get: return Vector2(column.width, row.height) if column and row else Vector2.ZERO
	var position: Vector2:
		get: return Vector2(column.position, row.position) if column and row else Vector2.ZERO


	func _init(content: Control):
		self.content = content

	func _to_string() -> String:
		return "[(%s,%s); is_origin: %s ; col_span: %s ; row_span: %s ; child: %s]" % [col_index, row_index, is_origin, col_span, row_span, content.name]

	func duplicate() -> Cell:
		var output = Cell.new(content)
		output.row_index = row_index
		output.col_index = col_index
		output.is_origin = is_origin
		return output
#endregion inner classes ###########################################################################################################
