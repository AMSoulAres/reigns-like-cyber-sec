extends Node

var terms = {
	"phishing": {
		"title": "Phishing",
		"definition": "Phishing é um tipo de golpe cibernético que usa mensagens falsas para enganar pessoas e roubar informações confidenciais como senhas, dados bancários e números de cartão de crédito."
	},
	"malware": {
		"title": "Malware",
		"definition": "Malware (software malicioso) é qualquer programa ou arquivo prejudicial ao usuário de computador. Exemplos incluem vírus, worms, cavalos de Troia e spyware."
	},
	"ransomware": {
		"title": "Ransomware",
		"definition": "Ransomware é um tipo de malware que sequestra os dados da vítima, criptografando-os, e exige um pagamento (resgate) para restaurar o acesso."
	},
	"firewall": {
		"title": "Firewall",
		"definition": "Um firewall é um sistema de segurança de rede que monitora e controla o tráfego de rede de entrada e saída com base em regras de segurança predeterminadas."
	},
	"vpn": {
		"title": "VPN",
		"definition": "Uma VPN (Rede Privada Virtual) estende uma rede privada através de uma rede pública e permite que os usuários enviem e recebam dados através de redes compartilhadas ou públicas como se seus dispositivos de computação estivessem diretamente conectados à rede privada."
	}
}

func process_text(text: String) -> String:
	var processed_text = text
	# Sort terms by length (descending) to avoid replacing substrings of longer terms first
	var sorted_keys = terms.keys()
	sorted_keys.sort_custom(func(a, b): return a.length() > b.length())
	
	for term in sorted_keys:
		# Case insensitive search
		var regex = RegEx.new()
		regex.compile("(?i)\\b" + term + "\\b")
		
		# Using a callback to preserve the original case of the matched word
		var matches = regex.search_all(processed_text)
		for i in range(matches.size() - 1, -1, -1):
			var match_result = matches[i]
			var start = match_result.get_start()
			var end = match_result.get_end()
			var original_word = match_result.get_string()
			
			# Add styling: Bold, Yellow Color, Underline
			var replacement = "[url=" + term + "][b][color=#FFD700][u]" + original_word + "[/u][/color][/b][/url]"
			processed_text = processed_text.left(start) + replacement + processed_text.right(-end)
			
	return processed_text

func get_definition(term_key: String) -> Dictionary:
	return terms.get(term_key.to_lower(), {})
