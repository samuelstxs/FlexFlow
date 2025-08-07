# FlexFlow

A dynamic liquidity pool protocol built on Stacks blockchain that enables automated market making with flexible fee structures, multi-hop routing, and robust security features.

## Overview

FlexFlow is a decentralized exchange (DEX) protocol that allows users to create liquidity pools, provide liquidity, and trade tokens through an automated market maker (AMM) system. The protocol emphasizes security, flexibility, and user control over traditional AMM designs, now featuring intelligent multi-hop routing for optimal token swaps.

## Features

- **Dynamic Liquidity Pools**: Create custom token pairs with configurable fee structures
- **Multi-Hop Routing**: Intelligent pathfinding for indirect token swaps through multiple pools
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
- **Maximum Hops**: 3 pools per multi-hop route

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
- `swap`: Exchange tokens through direct pairs
- `multi-hop-swap`: Execute token swaps through multiple pools
- `calculate-swap-output`: Preview trade outcomes before execution
- `calculate-multi-hop-output`: Preview multi-hop trade outcomes
- `find-optimal-route`: Discover best path for token pairs

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

;; Perform a direct token swap
(contract-call? .flexflow swap 
  u1 
  'SP1ABC...TOKEN-A 
  u100000 
  u95000)

;; Execute multi-hop swap (A -> B -> C)
(contract-call? .flexflow multi-hop-swap 
  (list u1 u2)
  'SP1ABC...TOKEN-A 
  'SP3GHI...TOKEN-C
  u100000 
  u90000)

;; Find optimal route between tokens
(contract-call? .flexflow find-optimal-route 
  'SP1ABC...TOKEN-A 
  'SP3GHI...TOKEN-C)
```

## Multi-Hop Routing

FlexFlow's multi-hop routing system automatically finds the most efficient path for token swaps when direct pairs don't exist. Key features include:

- **Intelligent Pathfinding**: Automatically discovers optimal routes up to 3 hops
- **Gas Optimization**: Minimizes transaction costs while maximizing output
- **Slippage Protection**: End-to-end slippage control across the entire route
- **Route Validation**: Ensures all intermediate pools have sufficient liquidity

## Security Considerations

- All user inputs are validated to prevent common vulnerabilities
- Emergency shutdown functionality for crisis management
- Slippage protection on all trades and liquidity operations
- Owner controls are time-locked and transparent
- Minimum liquidity requirements prevent manipulation
- Multi-hop routes are validated for sufficient liquidity at each step

## Fee Structure

- **Trading Fee**: 0.3% (configurable per pool)
- **Protocol Fee**: 0.05% (goes to protocol treasury)
- **Maximum Fee**: 3% (hardcoded limit)
- **Multi-Hop Fees**: Cumulative fees across all pools in route

## Governance

The protocol includes basic governance features:
- Owner can adjust pool fees within limits
- Emergency shutdown capabilities
- Pool activation/deactivation controls
- Ownership transfer mechanism

## Roadmap

### Phase 1 - Core Infrastructure ✅
- **Dynamic Liquidity Pools**: Create custom token pairs with configurable fee structures ✅
- **Automated Market Making**: Constant product formula for price discovery ✅
- **Multi-Hop Routing**: Implement pathfinding for indirect token swaps through multiple pools ✅

### Phase 2 - Tokenomics & Incentives
- **Governance Token**: Launch FLEX token with voting rights on protocol parameters
- **Yield Farming**: Add liquidity mining rewards and staking mechanisms

### Phase 3 - Advanced Features
- **Flash Loans**: Enable uncollateralized borrowing for arbitrage opportunities
- **Price Oracles**: Integration with external price feeds for better accuracy
- **Concentrated Liquidity**: Allow liquidity providers to specify price ranges

### Phase 4 - Ecosystem Expansion
- **Cross-Chain Bridges**: Enable token transfers between Stacks and other blockchains
- **Automated Strategies**: Smart contract-based portfolio rebalancing
- **NFT Integration**: Support for NFT-backed liquidity and fractional ownership

### Phase 5 - Analytics & Tools
- **Analytics Dashboard**: Real-time metrics, volume tracking, and performance analytics

## Testing

Run the test suite with:
```bash
clarinet test
```

Tests cover:
- Pool creation and management
- Liquidity operations
- Trading mechanics (direct and multi-hop)
- Security functions
- Error handling
- Multi-hop routing optimization

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