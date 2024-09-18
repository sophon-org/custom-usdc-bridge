// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L2SharedBridge} from "../src/L2SharedBridge.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployL2SharedBridge is Script {
    // TODO: read from env?
    address public constant L1_USDC_ADDRESS = 0xBF4FdF7BF4014EA78C0A07259FBc4315Cb10d94E; // MockUSDC on Sepolia testnet
    address public constant L2_USDC_ADDRESS = 0x27553b610304b6AB77855a963f8208443D773E60; // Native USDC on Sophon testnet
    address public constant SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia

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
        returns (
            // returns (DeploymentResults memory)
            address sharedBridgeProxy,
            address sharedBridgeImpl
        )
    {
        return _run(networkName, configName);
    }

    function _run(string memory networkName, string memory configName)
        internal
        returns (
            // returns (DeploymentResults memory)
            address sharedBridgeProxy,
            address sharedBridgeImpl
        )
    {
        // TODO: set proper addresses, maybe read from env
        address owner = address(msg.sender);

        vm.startBroadcast();
        // uint256 deployerPrivateKey = _getPrivateKey(networkName);
        // Config memory deployConfig = _getDeployConfig(configName);
        // vm.startBroadcast(depoyerPrivateKey);

        // DeploymentResults memory deploymentResults;

        L2SharedBridge sharedBridgeImpl = new L2SharedBridge(L1_USDC_ADDRESS, L2_USDC_ADDRESS);

        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            owner,
            abi.encodeWithSelector(L2SharedBridge.initialize.selector, SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1)
        );

        console.log("L2SharedBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L2SharedBridge proxy deployed @", address(sharedBridgeProxy));
        console.log("IMPORTANT: L1SharedBridge must be initialised with the L2SharedBridge address.");
        console.log(
            "L1SharedBridge(address(sharedBridgeProxy)).initializeChainGovernance(531050104, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2)"
        );
        console.log("Use the InitialiseL1Bridge script to do this.");
        console.log("IMPORTANT: L2SharedBridge must be added as minter on the L2 USDC contract.");
        console.log("Use the add-new-minter script on the USDC repo");
        // deploymentResults.sharedBridgeProxy = address(sharedBridgeProxy);
        // deploymentResults.sharedBridgeImpl = address(sharedBridgeImpl);

        // Fork from ML deployment scripts:
        // deploySharedBridge();
        // deploySharedBridgeProxy();
        // initializeChain();

        vm.stopBroadcast();
        // return deploymentResults;
        return (address(sharedBridgeProxy), address(sharedBridgeImpl));
    }

    // function deploySharedBridge() internal {
    //     bytes[] memory factoryDeps = new bytes[](1);
    //     factoryDeps[0] = contracts.beaconProxy;

    //     bytes memory constructorData = abi.encode(config.eraChainId);

    //     config.l2SharedBridgeImplementation = Utils.deployThroughL1({
    //         bytecode: contracts.l2SharedBridgeBytecode,
    //         constructorargs: constructorData,
    //         create2salt: "",
    //         l2GasLimit: Utils.MAX_PRIORITY_TX_GAS,
    //         factoryDeps: factoryDeps,
    //         chainId: config.chainId,
    //         bridgehubAddress: config.bridgehubAddress,
    //         l1SharedBridgeProxy: config.l1SharedBridgeProxy
    //     });
    // }

    // function deploySharedBridgeProxy() internal {
    //     address l2GovernorAddress = AddressAliasHelper.applyL1ToL2Alias(config.governance);
    //     bytes32 l2StandardErc20BytecodeHash = L2ContractHelper.hashL2Bytecode(contracts.beaconProxy);

    //     // solhint-disable-next-line func-named-parameters
    //     bytes memory proxyInitializationParams = abi.encodeWithSignature(
    //         "initialize(address,address,bytes32,address)",
    //         config.l1SharedBridgeProxy,
    //         config.erc20BridgeProxy,
    //         l2StandardErc20BytecodeHash,
    //         l2GovernorAddress
    //     );

    //     bytes memory l2SharedBridgeProxyConstructorData = abi.encode(
    //         config.l2SharedBridgeImplementation,
    //         l2GovernorAddress,
    //         proxyInitializationParams
    //     );

    //     config.l2SharedBridgeProxy = Utils.deployThroughL1({
    //         bytecode: contracts.l2SharedBridgeProxyBytecode,
    //         constructorargs: l2SharedBridgeProxyConstructorData,
    //         create2salt: "",
    //         l2GasLimit: Utils.MAX_PRIORITY_TX_GAS,
    //         factoryDeps: new bytes[](0),
    //         chainId: config.chainId,
    //         bridgehubAddress: config.bridgehubAddress,
    //         l1SharedBridgeProxy: config.l1SharedBridgeProxy
    //     });
    // }

    // function initializeChain() internal {
    //     L1SharedBridge bridge = L1SharedBridge(config.l1SharedBridgeProxy);

    //     Utils.executeUpgrade({
    //         _governor: bridge.owner(),
    //         _salt: bytes32(0),
    //         _target: config.l1SharedBridgeProxy,
    //         _data: abi.encodeCall(bridge.initializeChainGovernance, (config.chainId, config.l2SharedBridgeProxy)),
    //         _value: 0,
    //         _delay: 0
    //     });
    // }
}
