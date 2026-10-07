// Leiloeiro: anuncia o preco na maquina a cada rodada, espera e decide.
// Mesmos planos da versao A; mensagens trocadas por operacoes no artefato.

/* Crencas iniciais */

preco_inicial(50).
incremento(10).
tempo_rodada(1000).      // ms de espera pelas respostas de cada rodada

/* Objetivo inicial */

!iniciar.

/* Planos */

+!iniciar
   <- .wait(2000);                   // tempo para os licitantes entrarem
      ?inscritos(L);
      ?preco_inicial(P);
      !rodada(1, P, L).

+!rodada(R, P, Ativos)
   <- .print("Rodada ", R, " | preco ", P, " | ativos: ", Ativos);
      anunciar(R, P);
      ?tempo_rodada(T);
      .wait(T);
      ?continuam(Continuam);
      !decidir(R, P, Ativos, Continuam).

// sobrou um licitante: vence pelo preco da rodada
+!decidir(_, P, _, [Vencedor])
   <- !resultado(Vencedor, P).

// ninguem aceitou o preco inicial
+!decidir(1, P, _, [])
   <- .print("Ninguem aceitou o preco inicial ", P, ". Sem venda.");
      !encerrar.

// todos desistiram na mesma rodada: sorteio pelo preco anterior
+!decidir(_, P, Ativos, []) : incremento(I)
   <- .shuffle(Ativos, [Vencedor | _]);
      .print("Todos desistiram em ", P, ". Sorteio entre ", Ativos);
      !resultado(Vencedor, P - I).

// mais de um continua: proxima rodada
+!decidir(R, P, _, Continuam) : incremento(I)
   <- !rodada(R + 1, P + I, Continuam).

+!resultado(Vencedor, P)
   <- ?item(Item);
      .print("VENCEDOR: ", Vencedor, " paga ", P, " por '", Item, "'");
      encerrar(Vencedor, P);
      !encerrar.

+!encerrar
   <- .wait(1000);
      .stopMAS.

{ include("$jacamo/templates/common-cartago.asl") }
