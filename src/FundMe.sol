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

// It's a good practice to rename the error with [Contract Name]__[Error Name]
// This way, it's easier to debug errors for larger projects to know that this specified error is related to the contract
error FundMe__NotOwner(); // Custom error for unauthorized access

contract FundMe {
    // Enable all uint256 values (like 'msg.value') to use functions from the PriceConverter library.
    using PriceConverter for uint256;

    // Example state variable
    uint256 public myValue = 1;

    // NOTE:
    // This value is currently compared directly against msg.value (Wei),
    // not actual USD. A price feed would be needed for real USD conversion.
    // We updated the number so that it doesn't be just 5 since getConversionRate return a number
    // with an 18 decimal. We can just declare it as '5 * 1e18' or '5 * (10**18)'
    uint256 public constant MINIMUM_USD = 5 * 1e18; // Minimum amount required to fund the contract
    // Using `constant` saves gas because the value is fixed at compile time
    // Constant variables are conventionally written in uppercase letters

    // Keep track of everyone's addresses who will send money to this contract
    address[] public funders;

    // Track how much ETH each address funded
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    // Variable assigned once during contract deployment - This will save much more gas than without 'immutable'
    address public immutable i_owner;

    // Called when the contract is deployed
    // So that only the owner of the contract can use the withdraw function
    constructor() {
        i_owner = msg.sender;
    }

    // Allows users to fund the contract with ETH.
    // Requirements: Sent ETH must be worth at least MINIMUM_USD.
    function fund() public payable {
        // Example state update
        // This change will revert if require() below fails
        myValue += 2;

        // Here, msg.value is automatically passed as the first argument
        // to getConversionRate() through the PriceConverter library.
        /* msg.value.getConversionRate();*/

        // Convert sent ETH into USD value and verify minimum amount.
        // msg.value = amount of ETH sent in Wei since 1 ETH = 1e18 Wei
        require(msg.value.getConversionRate() >= MINIMUM_USD, "ETH amount is below the minimum requirement."); // 1e18 = 1 ETH = 1,000,000,000,000,000,000 Wei = 1 * 10^18 Wei

        // Store funder address
        funders.push(msg.sender);

        // Update amount funded by this sender
        addressToAmountFunded[msg.sender] += msg.value;

        /*
        What does revert do?

        If require() fails:
        - All state changes made in this transaction are undone
        - Remaining unused gas is refunded to the caller
        - Transaction execution stops immediately

        Example:
        - myValue += 2 will be reverted if require() fails
        */
    }

    // Withdraws all funded amounts by resetting each funder's balance.
    // Iterates through the funders array and sets every funded amount to 0.
    function withdraw() public onlyOwner {
        // Loop through all funders
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            // Get funder address at current index
            address funder = funders[funderIndex];

            // Reset funded amount for this address
            addressToAmountFunded[funder] = 0;
        }

        // We still need to:
        // 1. Reset the array
        funders = new address[](0);

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
}
