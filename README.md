# Mayan-swiftX

Mayan-swiftX is a gasless custom swap order implementation built on top of the Mayan Swift protocol. This extension enables the following functionalities:

1. **Limit Orders**: Execute orders based on specified price targets.
2. **Conditional Orders**: Execute orders based on predefined conditions.
3. **Recurring Cross-Chain Swaps**: Facilitate automated swaps across different blockchains at regular intervals.

With Mayan-swiftX, users can enhance their trading strategies by leveraging these advanced order types, providing greater flexibility and control over their transactions.

## How It Works (Users)

![Order Flow](docs/mermaid-diagram-2025-07-09-002648.png)

1. A user signs a custom ERC20 order and sends it to the Searchbox API.
2. Anyone can call this API to retrieve the order or orders, validate them, and create them on Mayan Swift.
3. The executor is compensated, and the user receives the requested tokens.

⚠️ Note: The POST endpoint for submitting signed ERC20 orders is intentionally not publicly exposed, to prevent spam. Build an order with the API off-chain and execute it directly against the smart contract.


## How It Works (Developers)

1. A developer integrates the Searchbox API, takes the user's input parameters, and may specify one or more executors. They then build an order and call the `createAndPublish` function.
2. It is the responsibility of the specified executor to execute the order on Mayan Swift.

## Project Structure

The project is organized into the following main directories:

### Root Directory Structure
```
mayan-swiftX/
├── packages/
│   ├── api/            # API implementation and endpoints
│   └── contracts/      # Smart contracts and related utilities
└── node_modules/       # Project dependencies
```

### Key Directories
* **packages/api**: Contains all API endpoints and backend logic
  - API routes for order management
  - Implementation of gasless swap functionality
  - Integration with Mayan Swift protocol

* **packages/contracts**: Contains smart contract related code
  - Smart contract implementations
  - Contract interfaces
  - Contract utilities and helpers

## API Documentation

### 1. Get Conditional Order
Retrieve a conditional order based on specified parameters.

#### Example:
[https://github.com/searchboxai/mayan-swiftX/blob/main/packages/api/src/example/conditionalOrders.ts]

### 2. Get Gasless Conditional Tokens
Retrieve tokens eligible for gasless conditional orders on a specific chain.

#### Example:
```bash
curl https://mayan-swift-x.vercel.app/api/getGaslessCondTokens?chain=base
```

### 3. Get Gasless Limit Tokens
Retrieve tokens eligible for gasless limit orders on a specific chain.

#### Example:
```bash
curl https://mayan-swift-x.vercel.app/api/getGaslessLimitTokens?chain=base
```

### 4. Get Gasless Timed Tokens
Retrieve tokens eligible for gasless timed orders on a specific chain.

#### Example:
```bash
curl https://mayan-swift-x.vercel.app/api/getGaslessTimedTokens?chain=base
```

### 5. Get Instant Order
Retrieve an instant order based on parameters such as amount, tokens, chains, and destination address.

#### Example:
[https://github.com/searchboxai/mayan-swiftX/blob/main/packages/api/src/example/conditionalOrders.ts]

### 6. Get Integrated Chains
Retrieve a list of chains integrated with the system.

#### Example:
```bash
curl https://mayan-swift-x.vercel.app/api/getIntegratedChains
```

### 7. Check If a Chain Is Integrated
Check if a specific chain is integrated with the system.

#### Example:
```bash
curl https://mayan-swift-x.vercel.app/api/isIntegratedChain?chain=base
```

### 8. Execution


**Base Contract Address:** `0x5D9C504b3F02611912Af20ED39E60C539621E678`

**Example Executions:**  
- [🔗 Tx 1](https://explorer.mayan.finance/tx/SWIFT_0xe807b1deafa284cfa32d11dff09d1f1123d6c4627036aa12befb8160c52eadb6)
- [🔗 Tx 2](https://explorer.mayan.finance/tx/SWIFT_0x2779627cbc28d1806bbb9e6c5a68a8e03e228608e13da258bc167750f3af1b79)
- [🔗 Tx 3](https://explorer.mayan.finance/tx/SWIFT_0xb25fd0a649054995c5e468a6dc3356b2fbaa795de68b3f9349049440c2baa8e9)
- [🔗 Tx 4](https://explorer.mayan.finance/tx/SWIFT_0xc849751246bb2ad5a5f0f7c4c2dbe9da376406796b9dbd3e7c47ff6672ee13e8)
