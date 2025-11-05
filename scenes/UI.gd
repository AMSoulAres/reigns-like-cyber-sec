# UI.gd
extends CanvasLayer

# Referências às barras de progresso.
@onready var money_bar = %MoneyBar
@onready var moral_bar = %MoralBar
@onready var infra_bar = %InfraBar
@onready var reputation_bar = %RepBar

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
	_on_stats_changed(initial_stats)

# Esta função é o 'receptor' do sinal.
# O argumento 'new_stats' é o dicionário que enviamos com o sinal.
func _on_stats_changed(new_stats: Dictionary):
	# Atualiza o valor de cada barra de progresso com os novos dados.
	money_bar.value = new_stats["money"]
	moral_bar.value = new_stats["moral"]
	infra_bar.value = new_stats["infra"]
	reputation_bar.value = new_stats["reputation"]
