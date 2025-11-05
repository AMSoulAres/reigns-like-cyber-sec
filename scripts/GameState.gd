extends Node

const MIN_STAT = 0
const MAX_STAT = 100

var _money: int = 50
var money: int:
	get:
		return _money
	set(value):
		_money = clamp(value, MIN_STAT, MAX_STAT)

var _moral: int = 50
var moral: int:
	get:
		return _moral
	set(value):
		_moral = clamp(value, MIN_STAT, MAX_STAT)

var _infra: int = 50
var infra: int:
	get:
		return _infra
	set(value):
		_infra = clamp(value, MIN_STAT, MAX_STAT)

var _reputation: int = 50
var reputation: int:
	get:
		return _reputation
	set(value):
		_reputation = clamp(value, MIN_STAT, MAX_STAT)

# --- Sinais de Jogo e Estado ---
signal stats_changed(stats_dict)
signal game_over

func _ready():
	emit_stats_changed()

func apply_effects(effects: Dictionary):
	if effects.has("money"):
		money = money + effects["money"]
	if effects.has("infra"):
		infra = infra + effects["infra"]
	if effects.has("moral"):
		moral = moral + effects["moral"]
	if effects.has("reputation"):
		reputation = reputation + effects["reputation"]
		
	emit_stats_changed()
	check_game_over_conditions()
	
func check_game_over_conditions():
	var depleted = money <= MIN_STAT or infra <= MIN_STAT or moral <= MIN_STAT or reputation <= MIN_STAT
	var overflow = money >= MAX_STAT or infra >= MAX_STAT or moral >= MAX_STAT or reputation >= MAX_STAT

	if depleted:
		emit_signal("game_over")
		print("Game Over: Um dos recursos se esgotou.")
	elif overflow:
		emit_signal("game_over")
		print("Game Over: Um dos recursos excedeu o limite.")

func trigger_game_over(message: String = ""):
	if message != "":
		print(message)
	emit_signal("game_over")

func emit_stats_changed():
	var stats = {
		"money": money,
		"infra": infra,
		"moral": moral,
		"reputation": reputation
	}
	emit_signal("stats_changed", stats)
