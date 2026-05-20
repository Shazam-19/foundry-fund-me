// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Fund
// Withdraw

// Import Script from Forge standard library to enable interact scripting
import {Script, colsole} from "forge-std/Script.sol";

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        fundFundMe(mostRecentlyDeployed);
    }

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();

        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE};

        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }
}

contract WithdrawFundMe is Script {}

