// Comportamento comum dos licitantes. Quem inclui este arquivo define margem(M):
// o licitante continua enquanto preco <= valor_maximo * margem.
// Em vez de mensagens, o licitante percebe preco(P) na maquina e,
// se aceita, executa a operacao continuar. Desistir e so nao responder.

/* Objetivo inicial */

!iniciar.

/* Planos */

+!iniciar
   <- .random(X);
      V = math.floor(100 + X * 100);  // valor privado entre 100 e 199
      ?margem(M);
      L = math.floor(V * M);          // preco acima do qual desisto
      +limite(L);
      +ativo;
      entrar;
      .print("Valor maximo: ", V, " | desisto acima de ", L).

+preco(P) : ativo & limite(L) & P <= L
   <- .print("Preco ", P, ", continuo.");
      continuar.

+preco(P) : ativo
   <- .print("Preco ", P, ", desisto.");
      -ativo.

+preco(_).                            // ja fora do leilao: ignora

+vencedor(V) : .my_name(V)
   <- ?item(I);
      ?preco_final(P);
      .print("Venci '", I, "' por ", P, "!").

+vencedor(V)
   <- .print("Perdi para ", V, ".").

{ include("$jacamo/templates/common-cartago.asl") }
