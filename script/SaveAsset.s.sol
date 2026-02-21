// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SaveAsset} from "../src/SaveAsset.sol";

contract SaveAssetScript is Script {
    SaveAsset public saveasset;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        saveasset = new SaveAsset(msg.sender);

        vm.stopBroadcast();
    }
}
