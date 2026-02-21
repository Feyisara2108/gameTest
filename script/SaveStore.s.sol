// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SaveStore} from "../src/SaveStore.sol";

contract SaveStoreScript is Script {
    SaveStore public savestore;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        savestore = new SaveStore();

        vm.stopBroadcast();
    }
}
