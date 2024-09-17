// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {IL1ERC20Bridge} from "./interfaces/IL1ERC20Bridge.sol";
import {IL2SharedBridge} from "./interfaces/IL2SharedBridge.sol";
import {IL2Messenger} from "./interfaces/IL2Messenger.sol";
// import {AddressAliasHelper} from "@era-contracts/l2-contracts/contracts/vendor/AddressAliasHelper.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface MintableToken {
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
}

/// @author Sophon
/// @notice Forked from ML L1SharedBridge contract
/// @custom:security-contact security@matterlabs.dev
/// @notice The "default" bridge implementation for the ERC20 tokens. Note, that it does not
/// support any custom token logic, i.e. rebase tokens' functionality is not supported.
contract L2SharedBridge is IL2SharedBridge, Initializable {
    using SafeERC20 for IERC20;

    // TODO: do we have a different SYSTEM_CONTRACT_OFFSET IN SOPHON?
    uint160 constant SYSTEM_CONTRACTS_OFFSET = 0x8000; // 2^15

    /// @dev The address of the L1 shared bridge counterpart.
    address public override l1SharedBridge;

    // TODO: can i safely remove this?
    /// @dev The address of the legacy L1 erc20 bridge counterpart.
    /// This is non-zero only on Era, and should not be renamed for backward compatibility with the SDKs.
    address public override l1Bridge;

    /// @dev Contract is expected to be used as proxy implementation.
    /// @dev Disable the initialization to prevent Parity hack.
    // uint256 immutable ERA_CHAIN_ID; // TODO: check if i need this!

    /// @dev The address of the USDC token on L1.
    address public immutable L1_USDC_TOKEN;

    /// @dev The address of the USDC token on L2.
    address public immutable L2_USDC_TOKEN;

    constructor(address _l1UsdcToken, address _l2UsdcToken) {
        // ERA_CHAIN_ID = _eraChainId; // TODO: checke if we need this!
        L1_USDC_TOKEN = _l1UsdcToken;
        L2_USDC_TOKEN = _l2UsdcToken;
        _disableInitializers();
    }

    /// @notice Initializes the bridge contract for later use. Expected to be used in the proxy.
    /// @param _l1SharedBridge The address of the L1 Bridge contract.
    /// _l1Bridge The address of the legacy L1 Bridge contract.
    function initialize(address _l1SharedBridge)
        // address _l1Bridge,
        external
        reinitializer(2)
    {
        require(_l1SharedBridge != address(0), "bf");
        l1SharedBridge = _l1SharedBridge;
        // l1Bridge = _l1Bridge; TODO: do we need this?
    }

    /// @notice Finalize the deposit and mint funds
    /// @param _l1Sender The account address that initiated the deposit on L1
    /// @param _l2Receiver The account address that would receive minted ether
    /// _l1Token The address of the token that was locked on the L1
    /// @param _amount Total amount of tokens deposited from L1
    /// @param _data The additional data that user can pass with the deposit
    function finalizeDeposit(address _l1Sender, address _l2Receiver, address, uint256 _amount, bytes calldata _data)
        external
        override
    {
        // Only the L1 bridge counterpart can initiate and finalize the deposit.
        // require(
        //     AddressAliasHelper.undoL1ToL2Alias(msg.sender) == l1Bridge ||
        //         AddressAliasHelper.undoL1ToL2Alias(msg.sender) == l1SharedBridge,
        //     "mq"
        // );
        MintableToken(L2_USDC_TOKEN).mint(_l2Receiver, _amount);
        emit FinalizeDeposit(_l1Sender, _l2Receiver, L2_USDC_TOKEN, _amount);
    }

    /// @notice Initiates a withdrawal by burning funds on the contract and sending the message to L1
    /// where tokens would be unlocked
    /// @param _l1Receiver The account address that should receive funds on L1
    /// _l2Token The L2 token address which is withdrawn
    /// @param _amount The total amount of tokens to be withdrawn
    function withdraw(address _l1Receiver, address, uint256 _amount) external override {
        require(_amount > 0, "Amount cannot be zero");

        // transfer from msg.sender to here and then burn
        IERC20(L2_USDC_TOKEN).safeTransferFrom(msg.sender, address(this), _amount);
        MintableToken(L2_USDC_TOKEN).burn(_amount);

        // encode the message for l2ToL1log sent with withdraw initialization
        bytes memory message =
            abi.encodePacked(IL1ERC20Bridge.finalizeWithdrawal.selector, _l1Receiver, L1_USDC_TOKEN, _amount);
        // L2ContractHelper.sendMessageToL1(message);
        IL2Messenger(address(SYSTEM_CONTRACTS_OFFSET + 0x08)).sendToL1(message);

        emit WithdrawalInitiated(msg.sender, _l1Receiver, L2_USDC_TOKEN, _amount);
    }

    function l1TokenAddress(address _l2Token) external view returns (address) {
        return L1_USDC_TOKEN;
    }

    function l2TokenAddress(address _l1Token) public view override returns (address) {
        return L2_USDC_TOKEN;
    }
}
