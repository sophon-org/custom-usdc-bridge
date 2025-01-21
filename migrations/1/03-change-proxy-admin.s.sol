// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeploymentUtils} from "../../utils/DeploymentUtils.sol";

// Command to test:
// source .env && forge script ./migrations/1/03-change-proxy-admin.s.sol --rpc-url ethereum --sender 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD
contract ChangeProxyAdminMigration is Script, DeploymentUtils {
    address constant PROXY_ADMIN = 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD; // L1 Rollup Chains Multisig
    address constant L1_USDC_BRIDGE = 0xf553E6D903AA43420ED7e3bc2313bE9286A8F987;
    address constant NEW_PROXY_ADMIN = 0xC2a36181fB524a6bEfE639aFEd37A67e77d62cf1; // Ethereum Proxy Admin
    
    function run() public {
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal {
        // generate Safe transaction data for changeAdmin
        bytes memory changeAdminData = abi.encodeWithSignature(
            "changeAdmin(address)",
            NEW_PROXY_ADMIN
        );

        // print Safe transaction details
        console.log("\n=== Safe Transaction Data ===");
        console.log("From:", PROXY_ADMIN);
        console.log("To:", L1_USDC_BRIDGE);
        console.log("Value: 0");
        console.log("Data:", vm.toString(changeAdminData));
        console.log("========================\n");

        // simulate the Safe transaction execution
        console.log("\nSimulating Safe transaction execution...");
        vm.prank(PROXY_ADMIN);
        (bool success, bytes memory result) = L1_USDC_BRIDGE.call(changeAdminData);
        require(success, "Safe transaction simulation failed");
        console.log("Safe transaction simulation successful!");
    }
}