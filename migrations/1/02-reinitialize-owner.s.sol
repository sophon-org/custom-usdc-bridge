// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1USDCBridge} from "../../src/L1USDCBridge.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DeploymentUtils} from "../../utils/DeploymentUtils.sol";

// Command to test:
// source .env && forge script ./migrations/1/02-reinitialize-owner.s.sol --rpc-url ethereum --sender 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD
contract MigrateL1USDCBridgeV2 is Script, DeploymentUtils {
    string public constant version = "V2";
    address constant PROXY_ADMIN = 0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD; // Rollup Chains Multisig
    address constant NEW_OWNER = 0x8f7a9912416e8AdC4D9c21FAe1415D3318A11897; // Ethereum Protocol Handler

    function run() public {
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal {

        // get the existing proxy address
        address proxyAddress = getDeployedContract("L1USDCBridge");
        require(proxyAddress != address(0), "Proxy not deployed");

        // deploy new implementation
        vm.startBroadcast();
        address newImplementation = address(
            new L1USDCBridge(
                getDeployedContract("USDC"),
                IBridgehub(getDeployedContract("Bridgehub"))
            )
        );
        vm.stopBroadcast();
        
        console.log(string.concat("Migrating L1USDCBridge to ", version));
        console.log("New implementation deployed at:", newImplementation);

        // generate Safe transaction data for upgradeToAndCall
        bytes memory upgradeCallData = abi.encodeWithSelector(
            ITransparentUpgradeableProxy.upgradeToAndCall.selector,
            newImplementation,
            abi.encodeWithSelector(L1USDCBridge.reinitializeV2.selector, NEW_OWNER)
        );

        console.log("\n=== Safe Transaction Data ===");
        console.log("From:", PROXY_ADMIN);
        console.log("To:", proxyAddress);
        console.log("Value: 0");
        console.log("Data:", vm.toString(upgradeCallData));
        console.log("========================\n");

        // simulate the Safe transaction execution
        console.log("\nSimulating Safe transaction execution...");
        vm.prank(PROXY_ADMIN);
        (bool success, bytes memory result) = proxyAddress.call(upgradeCallData);
        require(success, "Safe transaction simulation failed");
        console.log("Safe transaction simulation successful!");

        // save the new implementation address
        saveDeployedContract(
            string.concat("L1USDCBridge-impl-", version), 
            newImplementation
        );
    }
}