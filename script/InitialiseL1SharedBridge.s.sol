// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

contract InitialiseL1SharedBridge is Script, DeploymentUtils {
    function run() public {
        vm.startBroadcast();

        uint256 sophonSepoliaChainId = vm.envUint("SOPHON_SEPOLIA_CHAIN_ID");
        // if first time, call initializeChainGovernance, else call reinitializeChainGovernance
        L1SharedBridge(getDeployedContract("L1SharedBridge")).initializeChainGovernance(
            sophonSepoliaChainId, getDeployedContract("L2SharedBridge", sophonSepoliaChainId)
        );
        // L1SharedBridge(getDeployedContract("L1SharedBridge")).reinitializeChainGovernance(
        //     sophonSepoliaChainId, getDeployedContract("L2SharedBridge", sophonSepoliaChainId)
        // );
        console.log(
            "L1SharedBridge successfully initialised with the L2SharedBridge address: ",
            vm.envAddress("SOPHON_CUSTOM_SHARED_BRIDGE_L2")
        );

        vm.stopBroadcast();
    }
}
