# UI.gd
extends CanvasLayer

# Referências às barras de progresso.
@onready var money_bar = %MoneyBar
@onready var moral_bar = %MoralBar
@onready var infra_bar = %InfraBar
@onready var reputation_bar = %RepBar
@onready var money_fill = %MoneyFill
@onready var moral_fill = %MoralFill
@onready var infra_fill = %InfraFill
@onready var reputation_fill = %RepFill

var _active_tweens: Dictionary = {}

# A função _ready é chamada uma vez quando o nó entra na árvore de cena.
func _ready():
	# Conecta o sinal 'stats_changed' do GameState à nossa função '_on_stats_changed'.
	# Quando o GameState emitir o sinal, esta função será chamada automaticamente.
	GameState.stats_changed.connect(_on_stats_changed)
	
	# Chama a função uma vez no início para definir os valores iniciais da UI.
	# Isto pode ser feito emitindo o sinal no _ready() do GameState, como fizemos.
	# Ou chamando a função diretamente com os dados iniciais.
	var initial_stats = {
		"money": GameState.money,
		"moral": GameState.moral,
		"infra": GameState.infra,
		"reputation": GameState.reputation
	}
	_apply_stats(initial_stats)

# Esta função é o 'receptor' do sinal.
# O argumento 'new_stats' é o dicionário que enviamos com o sinal.
func _on_stats_changed(new_stats: Dictionary):
	_apply_stats(new_stats)

func _apply_stats(stats: Dictionary):
	var money_value = stats.get("money", 0)
	var moral_value = stats.get("moral", 0)
	var infra_value = stats.get("infra", 0)
	var reputation_value = stats.get("reputation", 0)

	_animate_value(money_bar, money_value)
	_animate_value(moral_bar, moral_value)
	_animate_value(infra_bar, infra_value)
	_animate_value(reputation_bar, reputation_value)
	_animate_value(money_fill, money_value)
	_animate_value(moral_fill, moral_value)
	_animate_value(infra_fill, infra_value)
	_animate_value(reputation_fill, reputation_value)


func _animate_value(node: Range, target_value: float, duration: float = 0.5):
	var tween_id = node.get_instance_id()
	if _active_tweens.has(tween_id):
		var existing: Tween = _active_tweens[tween_id]
		if existing.is_running():
			existing.kill()
		_active_tweens.erase(tween_id)

	if is_equal_approx(node.value, target_value):
		node.value = target_value
		return

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
