// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    L2TransactionRequestTwoBridgesOuter,
    IBridgehub
} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";

interface MockUSDC {
    function approve(address usr, uint256 wad) external;
}

contract BridgeScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        uint256 amountToBridge = 1 * 10 ** 6; // 1 USDC

        approve(vm.envAddress("SOPH_TOKEN"), type(uint256).max);
        approve(vm.envAddress("L1_USDC_TOKEN"), amountToBridge);
        bridge(amountToBridge);

        vm.stopBroadcast();
    }

    function bridge(uint256 amountToBridge) public {
        uint256 L2_GAS_LIMIT = 435293;
        uint256 TX_GAS_PER_PUBDATA_BYTE_LIMIT = 800;
        uint256 CHAIN_ID = vm.envUint("SOPHON_SEPOLIA_CHAIN_ID"); // Sophon Sepolia

        // Prepare data for the bridgehubDeposit call
        bytes memory depositData = abi.encode(
            vm.envAddress("L1_USDC_TOKEN"),
            amountToBridge,
            msg.sender // sender is the recipient of the tokens on L2
        );

        // TODO: gasPrice() call sometimes fails sometimes not, why?
        // uint256 l2GasPrice = gasPrice();
        // console.log("Gas price:", l2GasPrice);
        // uint256 baseCost = IBridgehub(SEPOLIA_L1_BRIDGEHUB).l2TransactionBaseCost(
        //     CHAIN_ID, l2GasPrice, L2_GAS_LIMIT, TX_GAS_PER_PUBDATA_BYTE_LIMIT
        // );
        // // TODO: why baseCost is returning a very high number?
        // console.log("Base cost:", baseCost);

        IBridgehub(vm.envAddress("SEPOLIA_L1_BRIDGEHUB")).requestL2TransactionTwoBridges( // No vale needed if base token is not ETH (e.g SOPH)
            L2TransactionRequestTwoBridgesOuter({
                chainId: CHAIN_ID,
                mintValue: 4e18, // base tokens (SOPH for Sophon Sepolia, ETH for Sepolia)
                // mintValue: baseCost,
                l2Value: 0,
                l2GasLimit: L2_GAS_LIMIT, // TODO: it should take ~300'000
                l2GasPerPubdataByteLimit: TX_GAS_PER_PUBDATA_BYTE_LIMIT, // TODO: how to calculate?
                refundRecipient: address(0), // TODO: why is 0?
                secondBridgeAddress: vm.envAddress("SEPOLIA_CUSTOM_SHARED_BRIDGE_L1"),
                secondBridgeValue: 0,
                secondBridgeCalldata: depositData
            })
        );
    }

    function approve(address token, uint256 amount) public {
        IERC20 token = IERC20(token);
        address l1Bridge = vm.envAddress("SEPOLIA_CUSTOM_SHARED_BRIDGE_L1");

        // approve shared bridge to spend base tokens
        console.log("Checking %s allowance...", token.symbol());
        uint256 allowance = token.allowance(msg.sender, l1Bridge);
        if (allowance < amount) {
            console.log("Approving...");
            if (address(token) == vm.envAddress("L1_USDC_TOKEN")) {
                MockUSDC(address(token)).approve(l1Bridge, amount);
            } else {
                token.approve(l1Bridge, amount);
            }
            console.log("New allowance:", token.allowance(msg.sender, l1Bridge));
        }
        console.log("%s allowance OK", token.symbol());
    }

    function gasPrice() public returns (uint256 price) {
        // cast gas-price --rpc-url https://rpc.testnet.sophon.xyz/
        string[] memory args = new string[](4);
        args[0] = "cast";
        args[1] = "gas-price";
        args[2] = "--rpc-url";
        args[3] = "https://rpc.testnet.sophon.xyz/"; // TODO: get from ENV
        string memory result = string(vm.ffi(args));

        return vm.parseUint(result);
    }
}
