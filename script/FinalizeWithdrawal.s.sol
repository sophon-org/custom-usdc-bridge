// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1SharedBridge} from "../src/L1SharedBridge.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract FinalizeDepositScript is Script {
    L1SharedBridge public bridge;

    address public constant SEPOLIA_CUSTOM_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia TODO: get from ENV
    uint256 SOPHON_CHAIN_ID = 531050104; // Sophon Sepolia TODO: get from ENV

    function setUp() public {}

    struct FinalizationData {
        uint256 l1BatchNumber;
        uint256 l2MessageIndex;
        uint16 l2TxNumberInBlock;
        bytes message;
        address sender;
    }
    // bytes32[] proof;

    function finalizeWithdrawalParams() public returns (FinalizationData memory, bytes32[] memory) {
        // grab all params except for proof (since it fails)
        string[] memory args = new string[](4);
        args[0] = "node";
        args[1] = "script/getWithdrawalParams";
        args[2] = "--hash";
        args[3] = vm.envString("L2_WITHDRAWAL_HASH");
        string memory result = string(vm.ffi(args));
        FinalizationData memory data = abi.decode(vm.parseJson(result), (FinalizationData));

        if (data.sender == address(0)) {
            revert(result);
        }

        // grab only proof
        args = new string[](5);
        args[0] = "node";
        args[1] = "contracts/custom-usdc-bridge/script/getWithdrawalParmas";
        args[2] = "--proof";
        args[3] = "--hash";
        args[4] = vm.envString("L2_WITHDRAWAL_HASH");
        result = string(vm.ffi(args));
        bytes32[] memory proof = abi.decode(vm.parseJson(result), (bytes32[]));

        return (data, proof);
    }

    function run() public {
        vm.startBroadcast();

        (FinalizationData memory data, bytes32[] memory merkleProof) = finalizeWithdrawalParams();
        L1SharedBridge(SEPOLIA_CUSTOM_SHARED_BRIDGE_L1).finalizeWithdrawal(
            SOPHON_CHAIN_ID, data.l1BatchNumber, data.l2MessageIndex, data.l2TxNumberInBlock, data.message, merkleProof
        );

        vm.stopBroadcast();
    }
}
