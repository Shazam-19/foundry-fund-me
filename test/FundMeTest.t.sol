// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import Forge test utilities and console logging
import {Test, console} from "forge-std/Test.sol";

// Import the FundMe contract to be tested
import {FundMe} from "../src/FundMe.sol";

// Import the DeployFundMe contract to so we can deploy an instance of the contract whenever we want
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

// Instance of HelperConfig used to access network configuration functions
import {HelperConfig} from "../script/HelperConfig.s.sol";

/*
To test a single function, we can use 'forge test [FUNCTION NAME]'

To check how much of the code is tested, we use this command:
'forge coverage --fork-url $SEPOLIA_RPC_URL'
*/

contract FundMeTest is Test {
    // Declare a FundMe instance to interact with during tests
    FundMe fundMe;

    // Deploy a fresh HelperConfig contract before each test
    // This ensures each test runs in a clean isolated state
    HelperConfig helperConfig;

    // This function runs before each test to set up the environment
    function setUp() external {
        // Deploy a new FundMe contract instance
        // Note: The owner of FundMe will be this test contract
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        helperConfig = new HelperConfig();
    }

    // Test that the minimum USD required in FundMe is 5 USD (scaled by 1e18 for decimals)
    function testMinimumUSDIsFive() public view {
        // Assert that the MINIMUM_USD constant in FundMe equals 5e18
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Test that the owner of FundMe is correctly set to the deployer (this test contract)
    function testOwnerIsMsgSender() public view {
        // Verify that the owner of FundMe is the current contract (FundMeTest)
        // 'address(this)' refers to the current contract, not the external caller which is 'msg.sender'
        assertEq(fundMe.i_owner(), msg.sender);
    }

    /*
    What can we do to work with addresses outside our system?
    1. Unit
       - Testing a specific part of our code
    2. Integration
       - Testing how our code works with other parts of our code
    3. Forked
       - Testing our code on a simulated real environment
    4. Staging
       - Testing our code in a real environment that is not prod
    */
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testAnvilConfigReusesMock() public {
        // First call:
        // Deploys (or retrieves) the Anvil network configuration
        // On the first call, this should deploy a new MockV3Aggregator
        HelperConfig.NetworkConfig memory config1 = helperConfig.getOrCreateAnvilEthConfig();

        // Second call:
        // Should reuse the already deployed mock instead of deploying a new one
        HelperConfig.NetworkConfig memory config2 = helperConfig.getOrCreateAnvilEthConfig();

        // Debugging (optional):
        // Prints the price feed addresses to verify they are identical
        // console.log(config1.priceFeed);
        // console.log(config2.priceFeed);

        // Assertion:
        // Ensures both calls return the same mock price feed address
        // This confirms that mock reuse logic is working correctly
        assertEq(config1.priceFeed, config2.priceFeed);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // Hey, the next line, should revert!
        // assert(This tx fails/reverts)
        fundMe.fund(); // Send 0 ETH
    }

    function testFundUpdatesFundedDataStructures() public {
        fundMe.fund{value: 10e18}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));
        assertEq(amountFunded, 10e18);
    }
}
