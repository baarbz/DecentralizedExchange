# Decentralized Exchange (DEX) on Stacks

This project implements a simple Decentralized Exchange (DEX) using Clarity smart contracts on the Stacks blockchain. The DEX allows users to create liquidity pools, add/remove liquidity, and swap tokens.

## Features

- Create liquidity pools for token pairs
- Add liquidity to existing pools
- Remove liquidity from pools
- Swap tokens using an Automated Market Maker (AMM) model
- Simple fee mechanism (0.3% fee on swaps)

## Prerequisites

Before you begin, ensure you have met the following requirements:

- [Clarinet](https://github.com/hirosystems/clarinet) installed for local development and testing
- Basic understanding of Clarity smart contracts and the Stacks blockchain
- Familiarity with TypeScript for writing and running tests

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/dex-stacks.git
   cd dex-stacks
   ```

2. Install Clarinet if you haven't already:
   ```
   curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64-glibc.tar.gz | tar xz
   sudo mv clarinet /usr/local/bin
   ```

## Usage

### Deploying Contracts

To deploy the contracts to a local Clarinet console:

1. Start the Clarinet console:
   ```
   clarinet console
   ```

2. In the Clarinet console, you can interact with the deployed contracts. For example:
   ```
   (contract-call? .dex create-pool .token-x .token-y u1000000 u1000000)
   ```

### Interacting with the DEX

Here are some example interactions with the DEX:

1. Create a liquidity pool:
   ```
   (contract-call? .dex create-pool .token-x .token-y u1000000 u1000000)
   ```

2. Add liquidity to an existing pool:
   ```
   (contract-call? .dex add-liquidity .token-x .token-y u500000 u490000)
   ```

3. Swap tokens:
   ```
   (contract-call? .dex swap-x-for-y .token-x .token-y u100000 u90000)
   ```

4. Remove liquidity:
   ```
   (contract-call? .dex remove-liquidity .token-x .token-y u100000 u95000 u95000)
   ```

## Testing

To run the tests for this project:

1. Ensure you're in the project directory
2. Run the Clarinet test command:
   ```
   clarinet test
   ```

This will execute the tests defined in the `tests/dex_test.ts` file.

## Contributing

Contributions to this project are welcome. Please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Disclaimer

This DEX implementation is for educational purposes only and has not been audited. Use at your own risk in any production environment.

## Contact

If you have any questions or feedback, please open an issue in this repository.
