// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IL2SharedBridge} from "@era-contracts/l2-contracts/contracts/bridge/interfaces/IL2SharedBridge.sol";

interface USDC {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function isMinter(address) external view returns (bool);
    function isBlacklisted(address) external view returns (bool);
    function paused() external view returns (bool);
    function test() external view returns (uint256);
}

interface Proxy {
    function admin() external view returns (address);
    function changeAdmin(address newAdmin) external;
}

// IMPORTANT: Use [profile.zksync] on foundry.toml
contract WithdrawScript is Script {
    address public constant SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2 = 0x7147d704Ba0E1F146457Dc93806FE66c201aA7C5; // Sophon Sepolia
    address L2_USDC_ADDRESS = 0x27553b610304b6AB77855a963f8208443D773E60; // Native USDC on Sophon testnet

    function setUp() public {}

    function run() public {
        console.log(msg.sender);
        IERC20 token = IERC20(L2_USDC_ADDRESS);
        uint256 amountToWithdraw = 1 * 10 ** 6; // 1 USDC

        vm.startBroadcast();

        // approve shared bridge to spend USDC tokens
        console.log("Token name:", token.name());
        console.log("Balance:", token.balanceOf(msg.sender));
        uint256 allowance = token.allowance(msg.sender, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);
        console.log("USDC allowance:", allowance);
        if (allowance < amountToWithdraw) {
            console.log("Approving tokens for withdrawal");
            token.approve(SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2, type(uint256).max);
            console.log("USDC allowance:", token.allowance(msg.sender, SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2));
        }

        IL2SharedBridge bridgeL2 = IL2SharedBridge(SOPHON_CUSTOM_ERC20_SHARED_BRIDGE_L2);
        bridgeL2.withdraw(msg.sender, address(0), amountToWithdraw);

        vm.stopBroadcast();
    }
}
