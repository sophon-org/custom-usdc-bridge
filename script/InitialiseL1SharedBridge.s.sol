// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";

contract InitialiseL1SharedBridge is Script {
    function run() public {
        vm.startBroadcast();

        // if first time, call initializeChainGovernance, else call reinitializeChainGovernance
        L1SharedBridge(vm.envAddress("SEPOLIA_CUSTOM_SHARED_BRIDGE_L1")).initializeChainGovernance(
            vm.envUint("SOPHON_SEPOLIA_CHAIN_ID"), vm.envAddress("SOPHON_CUSTOM_SHARED_BRIDGE_L2")
        );
        // L1SharedBridge(vm.envAddress("SEPOLIA_CUSTOM_SHARED_BRIDGE_L1")).reinitializeChainGovernance(
        //     vm.envUint("SOPHON_SEPOLIA_CHAIN_ID"), vm.envAddress("SOPHON_CUSTOM_SHARED_BRIDGE_L2")
        // );
        console.log(
            "L1SharedBridge successfully initialised with the L2SharedBridge address: ",
            vm.envAddress("SOPHON_CUSTOM_SHARED_BRIDGE_L2")
        );

        vm.stopBroadcast();
    }
}
