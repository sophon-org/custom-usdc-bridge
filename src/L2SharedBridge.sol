// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {IL1ERC20Bridge} from "@era-contracts/l2-contracts/contracts/bridge/interfaces/IL1ERC20Bridge.sol";
import {IL2SharedBridge} from "@era-contracts/l2-contracts/contracts/bridge/interfaces/IL2SharedBridge.sol";
import {IL2StandardToken} from "@era-contracts/l2-contracts/contracts/bridge/interfaces/IL2StandardToken.sol";

import {L2StandardERC20} from "@era-contracts/l2-contracts/contracts/bridge/L2StandardERC20.sol";
import {AddressAliasHelper} from "@era-contracts/l2-contracts/contracts/vendor/AddressAliasHelper.sol";
import {
    L2ContractHelper,
    DEPLOYER_SYSTEM_CONTRACT,
    IContractDeployer
} from "@era-contracts/l2-contracts/contracts/L2ContractHelper.sol";
import {SystemContractsCaller} from "@era-contracts/l2-contracts/contracts/SystemContractsCaller.sol";

// TODO: use import
interface IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}

/// @author Sophon
/// @notice Forked from ML L1SharedBridge contract
/// @custom:security-contact security@matterlabs.dev
/// @notice The "default" bridge implementation for the ERC20 tokens. Note, that it does not
/// support any custom token logic, i.e. rebase tokens' functionality is not supported.
contract L2SharedBridge is IL2SharedBridge, Initializable {
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
        IERC20(L2_USDC_TOKEN).mint(_l2Receiver, _amount);
        emit FinalizeDeposit(_l1Sender, _l2Receiver, L2_USDC_TOKEN, _amount);
    }

    /// @notice Initiates a withdrawal by burning funds on the contract and sending the message to L1
    /// where tokens would be unlocked
    /// @param _l1Receiver The account address that should receive funds on L1
    /// _l2Token The L2 token address which is withdrawn
    /// @param _amount The total amount of tokens to be withdrawn
    function withdraw(address _l1Receiver, address, uint256 _amount) external override {
        require(_amount > 0, "Amount cannot be zero");

        IERC20(L2_USDC_TOKEN).burn(msg.sender, _amount);

        // encode the message for l2ToL1log sent with withdraw initialization
        bytes memory message =
            abi.encodePacked(IL1ERC20Bridge.finalizeWithdrawal.selector, _l1Receiver, L1_USDC_TOKEN, _amount);
        L2ContractHelper.sendMessageToL1(message);

        emit WithdrawalInitiated(msg.sender, _l1Receiver, L2_USDC_TOKEN, _amount);
    }

    function l1TokenAddress(address _l2Token) external view returns (address) {
        return L1_USDC_TOKEN;
    }

    function l2TokenAddress(address _l1Token) public view override returns (address) {
        return L2_USDC_TOKEN;
    }
}
