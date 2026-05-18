// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Purpose of this contract:
// 1. Store network-specific configuration values
// 2. Provide the correct price feed address based on the current blockchain network
// 3. Support local testing by using mock contracts on Anvil

// Import Script from Forge standard library to enable deployment scripting
import {Script} from "forge-std/Script.sol";

// Import the mock Chainlink price feed contract used for local testing
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network

    // Struct used to store network configuration values
    struct NetworkConfig {
        address priceFeed;
    }

    // Stores the active network configuration
    // This value is set during contract deployment
    NetworkConfig public activeNetworkConfig;

    constructor() {
        // Sepolia Testnet Chain ID
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig(); // Load the Sepolia network configuration

            // Ethereum Mainnet Chain ID
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig(); // Load the Ethereum Mainnet configuration

            // Default to local Anvil configuration
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    // Returns the ETH/USD price feed configuration for Sepolia
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // Chainlink ETH/USD price feed address on Sepolia
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });

        return sepoliaConfig;
    }

    // Returns the ETH/USD price feed configuration for Ethereum Mainnet
    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // Chainlink ETH/USD price feed address on Mainnet
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });

        return ethConfig;
    }

    // Returns the configuration for the local Anvil network
    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        // Deploy a mock price feed contract locally
        // This simulates the behavior of a real Chainlink price feed

        vm.startBroadcast();

        // Create a mock ETH/USD price feed
        // Parameters:
        // 8      -> Number of decimals used by the ETH price feed
        // 2000e8 -> Initial ETH price = 2000.00000000
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(8, 2000e8);

        vm.stopBroadcast();

        // Store the mock price feed address inside the network configuration struct
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed:address(mockPriceFeed)
        });

        // Return the local Anvil configuration
        return anvilConfig;
    }
}
