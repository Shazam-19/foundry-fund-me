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
We use this command: forge test --match-test testFundUpdatesFundedDataStructures

To check how much of the code is tested, we use this command:
'forge coverage --fork-url $SEPOLIA_RPC_URL'
*/

contract FundMeTest is Test {
    // Declare a FundMe instance to interact with during tests
    FundMe fundMe;

    // HelperConfig instance used to access network configurations during tests
    // This ensures each test runs in a clean isolated state
    HelperConfig helperConfig;

    // Test user address created with Foundry's makeAddr helper
    // Cannot be constant because the value is generated at runtime
    address USER = makeAddr("Shazam");

    // Amount of ETH sent when funding the contract during tests
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000

    // Initial ETH balance assigned to the test user
    uint256 constant STARTING_USER_BALANCE = 10 ether;

    // This function runs before each test to set up the environment
    function setUp() external {
        // Deploy a new FundMe contract instance
        // Note: The owner of FundMe will be this test contract
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // Create a HelperConfig instance for accessing network configurations
        helperConfig = new HelperConfig();

        // Assign an initial ETH balance to the test user
        vm.deal(USER, STARTING_USER_BALANCE);
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
        assertEq(fundMe.getOwner(), msg.sender);
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
        // Expect the next transaction to revert
        vm.expectRevert();

        // Attempt to fund the contract without sending ETH
        // This should fail because the minimum funding amount is not met
        fundMe.fund(); // Send 0 ETH
    }

    function testFundUpdatesFundedDataStructures() public {
        // Simulate the next transaction being sent by USER
        // Useful for testing how different users interact with the contract
        vm.prank(USER);

        // Fund the contract with the test ETH amount
        fundMe.fund{value: SEND_VALUE}();

        // Retrieve the amount funded by USER from storage
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        // Verify the funded amount was updated correctly
        assertEq(amountFunded, SEND_VALUE);
    }

    // Test that a funder's address is added to the funders array
    function testAddsFunderToArrayOfFunders() public {
        // Simulate the next transaction being sent by USER
        vm.prank(USER);

        // Fund the contract with the test ETH amount
        fundMe.fund{value: SEND_VALUE}();

        // Retrieve the first funder stored in the array
        address funder = fundMe.getFunder(0);

        // Verify that USER was added to the funders array
        assertEq(funder, USER);
    }

    // Modifier that funds the contract before running the test
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // Test that only the contract owner can withdraw funds
    function testOnlyOwnerCanWithdraw() public funded {
        // Simulate USER attempting to withdraw funds
        // Note: 'vm.prank(USER)' is only used once, so if we want to use it for multiple calles, then
        // Keep USER as msg.sender for all following transactions until stopPrank() is called
        // vm.startPrank(USER);
        // End the prank and reset msg.sender to the default test contract address
        // vm.stopPrank();
        vm.prank(USER);

        // Expect the next transaction to revert
        // because USER is not the contract owner
        vm.expectRevert();

        // Attempt to withdraw funds from the contract
        fundMe.withdraw();
    }

    // Test that the owner can successfully withdraw funds
    // when the contract has a single funder
    function testWithdrawWithASingleFunder() public funded {
        // Arrange //

        // Store the owner's initial ETH balance
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Store the contract's initial ETH balance
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act //

        // Simulate the owner calling withdraw()
        vm.prank(fundMe.getOwner());

        // Withdraw all ETH from the contract to the owner
        fundMe.withdraw();

        // Asssert //

        // Store the owner's new balance after withdrawal
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        // Store the contract's new balance after withdrawal
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Verify the contract balance is now empty
        assertEq(endingFundMeBalance, 0);

        // Verify the withdrawn ETH was transferred to the owner
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    // Test that the owner can withdraw funds successfully
    // after multiple users have funded the contract
    function testWithdrawFromMultipleFunders() public funded {
        // Arrange //
        // why are we using uint160 for using numbers to generate addresses?

        // Total number of additional funders to simulate
        uint160 numberOfFunders = 10;

        // Starting index for generating test addresses
        uint160 startingFunderIndex = 1;

        // Simulate multiple users funding the contract
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Create a temporary test address and assign it ETH
            // hoax() combines vm.deal() and vm.prank() into one helper
            hoax(address(i), SEND_VALUE);

            // Fund the contract from the generated address
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act //

        // Store the owner's initial ETH balance
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Store the contract's initial ETH balance
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Simulate all following transactions as the contract owner
        vm.startPrank(fundMe.getOwner());

        // Withdraw all ETH from the fundMe contract to owner contract
        fundMe.withdraw();

        // Stop impersonating the owner
        vm.stopPrank();

        // Assert //

        // Verify the contract balance is empty after withdrawal
        assert(address(fundMe).balance == 0);

        // Verify the owner received all withdrawn ETH
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
