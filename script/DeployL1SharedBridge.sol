// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployL1SharedBridgeScript is Script {
    // TODO: read from env?
    address public constant SEPOLIA_L1_BRIDGEHUB = 0x35A54c8C757806eB6820629bc82d90E056394C92; // Ethereum Sepolia
    address public constant ERA_DIAMOND_PROXY = 0x9A6DE0f62Aa270A8bCB1e2610078650D539B1Ef9; // Ethereum Sepolia
    address public constant L1_USDC_ADDRESS = 0xBF4FdF7BF4014EA78C0A07259FBc4315Cb10d94E; // MockUSDC on Sepolia testnet
    address public constant SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia
    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0x3Afa2982a08BEbDB076A4F289815d4c676FE446a; // Sophon Sepolia

    function setUp() public {}

    function run() public {
        // TODO: set proper addresses, maybe read from env
        address deployerAddress = msg.sender;
        address owner = address(123);

        vm.startBroadcast();

        L1SharedBridge sharedBridgeImpl = new L1SharedBridge(
            L1_USDC_ADDRESS,
            IBridgehub(SEPOLIA_L1_BRIDGEHUB), // Sepolia L1 Bridgehub
            531050104, // Sophon chain ID
            ERA_DIAMOND_PROXY // Era Diamond Proxy
        );

        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            owner,
            abi.encodeWithSelector(L1SharedBridge.initialize.selector, deployerAddress)
        );

        console.log("L1SharedBridge implementation deployed @", address(sharedBridgeImpl));
        console.log("L1SharedBridge proxy deployed @", address(sharedBridgeProxy));

        // L1SharedBridge(address(sharedBridgeProxy)).initializeChainGovernance(531050104, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);
        // L1SharedBridge(SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1).reinitializeChainGovernance(531050104, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);

        vm.stopBroadcast();
        // From ML deployment scripts:
        // deploySharedBridgeImplementation();
        // deploySharedBridgeProxy();
        // registerSharedBridge();
    }

    // function deploySharedBridgeImplementation() internal {
    //     bytes memory bytecode = abi.encodePacked(
    //         type(L1SharedBridge).creationCode,
    //         // solhint-disable-next-line func-named-parameters
    //         abi.encode(
    //             L1_USDC_ADDRESS,
    //             IBridgehub(SEPOLIA_L1_BRIDGEHUB), // Sepolia L1 Bridgehub
    //             531050104, // Sophon chain ID
    //             ERA_DIAMOND_PROXY // Era Diamond Proxy
    //         )
    //     );
    //     address contractAddress = Utils.deployViaCreate2(bytecode, "sophon", addresses.create2Factory);
    //     console.log("SharedBridgeImplementation deployed at:", contractAddress);
    //     addresses.bridges.sharedBridgeImplementation = contractAddress;
    // }

    // function deploySharedBridgeProxy() internal {
    //     bytes memory initCalldata = abi.encodeCall(L1SharedBridge.initialize, (config.deployerAddress));
    //     bytes memory bytecode = abi.encodePacked(
    //         type(TransparentUpgradeableProxy).creationCode,
    //         abi.encode(addresses.bridges.sharedBridgeImplementation, addresses.transparentProxyAdmin, initCalldata)
    //     );
    //     address contractAddress = deployViaCreate2(bytecode);
    //     console.log("SharedBridgeProxy deployed at:", contractAddress);
    //     addresses.bridges.sharedBridgeProxy = contractAddress;
    // }

    // function registerSharedBridge() internal {
    //     Bridgehub bridgehub = Bridgehub(addresses.bridgehub.bridgehubProxy);
    //     vm.startBroadcast();
    //     bridgehub.addToken(ADDRESS_ONE);
    //     bridgehub.setSharedBridge(addresses.bridges.sharedBridgeProxy);
    //     vm.stopBroadcast();
    //     console.log("SharedBridge registered");
    // }
}
