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
	},
	"zero trust": {
		"title": "Zero Trust",
		"definition": "Zero Trust é um modelo de segurança cibernética que opera com o princípio de nunca confiar e sempre verificar, assumindo que ameaças podem vir de dentro ou fora da rede. Ele elimina a confiança implícita e exige verificação constante para cada solicitação de acesso"
	},
	"patch": {
		"title": "Patch",
		"definition": "Um patch é uma atualização que corrige falhas de segurança ou outros problemas em um software ou sistema, sem alterar suas funcionalidades."
		},
	"mfa": {
		"title": "MFA",
		"definition": "MFA (Multi-Factor Authentication) é um método de autenticação que requer mais de uma forma de verificação para confirmar a identidade de um usuário. Exigindo senha, código de verificação, biometria entre outros."
	},
	"dark web": {
		"title": "Dark Web",
		"definition": "A Dark Web é uma parte da Web que não é acessível pelos motores de busca e que requer protocolos de segurança para acessar. É um ambiente anônimo e potencialmente perigoso, onde ocorrem transações ilegais e atividades criminosas."
	},
	"patches": {
		"title": "Patches",
		"definition": "Patches são atualizações que corrigem falhas de segurança ou outros problemas em um software ou sistema, sem alterar suas funcionalidades."
	},
	"backup": {
		"title": "Backup",
		"definition": "Backup é a cópia de segurança de dados, arquivos ou sistemas para que possam ser restaurados em caso de perda, corrupção ou falha."
	},
	"logs": {
		"title": "Logs",
		"definition": "Logs são registros de eventos, operações ou transações que ocorrem em um sistema ou aplicativo. Eles são usados para monitorar, rastrear e analisar o funcionamento do sistema."
	},
	"log": {
		"title": "Log",
		"definition": "Log é um registro de eventos, operações ou transações que ocorrem em um sistema ou aplicativo. Eles são usados para monitorar, rastrear e analisar o funcionamento do sistema."
	},
	"minerando": {
		"title": "Minerando",
		"definition": "Minerar é o processo de extração de dados de uma fonte externa para o sistema. No contexto de criptomoedas, é criação de novos blocos na blockchain, \"gerando moedas\"."
	},
	"minerar": {
		"title": "Minerar",
		"definition": "Minerar é o processo de extração de dados de uma fonte externa para o sistema. No contexto de criptomoedas, é criação de novos blocos na blockchain, \"gerando moedas\"."
	},
	"criptomoedas": {
		"title": "Criptomoedas",
		"definition": "Criptomoedas são moedas digitais que usam tecnologia blockchain para operar, sem a necessidade de uma autoridade central."
	},
	"criptomoeda": {
		"title": "Criptomoeda",
		"definition": "Criptomoeda é uma moeda digital que usam tecnologia blockchain para operar, sem a necessidade de uma autoridade central."
	},
	"chave privada": {
		"title": "Chave Privada",
		"definition": "Chave privada é um código único gerado na criptografia RSA para criptografar e descriptografar dados. Ela deve ser guardada em segurança e nunca compartilhada."
	},
	"chave publica": {
		"title": "Chave Pública",
		"definition": "Chave pública é um código único gerado na criptografia RSA para criptografar e descriptografar dados. Ela pode ser compartilhada livremente para todos que desejarem criptografar dados para você."
	},
	"dlp": {
		"title": "DLP",
		"definition": "DLP (Data Loss Prevention) é um sistema/estatégia de segurança que monitora e controla o fluxo de dados sensíveis em uma organização, prevendo e mitigando vazamentos de dados."
	},
	"arquitetura do sistema": {
		"title": "Arquitetura do Sistema",
		"definition": "Arquitetura do Sistema é a estrutura e design de um sistema, incluindo componentes, interações e fluxos de dados. Ela define como os componentes se comunicam e como os dados fluem entre eles."
	},
	"ip": {
		"title": "IP",
		"definition": "IP (Internet Protocol) é um endereço único que identifica um dispositivo na rede. Cada dispositivo na internet tem um endereço IP único e pode ser acessável por esse endereço"
	},
	"porta": {
		"title": "Porta",
		"definition": "Porta é um número que identifica um serviço ou aplicativo em um dispositivo na rede. Cada serviço ou aplicativo em um dispositivo tem uma ou mais portas para comunicação. Todo IP possui portas que podem ser abertas ou fechadas para comunicação."
	},
	"ips": {
		"title": "IP",
		"definition": "IP (Internet Protocol) é um endereço único que identifica um dispositivo na rede. Cada dispositivo na internet tem um endereço IP único e pode ser acessável por esse endereço"
	},
	"portas": {
		"title": "Porta",
		"definition": "Porta é um número que identifica um serviço ou aplicativo em um dispositivo na rede. Cada serviço ou aplicativo em um dispositivo tem uma ou mais portas para comunicação. Todo IP possui portas que podem ser abertas ou fechadas para comunicação."
	},
	"btc": {
		"title": "BTC",
		"definition": "BTC (Bitcoin) é a moeda digital mais popular e amplamente utilizada. Famosa por ser a primeira criptomoeda, baixa rastreabilidade e baixa volatilidade."
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
			# We quote the URL parameter to handle spaces correctly (e.g. [url="zero trust"])
			var replacement = "[url=\"" + term + "\"][b][color=#FFD700][u]" + original_word + "[/u][/color][/b][/url]"
			processed_text = processed_text.left(start) + replacement + processed_text.right(-end)
			
	return processed_text

func get_definition(term_key: String) -> Dictionary:
	return terms.get(term_key.to_lower(), {})
