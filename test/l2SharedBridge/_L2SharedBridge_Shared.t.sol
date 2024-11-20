// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {L2SharedBridge} from "../../src/L2SharedBridge.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IL2SharedBridge} from "../../src/interfaces/IL2SharedBridge.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

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

    event FinalizeDeposit(
        address indexed l1Sender, address indexed l2Receiver, address indexed l2Token, uint256 amount
    );
    event WithdrawalInitiated(
        address indexed l2Sender, address indexed l1Receiver, address indexed l2Token, uint256 amount
    );

    L2SharedBridge bridge;
    MintableToken mockL2Token;
    address l1SharedBridge;
    address alice;
    address bob;
    address proxyAdmin;

    uint256 depositAmount = 100 ether;
    uint160 constant SYSTEM_CONTRACTS_OFFSET = 0x8000;

    function setUp() public virtual {
        mockL2Token = new MintableToken();
        mockL2Token.initialize("Mock USDC", "USDC", 18);
        l1SharedBridge = makeAddr("l1SharedBridge");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        proxyAdmin = makeAddr("proxyAdmin");

        L2SharedBridge sharedBridgeImpl = new L2SharedBridge(address(mockL2Token), address(mockL2Token));
        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            proxyAdmin,
            abi.encodeWithSelector(L2SharedBridge.initialize.selector, l1SharedBridge)
        );
        bridge = L2SharedBridge(address(sharedBridgeProxy));
    }
}
