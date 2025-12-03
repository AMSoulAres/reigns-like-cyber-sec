extends Node

const MIN_STAT = 0
const MAX_STAT = 100

var tutorial_active: bool = false
var gallery_active: bool = false

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

var _sec: int = 50
var sec: int:
	get:
		return _sec
	set(value):
		_sec = clamp(value, MIN_STAT, MAX_STAT)

var _reputation: int = 50
var reputation: int:
	get:
		return _reputation
	set(value):
		_reputation = clamp(value, MIN_STAT, MAX_STAT)

var last_game_over_reason: String = ""
var _cards_played: int = 0
var cards_played: int:
	get:
		return _cards_played
	set(value):
		_cards_played = value
var victory_threshold: int = 30

const GAME_OVER_SEQUENCES = {
	"money_min": {
		"card_id": "game_over_money_min_0",
		"reason": "Os cofres secaram."
	},
	"money_max": {
		"card_id": "game_over_money_max_0",
		"reason": "A tesouraria saiu do controle."
	},
	"moral_min": {
		"card_id": "game_over_moral_min_0",
		"reason": "O engajamento da equipe despencou."
	},
	"moral_max": {
		"card_id": "game_over_moral_max_0",
		"reason": "O engajamento da equipe saiu do controle."
	},
	"sec_min": {
		"card_id": "game_over_sec_min_0",
		"reason": "A defesa cibernetica colapsou."
	},
	"sec_max": {
		"card_id": "game_over_sec_max_0",
		"reason": "A defesa cibernetica travou a operacao."
	},
	"reputation_min": {
		"card_id": "game_over_rep_min_0",
		"reason": "A reputacao da empresa afundou."
	},
	"reputation_max": {
		"card_id": "game_over_rep_max_0",
		"reason": "A reputacao desmedida provocou caos."
	},
	"victory": {
		"card_id": "retirement_00",
		"reason": "Você completou sua jornada como Chefe de Segurança."
	}
}

var _sequence_triggered: Dictionary = {}

# --- Sinais de Jogo e Estado ---
signal stats_changed(stats_dict)
signal game_over
signal game_over_sequence_requested(card_id: String, reason: String)
signal critical_warning(stat_name: String, value: int)

func _ready():
	_reset_sequences()
	emit_stats_changed()

func apply_effects(effects: Dictionary):
	if effects.has("money"):
		money = money + effects["money"]
	if effects.has("sec"):
		sec = sec + effects["sec"]
	if effects.has("moral"):
		moral = moral + effects["moral"]
	if effects.has("reputation"):
		reputation = reputation + effects["reputation"]
		
	emit_stats_changed()
	check_game_over_conditions()
	
func check_game_over_conditions():
	if _maybe_queue_sequence("money_min", money <= MIN_STAT, "money"): return
	if _maybe_queue_sequence("money_max", money >= MAX_STAT, "money"): return
	if _maybe_queue_sequence("moral_min", moral <= MIN_STAT, "moral"): return
	if _maybe_queue_sequence("moral_max", moral >= MAX_STAT, "moral"): return
	if _maybe_queue_sequence("sec_min", sec <= MIN_STAT, "sec"): return
	if _maybe_queue_sequence("sec_max", sec >= MAX_STAT, "sec"): return
	if _maybe_queue_sequence("reputation_min", reputation <= MIN_STAT, "reputation"): return
	if _maybe_queue_sequence("reputation_max", reputation >= MAX_STAT, "reputation"): return
	print("Cards played: %d/%d" % [cards_played, victory_threshold])
	print(cards_played >= victory_threshold)
	if _maybe_queue_sequence("victory", cards_played >= victory_threshold, "cards_played"): return

func trigger_game_over(message: String = ""):
	if message != "":
		last_game_over_reason = message
		print(message)
	else:
		last_game_over_reason = "O jogo terminou."
	emit_signal("game_over")

func reset_state():
	money = 50
	sec = 50
	moral = 50
	reputation = 50
	cards_played = 0
	last_game_over_reason = ""
	_reset_sequences()
	emit_stats_changed()

func emit_stats_changed():
	var stats = {
		"money": money,
		"sec": sec,
		"moral": moral,
		"reputation": reputation
	}
	emit_signal("stats_changed", stats)

func _maybe_queue_sequence(key: String, condition: bool, stat_name: String = "") -> bool:
	if not condition:
		return false
	if _sequence_triggered.get(key, false):
		return false
		
	_sequence_triggered[key] = true
	_execute_game_over_sequence(key, stat_name)
	return true

func _execute_game_over_sequence(key: String, stat_name: String):
	# Emit warning and wait
	if stat_name != "" and stat_name != "cards_played":
		emit_signal("critical_warning", stat_name, 0)
		await get_tree().create_timer(2.0).timeout
	
	var info: Dictionary = GAME_OVER_SEQUENCES.get(key, {})
	var card_id: String = info.get("card_id", "")
	var reason: String = info.get("reason", "")
	
	if reason != "":
		last_game_over_reason = reason
	if card_id == "":
		trigger_game_over(reason)
	else:
		emit_signal("game_over_sequence_requested", card_id, reason)

func _reset_sequences():
	_sequence_triggered.clear()
	for key in GAME_OVER_SEQUENCES.keys():
		_sequence_triggered[key] = false
