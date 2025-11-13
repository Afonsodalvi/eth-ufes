// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract KeccakDemo {
    // Função para demonstrar como os seletores são calculados
    function demonstrateSelectors()
        external
        pure
        returns (bytes4 incrementSelector, bytes4 numberSelector, bytes4 setNumberSelector)
    {
        // Os seletores são os primeiros 4 bytes do keccak256 da assinatura
        incrementSelector = bytes4(keccak256("increment()"));
        numberSelector = bytes4(keccak256("number()"));
        setNumberSelector = bytes4(keccak256("setNumber(uint256)"));
    }

    // Função para mostrar a assinatura completa
    function getFunctionSignature() external pure returns (string memory) {
        return "increment()";
    }

    // Função para mostrar o hash completo (não apenas os primeiros 4 bytes)
    function getFullHash() external pure returns (bytes32) {
        return keccak256("increment()");
    }
}
