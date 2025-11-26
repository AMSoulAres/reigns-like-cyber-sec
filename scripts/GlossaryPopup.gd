extends Control

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var panel: PanelContainer = %PanelContainer
@onready var background: ColorRect = $ColorRect

var _target_term = ""
var is_modal = false
var ui_scale: float = 1.0

func _ready():
	visible = false
	background.gui_input.connect(_on_background_gui_input)

func _on_background_gui_input(event: InputEvent):
	if is_modal and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func show_term(term_key: String, modal: bool = false, pos: Vector2 = Vector2.ZERO):
	_target_term = term_key
	var data = Glossary.get_definition(term_key)
	if data.is_empty():
		return
		
	title_label.text = data.get("title", "")
	description_label.text = data.get("definition", "")
	
	# Configure size constraints BEFORE waiting
	var viewport_size = get_viewport_rect().size
	
	if modal:
		panel.custom_minimum_size = Vector2.ZERO
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		# Dynamic width for mobile/small screens
		# Use 300px or 90% of screen width (adjusted for scale), whichever is smaller
		var available_width = (viewport_size.x / ui_scale) - 40
		var target_width = min(300, available_width)
		panel.custom_minimum_size = Vector2(target_width, 0)
		
		panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# Force reset size to shrink to content
	panel.size = Vector2.ZERO
	
	# Make visible but transparent to force layout update
	modulate.a = 0.0
	visible = true
	
	# Wait for layout to update based on new text and constraints
	# We need two frames: one for visibility to register, one for layout to settle
	panel.queue_sort()
	await get_tree().process_frame
	panel.queue_sort()
	await get_tree().process_frame
	panel.queue_redraw()
	
	# Check if request is still valid (user might have moved mouse away)
	if _target_term != term_key:
		visible = false # Hide if invalid
		return
	
	is_modal = modal
	
	# Apply scale
	var final_scale = Vector2(ui_scale, ui_scale)
	
	if modal:
		# Modal mode: Centered, dark background
		background.visible = true
		background.mouse_filter = Control.MOUSE_FILTER_STOP
		
		panel.set_anchors_preset(Control.PRESET_CENTER)
		# Center taking scale into account
		panel.position = (viewport_size - (panel.size * ui_scale)) * 0.5
		# We need to reset pivot or adjust position because scaling happens from top-left by default
		panel.pivot_offset = Vector2.ZERO
		
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_children_mouse_filter(panel, Control.MOUSE_FILTER_STOP)
		
	else:
		# Tooltip mode: Near mouse, no background dim
		background.visible = false
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.pivot_offset = Vector2.ZERO
		
		# Position above the target position with offset
		# The panel size in pixels is panel.size * ui_scale
		var visual_size = panel.size * ui_scale
		var offset_y = visual_size.y + (15 * ui_scale)
		var target_pos = pos - Vector2(visual_size.x * 0.5, offset_y)
		
		# Keep inside screen bounds
		target_pos.x = clamp(target_pos.x, 10 * ui_scale, viewport_size.x - visual_size.x - (10 * ui_scale))
		target_pos.y = clamp(target_pos.y, 10 * ui_scale, viewport_size.y - visual_size.y - (10 * ui_scale))
		
		panel.position = target_pos
		
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_filter(panel, Control.MOUSE_FILTER_IGNORE)
	
	# Animate entrance
	# Start slightly smaller than final scale
	panel.scale = final_scale * 0.9
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_property(panel, "scale", final_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_children_mouse_filter(node: Node, filter: int):
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = filter
		_set_children_mouse_filter(child, filter)

func handle_hover(term_key: String, active: bool, pos: Vector2):
	if is_modal:
		return # Don't interfere if modal is open
		
	if active:
		show_term(term_key, false, pos)
	else:
		close()

func _on_close_button_pressed():
	close()

func _gui_input(event):
	if is_modal and event is InputEventMouseButton and event.pressed:
		close()

func close():
	_target_term = ""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	# Scale down slightly relative to current ui_scale
	tween.tween_property(panel, "scale", Vector2(ui_scale, ui_scale) * 0.9, 0.1)
	tween.finished.connect(func(): visible = false; is_modal = false)
