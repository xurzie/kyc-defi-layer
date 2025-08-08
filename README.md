# KYC DeFi Layer

A smart contract that implements a KYC layer for interacting with DeFi protocols.  
Supports two KYC levels:
- **Basic** — daily deposit limit of 1000 tokens
- **Advanced** — no limit

## 📌 Amoy Network Addresses
- **KYCDeFiLayer**: `0x47F78562F6DB9229bA922A590353Eb520FBEF85d`
- **StableToken**: `0x546187512140956d94E61f15Fc3e3248F5430c85`
- **UniversalVerifier**: `0xfcc86A79fCb057A8e55C6B853dff9479C3cf607c`
- **Basic KYC requestId**: `1755142413`
- **Advanced KYC requestId**: `1755198332`

## 🚀 Features
- `deposit(uint256)` — deposits tokens after successful KYC verification.
- `withdraw(uint256)` — withdraws tokens after successful KYC verification.
- `callDeFi(address target, bytes data)` — allows interacting with any DeFi protocol via the KYC layer.

## 🧪 Local Testing
```bash
forge test
```
All tests use `MockVerifier` and `MockDeFi` to emulate the UniversalVerifier and a DeFi protocol.

## 📦 Deployment to Amoy
```bash
forge script script/KYCDeFiLayer.s.sol:DeployKYCDeFiLayer \
  --rpc-url https://rpc-amoy.polygon.technology \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

## 🔍 Example Transactions on Amoy

### 1. Approve StableToken
```bash
cast send 0x546187512140956d94E61f15Fc3e3248F5430c85 \
  "approve(address,uint256)" 0x47F78562F6DB9229bA922A590353Eb520FBEF85d 1000000000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology \
  --private-key <PRIVATE_KEY>
```

### 2. Deposit Tokens
```bash
cast send 0x47F78562F6DB9229bA922A590353Eb520FBEF85d \
  "deposit(uint256)" 1000000000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology \
  --private-key <PRIVATE_KEY>
```

## 📄 License
MIT
