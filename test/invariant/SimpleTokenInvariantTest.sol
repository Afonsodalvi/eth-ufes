// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/SimpleToken.sol";

/// @title SimpleTokenInvariantTest
/// @notice Teste de invariantes para SimpleToken
/// @dev Testa que totalSupply sempre é igual à soma de todos os saldos
/// 
/// O QUE SÃO TESTES DE INVARIANTES?
/// ================================
/// Invariantes são propriedades que SEMPRE devem ser verdadeiras, não importa
/// o que aconteça. Por exemplo: "A soma de todos os saldos deve ser igual ao
/// totalSupply". Se isso não for verdade, tokens foram criados ou destruídos
/// sem controle - um bug grave!
///
/// COMO FUNCIONA?
/// ==============
/// 1. Foundry cria um "handler" que faz operações aleatórias (mint, transfer)
/// 2. Foundry executa MUITAS operações com valores aleatórios
/// 3. Depois de cada operação, chama invariant_TotalSupplyEqualsBalances()
/// 4. Se o invariante quebrar, o teste falha e mostra a sequência que causou
contract SimpleTokenInvariantTest is Test {
    SimpleToken public token;
    
    /// @notice Lista de todos os endereços que receberam tokens
    /// @dev Precisamos rastrear isso para somar todos os saldos
    address[] public actors;
    
    /// @notice Mapeamento para verificar rapidamente se um endereço é ator
    mapping(address => bool) public isActor;
    
    /// @notice Handler que faz operações aleatórias no token
    /// @dev O Foundry vai chamar as funções públicas deste contrato
    SimpleTokenHandler public handler;

    /// @notice Setup inicial do teste
    function setUp() public {
        // 1. Deploy do token que vamos testar
        token = new SimpleToken();
        
        // 2. Deploy do handler (vai fazer operações aleatórias)
        handler = new SimpleTokenHandler(token, this);
        
        // 3. Dizer ao Foundry para usar o handler
        // Isso faz o Foundry chamar as funções públicas do handler
        targetContract(address(handler));
        
        // 4. Adicionar alguns endereços iniciais à lista de atores
        _addActor(address(this));      // O próprio contrato de teste
        _addActor(address(handler));   // O handler
    }
    
    /// @notice Adiciona um endereço à lista de atores
    /// @param actor Endereço a ser adicionado
    /// @dev Internal porque só queremos adicionar de forma controlada
    function _addActor(address actor) internal {
        // Só adiciona se ainda não estiver na lista
        if (!isActor[actor]) {
            actors.push(actor);
            isActor[actor] = true;
        }
    }
    
    /// @notice INVARIANTE: totalSupply deve ser igual à soma de todos os saldos
    /// @dev Esta função é chamada automaticamente pelo Foundry depois de cada
    ///      operação (ou grupo de operações). Se retornar false ou reverter,
    ///      o teste falha.
    ///
    /// POR QUE ESTE INVARIANTE É IMPORTANTE?
    /// =====================================
    /// Se totalSupply != soma dos saldos, significa que:
    /// - Tokens foram criados sem controle (totalSupply > soma)
    /// - Tokens foram destruídos sem controle (totalSupply < soma)
    /// Ambos são bugs graves!
    function invariant_TotalSupplyEqualsBalances() public view {
        uint256 sum;
        
        // Somar saldos de TODOS os atores conhecidos
        // IMPORTANTE: Precisamos rastrear todos os endereços que receberam
        // tokens, senão não conseguimos somar todos os saldos!
        for (uint256 i = 0; i < actors.length; i++) {
            sum += token.balanceOf(actors[i]);
        }
        
        // O INVARIANTE: totalSupply deve ser igual à soma
        // Se não for, algo está muito errado!
        assertEq(
            token.totalSupply(), 
            sum, 
            "totalSupply deve ser igual a soma de todos os saldos!"
        );
    }
    
    /// @notice Função pública para handlers adicionarem novos atores
    /// @param actor Endereço a ser adicionado
    /// @dev Apenas o handler pode chamar (segurança)
    ///      Isso evita que qualquer um adicione atores falsos
    function addActor(address actor) external {
        // Apenas o handler pode adicionar atores
        // Por quê? Para evitar que alguém "trapaceie" adicionando endereços
        // vazios, o que faria o invariante sempre passar (mas não seria real!)
        require(msg.sender == address(handler), "Apenas handler pode adicionar");
        _addActor(actor);
    }
}

/// @title SimpleTokenHandler
/// @notice Handler que faz operações aleatórias no token para testes
/// @dev O Foundry vai chamar as funções públicas deste contrato com valores
///      aleatórios. Nossa responsabilidade é garantir que as operações sejam
///      válidas e que rastreamos o estado necessário.
///
/// O QUE É UM HANDLER?
/// ===================
/// Um handler é um contrato que "traduz" operações para o Foundry. O Foundry
/// não sabe como usar nosso contrato diretamente, então criamos um handler
/// que:
/// 1. Recebe valores aleatórios do Foundry
/// 2. Valida e ajusta esses valores (usando bound())
/// 3. Faz a operação no contrato
/// 4. Rastreia o que aconteceu (adiciona atores, etc.)
contract SimpleTokenHandler is Test {
    SimpleToken public token;
    SimpleTokenInvariantTest public test;
    
    /// @notice Lista de endereços que podem receber tokens
    /// @dev Usamos isso para escolher destinatários aleatórios
    address[] public possibleRecipients;
    
    constructor(SimpleToken _token, SimpleTokenInvariantTest _test) {
        token = _token;
        test = _test;
        
        // Adicionar alguns endereços possíveis para receber tokens
        // Quanto mais endereços, mais cenários testamos
        possibleRecipients.push(address(this));
        possibleRecipients.push(address(test));
        possibleRecipients.push(address(0x1));
        possibleRecipients.push(address(0x2));
        possibleRecipients.push(address(0x3));
        possibleRecipients.push(address(0x4));
        possibleRecipients.push(address(0x5));
    }
    
    /// @notice Handler para mint - Foundry vai chamar com valores aleatórios
    /// @param to Destinatário (pode ser address(0) para escolher aleatório)
    /// @param amount Quantidade (será limitada para evitar overflow)
    /// @dev Esta função é chamada pelo Foundry com valores aleatórios.
    ///      Nós validamos e ajustamos esses valores antes de fazer a operação.
    function mint(address to, uint256 amount) public {
        // LIMITAR amount para evitar overflow
        // bound() garante que amount está entre 1 e type(uint128).max
        // Por quê type(uint128)? Para evitar problemas com números muito grandes
        amount = bound(amount, 1, type(uint128).max);
        
        // Se to não foi especificado (address(0)), escolher aleatório
        if (to == address(0)) {
            // Escolher um endereço aleatório da lista
            // Usamos keccak256 para gerar "aleatoriedade" (em testes)
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) 
                % possibleRecipients.length;
            to = possibleRecipients[index];
        }
        
        // Fazer o mint
        token.mint(to, amount);
        
        // IMPORTANTE: Adicionar destinatario a lista de atores
        // Isso garante que o invariante vai verificar o saldo dele
        test.addActor(to);
    }
    
    /// @notice Handler para transfer - Foundry vai chamar com valores aleatorios
    /// @param to Destinatario (pode ser address(0) para escolher aleatorio)
    /// @param amount Quantidade (sera limitada ao saldo disponivel)
    /// @dev Esta funcao e mais complexa porque precisa:
    ///      1. Escolher um remetente que tem saldo
    ///      2. Limitar amount ao saldo disponivel
    ///      3. Simular que o remetente esta fazendo a chamada (vm.prank)
    function transfer(address to, uint256 amount) public {
        // Escolher um remetente aleatorio que tem saldo
        address from = _getRandomActorWithBalance();
        if (from == address(0)) {
            // Ninguem tem saldo, nao podemos fazer transfer
            return;
        }
        
        // LIMITAR amount ao saldo disponivel do remetente
        // bound() garante que amount esta entre 1 e o saldo maximo
        uint256 maxAmount = token.balanceOf(from);
        if (maxAmount == 0) return; // Nao tem saldo mesmo
        amount = bound(amount, 1, maxAmount);
        
        // Se to nao foi especificado, escolher aleatorio
        if (to == address(0)) {
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) 
                % possibleRecipients.length;
            to = possibleRecipients[index];
        }
        
        // IMPORTANTE: Usar vm.prank para simular que 'from' esta fazendo a chamada
        // Por que? Porque transfer() verifica msg.sender e so permite transferir
        // seus proprios tokens. vm.prank faz a proxima chamada como se fosse de 'from'
        vm.prank(from);
        token.transfer(to, amount);
        
        // Adicionar destinatario a lista de atores se for novo
        test.addActor(to);
    }
    
    /// @notice Pega um ator aleatorio que tem saldo
    /// @return Endereco de um ator com saldo, ou address(0) se ninguem tem
    /// @dev Esta funcao e usada para escolher quem vai fazer transfer
    function _getRandomActorWithBalance() internal view returns (address) {
        // Coletar todos os enderecos que tem saldo
        address[] memory candidates = new address[](possibleRecipients.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < possibleRecipients.length; i++) {
            if (token.balanceOf(possibleRecipients[i]) > 0) {
                candidates[count] = possibleRecipients[i];
                count++;
            }
        }
        
        // Se ninguem tem saldo, retornar address(0)
        if (count == 0) return address(0);
        
        // Escolher um aleatorio dos que tem saldo
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % count;
        return candidates[index];
    }
}
