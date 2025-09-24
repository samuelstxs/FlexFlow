# FlexFlow

A dynamic liquidity pool protocol built on Stacks blockchain that enables automated market making with flexible fee structures, multi-hop routing, robust security features, and decentralized governance through the FLEX token.

## Overview

FlexFlow is a decentralized exchange (DEX) protocol that allows users to create liquidity pools, provide liquidity, and trade tokens through an automated market maker (AMM) system. The protocol emphasizes security, flexibility, and community governance through the native FLEX token, featuring intelligent multi-hop routing for optimal token swaps.

## Features

- **Dynamic Liquidity Pools**: Create custom token pairs with configurable fee structures
- **Multi-Hop Routing**: Intelligent pathfinding for indirect token swaps through multiple pools
- **Automated Market Making**: Constant product formula for price discovery
- **Flexible Fee System**: Customizable trading fees per pool (default 0.3%)
- **FLEX Governance Token**: Decentralized protocol governance with voting rights
- **Liquidity Mining**: Earn FLEX tokens by providing liquidity and creating pools
- **Emergency Controls**: Built-in safety mechanisms for protocol governance
- **Slippage Protection**: User-defined minimum output amounts for trades

## FLEX Governance Token

FlexFlow introduces the FLEX token, a governance token that enables decentralized decision-making for protocol parameters:

### Token Specifications
- **Total Supply**: 100,000,000 FLEX
- **Decimals**: 6
- **Symbol**: FLEX
- **Name**: FlexFlow Governance Token

### Governance Features
- **Proposal Creation**: FLEX holders can create governance proposals (minimum 1,000 FLEX required)
- **Voting Rights**: Vote on protocol changes with FLEX tokens
- **Quorum Requirements**: 5% of total supply needed for proposal execution
- **Voting Period**: 1 week per proposal
- **Proposal Types**: 
  - Pool fee adjustments
  - Protocol fee changes
  - Additional governance parameters

### Earning FLEX Tokens
- **Pool Creation**: Receive 1,000 FLEX for creating new liquidity pools
- **Liquidity Mining**: Earn FLEX proportional to liquidity provided (0.1% of added liquidity)
- **Trading Activity**: Future rewards for active traders (roadmap item)

## Technical Specifications

- **Language**: Clarity smart contract
- **Blockchain**: Stacks
- **Fee Structure**: 0.3% default trading fee, 0.05% protocol fee
- **Minimum Liquidity**: 1,000 units to prevent division by zero attacks
- **Maximum Fee**: 3% cap on trading fees
- **Maximum Hops**: 3 pools per multi-hop route
- **Governance**: FLEX token-based voting system

## Core Functions

### Pool Management
- `create-pool`: Initialize new token pair pools
- `get-pool-info`: Query pool reserves and metadata
- `toggle-pool-status`: Enable/disable trading for specific pools

### Liquidity Operations
- `add-liquidity`: Provide tokens to earn trading fees and FLEX rewards
- `remove-liquidity`: Withdraw tokens and accumulated fees
- `get-user-balance`: Check liquidity provider balance

### Trading
- `swap`: Exchange tokens through direct pairs
- `multi-hop-swap`: Execute token swaps through multiple pools
- `calculate-swap-output`: Preview trade outcomes before execution
- `calculate-multi-hop-output`: Preview multi-hop trade outcomes
- `find-optimal-route`: Discover best path for token pairs

### FLEX Token Functions
- `launch-flex-token`: Initialize the FLEX token (admin only)
- `transfer`: Transfer FLEX tokens between users
- `mint`: Create new FLEX tokens (admin only)
- `burn`: Destroy FLEX tokens
- `get-balance`: Check FLEX token balance
- `get-total-supply`: Query total FLEX supply

### Governance Functions
- `create-proposal`: Submit governance proposals (requires 1,000 FLEX minimum)
- `vote`: Cast votes on active proposals
- `execute-proposal`: Execute passed proposals after voting period
- `get-proposal`: Query proposal details
- `get-user-vote`: Check user's vote on specific proposals

### Security Features
- `set-emergency-shutdown`: Pause all operations if needed
- `transfer-ownership`: Update contract administrator
- `set-pool-fee`: Adjust trading fees per pool (governance or admin)

## Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Clarinet development environment
- Basic understanding of AMM mechanics
- FLEX tokens for governance participation

### Installation

1. Clone the repository
2. Install Clarinet: `npm install -g @stacks/clarinet`
3. Run tests: `clarinet test`
4. Deploy: `clarinet deploy`

### Usage Example

```clarity
;; Launch FLEX governance token (admin only)
(contract-call? .flexflow launch-flex-token)

;; Create a new liquidity pool (earn 1,000 FLEX)
(contract-call? .flexflow create-pool 
  'SP1ABC...TOKEN-A 
  'SP2DEF...TOKEN-B 
  u1000000 
  u2000000)

;; Add liquidity to existing pool (earn FLEX rewards)
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

;; Create a governance proposal (requires 1,000+ FLEX)
(contract-call? .flexflow create-proposal 
  "Reduce Pool 1 Fee"
  "Proposal to reduce trading fee from 0.3% to 0.25%"
  "fee-change"
  u25  ;; 0.25%
  u1)  ;; Pool ID

;; Vote on proposal
(contract-call? .flexflow vote 
  u1      ;; Proposal ID
  true    ;; Support
  u5000000000)  ;; Vote with 5,000 FLEX

;; Execute passed proposal
(contract-call? .flexflow execute-proposal u1)
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
- Governance proposals require quorum and voting periods
- FLEX token voting power prevents sybil attacks

## Fee Structure

- **Trading Fee**: 0.3% (configurable per pool via governance)
- **Protocol Fee**: 0.05% (adjustable via governance)
- **Maximum Fee**: 3% (hardcoded limit)
- **Multi-Hop Fees**: Cumulative fees across all pools in route
- **Governance Participation**: Free (gas costs only)

## Governance Process

1. **Proposal Creation**: Any user with 1,000+ FLEX can create proposals
2. **Voting Period**: 1 week for community to vote with FLEX tokens
3. **Quorum Check**: Minimum 5% of total FLEX supply must participate
4. **Execution**: Passed proposals are executed automatically
5. **Types Supported**: Pool fee changes, protocol fee adjustments

## Roadmap

### Phase 1 - Core Infrastructure ✅
- **Dynamic Liquidity Pools**: Create custom token pairs with configurable fee structures ✅
- **Automated Market Making**: Constant product formula for price discovery ✅
- **Multi-Hop Routing**: Implement pathfinding for indirect token swaps through multiple pools ✅

### Phase 2 - Tokenomics & Incentives ✅
- **Governance Token**: Launch FLEX token with voting rights on protocol parameters ✅
- **Liquidity Mining**: Add liquidity mining rewards for pool participants ✅

### Phase 3 - Advanced Features
- **Flash Loans**: Enable uncollateralized borrowing for arbitrage opportunities
- **Price Oracles**: Integration with external price feeds for better accuracy
- **Concentrated Liquidity**: Allow liquidity providers to specify price ranges
- **Advanced Governance**: Time-locked proposals, delegation, and multi-signature execution

### Phase 4 - Ecosystem Expansion
- **Cross-Chain Bridges**: Enable token transfers between Stacks and other blockchains
- **Automated Strategies**: Smart contract-based portfolio rebalancing
- **NFT Integration**: Support for NFT-backed liquidity and fractional ownership
- **Yield Farming**: Additional reward mechanisms and liquidity incentives

### Phase 5 - Analytics & Tools
- **Analytics Dashboard**: Real-time metrics, volume tracking, and performance analytics
- **Governance Dashboard**: Proposal tracking, voting history, and delegation tools
- **Mobile App**: Native mobile application for trading and governance

## Testing

Run the test suite with:
```bash
clarinet test
```

Tests cover:
- Pool creation and management
- Liquidity operations
- Trading mechanics (direct and multi-hop)
- FLEX token functionality
- Governance proposal lifecycle
- Security functions
- Error handling
- Multi-hop routing optimization

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## FLEX Token Economics

- **Initial Distribution**: Contract owner receives full supply at launch
- **Inflation**: Controlled through governance (minting requires admin approval)
- **Deflation**: Users can burn their own tokens
- **Utility**: Governance voting, proposal creation, future fee discounts
- **Rewards**: Earned through liquidity provision and pool creation

## Support

For support and questions:
- Create an issue in the GitHub repository
- Join our Discord community
- Review the documentation
- Participate in governance discussions

---

**Disclaimer**: This software is experimental. Use at your own risk. Always audit smart contracts before deploying to mainnet. FLEX tokens represent governance rights and do not guarantee financial returns.