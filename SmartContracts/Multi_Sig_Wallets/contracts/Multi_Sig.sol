// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Multi_Sig{
    using SafeMath for uint;

    // States
    enum State{Contract_FuelingUp, Contract_Active, Transaction_Proposed}

    // Structs
    struct Transaction{
        State currentState;

        uint approvals;
        uint rejections;
        uint amount;
        address payable destination;
        bytes data;
        address[3] address_record;
        uint endTime;
        uint index;
    }

    // Events
    event Transaction_Proposed(address destination, uint amount);
    event Transaction_Approved(address destination, uint amount, bytes data);
    event Transaction_Rejected(address destination, uint amount);

    // Modifiers

    /**
    @dev This modifier is used to check whether a particular address is present in the `addresses` or not
    */
    modifier _Allowed(address _current){
        for (uint i = 0; i < addresses.length; i++){
            require(addresses[i] != _current, "You have already added the ethers in the contract's balance");
        }
        _;
    }

    /**
    @dev This modifier is used to check whether a particular address has casted his vote for a give transaction or not
     */
    modifier _Permit(address _current){
        for (uint i = 0; i < addresses.length; i++){
            require(transaction_Records[counter].address_record[i] != _current, "You have already gave your approval or rejection for this transaction");
        }
        _;
    }

    /**
    @dev This modifier is used to check whether the address calling a function comes under the owners or not
     */
    modifier onlyOwners(){
        require((msg.sender == owner_addresses[0]) || (msg.sender == owner_addresses[1]) || (msg.sender == owner_addresses[2]), "You are not the owner of this contract");
        _;
    }

    /**
    @dev this modifier will be used when you want to make a function call only in particular state..
     */
    modifier inState(State _state){
        require(state == _state, "You can't call this function in current state");
        _;
    }

    /**
    @dev This modifier will be used when the user want to make function call in any particular state..Specifically for transactions
     */
    modifier transaction_inState(State _state){
        require(transaction_Records[counter].currentState == _state, "You can't call this function in current state");
        _;
    }

    // State Variables
    Transaction[] public transaction_Records;
    uint public counter;
    uint public balance = 0;
    address[] public owner_addresses;
    uint public Amount = 0;
    State public state;
    address[] public addresses;

    // Constructor
    /**
    @notice This constructor will add the addresses to the queues and also indicate the amount to be 
    added in the contract's balance by each owner..
    @param _owner2 -> address of the 2nd owner
    @param _owner3 -> address of the 3rd owner
    @param amount -> The amount of ether to be added by each owner in the contract's balance
     */
    constructor(address _owner2, address _owner3, uint amount){
        address[] memory owners = new address[](3);
        owners[0] = payable(msg.sender);
        owners[1] = payable(_owner2);
        owners[2] = payable(_owner3);
        for(uint i = 0; i < 3; i++){
            owner_addresses.push(owners[i]);
        }
        Amount = amount;
        state = State.Contract_FuelingUp;
    }

    /**
    @notice This function will let the owners add the specific amount in the contract's balance..
    @dev It will also add the owners in the addresses array..
     */
    function add_Amount() external _Allowed(msg.sender) onlyOwners inState(State.Contract_FuelingUp) payable{
        require(msg.value >= Amount, "Add more amount to the contract");
        balance = balance.add(msg.value);
        addresses.push(msg.sender);
        if (addresses.length == 3){
            state = State.Contract_Active;
        }
    }

    /**
    @notice This function will be used to propose a transaction by an owner and gets it added to the queue
    @param _amount -> This will store the amount the owner needs to transact
    @param _destination -> This consists of the address to which the ether is been sent
    @param _data -> This contains any sort of data in bytes.
     */
    function propose_Transaction(uint _amount, address _destination, bytes memory _data) onlyOwners inState(State.Contract_Active) external{
        require(_amount <= balance, "Contract doesn't have this much amount of ethers");
        Transaction memory transaction;
        transaction.currentState = State.Transaction_Proposed;
        transaction.approvals = 1;
        transaction.amount = _amount;
        transaction.destination = payable(_destination);
        transaction.data = _data;
        transaction.endTime = block.timestamp.add(86400);
        transaction.address_record[0] = msg.sender;
        transaction.index = transaction.index.add(1);
        transaction_Records.push(transaction);
        emit Transaction_Proposed(_destination, _amount);
    }

    /**
    @notice This function will be used by the one of the owners to cast their vote to approve the transaction
     */
    function Approve_Transaction() external _Permit(msg.sender) onlyOwners transaction_inState(State.Transaction_Proposed){
        transaction_Records[counter].approvals = transaction_Records[counter].approvals.add(1);
        transaction_Records[counter].address_record[transaction_Records[counter].index] = msg.sender;
        transaction_Records[counter].index = transaction_Records[counter].index.add(1);
    }

    /**
    @notice This function will be used by the one of the owners to cast their vote to reject the transaction
     */
    function Reject_Transaction() external _Permit(msg.sender) onlyOwners transaction_inState(State.Transaction_Proposed){
        transaction_Records[counter].rejections = transaction_Records[counter].rejections.add(1);
        transaction_Records[counter].address_record[transaction_Records[counter].index] = msg.sender;
        transaction_Records[counter].index = transaction_Records[counter].index.add(1);
    }

    /**
    @notice This function will be used by the one of the owners to implement the transaction and increment the counter by 1..
     */
    function implement_Transaction() external onlyOwners transaction_inState(State.Transaction_Proposed){
        require(transaction_Records[counter].amount <= balance, "Contract doesn't have this much amount of ethers");
        if (transaction_Records[counter].approvals >= 2 && transaction_Records[counter].endTime > block.timestamp){
            balance = balance.sub(transaction_Records[counter].amount);
            payable(transaction_Records[counter].destination).transfer(transaction_Records[counter].amount);
            emit Transaction_Approved(transaction_Records[counter].destination, transaction_Records[counter].amount, transaction_Records[counter].data);
        } else{
            emit Transaction_Rejected(transaction_Records[counter].destination, transaction_Records[counter].amount);
        }
        delete transaction_Records[counter];
        counter = counter.add(1);
    }

    /**
    @notice This function will be used to propose funding amount in the contract if somehow the starting deposit gets over..
     */
    function Propose_Funding(uint amount) external onlyOwners inState(State.Contract_Active){
        Amount = amount;
        for (uint i = 0; i < 3; i++){
            addresses.pop();
        }
        state = State.Contract_FuelingUp;
    }
}