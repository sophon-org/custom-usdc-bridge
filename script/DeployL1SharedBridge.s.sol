// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

contract DeployL1SharedBridge is Script, DeploymentUtils {
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
        address deployerAddress = msg.sender;
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");

        vm.startBroadcast();

        sharedBridgeProxy = getDeployedContract("L1SharedBridge");

        // deploy implementation
        sharedBridgeImpl =
            address(new L1SharedBridge(getDeployedContract("USDC"), IBridgehub(getDeployedContract("Bridgehub"))));

        // if proxy exists, upgrade proxy with new implementation
        if (sharedBridgeProxy != address(0)) {
            console.log("Upgrading L1SharedBridge");
            if (msg.sender != proxyAdmin) revert("Only proxy admin can upgrade the implementation");
            ITransparentUpgradeableProxy(payable(sharedBridgeProxy)).upgradeTo(sharedBridgeImpl);
            console.log("L1SharedBridge implementation upgraded @", sharedBridgeImpl);
            saveDeployedContract("L1SharedBridge-impl", sharedBridgeImpl);
            return (sharedBridgeProxy, sharedBridgeImpl);
        }

        // deploy proxy
        sharedBridgeProxy = address(
            new TransparentUpgradeableProxy(
                sharedBridgeImpl,
                proxyAdmin,
                abi.encodeWithSelector(L1SharedBridge.initialize.selector, deployerAddress)
            )
        );

        console.log("L1SharedBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L1SharedBridge proxy deployed @", address(sharedBridgeProxy));
        saveDeployedContract("L1SharedBridge", address(sharedBridgeProxy));
        saveDeployedContract("L1SharedBridge-impl", address(sharedBridgeImpl));

        vm.stopBroadcast();
        return (address(sharedBridgeProxy), address(sharedBridgeImpl));
    }
}
