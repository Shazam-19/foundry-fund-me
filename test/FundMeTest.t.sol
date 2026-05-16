// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Forge test utilities and console logging
import {Test, console} from "forge-std/Test.sol";

// Import the FundMe contract to be tested
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    // Declare a FundMe instance to interact with during tests
    FundMe fundMe;

    // This function runs before each test to set up the environment
    function setUp() external {
        // Deploy a new FundMe contract instance
        // Note: The owner of FundMe will be this test contract
        fundMe = new FundMe();
    }

    // Test that the minimum USD required in FundMe is 5 USD (scaled by 1e18 for decimals)
    function testMinimumUSDIsFive() public view {
        // Assert that the MINIMUM_USD constant in FundMe equals 5e18
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Test that the owner of FundMe is correctly set to the deployer (this test contract)
    function testOwnerIsMsgSender() public {
        // Verify that the owner of FundMe is the current contract (FundMeTest)
        // 'address(this)' refers to the current contract, not the external caller 'msg.sender'
        assertEq(fundMe.i_owner(), address(this));
    }
}
