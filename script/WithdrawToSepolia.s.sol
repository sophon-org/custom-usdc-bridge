// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IL2SharedBridge} from "@era-contracts/l2-contracts/contracts/bridge/interfaces/IL2SharedBridge.sol";

// IMPORTANT: Use [profile.zksync] on foundry.toml
contract WithdrawScript is Script {
    // Counter public counter;
    address public constant CONTRACT_DEPLOYER = 0x0000000000000000000000000000000000008006;

    address public constant SEPOLIA_L1_BRIDGEHUB = 0x35A54c8C757806eB6820629bc82d90E056394C92; // Ethereum Sepolia
    address public constant SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia

    address public constant ZKSYNC_ERC20_SHARED_BRIDGE_L2 = 0x681A1AFdC2e06776816386500D2D461a6C96cB45; // zkSync Sepolia
    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0xb10DD9f622Ad0192cb007e12d5359081B90273bB; // Sophon Sepolia

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        IL2SharedBridge bridgeL2 = IL2SharedBridge(SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);
        bridgeL2.withdraw(msg.sender, address(0), 5e18);

        vm.stopBroadcast();
    }
}
