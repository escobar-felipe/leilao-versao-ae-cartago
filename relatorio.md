# Relatório: Leilão Japonês em um Sistema Multiagente

**Disciplina:** Sistemas Multiagentes
**Trabalho:** implementação de um Japanese Auction em duas versões. Na versão A só os agentes são programados, em Jason. Na versão AE um artefato CArtAgO instrumenta o ambiente.
**Este documento cobre a versão AE e traz, na seção 7, a análise comparativa entre as duas versões.** A versão A está em https://github.com/escobar-felipe/leilao-versao-a-jason.

## 1. Objetivo

Exercitar a programação das dimensões de um SMA, ou seja, agentes, interação e ambiente, implementando a venda de um produto pelas regras do leilão japonês. Na versão AE o ambiente deixa de ser passivo: um artefato CArtAgO guarda o estado do leilão e serve de ponto de encontro entre leiloeiro e licitantes.

## 2. Regras do leilão japonês

No leilão japonês, também chamado de *button auction*, o preço sobe em degraus fixos. Todos os licitantes começam ativos. A cada aumento de preço, cada licitante decide se permanece ou se retira, e quem se retira não volta. O leilão termina quando resta um único licitante ativo. Ele leva o item pelo preço corrente.

As regras adotadas são as mesmas da versão A:

| Situação | Regra adotada |
|---|---|
| Preço inicial e passo | Preço inicial 50, incremento 10 por rodada |
| Resposta do licitante | Executa `continuar` na máquina se aceita o preço. Sem resposta até o fim da rodada, 1 s, conta como desistência |
| Resta um ativo | Vence pelo preço da rodada |
| Todos os ativos desistem na mesma rodada | Sorteio entre eles. O vencedor paga o preço da rodada anterior, o último que todos aceitaram |
| Ninguém aceita o preço inicial | Item sem venda |

## 3. Arquitetura

### 3.1 Agentes

| Agente | Quantidade | Papel |
|---|---|---|
| `leiloeiro` | 1 | Anuncia o preço na máquina, espera, lê quem continuou e aplica as regras |
| `licitante` | 3 | Licitante racional. Continua enquanto o preço não passa do seu valor máximo privado |
| `cauteloso` | 1 | Desiste quando o preço passa de 80% do valor máximo privado |

Os agentes são os mesmos da versão A. Cada licitante sorteia um valor máximo privado entre 100 e 199 ao iniciar, calcula `limite = floor(valor_maximo * margem)` e guarda o resultado na crença `limite(L)`. O leiloeiro mantém os mesmos planos `!rodada`, `!decidir`, `!resultado` e `!encerrar`.

### 3.2 O artefato: máquina de leilão

A classe `MaquinaLeilao` estende `cartago.Artifact`. Ela não decide nada. Ela é um quadro compartilhado que todos os agentes enxergam.

| Propriedade observável | Quem muda | Significado |
|---|---|---|
| `item(I)` | criação | item em leilão |
| `inscritos(L)` | `entrar` | lista dos licitantes que entraram |
| `rodada(R)`, `preco(P)` | `anunciar` | rodada e preço correntes |
| `continuam(L)` | `continuar`, zerada por `anunciar` | quem aceitou o preço da rodada corrente |
| `vencedor(V)`, `preco_final(P)` | `encerrar` | resultado, definidas só no fim |

| Operação | Quem chama | Efeito |
|---|---|---|
| `entrar` | licitante | acrescenta o nome do agente a `inscritos` |
| `anunciar(R, P)` | leiloeiro | atualiza `rodada` e `preco`, zera `continuam` |
| `continuar` | licitante | acrescenta o nome do agente a `continuam` |
| `encerrar(V, P)` | leiloeiro | define `vencedor` e `preco_final` |

O artefato descobre quem chamou a operação com `getCurrentOpAgentId()`, então o licitante não precisa se identificar. A propriedade `preco` só é criada na primeira chamada de `anunciar`, para que o evento `+preco(P)` dispare já na rodada 1 e não antes.

### 3.3 Interação

Toda a interação passa pela máquina. Ninguém envia mensagem.

```
licitante                 maquina                      leiloeiro
    |-- entrar ------------>|                              |
    |                       |<------------- anunciar(R,P) -|
    |<== percebe preco(P) ==|== percebe preco(P) =========>|
    |-- continuar --------->|                              |
    |                       |<-- le continuam(L) ----------|  apos 1 s
    |                       |         decide: proxima rodada / vencedor / empate / sem venda
    |                       |<------------- encerrar(V,P) -|
    |<== percebe vencedor ==|                              |
```

Cada licitante faz `focus` no artefato pelo `leilao.jcm`. A partir daí, toda mudança nas propriedades observáveis chega como percepção, e a adição de crença `+preco(P)` dispara o plano de resposta. O leiloeiro, depois de esperar o tempo da rodada, lê a crença `continuam(L)` que a máquina mantém e segue com os mesmos quatro planos de `!decidir` da versão A.

## 4. Código

| Arquivo | Conteúdo |
|---|---|
| `leilao.jcm` | Agentes com `focus: w.maquina`, workspace `w` e o artefato |
| `src/env/leilao/MaquinaLeilao.java` | Artefato, 60 linhas |
| `src/agt/leiloeiro.asl` | Crenças de configuração e planos `!iniciar`, `!rodada`, `!decidir`, `!resultado`, `!encerrar` |
| `src/agt/estrategia_licitante.asl` | Entrada na máquina, cálculo de `limite/1`, reação a `+preco` e a `+vencedor` |
| `src/agt/licitante.asl` | `margem(1)` e include |
| `src/agt/cauteloso.asl` | `margem(0.8)` e include |

## 5. Execução de exemplo

O arquivo `docs/log-exemplo.txt` guarda o log completo. Trecho resumido de uma execução:

```
[licitante1] Valor maximo: 198 | desisto acima de 198
[cauteloso]  Valor maximo: 112 | desisto acima de 89
[licitante2] Valor maximo: 135 | desisto acima de 135
[licitante3] Valor maximo: 110 | desisto acima de 110
[leiloeiro] Rodada 1 | preco 50 | ativos: [cauteloso,licitante1,licitante2,licitante3]
...
[leiloeiro] Rodada 5 | preco 90 | ativos: [licitante2,cauteloso,licitante3,licitante1]
[cauteloso] Preco 90, desisto.
...
[leiloeiro] Rodada 10 | preco 140 | ativos: [licitante1,licitante2]
[licitante1] Preco 140, continuo.
[licitante2] Preco 140, desisto.
[leiloeiro] VENCEDOR: licitante1 paga 140 por 'quadro a oleo'
[licitante1] Venci 'quadro a oleo' por 140!
```

Verificamos os outros dois casos em cópias do projeto. Empate: com todos os licitantes valendo 100, todos desistem em 110 e o leiloeiro sorteia um vencedor, que paga 100. Sem venda: com preço inicial 300, ninguém aceita a rodada 1 e o leiloeiro encerra sem vender.

## 6. Observações sobre as estratégias

Valem as mesmas da versão A. Permanecer até o próprio valor máximo é a estratégia dominante, e o `cauteloso` paga o preço de se desviar dela. O preço final fica próximo do segundo maior valor privado, arredondado para o degrau seguinte.

## 7. Análise comparativa: versão A x versão AE

As duas versões usam os mesmos agentes, as mesmas regras e os mesmos planos de decisão do leiloeiro. A diferença está em onde o estado do leilão vive e em como os agentes se coordenam.

| Dimensão | Versão A, só agentes | Versão AE, artefato CArtAgO |
|---|---|---|
| Onde fica o estado do leilão | Nas crenças e nos argumentos dos planos do leiloeiro. Cada licitante guarda a sua cópia do preço, recebida por mensagem | Nas propriedades observáveis do artefato. Existe um único preço, uma única rodada e uma única lista de quem continua, iguais para todos |
| Descoberta dos participantes | Directory Facilitator: `df_register`, `df_search`, `df_subscribe`, mais uma crença `provider` para validar o remetente | `focus` declarado no `.jcm` e operação `entrar`. A lista `inscritos` já chega ao leiloeiro como crença |
| Como o preço chega ao licitante | Mensagem `tell preco(R, P)` enviada pelo leiloeiro à lista de ativos | Percepção `preco(P)`, gerada pelo próprio artefato para todos os que fazem `focus` |
| Como a resposta chega ao leiloeiro | Mensagens `continuo(R)` e `desisto(R)`, contadas com `.findall` por rodada | Operação `continuar`, acumulada pelo artefato em `continuam(L)`. Desistir é não responder |
| Mensagens por rodada | 1 envio em lista mais 1 resposta por ativo | Nenhuma. 1 operação do leiloeiro mais 1 operação por licitante que continua |
| Sincronização da rodada | Espera fixa de 1 s | Espera fixa de 1 s. `anunciar` zera `continuam`, então uma resposta atrasada da rodada anterior não contamina a seguinte sem precisar carregar o número da rodada |
| Garantia das regras | Depende do comportamento dos agentes. Um licitante mal programado pode mandar `continuo` de uma rodada antiga ou responder sem ter sido chamado | O artefato é o único ponto de escrita. Ele pode recusar operações fora de hora com `failed()`, o que não existe com mensagens |
| Observabilidade | Console e Mind Inspector dos agentes | Console, Mind Inspector e inspetor de artefatos em http://127.0.0.1:3273, que mostra o estado do leilão ao vivo |
| Código dos licitantes | 50 linhas de AgentSpeak. Precisa validar o remetente com `provider(A, "leiloeiro")` | 58 linhas de AgentSpeak. Não valida remetente: a percepção vem do artefato |
| Código do leiloeiro | 59 linhas | 59 linhas, com `.send` trocado por `anunciar` e `.findall` trocado por `?continuam(L)` |
| Código em Java | Nenhum | 60 linhas no artefato |
| Execução | `jason leilao.mas2j`, inicia em segundos | `./gradlew`, baixa dependências na primeira vez e sobe dois servidores HTTP |

O que a versão AE ganha:

- **Uma única fonte de verdade.** Preço, rodada e lista de quem continua existem num lugar só. Na versão A cada agente tem a sua cópia, e a consistência depende de toda mensagem chegar.
- **Menos protocolo nos agentes.** O licitante não precisa saber quem é o leiloeiro nem numerar respostas. O leiloeiro não precisa de DF nem de `.findall` por rodada.
- **Ponto natural para impor regras.** Como toda escrita passa pelo artefato, ele pode validar quem entra, quem continua e quando, com `failed()`. Deixamos a máquina sem validações para manter o código curto, mas é uma linha por regra.
- **Inspeção.** O inspetor de artefatos mostra o leilão inteiro numa página.

O que a versão A ganha:

- **Zero Java e zero infraestrutura.** Um arquivo `.mas2j` e quatro `.asl`, rodando com o Jason CLI.
- **Autonomia total dos agentes.** Toda a semântica do leilão está em AgentSpeak. Isso é bom para estudar comunicação, e a razão de a versão A ser o primeiro passo do trabalho.
- **Mais fácil de distribuir.** Mensagens funcionam entre máquinas com JADE sem mudar o código. Um artefato local exige workspace remoto.

Conclusão: para um leilão, que é por natureza um recurso compartilhado com estado único, o artefato é o modelo mais fiel. O leilão japonês real tem um painel com o preço e um botão para cada licitante; a máquina de leilão é exatamente isso. A versão por mensagens reproduz o mesmo comportamento, mas obriga cada agente a reconstruir o estado do painel por conta própria.

## 8. Limitações e trabalhos futuros

- A máquina não valida as operações. Acrescentar `failed()` em `continuar` quando o agente não está entre os ativos, e em `entrar` depois da abertura, fecharia as brechas apontadas na seção 7.
- Um único item por execução. Com o artefato, vários itens seriam vários artefatos, um por leilão.
- As esperas são fixas: 2 s pela inscrição e 1 s por rodada. O artefato poderia sinalizar quando todos os ativos responderam, com `signal`, e o leiloeiro fecharia a rodada na hora.

## 9. Referências

- JaCaMo, documentação oficial: https://jacamo-lang.github.io/
- CArtAgO, API de artefatos: https://cartago.sourceforge.net/
- Exemplo `auction` distribuído com o JaCaMo: https://github.com/jacamo-lang/jacamo/tree/master/examples/auction
- Jason, documentação oficial: https://jason-lang.github.io/doc/
- Japanese auction: https://en.wikipedia.org/wiki/Japanese_auction
- Boissier, O.; Bordini, R. H.; Hübner, J. F.; Ricci, A. *Multi-Agent Oriented Programming: Programming Multi-Agent Systems Using JaCaMo*. MIT Press, 2020.
