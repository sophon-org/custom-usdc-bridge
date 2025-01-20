// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L2USDCBridge} from "../src/L2USDCBridge.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";
import {TestExt} from "forge-zksync-std/TestExt.sol";

contract DeployL2USDCBridge is Script, TestExt, DeploymentUtils {
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
        address paymaster = vm.envAddress("PAYMASTER_ADDRESS");

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(bytes4(keccak256("general(bytes)")), bytes("0x"));

        vm.startBroadcast();

        sharedBridgeProxy = getDeployedContract("L2USDCBridge");

        // deploy implementation
        vmExt.zkUsePaymaster(paymaster, paymaster_encoded_input);
        sharedBridgeImpl = 0x1EeA0f29bcd9E52b5FD1AC7C616caF61993c86E4;
        // sharedBridgeImpl = address(
        //     new L2USDCBridge(getDeployedContract("USDC", vm.envUint("CHAIN_ID")), getDeployedContract("USDC"))
        // );

        // if proxy exists, upgrade proxy with new implementation
        if (sharedBridgeProxy != address(0)) {
            console.log("Upgrading L2USDCBridge");
            if (msg.sender != proxyAdmin) revert("Only proxy admin can upgrade the implementation");
            vmExt.zkUsePaymaster(paymaster, paymaster_encoded_input);
            ITransparentUpgradeableProxy(payable(sharedBridgeProxy)).upgradeTo(sharedBridgeImpl);
            console.log("L2USDCBridge implementation upgraded @", address(sharedBridgeImpl));
            saveDeployedContract("L2USDCBridge-impl", address(sharedBridgeImpl));
            return (sharedBridgeProxy, sharedBridgeImpl);
        }

        // deploy proxy
        vmExt.zkUsePaymaster(paymaster, paymaster_encoded_input);
        sharedBridgeProxy = address(
            new TransparentUpgradeableProxy(
                address(sharedBridgeImpl),
                proxyAdmin,
                abi.encodeWithSelector(
                    L2USDCBridge.initialize.selector, getDeployedContract("L1USDCBridge", vm.envUint("CHAIN_ID"))
                )
            )
        );

        console.log("L2USDCBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L2USDCBridge proxy deployed @", address(sharedBridgeProxy));
        saveDeployedContract("L2USDCBridge", address(sharedBridgeProxy));
        saveDeployedContract("L2USDCBridge-impl", address(sharedBridgeImpl));

        console.log("IMPORTANT: L1USDCBridge must be initialised with the L2USDCBridge address.");
        console.log(
            "L1USDCBridge(address(sharedBridgeProxy)).initializeChainGovernance(50104, SOPHON_CUSTOM_SHARED_BRIDGE_L2)"
        );
        console.log("Use the InitialiseL1Bridge script to do this.");
        console.log("IMPORTANT: L2USDCBridge must be added as minter on the L2 USDC contract.");
        console.log("Use the add-new-minter script on the USDC repo");

        vm.stopBroadcast();

        return (address(sharedBridgeProxy), address(sharedBridgeImpl));
    }
}
