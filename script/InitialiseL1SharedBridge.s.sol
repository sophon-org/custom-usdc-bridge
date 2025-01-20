// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1USDCBridge} from "../src/L1USDCBridge.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

contract InitialiseL1USDCBridge is Script, DeploymentUtils {
    function run() public {
        vm.startBroadcast();

        uint256 sophonChainId = vm.envUint("SOPHON_CHAIN_ID");
        // if first time, call initializeChainGovernance, else call reinitializeChainGovernance
        L1USDCBridge(getDeployedContract("L1USDCBridge")).initializeChainGovernance(
            sophonChainId, getDeployedContract("L2USDCBridge", sophonChainId)
        );
        // L1USDCBridge(getDeployedContract("L1USDCBridge")).reinitializeChainGovernance(
        //     sophonChainId, getDeployedContract("L2USDCBridge", sophonChainId)
        // );
        console.log(
            "L1USDCBridge successfully initialised with the L2USDCBridge address: ",
            getDeployedContract("L2USDCBridge", sophonChainId)
        );

        vm.stopBroadcast();
    }
}
