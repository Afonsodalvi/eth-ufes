// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SafePiggy} from "../src/projects/SafePiggy.sol";

contract SafePiggyScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);

        SafePiggy safePiggy = new SafePiggy();

        vm.stopBroadcast();

        // Logs para verificação
        console.log("SafePiggy deployed at:", address(safePiggy));
        console.log("Owner:", safePiggy.owner());
        console.log("Contract balance:", safePiggy.contractBalance());

        // Demonstração: definir allowance para o deployer
        vm.startBroadcast(deployerKey);
        safePiggy.setAllowanceInEth(deployer, 1); // 1 ETH
        vm.stopBroadcast();

        console.log("Allowance set for deployer:", safePiggy.getAllowance(deployer));
    }
}
