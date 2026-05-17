// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Script from Forge standard library to enable deployment scripting
import {Script} from "forge-std/Script.sol";
// Import the FundMe contract so it can be deployed in this script
import {FundMe} from "../src/FundMe.sol";

import {HelperConfig} from "./HelperConfig.s.sol";

// This contract handles the deployment of the FundMe contract
contract DeployFundMe is Script {
    // The `run` function is automatically called when executing this script
    function run() external returns (FundMe) {

        // Anything before startBroadcast -> Not a "real" tx
        HelperConfig helperConfig = new HelperConfig();

        // Since we are returning a struct, if it has multiple keys, then we must wrap it into ()
        // But since we only have one, we can omit the ()
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // Begin broadcasting transactions to the blockchain
        // All contract creation or state-changing operations between startBroadcast()
        // and stopBroadcast() are sent to the network
        // Anything after startBroadcast -> Real tx!
        vm.startBroadcast();

        // Deploy a new instance of the FundMe contract
        FundMe fundMe = new FundMe(ethUsdPriceFeed);

        // Stop broadcasting transactions
        // After this point, any further contract interactions are not sent to the blockchain
        vm.stopBroadcast();

        return fundMe;
    }
}
