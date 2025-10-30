// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract ClassVote {
    // ---------- Admin (controle de fase) ----------
    address public immutable admin;

    // ---------- Propostas ----------
    struct Proposal {
        string name;
        uint256 votes;
    }

    Proposal[] public proposals;

    // ---------- Um voto por endereço ----------
    mapping(address => bool) public voted;

    // ---------- Fases ----------
    enum Phase {
        Setup,
        Voting,
        Ended
    }

    Phase public phase;

    // ---------- Estado de empate da última rodada ----------
    // Indica se a rodada encerrada (Ended) terminou com empate entre propostas vencedoras
    bool public lastRoundWasTie;

    // ---------- Eventos ----------
    event Opened();
    event Voted(address indexed voter, uint256 indexed proposal);
    event Closed();

    // ---------- Erros ----------
    error OnlyAdmin();
    error PhaseError();
    error AlreadyVoted();
    error IndexOutOfBounds();
    // ---------- Modifiers ----------

    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier inPhase(Phase p) {
        if (phase != p) revert PhaseError();
        _;
    }

    // ---------- Constructor ----------
    // Recebe os nomes das propostas e começa em Setup.
    constructor(string[] memory names) {
        admin = msg.sender;
        for (uint256 i = 0; i < names.length; i++) {
            proposals.push(Proposal({name: names[i], votes: 0}));
        }
        phase = Phase.Setup;
    }

    // ---------- Abrir votação ----------
    function openVoting() external onlyAdmin inPhase(Phase.Setup) {
        phase = Phase.Voting;
        emit Opened();
    }

    // ---------- Votar em uma proposta ----------
    function vote(uint256 index) external inPhase(Phase.Voting) {
        if (voted[msg.sender]) revert AlreadyVoted();
        if (index >= proposals.length) revert IndexOutOfBounds();

        voted[msg.sender] = true; // registra primeiro (Effects)
        proposals[index].votes += 1; // depois altera votos
        emit Voted(msg.sender, index);
    }

    // ---------- Encerrar votação ----------
    function closeVoting() external onlyAdmin inPhase(Phase.Voting) {
        // Detecta se houve empate entre as propostas vencedoras
        // Didática do algoritmo de empate:
        // - Varremos todas as propostas procurando o MAIOR número de votos (maxVotes)
        // - Sempre que encontramos um valor MAIOR que maxVotes, atualizamos maxVotes
        //   e reiniciamos a contagem de vencedores (winnersCount = 1), pois há
        //   um novo líder isolado naquele momento.
        // - Se encontramos uma proposta com votos IGUAIS a maxVotes, significa que ela
        //   empata com o líder atual, então apenas incrementamos winnersCount.
        // - Ao final do laço:
        //     winnersCount == 1  -> há um único vencedor
        //     winnersCount > 1   -> existe pelo menos um empate no topo
        uint256 maxVotes = 0;
        uint256 winnersCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            uint256 v = proposals[i].votes;
            if (v > maxVotes) {
                maxVotes = v;
                winnersCount = 1; // novo líder isolado
            } else if (v == maxVotes) {
                winnersCount += 1; // mais um líder com mesmo máximo (empate no topo)
            }
        }

        lastRoundWasTie = (winnersCount > 1);
        phase = Phase.Ended;
        emit Closed();
    }

    // ---------- Reabrir votação somente em caso de empate ----------
    // Mantém votos anteriores e quem já votou continua sem poder votar novamente
    function reopenVotingOnTie() external onlyAdmin inPhase(Phase.Ended) {
        if (!lastRoundWasTie) revert PhaseError();
        // Permite nova fase de votação sem limpar estado
        phase = Phase.Voting;
        // Reset da flag para impedir reaberturas sequenciais sem novo empate
        lastRoundWasTie = false;
        emit Opened();
    }

    // ---------- Ver vencedor ----------
    function winner() external view inPhase(Phase.Ended) returns (uint256 idx) {
        uint256 max = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes > max) {
                max = proposals[i].votes;
                idx = i;
            }
        }
    }

    // ---------- Ajudas de leitura ----------
    function proposalsCount() external view returns (uint256) {
        return proposals.length;
    }
}
