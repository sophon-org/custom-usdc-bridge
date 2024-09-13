// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {L1SharedBridgeTest} from "./_L1SharedBridge_Shared.t.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {L1SharedBridge} from "@era-contracts/l1-contracts/contracts/bridge/L1SharedBridge.sol";
import {ETH_TOKEN_ADDRESS} from "@era-contracts/l1-contracts/contracts/common/Config.sol";
import {IBridgehub} from "@era-contracts/l1-contracts/contracts/bridgehub/IBridgehub.sol";
import {L2Message, TxStatus} from "@era-contracts/l1-contracts/contracts/common/Messaging.sol";
import {IMailbox} from "@era-contracts/l1-contracts/contracts/state-transition/chain-interfaces/IMailbox.sol";
import {IL1ERC20Bridge} from "@era-contracts/l1-contracts/contracts/bridge/interfaces/IL1ERC20Bridge.sol";
import {L2_BASE_TOKEN_SYSTEM_CONTRACT_ADDR} from "@era-contracts/l1-contracts/contracts/common/L2ContractAddresses.sol";
import {IGetters} from "@era-contracts/l1-contracts/contracts/state-transition/chain-interfaces/IGetters.sol";

/// We are testing all the specified revert and require cases.
contract L1SharedBridgeFailTest is L1SharedBridgeTest {
    function test_initialize_wrongOwner() public {
        vm.expectRevert("ShB owner 0");
        new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            proxyAdmin,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(L1SharedBridge.initialize.selector, address(0), eraPostUpgradeFirstBatch)
        );
    }

    function test_bridgehubDepositBaseToken_EthwrongMsgValue() public {
        vm.deal(bridgehubAddress, amount);
        vm.prank(bridgehubAddress);
        vm.expectRevert("L1SharedBridge: msg.value not equal to amount");
        sharedBridge.bridgehubDepositBaseToken(chainId, alice, ETH_TOKEN_ADDRESS, amount);
    }

    function test_bridgehubDepositBaseToken_ErcWrongMsgValue() public {
        vm.deal(bridgehubAddress, amount);
        token.mint(alice, amount);
        vm.prank(alice);
        token.approve(address(sharedBridge), amount);
        vm.prank(bridgehubAddress);
        vm.expectRevert("ShB m.v > 0 b d.it");
        sharedBridge.bridgehubDepositBaseToken{value: amount}(chainId, alice, address(token), amount);
    }

    function test_bridgehubDepositBaseToken_ErcWrongErcDepositAmount() public {
        token.mint(alice, amount);
        vm.prank(alice);
        token.approve(address(sharedBridge), amount);

        vm.mockCall(address(token), abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(10));

        bytes memory message = bytes("3T");
        vm.expectRevert(message);
        vm.prank(bridgehubAddress);
        sharedBridge.bridgehubDepositBaseToken(chainId, alice, address(token), amount);
    }

    function test_bridgehubDeposit_Eth_l2BridgeNotDeployed() public {
        vm.prank(owner);
        sharedBridge.reinitializeChainGovernance(chainId, address(0));
        vm.deal(bridgehubAddress, amount);
        vm.prank(bridgehubAddress);
        vm.mockCall(bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(address(token)));
        vm.expectRevert("ShB l2 bridge not deployed");
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit{value: amount}(chainId, alice, 0, abi.encode(ETH_TOKEN_ADDRESS, 0, bob));
    }

    function test_bridgehubDeposit_Erc_weth() public {
        vm.prank(bridgehubAddress);
        vm.expectRevert("ShB: WETH deposit not supported");
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit(chainId, alice, 0, abi.encode(l1WethAddress, amount, bob));
    }

    function test_bridgehubDeposit_Eth_baseToken() public {
        vm.prank(bridgehubAddress);
        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );
        vm.expectRevert("ShB: baseToken deposit not supported");
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit(chainId, alice, 0, abi.encode(ETH_TOKEN_ADDRESS, 0, bob));
    }

    function test_bridgehubDeposit_Eth_wrongDepositAmount() public {
        token.mint(alice, amount);
        vm.prank(alice);
        token.approve(address(sharedBridge), amount);
        vm.prank(bridgehubAddress);
        vm.mockCall(bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(address(token)));
        vm.expectRevert("ShB wrong withdraw amount");
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit(chainId, alice, 0, abi.encode(ETH_TOKEN_ADDRESS, amount, bob));
    }

    function test_bridgehubDeposit_Erc_msgValue() public {
        vm.deal(bridgehubAddress, amount);
        token.mint(alice, amount);
        vm.prank(alice);
        token.approve(address(sharedBridge), amount);
        vm.prank(bridgehubAddress);
        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );
        vm.expectRevert("ShB m.v > 0 for BH d.it 2");
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit{value: amount}(chainId, alice, 0, abi.encode(address(token), amount, bob));
    }

    function test_bridgehubDeposit_Erc_wrongDepositAmount() public {
        token.mint(alice, amount);
        vm.prank(alice);
        token.approve(address(sharedBridge), amount);
        vm.prank(bridgehubAddress);
        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );
        vm.mockCall(address(token), abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(10));
        bytes memory message = bytes("5T");
        vm.expectRevert(message);
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit(chainId, alice, 0, abi.encode(address(token), amount, bob));
    }

    function test_bridgehubDeposit_Eth() public {
        vm.prank(bridgehubAddress);
        vm.mockCall(bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(address(token)));
        bytes memory message = bytes("6T");
        vm.expectRevert(message);
        // solhint-disable-next-line func-named-parameters
        sharedBridge.bridgehubDeposit(chainId, alice, 0, abi.encode(ETH_TOKEN_ADDRESS, 0, bob));
    }

    function test_bridgehubConfirmL2Transaction_depositAlreadyHappened() public {
        bytes32 txDataHash = keccak256(abi.encode(alice, address(token), amount));
        _setSharedBridgeDepositHappened(chainId, txHash, txDataHash);
        vm.prank(bridgehubAddress);
        vm.expectRevert("ShB tx hap");
        sharedBridge.bridgehubConfirmL2Transaction(chainId, txDataHash, txHash);
    }

    function test_claimFailedDeposit_proofInvalid() public {
        vm.mockCall(
            bridgehubAddress,
            abi.encodeWithSelector(IBridgehub.proveL1ToL2TransactionStatus.selector),
            abi.encode(address(0))
        );
        vm.prank(bridgehubAddress);
        bytes memory message = bytes("yn");
        vm.expectRevert(message);
        sharedBridge.claimFailedDeposit({
            _chainId: chainId,
            _depositSender: alice,
            _l1Token: ETH_TOKEN_ADDRESS,
            _amount: amount,
            _l2TxHash: txHash,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _merkleProof: merkleProof
        });
    }

    function test_claimFailedDeposit_amountZero() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(
                IBridgehub.proveL1ToL2TransactionStatus.selector,
                chainId,
                txHash,
                l2BatchNumber,
                l2MessageIndex,
                l2TxNumberInBatch,
                merkleProof,
                TxStatus.Failure
            ),
            abi.encode(true)
        );

        bytes memory message = bytes("y1");
        vm.expectRevert(message);
        sharedBridge.claimFailedDeposit({
            _chainId: chainId,
            _depositSender: alice,
            _l1Token: ETH_TOKEN_ADDRESS,
            _amount: 0,
            _l2TxHash: txHash,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _merkleProof: merkleProof
        });
    }

    function test_claimFailedDeposit_depositDidNotHappen() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(
                IBridgehub.proveL1ToL2TransactionStatus.selector,
                chainId,
                txHash,
                l2BatchNumber,
                l2MessageIndex,
                l2TxNumberInBatch,
                merkleProof,
                TxStatus.Failure
            ),
            abi.encode(true)
        );

        vm.expectRevert("ShB: d.it not hap");
        sharedBridge.claimFailedDeposit({
            _chainId: chainId,
            _depositSender: alice,
            _l1Token: ETH_TOKEN_ADDRESS,
            _amount: amount,
            _l2TxHash: txHash,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _merkleProof: merkleProof
        });
    }

    function test_claimFailedDeposit_chainBalanceLow() public {
        vm.deal(address(sharedBridge), amount);

        bytes32 txDataHash = keccak256(abi.encode(alice, ETH_TOKEN_ADDRESS, amount));
        _setSharedBridgeDepositHappened(chainId, txHash, txDataHash);
        require(sharedBridge.depositHappened(chainId, txHash) == txDataHash, "Deposit not set");

        vm.mockCall(
            bridgehubAddress,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(
                IBridgehub.proveL1ToL2TransactionStatus.selector,
                chainId,
                txHash,
                l2BatchNumber,
                l2MessageIndex,
                l2TxNumberInBatch,
                merkleProof,
                TxStatus.Failure
            ),
            abi.encode(true)
        );

        vm.expectRevert("ShB n funds");
        sharedBridge.claimFailedDeposit({
            _chainId: chainId,
            _depositSender: alice,
            _l1Token: ETH_TOKEN_ADDRESS,
            _amount: amount,
            _l2TxHash: txHash,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _merkleProof: merkleProof
        });
    }

    function test_finalizeWithdrawal_chainBalance() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );

        bytes memory message = abi.encodePacked(IMailbox.finalizeEthWithdrawal.selector, alice, amount);
        L2Message memory l2ToL1Message =
            L2Message({txNumberInBatch: l2TxNumberInBatch, sender: L2_BASE_TOKEN_SYSTEM_CONTRACT_ADDR, data: message});

        vm.mockCall(
            bridgehubAddress,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(
                IBridgehub.proveL2MessageInclusion.selector,
                chainId,
                l2BatchNumber,
                l2MessageIndex,
                l2ToL1Message,
                merkleProof
            ),
            abi.encode(true)
        );

        vm.expectRevert("ShB not enough funds 2");

        sharedBridge.finalizeWithdrawal({
            _chainId: chainId,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _message: message,
            _merkleProof: merkleProof
        });
    }

    function test_checkWithdrawal_wrongProof() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );

        bytes memory message = abi.encodePacked(IMailbox.finalizeEthWithdrawal.selector, alice, amount);
        L2Message memory l2ToL1Message =
            L2Message({txNumberInBatch: l2TxNumberInBatch, sender: L2_BASE_TOKEN_SYSTEM_CONTRACT_ADDR, data: message});

        vm.mockCall(
            bridgehubAddress,
            // solhint-disable-next-line func-named-parameters
            abi.encodeWithSelector(
                IBridgehub.proveL2MessageInclusion.selector,
                chainId,
                l2BatchNumber,
                l2MessageIndex,
                l2ToL1Message,
                merkleProof
            ),
            abi.encode(false)
        );

        vm.expectRevert("ShB withd w proof");

        sharedBridge.finalizeWithdrawal({
            _chainId: chainId,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _message: message,
            _merkleProof: merkleProof
        });
    }

    function test_parseL2WithdrawalMessage_WrongMsgLength() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );

        bytes memory message = abi.encodePacked(IMailbox.finalizeEthWithdrawal.selector);

        vm.expectRevert("ShB wrong msg len");
        sharedBridge.finalizeWithdrawal({
            _chainId: chainId,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _message: message,
            _merkleProof: merkleProof
        });
    }

    function test_parseL2WithdrawalMessage_WrongMsgLength2() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress,
            abi.encodeWithSelector(IBridgehub.baseToken.selector, alice, amount),
            abi.encode(ETH_TOKEN_ADDRESS)
        );

        bytes memory message = abi.encodePacked(IL1ERC20Bridge.finalizeWithdrawal.selector, alice, amount);
        // should have more data here

        vm.expectRevert("ShB wrong msg len 2");

        sharedBridge.finalizeWithdrawal({
            _chainId: eraChainId,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _message: message,
            _merkleProof: merkleProof
        });
    }

    function test_parseL2WithdrawalMessage_WrongSelector() public {
        vm.deal(address(sharedBridge), amount);

        vm.mockCall(
            bridgehubAddress, abi.encodeWithSelector(IBridgehub.baseToken.selector), abi.encode(ETH_TOKEN_ADDRESS)
        );

        // notice that the selector is wrong
        bytes memory message = abi.encodePacked(IMailbox.proveL2LogInclusion.selector, alice, amount);

        vm.expectRevert("ShB Incorrect message function selector");
        sharedBridge.finalizeWithdrawal({
            _chainId: eraChainId,
            _l2BatchNumber: l2BatchNumber,
            _l2MessageIndex: l2MessageIndex,
            _l2TxNumberInBatch: l2TxNumberInBatch,
            _message: message,
            _merkleProof: merkleProof
        });
    }
}
