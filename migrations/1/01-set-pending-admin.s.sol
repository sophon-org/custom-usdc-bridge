// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1USDCBridge} from "../../src/L1USDCBridge.sol";
import {DeploymentUtils} from "../../utils/DeploymentUtils.sol";

// Command to test:
// source .env && forge script ./migrations/1/01-set-pending-admin.s.sol --rpc-url ethereum --sender 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD
contract SetPendingAdminMigration is Script, DeploymentUtils {
    string public constant version = "SET_PENDING_ADMIN";

    address constant L1_USDC_BRIDGE = 0xf553E6D903AA43420ED7e3bc2313bE9286A8F987;
    address constant BRIDGE_OWNER = 0xe4644b6d106A18062344c0A853666bc0B8f052d1; // L1 Sophon Tech Multisig
    address constant NEW_ADMIN = 0x4e4943346848c4867F81dFb37c4cA9C5715A7828; // Ethereum ML Multisig
    
    function run() public {
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal {
        // generate Safe transaction data for setPendingAdmin
        bytes memory setPendingAdminData = abi.encodeWithSelector(
            L1USDCBridge.setPendingAdmin.selector,
            NEW_ADMIN
        );

        // print Safe transaction details
        console.log("\n=== Safe Transaction Data ===");
        console.log("From:", BRIDGE_OWNER);
        console.log("To:", L1_USDC_BRIDGE);
        console.log("Value: 0");
        console.log("Data:", vm.toString(setPendingAdminData));
        console.log("========================\n");

        // simulate the Safe transaction execution
        console.log("\nSimulating Safe transaction execution...");
        vm.prank(BRIDGE_OWNER);
        (bool success, bytes memory result) = L1_USDC_BRIDGE.call(setPendingAdminData);
        require(success, "Safe transaction simulation failed");
        console.log("Safe transaction simulation successful!");
    }
}