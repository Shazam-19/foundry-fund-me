// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @dev `Test` gives us access to Foundry cheatcodes (vm.*) and assertion helpers.
 *      `console` allows logging values during test execution for debugging.
 */
import {Test, console} from "forge-std/Test.sol";

/// @dev The contract we are testing.
import {FundMe} from "../../src/FundMe.sol";

/**
 * @dev We import the deploy script so we can deploy a fresh FundMe instance
 *      before each test, ensuring tests are isolated and repeatable.
 */
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

/// @dev Import both interaction scripts so we can test them as part of integration testing.
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

/**
 * @title  InteractionsTest
 * @notice Integration tests that verify the full fund → withdraw flow
 *         using the Interactions scripts, not just the FundMe contract directly.
 * @dev    This is an integration test (vs a unit test), because it tests multiple
 *         contracts working together: DeployFundMe, FundFundMe, WithdrawFundMe, and FundMe.
 */
contract InteractionsTest is Test {
    /// @notice The FundMe instance deployed fresh before each test.
    FundMe fundMe;

    /// @notice A fake user address created by Foundry's makeAddr() cheatcode.
    ///         makeAddr() generates a deterministic address from a label string.
    address USER = makeAddr("Shazam");

    /// @notice The amount of ETH the interaction scripts will send to FundMe.
    ///         Must meet FundMe's minimum funding threshold (checked via Chainlink price feed).
    uint256 constant SEND_VALUE = 0.1 ether;

    /// @notice The starting ETH balance given to USER for testing purposes.
    uint256 constant STARTING_BALANCE = 10 ether;

    /**
     * @dev GAS_PRICE is declared but not currently used in any test.
     *      It is kept here as a placeholder for future tests that simulate
     *      gas cost calculations (e.g., checking ETH balances after withdrawals
     *      while accounting for gas spent).
     */
    uint256 constant GAS_PRICE = 1;

    /**
     * @notice Runs before every individual test function.
     * @dev    Deploys a fresh FundMe contract using the DeployFundMe script,
     *         then funds USER with STARTING_BALANCE ETH using vm.deal().
     *
     *         `vm.deal(address, amount)` is a Foundry cheatcode that sets an
     *         address's ETH balance directly, without needing a real transfer.
     */
    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run(); // Deploy a fresh FundMe and store the reference.
        vm.deal(USER, STARTING_BALANCE); // Give USER a starting balance for any future tests.
    }

    /**
     * @notice Verifies that the FundFundMe and WithdrawFundMe scripts work correctly
     *         end-to-end, resulting in a zero balance after withdrawal.
     * @dev    This is an integration test that exercises the full lifecycle:
     *         1. Fund FundMe via the FundFundMe interaction script.
     *         2. Withdraw all funds via the WithdrawFundMe interaction script.
     *         3. Assert that the FundMe contract balance is 0.
     *
     *         Note: The actual funder in this test is the broadcaster (Foundry's
     *         default test sender), not USER. USER's balance is set up in setUp()
     *         and is available if needed by future tests or expanded assertions.
     */
    function testUserCanFundInteractions() public {
        // --- Step 1: Fund FundMe using the interaction script ---

        FundFundMe fundFundMe = new FundFundMe();

        // Give the test contract enough ETH to fund (needed because fundFundMe
        // uses vm.startBroadcast which sends from the default test sender).
        vm.deal(USER, SEND_VALUE);

        // Call the funding helper directly. This internally uses vm.startBroadcast
        // to simulate a real on-chain transaction during testing.
        fundFundMe.fundFundMe(address(fundMe));

        // --- Step 2: Withdraw all funds using the interaction script ---

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();

        // Call the withdraw helper. This will only succeed if the broadcaster
        // is the owner of the FundMe contract (which it is in the test environment).
        withdrawFundMe.withdrawFundMe(address(fundMe));

        // --- Step 3: Assert the contract balance is now zero ---

        // After a successful withdrawal, FundMe should hold no ETH.
        // `address(fundMe).balance` reads the ETH balance of the contract.
        assert(address(fundMe).balance == 0);
    }
}
