/*
    Problem 2: VOTING

    Create a smart contract named 'Voting' that allows users to vote for their favorite candidate in an election. The contract should have the following functionality:
    1. The contract should have a constructor that takes an array of candidate names as an argument and initializes an empty mapping that will store the vote count for each candidate.
    2. The contract should have a function named 'vote' that takes a candidate name as an argument and increments the vote count for that candidate by 1.
    3. The contract should have a function named 'getVotes' that takes a candidate name as an argument and returns the vote count for that candidate.
    4. The contract should have a function named 'getWinner' that returns the name of the candidate with the highest vote count.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Voting{

    string[] public candidates;
    mapping(string => uint) public voteCount;
    mapping(address => bool) public hasVoted;
    address private owner;

    enum State {Created, Finished}
    State public state;

    event StateChanged(State newState);

    /// This function cannot be called at the current state
    error invalidState();

    modifier inState(State _state){
        if (state != _state){
            revert invalidState();
        }
        _;
    }

    modifier notOwner(){
        require(msg.sender != owner, "Owner can't access this method");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }

    constructor(string[] memory _values){
        for(uint i = 0; i < _values.length; i++){
            candidates.push(_values[i]);
            voteCount[_values[i]] = 0;
        }
        owner = msg.sender;
    }

    function vote(string memory _candidate) external notOwner inState(State.Created){
        require(!hasVoted[msg.sender], "This address has already voted!");
        voteCount[_candidate]++;
        hasVoted[msg.sender] = true;
    }

    
    function getVotes(string memory _name) public onlyOwner inState(State.Finished) view returns(uint){
        return voteCount[_name];
    }

    function getCandidates() public view returns(string[] memory){
        return candidates;
    }

    function getWinner() public onlyOwner inState(State.Finished) view returns(string memory){
        uint max = voteCount[candidates[0]];
        string memory winner = candidates[0];
        for (uint i = 1; i < candidates.length; i++){
            if (voteCount[candidates[i]] > max){
                max = voteCount[candidates[i]];
                winner = candidates[i];
            }
        }

        return winner;
    }

    function reset() public onlyOwner inState(State.Finished){
        for (uint i = 0; i < candidates.length; i++){
            voteCount[candidates[i]] = 0;
        }
        state = State.Created;
        emit StateChanged(state);
    }

    function voting_Ended() public onlyOwner inState(State.Created){
        state = State.Finished;
        emit StateChanged(state);
    }
}