// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L2SharedBridge} from "../L2SharedBridge.sol";

contract FinalizeDepositScript is Script {
    L2SharedBridge public bridge;

    address public constant L1_USDC_ADDRESS = 0x1c9Ff39402b15e9A7C67ffd1A260d04d852F5DFe; // MockUSDC on Sepolia testnet
    address public constant L2_USDC_ADDRESS = 0x27553b610304b6AB77855a963f8208443D773E60; // Native USDC on Sophon testnet
    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0x3Afa2982a08BEbDB076A4F289815d4c676FE446a; // Sophon Sepolia

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        uint256 amountToBridge = 0.1 * 10 ** 6; // 1 USDC

        bytes memory depositData = abi.encode(
            L1_USDC_ADDRESS,
            amountToBridge,
            msg.sender // sender is the recipient of the tokens on L2
        );

        L2SharedBridge(SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2).finalizeDeposit(
            msg.sender, msg.sender, L1_USDC_ADDRESS, amountToBridge, depositData
        );

        vm.stopBroadcast();
    }
}
