package leilao;

import cartago.*;
import jason.asSyntax.*;

/**
 * Maquina de leilao: quadro compartilhado entre leiloeiro e licitantes.
 * Substitui as mensagens e o Directory Facilitator da versao A.
 *
 * Propriedades observaveis (viram crencas de quem faz focus):
 *   item(I)        item em leilao
 *   inscritos(L)   licitantes que entraram
 *   rodada(R)      rodada corrente
 *   preco(P)       preco da rodada corrente
 *   continuam(L)   licitantes que aceitaram o preco da rodada corrente
 *   vencedor(V) e preco_final(P), definidas so no encerramento
 */
public class MaquinaLeilao extends Artifact {

    void init(String item) {
        defineObsProperty("item", item);
        defineObsProperty("inscritos", new ListTermImpl());
        defineObsProperty("rodada", 0);
        defineObsProperty("continuam", new ListTermImpl());
    }

    // licitante se inscreve no leilao
    @OPERATION void entrar() {
        adicionar("inscritos", agente());
    }

    // leiloeiro anuncia o preco da rodada e zera a lista de quem continua
    @OPERATION void anunciar(int rodada, int preco) {
        getObsProperty("rodada").updateValue(rodada);
        getObsProperty("continuam").updateValue(new ListTermImpl());
        if (hasObsProperty("preco")) getObsProperty("preco").updateValue(preco);
        else defineObsProperty("preco", preco);
    }

    // licitante aceita o preco da rodada corrente
    @OPERATION void continuar() {
        adicionar("continuam", agente());
    }

    // leiloeiro publica o resultado
    @OPERATION void encerrar(String vencedor, int preco) {
        defineObsProperty("preco_final", preco);
        defineObsProperty("vencedor", new Atom(vencedor));
    }

    private void adicionar(String propriedade, String nome) {
        ListTerm lista = ((ListTerm) getObsProperty(propriedade).getValue()).cloneLT();
        lista.add(new Atom(nome));
        getObsProperty(propriedade).updateValue(lista);
    }

    private String agente() {
        return getCurrentOpAgentId().getAgentName();
    }
}
