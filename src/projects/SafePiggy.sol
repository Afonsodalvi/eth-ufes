// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// ⚠️ Erros personalizados: barateiam gas e padronizam mensagens
error NotOwner();
error ZeroAmount();
error NotAllowed();
error ReentrancyDetected();

// 💡 Objetivo:
// - Qualquer pessoa pode depositar ETH (receive/deposit).
// - O "dono" (owner) pode definir uma allowance (autorização) para que
// determinadas contas possam "puxar" (pull) valores do cofre.
// - Padrão "Pull over Push": o usuário pega o dinheiro na quantidade autorizada,
// - pullAttack() é vulnerável a reentrância porque não tem modifier noReentrancy

contract SafePiggy {
    // ✔️ owner: imutável após o deploy
    address public immutable owner;

    // ✔️ mapping: chave -> valor (não iterável)
    // Guarda quanto cada endereço está autorizado a sacar via pull()
    mapping(address => uint256) public allowance;

    // 🔒 Proteção contra reentrância
    // Estado que previne chamadas recursivas maliciosas
    bool private locked;
    

    // ✔️ Eventos: facilitam auditoria e UX das dApps
    event Deposited(address indexed from, uint256 amount);
    event AllowanceSet(address indexed who, uint256 amount);
    event Pulled(address indexed who, uint256 amount);
    event FallbackCalled(address indexed from, uint256 value, bytes data);

    // ✔️ Modifier: pré-condição reutilizável
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 🔒 Modifier anti-reentrância: previne ataques de reentrância
    //
    // COMO FUNCIONA:
    // 1. locked = false (inicial)
    // 2. Função é chamada → locked = true
    // 3. Durante execução, se houver call externo malicioso:
    //    - O call tenta chamar a mesma função novamente
    //    - locked já é true → revert ReentrancyDetected()
    // 4. Função termina → locked = false
    //
    // EXEMPLO DE ATAQUE SEM PROTEÇÃO:
    // 1. Usuário chama pull() → recebe ETH
    // 2. Seu contrato malicioso recebe ETH no receive()
    // 3. receive() chama pull() novamente → recebe mais ETH
    // 4. Repete até esgotar o contrato
    //
    // COM PROTEÇÃO:
    // 1. Usuário chama pull() → locked = true → recebe ETH
    // 2. Contrato malicioso tenta pull() novamente
    // 3. locked = true → revert ReentrancyDetected() ❌
    modifier noReentrancy() {
        if (locked) revert ReentrancyDetected();
        locked = true;
        _;
        locked = false;
    }
    

    // ✔️ constructor: define o owner no momento do deploy
    constructor() {
        owner = msg.sender;
    }

    // ✔️ receive: aceita ETH enviado sem data (ex.: transfer/call simples)
    // Atualiza nada além do log; o saldo do contrato muda automaticamente
    receive() external payable {
        if (msg.value == 0) revert ZeroAmount();
        emit Deposited(msg.sender, msg.value);
    }

    // ✔️ fallback: chamada quando não existe função correspondente à assinatura
    // Útil para registrar chamadas inesperadas e não perder ETH enviado com data
    fallback() external payable {
        // Podemos aceitar ETH aqui também se for "payable"
        // (não é obrigatório mexer em allowance)
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }

    // ✔️ Função de depósito explícita (também aceita ETH)
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        emit Deposited(msg.sender, msg.value);
    }

    // ✔️ Define a autorização (em wei) para um endereço sacar via pull()
    // ⚠️ ATENÇÃO: amount deve ser em wei (1 ETH = 1e18 wei)
    // 💡 IMPORTANTE: Allowance é INDEPENDENTE do depósito do usuário
    // O owner pode autorizar qualquer valor, mesmo que o usuário não tenha depositado
    function setAllowance(address who, uint256 amount) external onlyOwner {
        allowance[who] = amount; // storage: persiste na blockchain
        emit AllowanceSet(who, amount);
    }

    // ✔️ Função auxiliar para definir allowance em ETH (mais fácil de usar)
    // 💡 IMPORTANTE: Allowance é INDEPENDENTE do depósito do usuário
    // O owner pode autorizar qualquer valor, mesmo que o usuário não tenha depositado
    function setAllowanceInEth(address who, uint256 ethAmount) external onlyOwner {
        allowance[who] = ethAmount * 1e18; // Converte ETH para wei
        emit AllowanceSet(who, allowance[who]);
    }

    // ✔️ Usuário autorizado "puxa" seu próprio valor (Pull over Push)
    // Padrão CEI (Checks-Effects-Interactions) demonstrado
    // 🔒 Protegido contra reentrância com noReentrancy modifier
    function pull() external noReentrancy {
        uint256 amount = allowance[msg.sender];
        if (amount == 0) revert NotAllowed();

        // Verificar se o contrato tem saldo suficiente
        if (address(this).balance < amount) revert NotAllowed();

        // Effects: atualizar estado ANTES da interação externa
        allowance[msg.sender] = 0;

        // Interactions: transferência de ETH (externa) no final
        // ⚠️ ATENÇÃO: Ainda vulnerável a reentrância se o receiver for um contrato malicioso
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");

        emit Pulled(msg.sender, amount);
    }

    function pullAttack() external {
        uint256 amount = allowance[msg.sender];
        if (amount == 0) revert NotAllowed();

        // Verificar se o contrato tem saldo suficiente
        if (address(this).balance < amount) revert NotAllowed();

        // 🚨 VULNERÁVEL: Call externo ANTES de zerar o allowance
        // Isso permite reentrância porque o allowance ainda não foi zerado
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");

        // 🚨 VULNERÁVEL: Zerar allowance DEPOIS da transferência
        // O atacante pode chamar pullAttack() novamente antes desta linha
        allowance[msg.sender] = 0;

        emit Pulled(msg.sender, amount);
    }

    // ✔️ Função de leitura (view): não altera estado
    function contractBalance() external view returns (uint256) {
        // address(this).balance lê o saldo em wei deste contrato
        return address(this).balance;
    }

    // ✔️ Getters públicos: o Solidity gera automaticamente para variáveis public,
    // então allowance(who) já é visível. Exemplo mantido para clareza didática.
    function getAllowance(address who) external view returns (uint256) {
        return allowance[who];
    }
}
