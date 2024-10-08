// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L2SharedBridge} from "../src/L2SharedBridge.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
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

    function _run(string memory networkName, string memory configName)
        internal
        returns (address sharedBridgeProxy, address sharedBridgeImpl)
    {
        // TODO: set proper addresses, maybe read from env
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");

        vm.startBroadcast();

        sharedBridgeProxy = getDeployedContract("L2SharedBridge");

        // deploy implementation
        sharedBridgeImpl = address(
            new L2SharedBridge(getDeployedContract("USDC", vm.envUint("SEPOLIA_CHAIN_ID")), getDeployedContract("USDC"))
        );

        // if proxy exists, upgrade proxy with new implementation
        if (sharedBridgeProxy != address(0)) {
            console.log("Upgrading L2SharedBridge");
            if (msg.sender != proxyAdmin) revert("Only proxy admin can upgrade the implementation");
            ITransparentUpgradeableProxy(payable(sharedBridgeProxy)).upgradeTo(sharedBridgeImpl);
            console.log("L2SharedBridge implementation upgraded @", address(sharedBridgeImpl));
            saveDeployedContract("L2SharedBridge-impl", address(sharedBridgeImpl));
            return (sharedBridgeProxy, sharedBridgeImpl);
        }

        // deploy proxy
        sharedBridgeProxy = address(
            new TransparentUpgradeableProxy(
                address(sharedBridgeImpl),
                proxyAdmin,
                abi.encodeWithSelector(
                    L2SharedBridge.initialize.selector,
                    getDeployedContract("L1SharedBridge", vm.envUint("SEPOLIA_CHAIN_ID"))
                )
            )
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
