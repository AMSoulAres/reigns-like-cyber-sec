# Guia de Questlines

O sistema de cartas agora suporta personagens recorrentes com sequencias de eventos (questlines). As cartas ficam agrupadas em pastas numeradas (`card_data/hacker_bug`, `card_data/tech_breach`, etc.), facilitando enxergar a ordem sugerida (01, 02, 03...). Cada carta pode apontar explicitamente para a proxima etapa por lado da escolha, incluindo atrasos antes do reaparecimento e finais que encerram a partida.

## Propriedades novas em `CardData`
- `questline_id`: identifica todas as cartas da mesma narrativa.
- `quest_step`: indica a ordem (0 para a carta de entrada, numeros maiores para os passos seguintes).
- `available_from_start`: quando `true`, a carta entra no baralho inicial. Use `false` para cartas que so devem aparecer apos serem agendadas por outra carta.
- `reshuffle_after_use`: define se a carta volta para o descarte para reaparecer futuramente. Para passos de questline geralmente queremos `false`.
- `next_card_id_left` / `next_card_id_right`: `card_id` da proxima carta a ser agendada apos cada decisao.
- `next_card_delay_left` / `next_card_delay_right`: numero de cartas sorteadas antes da proxima etapa reaparecer.
- `game_over_left` / `game_over_right`: dispara `Game Over` imediato para a escolha correspondente (independente dos atributos).

## Como montar uma nova questline
1. Crie uma carta "entrada" (`quest_step = 0`) com `available_from_start = true` e `reshuffle_after_use = false`.
2. Defina os efeitos de cada decisao e o proximo `card_id` usando os campos `next_card_id_*`. Se nao quiser continuacao, deixe vazio.
3. Crie as cartas seguintes (`quest_step = 1, 2, ...`) com `available_from_start = false`.
4. Ajuste `next_card_delay_*` para controlar quantos turnos devem passar ate o proximo capitulo aparecer.
5. Marque `game_over_* = true` em qualquer decisao que deva encerrar a campanha imediatamente.

## Exemplo de fluxo
- `hacker_bug_01_entry` -> (ignorar) -> `hacker_bug_02_ignore_fallout` -> (encobrir) -> Game Over.
- `tech_breach_01_entry` -> (corrigir) -> `tech_breach_02_training` -> (investir) -> `tech_breach_03_audit` -> (negligenciar) -> `tech_breach_03_board_hearing` -> (mentir) -> Game Over.

## Templates
Ha dois recursos de exemplo desativados (`example_quest_step0.tres` e `example_quest_step1.tres`). Duplique-os, mude os IDs e personalize para criar novas narrativas rapidamente.

Dica: mantenha cada `card_id` unico e, sempre que possivel, reutilize retratos para reforcar que o mesmo personagem esta voltando ao jogo.