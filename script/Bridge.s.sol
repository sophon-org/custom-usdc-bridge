// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    L2TransactionRequestTwoBridgesOuter,
    IBridgehub
} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";

contract BridgeScript is Script {
    address public constant SEPOLIA_L1_BRIDGEHUB = 0x35A54c8C757806eB6820629bc82d90E056394C92; // Ethereum Sepolia
    address public constant SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1 = 0x8dA770B66f6F4F71068Fe5Dd1cB879a0353f90D8; // Ethereum Sepolia

    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0x7147d704Ba0E1F146457Dc93806FE66c201aA7C5; // Sophon Sepolia
    address L1_USDC_ADDRESS = 0xBF4FdF7BF4014EA78C0A07259FBc4315Cb10d94E; // MockUSDC on Sepolia testnet
    address L2_USDC_ADDRESS = 0x27553b610304b6AB77855a963f8208443D773E60; // Native USDC on Sophon testnet
    address public constant SOPH_TOKEN = 0x06c03F9319EBbd84065336240dcc243bda9D8896; // SOPH

    uint256 L2_GAS_LIMIT = 435293;
    uint256 TX_GAS_PER_PUBDATA_BYTE_LIMIT = 800;
    uint256 CHAIN_ID = 531050104; // Sophon Sepolia

    function setUp() public {}

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

    function run() public {
        vm.startBroadcast();
        uint256 amountToBridge = 1 * 10 ** 6; // 1 LINK

        IERC20 SOPH = IERC20(SOPH_TOKEN);
        IBridgehub bridge = IBridgehub(SEPOLIA_L1_BRIDGEHUB);

        // Approve bridgehub to spend base tokens
        console.log("Checking SOPH allowance...");
        uint256 allowanceSOPH = SOPH.allowance(msg.sender, SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1);
        if (allowanceSOPH < amountToBridge) {
            console.log("Approving SOPH for bridge");
            SOPH.approve(SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1, type(uint256).max);
            console.log("SOPH allowance:", SOPH.allowance(msg.sender, SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1));
        }
        console.log("SOPH allowance OK");

        // TODO: I BELIEVE THIS IS NOT WORKING...
        // Approve shared bridge to spend MockUSDC tokens
        console.log("Checking USDC allowance...");
        IERC20 token = IERC20(L1_USDC_ADDRESS);
        uint256 allowance = token.allowance(msg.sender, SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1);
        if (allowance < amountToBridge) {
            console.log("Approving tokens for bridge");
            token.approve(SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1, type(uint256).max);
            console.log("USDC allowance:", token.allowance(msg.sender, SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1));
        }
        console.log("USDC allowance OK");

        // Prepare data for the bridgehubDeposit call
        bytes memory depositData = abi.encode(
            L1_USDC_ADDRESS,
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

        // bridge.requestL2TransactionTwoBridges{ value: 4402173869530008 }(
        bridge.requestL2TransactionTwoBridges( // No vale needed if base token is not ETH (e.g SOPH)
            L2TransactionRequestTwoBridgesOuter({
                chainId: CHAIN_ID,
                mintValue: 2e18, // base tokens (SOPH for Sophon Sepolia, ETH for Sepolia)
                // mintValue: baseCost,
                l2Value: 0,
                l2GasLimit: L2_GAS_LIMIT, // TODO: it should take ~300'000
                l2GasPerPubdataByteLimit: TX_GAS_PER_PUBDATA_BYTE_LIMIT, // TODO: how to calculate?
                refundRecipient: address(0), // TODO: why is 0?
                secondBridgeAddress: SEPOLIA_CUSTOM_ERC20_SHARED_BRIDGE_L1,
                secondBridgeValue: 0,
                secondBridgeCalldata: depositData
            })
        );

        vm.stopBroadcast();
    }
}
