# Relatório de validação — protótipo Muchineko

Data: 18/11/2026. Engine: Godot 4.4.1 stable, GL Compatibility.

## Como foi testado (e os limites do ambiente)

- Testes automatizados em **modo headless**, com eventos de entrada reais (`InputEventAction`) controlando o jogador.
- Capturas e inspeção visual com o jogo **realmente em execução**, usando renderização por software (Mesa llvmpipe sob Xvfb). Não havia GPU nem janela real.
- **Não houve sessão de jogo interativa com uma pessoa.** A sensação do controle, o conforto da câmera, a fluidez das animações em movimento e a impressão geral dependem de você.
- **Áudio não foi ouvido.** O sandbox usa o driver de áudio "dummy". Os sons foram verificados só por análise de forma de onda (pico, clipping, bordas dos loops).
- **Desempenho real não foi medido.** Software rendering não representa o seu notebook.
- **Não foi gerado executável.** Os templates de exportação não estão instalados no sandbox; entrego o projeto completo.

## Resultado dos testes automatizados: 49 aprovados, 0 falhos

Lista completa em `tests/last_run_report.txt`. O que cobrem:

| Área | O que foi verificado |
|---|---|
| Inicialização | Cena principal sobe sem erro; nós esperados existem; Input Map definido |
| Paleta | Constantes são exatamente os 6 HEX oficiais |
| Física | Parado no chão sem jitter (variação de y 0,0000) |
| Movimento | Caminhada e corrida batem com os parâmetros (±3%); velocidade cai com o peso; para em menos de 0,5 s sem parar instantaneamente; inverte direção em menos de 0,4 s |
| Salto | Altura: leve ≈147 px, normal ≈125, pesado ≈85; altura variável; coyote time; jump buffer |
| Percurso | Cada salto da rota principal é alcançável por gato leve, normal e pesado (varredura de tempo de segurar e velocidade de partida) |
| Peso como ferramenta | Passarela opcional: só o gato leve alcança direto; normal e pesado não; rota alternativa por saliência alcançável por normal e pesado |
| Retorno | Escada de incêndio sobe do beco ao terraço em 4 saltos (normal e pesado); descer com S+Espaço; subir atravessando por baixo |
| Colisão | Parede à direita sem atravessar e sem tremer (variação < 0,5 px); limite à esquerda; queda pela borda pousa corretamente |
| Itens | Ração +2% e contador; lata +10%; correr reduz o peso devagar |
| Interação | Porta abre e fecha com E; janela acende |
| Câmera/respawn | Respeita limites; cair no vazio reaparece no início |

## Problemas encontrados e corrigidos durante a validação

1. Erros de parse no script do gato (ordem dos argumentos de `draw_line`): corrigido.
2. Skyline invisível por causa do deslocamento vertical do parallax: corrigido.
3. **Violação da regra de paleta:** o código usava misturas e transparências que geravam tons cinza fora dos 6 aprovados (janelas do fundo, névoa, céu, sombra, poeira, overlay de pausa). Corrigido com cores exatas e tramas de listras. Verificação por pixel nas 16 capturas: 97,0% a 99,4% dos pixels são exatamente um dos 6 tons; o restante são bordas suavizadas; saturação máxima 0,094 (igual à do próprio Warm Gray).
4. A rota alternativa até a passarela era apertada demais para o gato pesado: aumentei provisoriamente o multiplicador de salto pesado (0,82 → 0,86).
5. Vários testes meus estavam errados no começo (corrida contra a caixa de ventilação, lata já coletada, expectativa de pouso); foram corrigidos, e os testes de rota agora varrem parâmetros em vez de depender de um salto único.

## Comportamento conhecido do Godot

Rodar `godot --path .` numa pasta recém-extraída, sem importar antes, falha com "Could not find type Player/RooftopLevel" (cache de `class_name` ausente). Testei: depois de `--import` (ou de abrir no editor) tudo funciona e os 49 testes passam em uma pasta limpa.

## Não testado

Controle de videogame; reiniciar pelo menu de pausa (só a tela de pausa foi capturada, a navegação por teclado não foi exercitada); outras proporções de janela; execução prolongada; outras versões do Godot; áudio audível.

## Avaliação visual (minha, a confirmar por você)

Bate com a referência: paleta, geometria Bauhaus, HUD, letreiro むちねこ, caixa d'água com cúpula, fachada clara com grade de janelas sob laje preta, gato de manchas pretas.

Ainda diverge do conceito: o gato é mais anguloso e menos "mochi" que o da imagem e só aparece de perfil; o skyline ainda tem mais ruído de janelas que a referência, que é mais suave; o primeiro plano é pobre; a escala do gato é um pouco menor que a da imagem.

## Decisões ainda pendentes

D-001 (faixas de peso), D-002 (engine, resolvida por você: Godot), enquadramento e resolução definitivos, parâmetros finais de física, forma da arte final. Nenhum documento canônico foi alterado.
