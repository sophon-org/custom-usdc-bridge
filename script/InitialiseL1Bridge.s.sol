// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";

contract InitialiseL1SharedBridge is Script {
    // TODO: read from env?
    address public constant SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia
    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0x7147d704Ba0E1F146457Dc93806FE66c201aA7C5; // Sophon Sepolia

    function run() public {
        vm.startBroadcast();
        // if first time, call initializeChainGovernance, else call reinitializeChainGovernance
        // L1SharedBridge(SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1).initializeChainGovernance(531050104, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);
        L1SharedBridge(SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1).reinitializeChainGovernance(
            531050104, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2
        );
        console.log(
            "L1SharedBridge successfully initialised with the L2SharedBridge address: ",
            SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2
        );

        vm.stopBroadcast();
    }
}
