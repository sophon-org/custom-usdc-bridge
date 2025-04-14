// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeploymentUtils} from "../../utils/DeploymentUtils.sol";

// Command to test:
// source .env && forge script ./migrations/50104/01-change-proxy-admin.s.sol --rpc-url sophon --sender 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD
contract TransferProxyAdminOwnershipMigration is Script, DeploymentUtils {
    address constant PROXY_ADMIN_OWNER = 0x4cB9ac68A2151f14E8242a984b1F1faDb36EBF60; // Tom's EOA
    address constant PROXY_ADMIN = 0x811690309C7eaa2Fe033AD3Cb7Ac05c94FdD7a08;
    address constant NEW_OWNER = 0xA08b9912416E8aDc4D9C21Fae1415d3318A129A8; // Aliased ProtocolUpgradeHandler
    
    function run() public {
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal {
        // generate transaction data for transferOwnership
        bytes memory transferOwnershipData = abi.encodeWithSignature(
            "transferOwnership(address)",
            NEW_OWNER
        );

        // print transaction details
        console.log("\n=== Transaction Data ===");
        console.log("From:", PROXY_ADMIN_OWNER);
        console.log("To:", PROXY_ADMIN);
        console.log("Value: 0");
        console.log("Data:", vm.toString(transferOwnershipData));
        console.log("========================\n");

        // simulate the transaction execution
        console.log("\nSimulating transaction execution...");
        vm.prank(PROXY_ADMIN_OWNER);
        (bool success, bytes memory result) = PROXY_ADMIN.call(transferOwnershipData);
        require(success, "Transaction simulation failed");
        console.log("Transaction simulation successful!");
    }
}