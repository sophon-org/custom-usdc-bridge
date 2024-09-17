## Custom bridge for Native USDC


Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build -C contracts/custom-usdc-bridge/

# zkSync build
$ forge build -C contracts/custom-usdc-bridge/ --zksync
```

### Scripts

```shell
# Deploy L1 Shared Bridge
$ source .env && forge script ./contracts/custom-usdc-bridge/script/DeployL1SharedBridge.sol --rpc-url sepoliaTestnet --private-key $PRIVATE_KEY --verify --broadcast

# Deploy L2 Shared Bridge
$ source .env && forge script ./contracts/custom-usdc-bridge/script/DeployL2SharedBridge.s.sol --rpc-url sophonTestnet --private-key $PRIVATE_KEY --zksync --broadcast --verify --slow

# Initialise L1 Shared Bridge
$ source .env && forge script ./contracts/custom-usdc-bridge/script/InitialiseL1Bridge.s.sol --rpc-url sepoliaTestnet --private-key $PRIVATE_KEY --broadcast

# Bridge from Sophon to Ethereum (L1 -> L2)
$ source .env && forge script ./contracts/custom-usdc-bridge/script/BridgeScript.s.sol --rpc-url sepoliaTestnet --private-key $PRIVATE_KEY --ffi --broadcast

# Withdraw from Sophon to Ethereum (L2 -> L1)
$ source .env && forge script ./contracts/custom-usdc-bridge/script/Withdraw.s.sol --rpc-url sophonTestnet --private-key $PRIVATE_KEY --zksync --slow -vvvv --broadcast

# Finalise withdrawal on Ethereum
$ source .env && export L2_WITHDRAWAL_HASH="YOUR_TX_HASH" && forge script ./contracts/custom-usdc-bridge/script/FinalizeWithdrawal.s.sol --rpc-url sepoliaTestnet --private-key $PRIVATE_KEY --ffi --broadcast
```

### Test

```shell
$ forge test -C contracts/custom-usdc-bridge/
```

### Format

```shell
$ forge fmt contracts/custom-usdc-bridge/
```

### Gas Snapshots

```shell
$ forge snapshot
```