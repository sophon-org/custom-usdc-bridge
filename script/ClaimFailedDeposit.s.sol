// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {L1USDCBridge} from "../src/L1USDCBridge.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface MasterMinter {
    function owner() external view returns (address);
    function configureMinter(uint256 minterId) external;
}

contract ClaimFailedDepositScript is Script, DeploymentUtils {
    L1USDCBridge public bridge;

    function setUp() public {}

    struct ClaimFailedDepositData {
        uint256 l1BatchNumber;
        uint256 l2MessageIndex;
        uint16 l2TxNumberInBlock;
        bytes message;
        address sender;
    }

    function claimFailedDepositParams() public returns (ClaimFailedDepositData memory, bytes32[] memory) {
        // grab all params except for proof (since it fails)
        string[] memory args = new string[](4);
        args[0] = "node";
        args[1] = "script/getWithdrawalParams";
        args[2] = "--hash";
        args[3] = vm.envString("L2_WITHDRAWAL_HASH");
        string memory result = string(vm.ffi(args));
        ClaimFailedDepositData memory data = abi.decode(vm.parseJson(result), (ClaimFailedDepositData));

        if (data.sender == address(0)) {
            revert(result);
        }

        // grab only proof
        args = new string[](5);
        args[0] = "node";
        args[1] = "script/getWithdrawalParams";
        args[2] = "--proof";
        args[3] = "--hash";
        args[4] = vm.envString("L2_WITHDRAWAL_HASH");
        result = string(vm.ffi(args));
        bytes32[] memory proof = abi.decode(vm.parseJson(result), (bytes32[]));

        return (data, proof);
    }

    function run() public {
        vm.startBroadcast();

        // function claimFailedDeposit(
        //     uint256 _chainId,
        //     address _depositSender,
        //     address _l1Token,
        //     uint256 _amount,
        //     bytes32 _l2TxHash,
        //     uint256 _l2BatchNumber,
        //     uint256 _l2MessageIndex,
        //     uint16 _l2TxNumberInBatch,
        //     bytes32[] calldata _merkleProof
        // ) external override {

        (ClaimFailedDepositData memory data, bytes32[] memory merkleProof) = claimFailedDepositParams();
        console.logBytes(data.message);
        // (,address depositSender, address l1Token, uint256 amount) = abi.decode(data.message, (bytes4, address, address, uint256));

        bytes memory data2 =
            hex"11a2ccc11c9ff39402b15e9a7c67ffd1a260d04d852f5dfebf4fdf7bf4014ea78c0a07259fbc4315cb10d94e00000000000000000000000000000000000000000000000000000000000f4240";
        // log length
        console.log("data2 length: %s", data2.length);
        (bytes4 signature, address addr1, address addr2, uint256 value) = decodeData(data2);
        console.logBytes4(signature);
        console.log("addr1: %s", addr1);
        console.log("addr2: %s", addr2);
        console.log("value: %s", value);
        // L1USDCBridge(getDeployedContract("L1USDCBridge")).claimFailedDeposit(
        //     vm.envUint("CHAIN_ID"),
        //     depositSender,
        //     l1Token,
        //     amount,
        //     vm.envBytes32("L2_WITHDRAWAL_HASH"),
        //     data.l1BatchNumber,
        //     data.l2MessageIndex,
        //     data.l2TxNumberInBlock,
        //     merkleProof
        // );

        // MasterMinter masterMinter = MasterMinter(0x910FCc44534A88394Aa92CeF0ef9b359c6CfF023);
        // console.log("Configuring MasterMinter allowance to infinity for USDC...");
        // // check owneship
        // if (masterMinter.owner() != msg.sender) {
        //     console.log("MasterMinter is not owned by this contract");
        //     return;
        // }
        // masterMinter.configureMinter(type(uint256).max); // allowance that the minter can mint

        vm.stopBroadcast();
    }

    // Function to decode the data
    function decodeData(bytes memory data)
        public
        pure
        returns (bytes4 signature, address addr1, address addr2, uint256 value)
    {
        require(data.length == 76, "Invalid data length");

        assembly {
            // The first 4 bytes are the function signature
            signature := mload(add(data, 0x20)) // Load the first 4 bytes

            // After the first 4 bytes, the next 20 bytes are the first address
            addr1 := mload(add(data, 0x24)) // Load the next 20 bytes

            // The next 20 bytes are the second address
            addr2 := mload(add(data, 0x30)) // Load the next 20 bytes

            // The last 32 bytes are the value
            value := mload(add(data, 0x4c)) // Load the last 32 bytes
        }
    }
}
