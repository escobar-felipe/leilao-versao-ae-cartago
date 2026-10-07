# Leilão Japonês em JaCaMo, Versão AE

Sistema multiagente que vende um produto pelas regras do
[Japanese Auction](https://en.wikipedia.org/wiki/Japanese_auction).
Nesta versão o ambiente ajuda o leilão: um artefato CArtAgO, a máquina de leilão,
publica o preço de cada rodada e recolhe quem continua. Os agentes continuam em Jason.

A versão A, só com agentes e mensagens, está em
[leilao-versao-a-jason](https://github.com/escobar-felipe/leilao-versao-a-jason).
O [`relatorio.md`](relatorio.md) compara as duas.

## Como executar

Você precisa de Java 21. O Gradle wrapper baixa o JaCaMo 1.3.1 na primeira execução.

```bash
./gradlew -q --console=plain
```

Se tiver o JaCaMo CLI instalado, `jacamo leilao.jcm` também funciona.
A saída vai para o console. O leiloeiro encerra o MAS ao final do leilão.
Durante a execução, o inspetor de agentes fica em http://127.0.0.1:3272 e o de
artefatos em http://127.0.0.1:3273.
O arquivo [`docs/log-exemplo.txt`](docs/log-exemplo.txt) guarda o log de uma execução completa.

## Estrutura

| Arquivo | Papel |
|---|---|
| `leilao.jcm` | Declara o MAS: 1 `leiloeiro`, 3 `licitante`, 1 `cauteloso`, o workspace e o artefato |
| `src/env/leilao/MaquinaLeilao.java` | Artefato CArtAgO: propriedades observáveis e operações do leilão |
| `src/agt/leiloeiro.asl` | Conduz as rodadas pela máquina e declara o vencedor |
| `src/agt/estrategia_licitante.asl` | Comportamento comum dos licitantes, incluído pelos dois arquivos abaixo |
| `src/agt/licitante.asl` | Licitante racional: fica até o seu valor máximo privado, `margem(1)` |
| `src/agt/cauteloso.asl` | Licitante que desiste a 80% do valor máximo, `margem(0.8)` |
| `relatorio.md` | Relatório do trabalho com a análise comparativa |

## A máquina de leilão

Propriedades observáveis, que viram crenças de todo agente com `focus` no artefato:
`item(I)`, `inscritos(L)`, `rodada(R)`, `preco(P)`, `continuam(L)` e, no fim,
`vencedor(V)` e `preco_final(P)`.

Operações: `entrar` para o licitante se inscrever, `anunciar(R, P)` para o leiloeiro
publicar o preço da rodada, `continuar` para o licitante aceitar o preço e
`encerrar(V, P)` para o leiloeiro publicar o resultado. Desistir é não chamar `continuar`.

## Regras implementadas

- O leiloeiro anuncia um preço inicial de 50 e sobe 10 por rodada.
- Em cada rodada, cada licitante ativo que aceita o preço executa `continuar`. Quem não aceita fica fora.
- Cada rodada dura 1 segundo. Licitante que não responde nesse tempo conta como desistente.
- Quando resta um único licitante ativo, ele vence pelo preço da rodada.
- Se todos os ativos desistem na mesma rodada, o leiloeiro sorteia um deles como vencedor,
  pelo preço da rodada anterior.
- Se ninguém aceita o preço inicial, o item fica sem venda.

## Parâmetros

O item fica no `leilao.jcm`, no argumento do artefato. Preço inicial, incremento e tempo
da rodada ficam nas crenças iniciais de `leiloeiro.asl`. Para mudar o número de licitantes,
edite `instances: 3` no `leilao.jcm`.
