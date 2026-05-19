// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/*
FundMe Contract
---------------
Purpose:
- Allow users to fund the contract with ETH
- Enforce a minimum funding amount in USD
- Track funders and their contributions
- Allow funds to be withdrawn later
*/

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// It's a good practice to rename the error with [Contract Name]__[Error Name]
// This way, it's easier to debug errors for larger projects to know that this specified error is related to the contract
error FundMe__NotOwner(); // Custom error for unauthorized access

contract FundMe {
    // Enable all uint256 values (like 'msg.value') to use functions from the PriceConverter library.
    using PriceConverter for uint256;

    // Example state variable
    uint256 public myValue = 1;

    /*
    What does revert do?

    If require() fails:
    - All state changes made in this transaction are undone
    - Remaining unused gas is refunded to the caller
    - Transaction execution stops immediately

    Example:
    - myValue += 2 will be reverted if require() fails
    */

    // NOTE:
    // This value 'MINIMUM_USD' is currently compared directly against 'msg.value' (Wei),
    // not actual USD. A price feed would be needed for real USD conversion.
    // We updated the number so that it doesn't be just 5 since 'getConversionRate()' return a number
    // with an 18 decimal. We can just declare it as '5 * 1e18' or '5 * (10**18)'
    uint256 public constant MINIMUM_USD = 5 * 1e18; // Minimum amount required to fund the contract
    // Using `constant` saves gas because the value is fixed at compile time
    // Constant variables are conventionally written in uppercase letters

    AggregatorV3Interface private s_priceFeed;

    // Keep track of everyone's addresses who will send money to this contract
    // Private will be more gas efficient than 'public'
    address[] private s_funders; // 's_' indicates this is a storage/state variable

    // Track how much ETH each address funded
    // 's_' indicates this is a storage/state variable
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    // Variable assigned once during contract deployment - This will save much more gas than without 'immutable'
    address private immutable i_owner;

    // Called when the contract is deployed
    // So that only the owner of the contract can use the withdraw function
    constructor(address PriceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(PriceFeed);
    }

    // Allows users to fund the contract with ETH.
    // Requirements: Sent ETH must be worth at least MINIMUM_USD.
    function fund() public payable {
        // Example state update
        // This change will revert if require() below fails
        myValue += 2;

        // Here, 'msg.value' is automatically passed as the first argument
        // to 'getConversionRate()' through the PriceConverter library.
        /* msg.value.getConversionRate();*/

        // Convert sent ETH into USD value and verify minimum amount.
        // msg.value = amount of ETH sent in Wei since 1 ETH = 1e18 Wei
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "ETH amount is below the minimum requirement.");
        // 1e18 = 1 ETH = 1,000,000,000,000,000,000 Wei = 1 * 10^18 Wei

        // Store funder address
        s_funders.push(msg.sender);

        // Update amount funded by this sender
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    // Withdraws all funded amounts by resetting each funder's balance.
    // Iterates through the funders array and sets every funded amount to 0.
    function withdraw() public onlyOwner {
        // Loop through all funders
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            // Get funder address at current index
            address funder = s_funders[funderIndex];

            // Reset funded amount for this address
            s_addressToAmountFunded[funder] = 0;
        }

        // We still need to:
        // 1. Reset the array
        s_funders = new address[](0);

        // 2. Actually withdraw ALL the funds. There are 3 ways to do this:
        //    a) transfer (2300 gas, throws error)
        //    b) send (2300 gas, returns bool)
        //    c) call (forward all gas or set gas, returns a bool & bytes object)

        /*

        // a)
        // 'msg.sender' = address - we can't send ETH
        // 'payable(msg.sender)' = payable address - we can send ETH
        payable(msg.sender).transfer(address(this).balance); // Here we will transfer/withdraw all balance

        // b)
        // - Returns true if successful
        // - Returns false if failed
        bool sendSuccess = payable(msg.sender).send(address(this).balance); // Here we will transfer/withdraw all balance
        require(sendSuccess, "Failed to Send ETH to the Address");


        */

        // c)
        // Since we don't care about calling any functions in this 'call',
        // we will ignore the returned data bytes and just leave the returned bool
        /* (bool callSuccess, bytes memory dataReturned)*/
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}(""); // Here we will transfer/withdraw all balance
        /*
            Empty string "" means:
            - No calldata
            - No function is being called
            - ETH is simply transferred
            */
        require(callSuccess, "Failed to Send ETH to the Address");
    }

    /**
     * @notice Withdraws all contract funds to the owner, resetting all funder records.
     * @dev Gas-optimized version of the standard withdraw function.
     *      The key optimization: instead of reading `s_funders.length` from storage
     *      on every loop iteration (expensive), we cache it once in a local memory
     *      variable `fundersLength`. Each storage read costs 2100 gas (SLOAD opcode),
     *      so this saves significant gas when the funders list is large.
     *
     *      Access control is enforced by the `onlyOwner` modifier — only the contract
     *      owner can call this function.
     */
    function cheaperWithdraw() public onlyOwner {
        // Cache the array length in memory to avoid repeated expensive storage reads.
        // Reading from memory costs 3 gas vs. 2100 gas per read from storage (EIP-2929).
        uint256 fundersLength = s_funders.length;

        // Loop through every funder and zero out their funded amount.
        // This prevents re-entrancy exploits and keeps accounting accurate after withdrawal.
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex]; // Load funder address from storage
            s_addressToAmountFunded[funder] = 0; // Reset their contribution to zero
        }

        // Reset the funders array to an empty state.
        // `new address[](0)` creates a new empty dynamic array, effectively clearing all entries.
        s_funders = new address[](0);

        // Transfer the entire ETH balance of this contract to the owner (msg.sender).
        // `call` is the recommended low-level method for sending ETH (over `transfer` or `send`)
        // because it forwards all available gas and does not revert automatically on failure.
        // The empty string `""` means no calldata is sent; we are transferring ETH only.
        // `callSuccess` captures whether the transfer succeeded (true) or failed (false).
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");

        // Revert the entire transaction if the ETH transfer failed.
        // This protects against silent failures where the owner doesn't receive funds.
        require(callSuccess, "Failed to Send ETH to the Address");
    }

    // Returns the version of the deployed Chainlink price feed contract.
    function getVersion() public view returns (uint256) {
        // Create an interface instance pointing to the deployed
        // Chainlink ETH/USD price feed contract and return its version.
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Must be Owner to be able to Withdraw");

        // Revert if the caller is not the contract owner
        // Using a custom error is more gas-efficient than using a require statement
        // with a long revert string because the string does not need to be stored.
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Handle ETH sent directly to the contract
    // without calling the fund function explicitly
    receive() external payable {
        fund();
    }

    // Called when the function does not exist or when calldata is not empty.
    fallback() external payable {
        fund();
    }

    /*
    * View / Pure functions (Getters)
    * Getter function for retrieving the amount funded by a specific address.
    *
    * Since `s_funders` and `s_addressToAmountFunded` are marked as private,
    * they cannot be accessed directly outside the contract.
    * This function provides controlled read access to the funding data.
    */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        // Return the total amount funded by the given address
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        // Return the funder address who sent ETH to the contract address
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner; // Return the contract owner's address
    }
}
