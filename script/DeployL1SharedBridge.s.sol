// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployL1SharedBridge is Script {
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
        address deployerAddress = msg.sender;
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");

        vm.startBroadcast();

        L1SharedBridge sharedBridgeImpl =
            new L1SharedBridge(vm.envAddress("L1_USDC_TOKEN"), IBridgehub(vm.envAddress("SEPOLIA_L1_BRIDGEHUB")));

        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            proxyAdmin,
            abi.encodeWithSelector(L1SharedBridge.initialize.selector, deployerAddress)
        );

        console.log("L1SharedBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L1SharedBridge proxy deployed @", address(sharedBridgeProxy));

        vm.stopBroadcast();
        return (address(sharedBridgeProxy), address(sharedBridgeImpl));
    }
}
