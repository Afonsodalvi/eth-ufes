// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ClassVote} from "../src/projects/ClassVote.sol";

contract ClassVoteScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        // Configurações do deploy
        string[] memory proposalNames = new string[](3);
        proposalNames[0] = "Proposal A - Implement voting system";
        proposalNames[1] = "Proposal B - Improve user interface";
        proposalNames[2] = "Proposal C - Add security features";

        vm.startBroadcast(deployerKey);

        ClassVote classVote = new ClassVote(proposalNames);

        vm.stopBroadcast();

        // Logs para verificação
        console.log("ClassVote deployed at:", address(classVote));
        console.log("Admin:", classVote.admin());
        console.log("Phase:", uint256(classVote.phase()));
        console.log("Proposals count:", classVote.proposalsCount());

        // Log das propostas
        for (uint256 i = 0; i < proposalNames.length; i++) {
            (string memory name, uint256 votes) = classVote.proposals(i);
            console.log("Proposal %s: %s (votes: %s)", i, name, votes);
        }
    }
}
