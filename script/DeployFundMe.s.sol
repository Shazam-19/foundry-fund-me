// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Script from Forge standard library to enable deployment scripting
import {Script} from "forge-std/Script.sol";
// Import the FundMe contract so it can be deployed in this script
import {FundMe} from "../src/FundMe.sol";
// Import the helper contract used to manage network-specific configuration
import {HelperConfig} from "./HelperConfig.s.sol";

// This contract handles the deployment of the FundMe contract
contract DeployFundMe is Script {
    // The `run` function is automatically called when executing this script
    function run() external returns (FundMe) {
        // Create an instance of the HelperConfig contract
        // This contract stores configuration values for different networks
        HelperConfig helperConfig = new HelperConfig(); // This isn't stored on the blockchain

        // Retrieve the active ETH/USD price feed address
        // The returned value depends on the currently selected network
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // This isn't stored on the blockchain

        // The above line retrieve the ETH/USD price feed address from the active network configuration.
        // Since the function returns a single value, we can assign it directly without having to write it like
        // (address ethUsdPriceFeed)

        // Start broadcasting transactions to the blockchain
        // Any state-changing operations after this point become real transactions
        vm.startBroadcast();

        // Deploy the FundMe contract using the price feed address
        FundMe fundMe = new FundMe(ethUsdPriceFeed);

        // Stop broadcasting transactions
        // Any code after this point will not be sent as a blockchain transaction
        vm.stopBroadcast();

        // Return the deployed contract instance
        return fundMe;
    }
}
/*
Overall Flow of the Script
1. Load configuration
2. Get price feed address
3. Start blockchain broadcasting
4. Deploy FundMe contract
5. Stop broadcasting
6. Return deployed contract

Example Deployment Command:
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $SEPOLIA_RPC_URL --broadcast
*/