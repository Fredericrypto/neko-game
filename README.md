# Muchineko — protótipo visual e jogável

Primeiro contato jogável: um gato, uma pequena área de telhados e a identidade e-ink. Projeto Godot real (cenas, scripts, Input Map, recursos). **Não é o jogo nem o Vertical Slice.**

## Versão e como abrir

- **Godot 4.4.1 (stable)**, renderizador **GL Compatibility**. Foi a versão usada para construir e testar. Outras 4.x podem funcionar, mas não foram testadas.
- Abra o Godot, clique em **Import**, escolha o `project.godot` desta pasta e abra. Na primeira abertura ele reimporta fontes e áudios (alguns segundos).
- Rode com **F5** (cena principal `scenes/main/main.tscn`).
- Por linha de comando, **importe antes** (o Godot só registra as `class_name` na primeira importação; sem isso aparece "Could not find type Player"): `godot --headless --path . --import` e depois `godot --path .`.

## Controles (Input Map do projeto, teclas físicas: funcionam em ABNT2 e QWERTY)

| Ação | Teclado | Controle |
|---|---|---|
| Mover | A / D ou setas | Analógico esquerdo / direcional |
| Pular | Espaço (ou W / ↑) | A |
| Correr | Shift | X ou gatilho direito |
| Interagir | E | Y |
| Descer de plataforma fina | S + Espaço | Baixo + A |
| Pausar | Esc | Start |
| **Teste de peso** (ferramenta temporária) | **1** = mais leve, **2** = mais pesado | — |

Controle de videogame está mapeado, mas **não foi testado** (eu não tenho um controle).

## O que existe

- Gato procedural vetorial (corpo, cabeça, orelhas, 4 patas, cauda de molas), com idle, caminhada, corrida, salto, queda, aterrissagem com achatamento e derrapagem de mudança de direção.
- Peso contínuo de 0 a 100% (começa em 42%, como no conceito). Muda silhueta, hitbox, velocidade, aceleração, salto, aterrissagem e som. Ração (+2%) e lata (+10%) engordam; correr emagrece devagar.
- Área de telhados com 3 alturas, vão, caixote, tubo, torre com caixa d'água, passarela opcional (só o gato leve alcança direto), duas escadas de incêndio que levam de volta (rota alternativa), porta interativa com janela que acende.
- Fundo em duas camadas de parallax com o letreiro むちねこ, antenas, fios, planta, ventilador e folhas movidos por um vento compartilhado.
- HUD no estilo do conceito (WEIGHT, barra, %, contador de ração, pausa). Menu de pausa com Retomar, Reiniciar e Sair.
- Áudio básico sintetizado (passos, pulo, pouso, comer, porta, ambiência e vento).

## Estrutura

```
project.godot            configuração + Input Map
scenes/main|player|environment|ui   cenas
scripts/player           player.gd, cat_visual.gd, movement_params.gd
scripts/camera           follow_camera.gd
scripts/environment      nível (dados + colisão), skyline, fachadas, vida ambiental, itens, porta
scripts/systems          palette.gd, game_audio.gd
scripts/ui               hud.gd
resources/movement_params.tres   TODOS os parâmetros de movimento e peso (editáveis no Inspetor)
assets/audio|fonts       áudio gerado por tools/generate_audio.py; fonte Zen Kaku Gothic New (OFL)
tests/                   run_tests.gd (49 testes) e last_run_report.txt
tools/                   setup_input_map.gd, generate_audio.py, shot.gd, capture_demo.gd
screenshots/             capturas reais da execução
```

## Testes

```
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
```

Capturas reais (precisam de renderização; no meu sandbox usei Xvfb):
`godot --path . -s tools/capture_demo.gd -- res://screenshots`

## Provisório (nada disso é decisão aprovada)

- Resolução 1280×720 com zoom de câmera 1,15 e enquadramento: a documentação deixa pendente.
- Faixas de peso (Light 0–30, Normal 31–65, Heavy 66–100) e todos os multiplicadores: dependem da decisão D-001. Ficam em `movement_params.tres`.
- Valores de física (gravidade, velocidades, salto): ajustados por teste, não por sensação em mãos humanas.
- Arte: tudo desenhado por código em vetores; é uma proposta para avaliação, não asset final.
- Áudio: sintético, só para dar vida ao protótipo.
- A fonte (Zen Kaku Gothic New, licença OFL, `assets/fonts/OFL.txt`) é escolha provisória para HUD e letreiro.

## Limitações conhecidas

Sem menu principal, sem remapeamento de teclas, sem dia/noite, sem clima, sem áudio espacial/binaural, sem interiores, sem save, sem inimigos, sem NPCs. O gato só tem vista lateral (não há as poses frontais do conceito).
