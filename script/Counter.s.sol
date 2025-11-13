// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        require(deployerKey != 0, "Missing PRIVATE_KEY");

        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);

        Counter counter = new Counter();

        vm.stopBroadcast();

        console.log("Counter deployed at:", address(counter));
        console.log("Initial number:", counter.number());
    }
}
