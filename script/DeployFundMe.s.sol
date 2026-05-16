// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Script from Forge standard library to enable deployment scripting
import {Script} from "forge-std/Script.sol";
// Import the FundMe contract so it can be deployed in this script
import {FundMe} from "../src/FundMe.sol";

// This contract handles the deployment of the FundMe contract
contract DeployFundMe is Script {
    // The `run` function is automatically called when executing this script
    function run() external {
        // Begin broadcasting transactions to the blockchain
        // All contract creation or state-changing operations between startBroadcast()
        // and stopBroadcast() are sent to the network
        vm.startBroadcast();

        // Deploy a new instance of the FundMe contract
        new FundMe();

        // Stop broadcasting transactions
        // After this point, any further contract interactions are not sent to the blockchain
        vm.stopBroadcast();
    }
}
