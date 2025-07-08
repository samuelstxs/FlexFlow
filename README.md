# FlexFlow

A dynamic liquidity pool protocol built on Stacks blockchain that enables automated market making with flexible fee structures and robust security features.

## Overview

FlexFlow is a decentralized exchange (DEX) protocol that allows users to create liquidity pools, provide liquidity, and trade tokens through an automated market maker (AMM) system. The protocol emphasizes security, flexibility, and user control over traditional AMM designs.

## Features

- **Dynamic Liquidity Pools**: Create custom token pairs with configurable fee structures
- **Automated Market Making**: Constant product formula for price discovery
- **Flexible Fee System**: Customizable trading fees per pool (default 0.3%)
- **Emergency Controls**: Built-in safety mechanisms for protocol governance
- **Slippage Protection**: User-defined minimum output amounts for trades
- **Liquidity Mining**: Earn fees proportional to liquidity provision

## Technical Specifications

- **Language**: Clarity smart contract
- **Blockchain**: Stacks
- **Fee Structure**: 0.3% default trading fee, 0.05% protocol fee
- **Minimum Liquidity**: 1,000 units to prevent division by zero attacks
- **Maximum Fee**: 3% cap on trading fees

## Core Functions

### Pool Management
- `create-pool`: Initialize new token pair pools
- `get-pool-info`: Query pool reserves and metadata
- `toggle-pool-status`: Enable/disable trading for specific pools

### Liquidity Operations
- `add-liquidity`: Provide tokens to earn trading fees
- `remove-liquidity`: Withdraw tokens and accumulated fees
- `get-user-balance`: Check liquidity provider balance

### Trading
- `swap`: Exchange tokens through the AMM
- `calculate-swap-output`: Preview trade outcomes before execution

### Security Features
- `set-emergency-shutdown`: Pause all operations if needed
- `transfer-ownership`: Update contract administrator
- `set-pool-fee`: Adjust trading fees per pool

## Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Clarinet development environment
- Basic understanding of AMM mechanics

### Installation

1. Clone the repository
2. Install Clarinet: `npm install -g @stacks/clarinet`
3. Run tests: `clarinet test`
4. Deploy: `clarinet deploy`

### Usage Example

```clarity
;; Create a new liquidity pool
(contract-call? .flexflow create-pool 
  'SP1ABC...TOKEN-A 
  'SP2DEF...TOKEN-B 
  u1000000 
  u2000000)

;; Add liquidity to existing pool
(contract-call? .flexflow add-liquidity 
  u1 
  u500000 
  u1000000 
  u100000)

;; Perform a token swap
(contract-call? .flexflow swap 
  u1 
  'SP1ABC...TOKEN-A 
  u100000 
  u95000)
```

## Security Considerations

- All user inputs are validated to prevent common vulnerabilities
- Emergency shutdown functionality for crisis management
- Slippage protection on all trades and liquidity operations
- Owner controls are time-locked and transparent
- Minimum liquidity requirements prevent manipulation

## Fee Structure

- **Trading Fee**: 0.3% (configurable per pool)
- **Protocol Fee**: 0.05% (goes to protocol treasury)
- **Maximum Fee**: 3% (hardcoded limit)

## Governance

The protocol includes basic governance features:
- Owner can adjust pool fees within limits
- Emergency shutdown capabilities
- Pool activation/deactivation controls
- Ownership transfer mechanism

## Testing

Run the test suite with:
```bash
clarinet test
```

Tests cover:
- Pool creation and management
- Liquidity operations
- Trading mechanics
- Security functions
- Error handling

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## Support

For support and questions:
- Create an issue in the GitHub repository
- Join our Discord community
- Review the documentation

---

**Disclaimer**: This software is experimental. Use at your own risk. Always audit smart contracts before deploying to mainnet.