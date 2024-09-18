// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../../src/L1SharedBridge.sol";
import {L2SharedBridge} from "../../src/L2SharedBridge.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";

contract SharedBridgesTest is Test {
    uint256 sepoliaTestnet = vm.createSelectFork("sepoliaTestnet");
    uint256 sophonTestnet = vm.createSelectFork("sophonTestnet");

    address l1SharedBridge;
    address l2SharedBridge;
    address alice;

    function deployL1Contracts() public {
        vm.selectFork(sepoliaTestnet);

        // deploy implementation
        L1SharedBridge sharedBridgeImpl = new L1SharedBridge{salt: "1"}(
            vm.envAddress("L1_USDC_TOKEN"),
            IBridgehub(vm.envAddress("SEPOLIA_L1_BRIDGEHUB")), // Sepolia L1 Bridgehub
            vm.envUint("SOPHON_SEPOLIA_CHAIN_ID"), // Sophon chain ID
            vm.envAddress("ERA_DIAMOND_PROXY") // Era Diamond Proxy);
        );

        // deploy proxy
        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            address(alice), // proxy admin
            abi.encodeWithSelector(L1SharedBridge.initialize.selector, address(this)) // implementation owner
        );

        l1SharedBridge = address(sharedBridgeProxy);
    }

    function deployL2Contracts() public {
        vm.selectFork(sophonTestnet);

        // deploy implementation
        L2SharedBridge sharedBridgeImpl =
            new L2SharedBridge(vm.envAddress("L1_USDC_TOKEN"), vm.envAddress("L2_USDC_TOKEN"));

        // deploy proxy
        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            address(this),
            abi.encodeWithSelector(L2SharedBridge.initialize.selector, l1SharedBridge)
        );

        l2SharedBridge = address(sharedBridgeProxy);
    }

    function setUp() public {
        alice = makeAddr("alice");

        deployL1Contracts();
        deployL2Contracts();

        // initialise L1 shared bridge with L2 shared bridge address
        vm.selectFork(sepoliaTestnet);
        L1SharedBridge(l1SharedBridge).initializeChainGovernance(vm.envUint("SOPHON_SEPOLIA_CHAIN_ID"), l2SharedBridge);

        // add L2 shared bridge as minter on USDC
    }
}
