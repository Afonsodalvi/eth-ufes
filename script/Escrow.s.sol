// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SimpleEscrow} from "../src/projects/Escrow.sol";

contract EscrowScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        // Configurações do deploy - endereços de exemplo
        // Em produção, use endereços reais
        address buyer = vm.addr(1); // Primeira conta derivada
        address seller = vm.addr(2); // Segunda conta derivada
        address arbiter = vm.addr(3); // Terceira conta derivada
        uint256 price = 1 ether; // 1 ETH

        vm.startBroadcast(deployerKey);

        SimpleEscrow escrow = new SimpleEscrow(buyer, seller, arbiter, price);

        vm.stopBroadcast();

        // Logs para verificação
        console.log("SimpleEscrow deployed at:", address(escrow));
        console.log("Buyer:", escrow.BUYER());
        console.log("Seller:", escrow.SELLER());
        console.log("Arbiter:", escrow.ARBITER());
        console.log("Price:", escrow.PRICE());
        console.log("State:", escrow.status());
        console.log("Time limit:", escrow.timeLimit());
    }
}
