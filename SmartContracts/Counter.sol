/*
    Problem 1: COUNTER

    Create a smart contract in Solidity called 'Counter' that has a state variable 'count' initialized to zero. The contract should have two functions:

    1. 'increment()': A function that increases the value of the 'count' variable by 1.
    2. 'getCount()': A function that returns the current value of the 'count' variable.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Counter{
    uint private count;
    address public owner;

    event valueChanged(uint newValue);

    constructor(){
        count = 0;
        owner = msg.sender;
    }


    function getCount() public view returns(uint){
        return count;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    function increment() public onlyOwner{
        count++;
        emit valueChanged(count);
    }


    /*
        The fallback function is a function that is called when someone sends Ether or calls the contract with invalid data. The receive function is a new function added in Solidity 0.6.0 and is called when someone sends Ether to the contract without specifying any function to call.

        If a contract does not have a fallback function or a receive function, then any transaction sent to the contract with invalid data or without specifying a function to call will be rejected and any Ether sent to the contract will be lost forever. Therefore, it's a good practice to always include a fallback function or a receive function in your contracts, even if it's empty.
    */
    fallback() external payable {
    // do nothing
    }

    receive() external payable {
    // do nothing
    }
}