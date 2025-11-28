# UI.gd
extends CanvasLayer

# Referências às barras de progresso e container principal.
@onready var money_fill: TextureProgressBar = %MoneyFill
@onready var moral_fill: TextureProgressBar = %MoralFill
@onready var sec_fill: TextureProgressBar = %SecFill
@onready var reputation_fill: TextureProgressBar = %RepFill
@onready var root_container: Control = %HBoxContainer
@onready var glossary_popup: Control = %GlossaryPopup

var _active_tweens: Dictionary = {}
var _color_tweens: Dictionary = {}
var _base_colors: Dictionary = {}
var _base_container_size: Vector2 = Vector2.ZERO
var _base_container_pos: Vector2 = Vector2.ZERO
var _layout_ready := false
var _last_card_size: Vector2 = Vector2.ZERO
var _last_viewport_size: Vector2 = Vector2.ZERO
var _viewport_connected := false

const COLOR_HIGHLIGHT_UP = Color(0.2, 0.85, 0.2, 1.0)
const COLOR_HIGHLIGHT_DOWN = Color(0.9, 0.2, 0.2, 1.0)
const REFERENCE_RESOLUTION = Vector2(1920, 1080)
const REFERENCE_CARD_SIZE = Vector2(541, 843)
const BASELINE_CARD_SCALE = REFERENCE_RESOLUTION.y / REFERENCE_CARD_SIZE.y

# A função _ready é chamada uma vez quando o nó entra na árvore de cena.
func _ready():
	# Conecta o sinal 'stats_changed' do GameState à nossa função '_on_stats_changed'.
	# Quando o GameState emitir o sinal, esta função será chamada automaticamente.
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.critical_warning.connect(_on_critical_warning)
	_register_fill(money_fill)
	_register_fill(moral_fill)
	_register_fill(sec_fill)
	_register_fill(reputation_fill)
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	if not is_inside_tree():
		call_deferred("_initialize_ui")
		return
	await get_tree().process_frame
	_capture_layout_metrics()
	await _connect_viewport_signals()
	_update_layout()
	var initial_stats = {
		"money": GameState.money,
		"moral": GameState.moral,
		"sec": GameState.sec,
		"reputation": GameState.reputation
	}
	_apply_stats(initial_stats, false)

# Esta função é o 'receptor' do sinal.
# O argumento 'new_stats' é o dicionário que enviamos com o sinal.
func _on_stats_changed(new_stats: Dictionary):
	_apply_stats(new_stats, true)

func _on_viewport_size_changed():
	var viewport := get_viewport()
	if viewport == null:
		return
	_last_viewport_size = viewport.get_visible_rect().size
	_update_layout()

func _connect_viewport_signals() -> void:
	if _viewport_connected:
		return
	var tree := get_tree()
	if tree == null:
		return
	while true:
		var viewport := get_viewport()
		if viewport != null:
			if not viewport.size_changed.is_connected(_on_viewport_size_changed):
				viewport.size_changed.connect(_on_viewport_size_changed)
			_last_viewport_size = viewport.get_visible_rect().size
			_viewport_connected = true
			return
		await tree.process_frame

func update_card_metrics(card_size: Vector2, viewport_size: Vector2):
	_last_card_size = card_size
	if viewport_size != Vector2.ZERO:
		_last_viewport_size = viewport_size
	_update_layout()

func _apply_stats(stats: Dictionary, animate: bool = true):
	var money_value = stats.get("money", 0)
	var moral_value = stats.get("moral", 0)
	var sec_value = stats.get("sec", 0)
	var reputation_value = stats.get("reputation", 0)

	if animate:
		_animate_value(money_fill, money_value)
		_animate_value(moral_fill, moral_value)
		_animate_value(sec_fill, sec_value)
		_animate_value(reputation_fill, reputation_value)
	else:
		_set_value_immediate(money_fill, money_value)
		_set_value_immediate(moral_fill, moral_value)
		_set_value_immediate(sec_fill, sec_value)
		_set_value_immediate(reputation_fill, reputation_value)


func _animate_value(node: Range, target_value: float, duration: float = 0.5):
	var tween_id = node.get_instance_id()
	if _active_tweens.has(tween_id):
		var existing: Tween = _active_tweens[tween_id]
		if existing.is_running():
			existing.kill()
		_active_tweens.erase(tween_id)

	if is_equal_approx(node.value, target_value):
		node.value = target_value
		_restore_base_color(node)
		return

	var increasing = target_value > node.value
	_animate_fill_color(node, increasing, duration)

	var tween := create_tween()
	_active_tweens[tween_id] = tween
	var tweener = tween.tween_property(node, "value", target_value, duration)
	tweener.set_trans(Tween.TRANS_SINE)
	tweener.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		if _active_tweens.get(tween_id) == tween:
			_active_tweens.erase(tween_id)
		node.value = target_value
	)

func _set_value_immediate(node: Range, value: float):
	var tween_id = node.get_instance_id()
	if _active_tweens.has(tween_id):
		var existing: Tween = _active_tweens[tween_id]
		if existing.is_running():
			existing.kill()
		_active_tweens.erase(tween_id)
	node.value = value
	_restore_base_color(node)

func _register_fill(node: TextureProgressBar):
	if node == null:
		return
	_base_colors[node.get_instance_id()] = node.tint_progress

func _animate_fill_color(node: Range, increasing: bool, duration: float):
	if not (node is TextureProgressBar):
		return
	var fill: TextureProgressBar = node
	var base_color: Color = _base_colors.get(fill.get_instance_id(), fill.tint_progress)
	var highlight_rgb = COLOR_HIGHLIGHT_UP if increasing else COLOR_HIGHLIGHT_DOWN
	var highlight = Color(highlight_rgb.r, highlight_rgb.g, highlight_rgb.b, base_color.a)
	if highlight.is_equal_approx(base_color):
		return
	var color_key = "%s:color" % fill.get_instance_id()
	if _color_tweens.has(color_key):
		var running: Tween = _color_tweens[color_key]
		if running.is_running():
			running.kill()
		_color_tweens.erase(color_key)
	fill.tint_progress = base_color

	var color_tween := create_tween()
	_color_tweens[color_key] = color_tween
	var to_highlight = color_tween.tween_property(fill, "tint_progress", highlight, duration * 0.35)
	to_highlight.set_trans(Tween.TRANS_SINE)
	to_highlight.set_ease(Tween.EASE_OUT)
	var to_base = color_tween.tween_property(fill, "tint_progress", base_color, duration * 0.65)
	to_base.set_trans(Tween.TRANS_SINE)
	to_base.set_ease(Tween.EASE_IN)
	color_tween.finished.connect(func():
		if _color_tweens.get(color_key) == color_tween:
			_color_tweens.erase(color_key)
			fill.tint_progress = base_color
	)

func _restore_base_color(node: Range):
	if not (node is TextureProgressBar):
		return
	var fill: TextureProgressBar = node
	var color_key = "%s:color" % fill.get_instance_id()
	if _color_tweens.has(color_key):
		var running: Tween = _color_tweens[color_key]
		if running.is_running():
			running.kill()
		_color_tweens.erase(color_key)
	fill.tint_progress = _base_colors.get(fill.get_instance_id(), fill.tint_progress)

func _capture_layout_metrics():
	if root_container == null:
		return
	_base_container_size = root_container.size
	if _base_container_size == Vector2.ZERO:
		_base_container_size = root_container.get_combined_minimum_size()
	_base_container_pos = root_container.position
	_layout_ready = true

func _update_layout():
	if root_container == null:
		return
	if not _layout_ready:
		_capture_layout_metrics()
	var viewport := get_viewport()
	if viewport == null:
		return
	if _last_viewport_size == Vector2.ZERO:
		_last_viewport_size = viewport.get_visible_rect().size
	var viewport_size = _last_viewport_size
	if viewport_size == Vector2.ZERO or _base_container_size == Vector2.ZERO:
		return
		
	var scale_factor = _compute_ui_scale(viewport_size)
	root_container.scale = Vector2.ONE * scale_factor
	
	# Update glossary popup scale
	if glossary_popup and "ui_scale" in glossary_popup:
		glossary_popup.ui_scale = scale_factor
	
	# Use pivot-based scaling to keep it centered via anchors
	# We assume the container is anchored to Top-Center in the scene
	if root_container.size.x > 0:
		root_container.pivot_offset = Vector2(root_container.size.x * 0.5, 0)
	
	# We do NOT set root_container.position manually anymore.
	# The anchors will keep it centered, and pivot_offset + scale will handle the resizing from the center.

func _compute_ui_scale(viewport_size: Vector2) -> float:
	var fallback_scale = min(
		viewport_size.x / REFERENCE_RESOLUTION.x,
		viewport_size.y / REFERENCE_RESOLUTION.y
	)
	if fallback_scale <= 0.0:
		fallback_scale = 0.01
	if _last_card_size == Vector2.ZERO or REFERENCE_CARD_SIZE.y <= 0.0 or BASELINE_CARD_SCALE <= 0.0:
		return fallback_scale
	var card_scale = _last_card_size.y / REFERENCE_CARD_SIZE.y
	if card_scale <= 0.0:
		return fallback_scale
	var normalized_scale = card_scale / BASELINE_CARD_SCALE
	return max(normalized_scale, 0.05)

func show_glossary(term_key: String):
	if glossary_popup and glossary_popup.has_method("show_term"):
		glossary_popup.show_term(term_key, true) # Force show as modal on click

func handle_glossary_hover(term_key: String, active: bool, pos: Vector2):
	if glossary_popup and glossary_popup.has_method("handle_hover"):
		glossary_popup.handle_hover(term_key, active, pos)

func _on_critical_warning(stat_name: String, _value: int):
	# 1. Shake Screen (Root Container)
	var shake_tween = create_tween()
	var original_pos = _base_container_pos
	# Se _base_container_pos for zero, tenta pegar a atual
	if original_pos == Vector2.ZERO and root_container:
		original_pos = root_container.position
		
	for i in range(10):
		var shake_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		shake_tween.tween_property(root_container, "position", original_pos + shake_offset, 0.05)
	shake_tween.tween_property(root_container, "position", original_pos, 0.05)
	
	# 2. Pulse the specific bar
	var target_node: Control = null
	match stat_name:
		"money": target_node = money_fill
		"moral": target_node = moral_fill
		"sec": target_node = sec_fill
		"reputation": target_node = reputation_fill
		
	if target_node:
		var pulse_tween = create_tween()
		pulse_tween.set_loops(4) # 2 seconds total approx
		pulse_tween.tween_property(target_node, "modulate", Color.RED, 0.25)
		pulse_tween.tween_property(target_node, "modulate", Color.WHITE, 0.25)
