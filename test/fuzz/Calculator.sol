// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract Calculator {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
}

contract CalculatorTest is Test {
    Calculator calc;

    function setUp() public {
        calc = new Calculator();
    }

    // Foundry vai chamar essa função com MUITOS valores aleatórios para a e b
    function testFuzz_Add_NeverOverflows(uint256 a, uint256 b) public view {
        // vm.assume = "considere somente casos onde isso é verdade"
        vm.assume(a <= type(uint256).max - b);

        uint256 result = calc.add(a, b);

        // Regras simples que SEMPRE devem valer
        assert(result >= a);
        assert(result >= b);
    }
}
