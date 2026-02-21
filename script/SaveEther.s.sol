// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SaveEther} from "../src/SaveEther.sol";

contract SaveEtherScript is Script {
    SaveEther public saveether;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        saveether = new SaveEther();

        vm.stopBroadcast();
    }
}
