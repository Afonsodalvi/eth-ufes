// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {ClassVote} from "../src/projects/ClassVote.sol";
import {SimpleEscrow} from "../src/projects/Escrow.sol";
import {TimeLockVault} from "../src/projects/TimeLockVault.sol";
import {SafePiggy} from "../src/projects/SafePiggy.sol";

contract DeployAllScript is Script {
    // Estrutura para armazenar endereços dos contratos deployados
    struct DeployedContracts {
        address counter;
        address classVote;
        address escrow;
        address timeLockVault;
        address safePiggy;
    }

    function setUp() public {}

    function run() external returns (DeployedContracts memory contracts) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);
        console.log("=== Deploying All Contracts ===");

        vm.startBroadcast(deployerKey);

        // 1. Deploy Counter
        console.log("\n1. Deploying Counter...");
        Counter counter = new Counter();
        contracts.counter = address(counter);
        console.log("Counter deployed at:", contracts.counter);

        // 2. Deploy ClassVote
        console.log("\n2. Deploying ClassVote...");
        string[] memory proposalNames = new string[](3);
        proposalNames[0] = "Proposal A - Implement voting system";
        proposalNames[1] = "Proposal B - Improve user interface";
        proposalNames[2] = "Proposal C - Add security features";

        ClassVote classVote = new ClassVote(proposalNames);
        contracts.classVote = address(classVote);
        console.log("ClassVote deployed at:", contracts.classVote);

        // 3. Deploy Escrow
        console.log("\n3. Deploying SimpleEscrow...");
        address buyer = vm.addr(1);
        address seller = vm.addr(2);
        address arbiter = vm.addr(3);
        uint256 price = 1 ether;

        SimpleEscrow escrow = new SimpleEscrow(buyer, seller, arbiter, price);
        contracts.escrow = address(escrow);
        console.log("SimpleEscrow deployed at:", contracts.escrow);

        // 4. Deploy TimeLockVault
        console.log("\n4. Deploying TimeLockVault...");
        TimeLockVault timeLockVault = new TimeLockVault();
        contracts.timeLockVault = address(timeLockVault);
        console.log("TimeLockVault deployed at:", contracts.timeLockVault);

        // 5. Deploy SafePiggy
        console.log("\n5. Deploying SafePiggy...");
        SafePiggy safePiggy = new SafePiggy();
        contracts.safePiggy = address(safePiggy);
        console.log("SafePiggy deployed at:", contracts.safePiggy);

        vm.stopBroadcast();

        // Log resumo
        console.log("\n=== Deployment Summary ===");
        console.log("Counter:", contracts.counter);
        console.log("ClassVote:", contracts.classVote);
        console.log("SimpleEscrow:", contracts.escrow);
        console.log("TimeLockVault:", contracts.timeLockVault);
        console.log("SafePiggy:", contracts.safePiggy);

        // Log dos endereços para uso posterior
        console.log("\n=== Contract Addresses ===");
        console.log("Counter:", contracts.counter);
        console.log("ClassVote:", contracts.classVote);
        console.log("SimpleEscrow:", contracts.escrow);
        console.log("TimeLockVault:", contracts.timeLockVault);
        console.log("SafePiggy:", contracts.safePiggy);

        return contracts;
    }
}
