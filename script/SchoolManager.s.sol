// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SchoolManager} from "../src/SchoolManager.sol";

contract SchoolManagerScript is Script {
    SchoolManager public schoolmanager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // I'm passing the initial supply here
        uint256 initialSupply = 1_000_000 * 10 ** 18;
        schoolmanager = new SchoolManager(initialSupply);

        vm.stopBroadcast();
    }
}
