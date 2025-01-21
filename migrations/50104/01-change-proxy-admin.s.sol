// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeploymentUtils} from "../../utils/DeploymentUtils.sol";

// Command to test:
// source .env && forge script ./migrations/50104/01-change-proxy-admin.s.sol --rpc-url sophon --sender 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD
contract ChangeProxyAdminMigration is Script, DeploymentUtils {
    string public constant version = "CHANGE_PROXY_ADMIN_2";

    address constant PROXY_ADMIN = 0xa3b1f968b608642dD16d7Fd31bEc0B2c915908dB;
    address constant L2_USDC_BRIDGE = 0x0F44bac3ec514BE912aa4359017593B35E868d74;
    address constant NEW_PROXY_ADMIN = 0x811690309C7eaa2Fe033AD3Cb7Ac05c94FdD7a08; // Sophon's Proxy Admin
    
    function run() public {
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal {
        // generate transaction data for changeAdmin
        bytes memory changeAdminData = abi.encodeWithSignature(
            "changeAdmin(address)",
            NEW_PROXY_ADMIN
        );

        // Print transaction details
        console.log("\n=== Transaction Data ===");
        console.log("From:", PROXY_ADMIN);
        console.log("To:", L2_USDC_BRIDGE);
        console.log("Value: 0");
        console.log("Data:", vm.toString(changeAdminData));
        console.log("========================\n");

        // Simulate the transaction execution
        console.log("\nSimulating transaction execution...");
        vm.prank(PROXY_ADMIN);
        (bool success, bytes memory result) = L2_USDC_BRIDGE.call(changeAdminData);
        require(success, "Transaction simulation failed");
        console.log("Transaction simulation successful!");
    }
}