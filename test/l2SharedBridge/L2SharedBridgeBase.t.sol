// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {L2SharedBridge} from "../../src/L2SharedBridge.sol";
import {IL1ERC20Bridge} from "../../src/interfaces/IL1ERC20Bridge.sol";
import {IL2Messenger} from "../../src/interfaces/IL2Messenger.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IL2SharedBridge} from "../../src/interfaces/IL2SharedBridge.sol";

contract MintableToken is MockERC20 {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}

contract MockL2Messenger {
    function sendToL1(bytes memory message) external returns (bytes32) {
        return keccak256(message);
    }
}

contract L2SharedBridgeTest is Test {
    using SafeERC20 for IERC20;

    L2SharedBridge bridge;
    MintableToken mockL2Token;
    address l1SharedBridge;
    address alice;
    address bob;

    uint256 depositAmount = 100 ether;
    uint160 constant SYSTEM_CONTRACTS_OFFSET = 0x8000; // 2^15

    function setUp() public {
        mockL2Token = new MintableToken();
        mockL2Token.initialize("Mock USDC", "USDC", 18);
        l1SharedBridge = makeAddr("l1SharedBridge");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // deploy L2SharedBridge with mock L1 and L2 token addresses
        address proxyAdmin = makeAddr("proxyAdmin");
        L2SharedBridge sharedBridgeImpl = new L2SharedBridge(address(mockL2Token), address(mockL2Token));
        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            proxyAdmin,
            abi.encodeWithSelector(L2SharedBridge.initialize.selector, l1SharedBridge)
        );
        bridge = L2SharedBridge(address(sharedBridgeProxy));
    }

    function testFinalizeDeposit() public {
        uint256 initialBalance = mockL2Token.balanceOf(bob);
        address aliasedL1SharedBridge =
            address(uint160(l1SharedBridge) + uint160(0x1111000000000000000000000000000000001111));

        vm.expectEmit(true, true, true, true);
        emit IL2SharedBridge.FinalizeDeposit(alice, bob, address(mockL2Token), depositAmount);

        vm.prank(aliasedL1SharedBridge);
        bridge.finalizeDeposit(alice, bob, address(mockL2Token), depositAmount, "");

        uint256 finalBalance = mockL2Token.balanceOf(bob);
        assertEq(finalBalance - initialBalance, depositAmount);
    }

    function testFinalizeDeposit_RevertIfWrongCaller() public {
        vm.expectRevert(bytes("mq"));
        bridge.finalizeDeposit(alice, bob, address(mockL2Token), depositAmount, "");
    }

    function testWithdraw() public {
        mockL2Token.mint(alice, depositAmount);

        vm.startPrank(alice);
        mockL2Token.approve(address(bridge), depositAmount);

        // mock L2 messenger call
        bytes memory expectedMessage =
            abi.encodePacked(IL1ERC20Bridge.finalizeWithdrawal.selector, bob, address(mockL2Token), depositAmount);

        // initiate withdrawal
        MockL2Messenger mockMessenger = new MockL2Messenger();
        vm.etch(address(SYSTEM_CONTRACTS_OFFSET + 0x08), address(mockMessenger).code);

        vm.expectEmit(true, true, true, true);
        emit IL2SharedBridge.WithdrawalInitiated(alice, bob, address(mockL2Token), depositAmount);

        vm.expectCall(address(SYSTEM_CONTRACTS_OFFSET + 0x08), abi.encodeCall(IL2Messenger.sendToL1, expectedMessage));
        // vm.mockCall(
        //     address(SYSTEM_CONTRACTS_OFFSET + 0x08),
        //     abi.encodeWithSelector(IL2Messenger.sendToL1.selector, expectedMessage),
        //     bytes("")
        // );
        bridge.withdraw(bob, address(mockL2Token), depositAmount);

        uint256 aliceBalance = mockL2Token.balanceOf(alice);
        assertEq(aliceBalance, 0);

        vm.stopPrank();
    }

    function testWithdraw_RevertIfZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert("Amount cannot be zero");
        bridge.withdraw(bob, address(mockL2Token), 0);
        vm.stopPrank();
    }

    function testL2TokenAddress() public {
        address l2TokenAddress = bridge.l2TokenAddress(address(mockL2Token));
        assertEq(l2TokenAddress, address(mockL2Token));
    }

    function testL1TokenAddress() public {
        address l1TokenAddress = bridge.l1TokenAddress(address(mockL2Token));
        assertEq(l1TokenAddress, address(mockL2Token));
    }
}
