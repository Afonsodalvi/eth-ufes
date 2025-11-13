// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {TimeLockVault} from "../src/projects/TimeLockVault.sol";

contract TimeLockVaultScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);

        TimeLockVault timeLockVault = new TimeLockVault();

        vm.stopBroadcast();

        // Logs para verificação
        console.log("TimeLockVault deployed at:", address(timeLockVault));
        console.log("Min lock period:", timeLockVault.MIN_LOCK());
        console.log("Contract balance:", address(timeLockVault).balance);
    }
}
