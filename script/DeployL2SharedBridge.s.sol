// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L2SharedBridge} from "../src/L2SharedBridge.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

contract DeployL2SharedBridge is Script, DeploymentUtils {
    function run() public {
        // TODO: fix and send corresponding network and config names
        _run("", "");
    }

    function run(string memory networkName, string memory configName) public {
        _run(networkName, configName);
    }

    // call from tests -- avoiding the return when calling from the script results in cleaner logs
    function runAndReturnResults(string memory networkName, string memory configName)
        public
        returns (address sharedBridgeProxy, address sharedBridgeImpl)
    {
        return _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName) internal returns (address, address) {
        // TODO: set proper addresses, maybe read from env
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");

        vm.startBroadcast();

        L2SharedBridge sharedBridgeImpl =
            new L2SharedBridge(vm.envAddress("L1_USDC_TOKEN"), vm.envAddress("L2_USDC_TOKEN"));

        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            proxyAdmin,
            abi.encodeWithSelector(L2SharedBridge.initialize.selector, vm.envAddress("SEPOLIA_CUSTOM_SHARED_BRIDGE_L1"))
        );

        console.log("L2SharedBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L2SharedBridge proxy deployed @", address(sharedBridgeProxy));
        saveDeployedContract("L2SharedBridge", address(sharedBridgeProxy));
        saveDeployedContract("L2SharedBridge-impl", address(sharedBridgeImpl));

        console.log("IMPORTANT: L1SharedBridge must be initialised with the L2SharedBridge address.");
        console.log(
            "L1SharedBridge(address(sharedBridgeProxy)).initializeChainGovernance(531050104, SOPHON_CUSTOM_SHARED_BRIDGE_L2)"
        );
        console.log("Use the InitialiseL1Bridge script to do this.");
        console.log("IMPORTANT: L2SharedBridge must be added as minter on the L2 USDC contract.");
        console.log("Use the add-new-minter script on the USDC repo");

        vm.stopBroadcast();

        return (address(sharedBridgeProxy), address(sharedBridgeImpl));
    }
}
