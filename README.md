# Algorithmic Stable Vault

An institutional-grade implementation of a collateralized stablecoin system. This repository demonstrates the core mechanics behind protocols like MakerDAO, focusing on the relationship between volatile collateral and synthetic stability.

## Core Mechanics
* **Vault Management**: Users deposit ETH to open a vault.
* **Minting**: Stablecoins (STBL) are minted against the value of the deposited ETH.
* **Collateralization Ratio**: A 150% safety margin is enforced. If the value of ETH drops, the vault becomes eligible for liquidation.
* **Liquidations**: Third-party actors can repay a vault's debt to receive the collateral at a discount.



## Tech Stack
* **Solidity ^0.8.20**: Smart contract logic.
* **Chainlink Price Feeds**: Real-time ETH/USD valuation.
* **OpenZeppelin**: Secure ERC20 and Access Control standards.

## Deployment
1. Set the Chainlink Oracle address for your specific network (e.g., Sepolia).
2. Deploy `Stablecoin.sol`.
3. Deploy `VaultEngine.sol` and transfer stablecoin ownership to the engine.
