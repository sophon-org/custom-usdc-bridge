// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {DeploymentUtils} from "../utils/DeploymentUtils.sol";

interface MasterMinter {
    function configureController(address controller, address bridge) external;
    function getWorker(address controller) external view returns (address);
    function configureMinter(uint256 allowance) external;
}

interface USDC {
    function isMinter(address account) external view returns (bool);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract TestScript is Script, DeploymentUtils {
    function setUp() public {}

    function run() public {
        MasterMinter masterMinter = MasterMinter(getDeployedContract("MasterMinter"));
        console.log("GetWorker", masterMinter.getWorker(0x902767c9e11188C985eB3494ee469E53f1b6de53));

        // vm.prank(0x902767c9e11188C985eB3494ee469E53f1b6de53);
        // masterMinter.configureController(0x902767c9e11188C985eB3494ee469E53f1b6de53, getDeployedContract("L2USDCBridge"));
        vm.prank(0x902767c9e11188C985eB3494ee469E53f1b6de53);
        masterMinter.configureMinter(5000000000000000);

        USDC token = USDC(getDeployedContract("USDC"));
        vm.assertTrue(token.isMinter(getDeployedContract("L2USDCBridge")), "L2USDCBridge is not a minter");
    }
}

// pragma solidity ^0.8.13;

// import {Script, console} from "forge-std/Script.sol";
// import {DeploymentUtils} from "../utils/DeploymentUtils.sol";
// // import {GnosisSafe, Enum} from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
// import {TestExt} from "forge-zksync-std/TestExt.sol";

// interface GnosisSafe {
//     function execTransaction(
//         address to,
//         uint256 value,
//         bytes calldata data,
//         // Enum.Operation operation,
//         uint8 operation,
//         uint256 safeTxGas,
//         uint256 baseGas,
//         uint256 gasPrice,
//         address gasToken,
//         address payable refundReceiver,
//         bytes calldata signatures
//     ) external returns (bool success);
// }
// interface MasterMinter {
//     function configureController(address controller, address bridge) external;
//     function configureMinter(uint256 allowance) external;
// }

// interface USDC {
//     function isMinter(address account) external view returns (bool);
// }

// contract MultisigScript is Script, DeploymentUtils, TestExt {
//     address public safeAddress = 0x902767c9e11188C985eB3494ee469E53f1b6de53;

//     function setUp() public {}

//     function run() public {
//         vm.startBroadcast();

//         GnosisSafe safe = GnosisSafe(payable(safeAddress));
//         MasterMinter masterMinter = MasterMinter(getDeployedContract("MasterMinter"));

//         address controller = 0x902767c9e11188C985eB3494ee469E53f1b6de53;
//         address bridge = getDeployedContract("L2USDCBridge");
//         uint256 minterAllowance = 5000000000000000;
//         address paymaster = vm.envAddress("PAYMASTER_ADDRESS");

//         // Step 1: Encode transactions
//         bytes memory configureControllerData = abi.encodeWithSelector(
//             masterMinter.configureController.selector,
//             controller,
//             bridge
//         );

//         bytes memory configureMinterData = abi.encodeWithSelector(
//             masterMinter.configureMinter.selector,
//             minterAllowance
//         );

//         // Encode paymaster input
//         bytes memory paymaster_encoded_input = abi.encodeWithSelector(
//             bytes4(keccak256("general(bytes)")),
//             bytes("0x")
//         );

//         // Step 2: Submit `configureController` transaction to the Safe
//         vmExt.zkUsePaymaster(paymaster, paymaster_encoded_input);
//         sendTransaction(
//             safe,
//             address(masterMinter),
//             0, // No ETH value
//             configureControllerData
//         );

//         // Step 3: Submit `configureMinter` transaction to the Safe
//         vmExt.zkUsePaymaster(paymaster, paymaster_encoded_input);
//         sendTransaction(
//             safe,
//             address(masterMinter),
//             0, // No ETH value
//             configureMinterData
//         );

//         vm.stopBroadcast();

//         // Step 4: Verify L2USDCBridge is a minter
//         USDC token = USDC(getDeployedContract("USDC"));
//         require(token.isMinter(bridge), "L2USDCBridge is not a minter");
//         console.log("L2USDCBridge successfully configured as a minter.");
//     }

//     function sendTransaction(
//         GnosisSafe safe,
//         address to,
//         uint256 value,
//         bytes memory data
//     ) internal {
//         uint256 safeTxGas = 1000000;
//         uint256 baseGas = 0;
//         uint256 gasPrice = 0;
//         address gasToken = address(0);
//         address refundReceiver = address(0);
//         bytes memory signatures = ""; // Collect actual signatures off-chain or prepare them

//         // Execute the transaction
//         bool success = safe.execTransaction(
//             to,
//             value,
//             data,
//             // Enum.Operation.Call,
//             1,
//             safeTxGas,
//             baseGas,
//             gasPrice,
//             gasToken,
//             payable(refundReceiver),
//             signatures
//         );

//         require(success, "Safe execution failed");
//     }
// }
