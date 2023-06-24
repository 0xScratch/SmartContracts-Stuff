/*
    Problem 3: AUCTION

    Design a smart contract that allows users to create and participate in auctions. The contract should have the following functionality:
    1. Users can create an auction by specifying the item being auctioned, the minimum bid amount, and the duration of the auction.
    2. Users can place bids on an auction, but only if the auction is still active.
    3. Once the duration of the auction has passed, the highest bidder should be declared the winner and the item should be transferred to them.
    4. If no one bids on an auction, the item should be returned to the original owner.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

struct _auction{
    bool sold;
    string auction_item;
    address _seller;
    address payable high_bidder;
    uint highest_bid;
    uint reserve_price;
}

contract Auction {
    using SafeMath for uint;

    uint public duration;
    uint public startTime;
    uint public endTime;
    uint public currentBid;
    uint public minAmount;
    uint private counter;
    uint public balance;
    string public currentItem;
    address private auctioneer;
    address public currentBidder;
    address public currentSeller;
    address[] public auctionQueue;
    _auction private auction;
    mapping(address => string[]) public bidder;
    mapping(address => string) public seller;
    mapping(uint => _auction) public auctionHistory;
    mapping(address => bool) public inQueue;

    // Event for the highest current bid
    event Bid_Current(address bidder, uint amount);

    // Event telling the ending of an auction and who was the winner
    event Auction_End(string item, address highestBidder, uint highestBid);

    // States
    enum State{sessionStarted, sessionEnded, auctionActive, auctionEnd}
    State public state;

    // This function cannot be called at the current state
    error invalidState();

    // <-- Modifiers -->

    // This modifier will help in controlling the states
    modifier inState(State _state){
        if (state != _state){
            revert invalidState();
        }
        _;
    }

    modifier notInState(State _state){
        if (state == _state){
            revert invalidState();
        }
        _;
    }

    // This function makes sure that the placeBid function is called only if the bidder places greater value than the previous bid
    modifier bidCallable(){
        require(msg.value > currentBid, "Your Bid must be greater than the current Bid");
        _;
    }

    // Checks whether the time got expired or not
    modifier isExpired{
        require(block.timestamp <= endTime, "The time for current auction is over..Better luck next time!!");
        _;
    }

    // Making only the seller run that particular function
    modifier onlySeller{
        require(currentSeller == msg.sender, "Only Seller can access this function");
        _;
    }

    // Making only the auctioneer run that particular function
    modifier onlyAuctioneer{
        require(auctioneer == msg.sender, "Only Auctioneer can access this function");
        _;
    }

    // Making only the bidder run that particular function
    modifier onlyBidder{
        require(msg.sender != currentSeller && msg.sender != auctioneer, "Only Bidder can access this function");
        _;
    }

    constructor(){
        auctioneer = payable(msg.sender);
        state = State.sessionEnded;
        counter = 0;
    } 

    // This function will start a new session
    function startSession() public onlyAuctioneer inState(State.sessionEnded){
        state = State.sessionStarted;
    }

    // This function will help in providing the tokens to the sellers according to which they can have a kind of priority list..
    function addSellerToQueue() external notInState(State.sessionEnded){
        require(inQueue[msg.sender] == false, "You are already in the seller's queue list in this session");
        inQueue[msg.sender] = true;
        auctionQueue.push(msg.sender);
    }

    // This function will be start a new auction
    function startAuction(string memory item, uint value, uint _duration) external notInState(State.sessionEnded){
        require(block.timestamp >= endTime, "Previous Auction is still running");
        require(auctionQueue[counter] == msg.sender, "You can't start the auction right now.. Either get a token or wait for your turn");
        // Setting the duration limit to 4min..
        require(_duration <= 240, "Durations can't be more than 4 minutes");
        auction.sold = false;
        currentSeller = msg.sender;
        seller[currentSeller] = item;
        currentItem = item;
        minAmount = value;
        startTime = block.timestamp;
        endTime = startTime.add(_duration);
        state = State.auctionActive;
    }

    // This function will be called by bidders to bid for that item
    function placeBid() external onlyBidder bidCallable isExpired payable{
        require(msg.sender.balance >= msg.value, "You don't have enough funds to buy this item");

        uint previousBid = currentBid;
        address payable previousBidder = payable(currentBidder);

        currentBid = msg.value;
        currentBidder = payable(msg.sender);

        balance = balance.add(currentBid).sub(previousBid);

        if (previousBidder != address(0)){
            if(!previousBidder.send(previousBid)){
                payable(currentBidder).transfer(previousBid);
                balance = balance.sub(previousBid);
            }
        }

        emit Bid_Current(currentBidder, currentBid);
    }


    // This function tells what is the current time epoch going on..
    function currentTime() external view returns(uint){
        return block.timestamp;
    }

    // This function will tell how much time is left for the auction to end
    function time_left() external view isExpired returns(uint){
        uint val = endTime.sub(block.timestamp);
        return val;
    }

    // This function will tell who is the next seller
    function next_seller() external view notInState(State.sessionEnded) returns(address){
        uint count = counter;
        require(auctionQueue[count+1] == address(0),"There is no seller listed down after this..");
        address next = auctionQueue[count+1];
        return next;
    }

    // This function will be called by the seller to end the Auction and take funds if item got sold
    function endAuction() external inState(State.auctionActive) onlySeller{
        auction.auction_item = currentItem;
        auction._seller = currentSeller;
        endTime = 0;
        auction.reserve_price = minAmount;
        if (currentBidder != address(0)){
            auction.sold = true;
            payable(msg.sender).transfer(balance);
            balance = 0;
            auction.high_bidder = payable(currentBidder);
            auction.highest_bid = currentBid;
            bidder[currentBidder].push(currentItem);
            seller[currentSeller] = "";
            emit Auction_End(currentItem, currentBidder, currentBid);
        }
        auctionHistory[counter] = auction;
        currentItem = "";
        counter++;
        currentBid = 0;
        state = State.auctionEnd;
    }

    /**
    * @dev Terminate the auction in case of any suspicious activity by the auctioneer.
    * The highest bidder will be refunded their bid amount and the auction will be marked as ended.
    * Only the auctioneer can call this function.
    */
    function terminateAuction() public onlyAuctioneer inState(State.auctionActive){
        endTime = 0;
        if (currentBidder != address(0)){
            balance = 0;
            payable(currentBidder).transfer(currentBid);
            currentBid = 0;
        }
        counter++;
        state = State.auctionEnd;
    }

    // This function will be called by the auctioneer to end the session
    function terminateSession() public onlyAuctioneer inState(State.auctionEnd){
        endTime = 0;
        balance = 0;
        currentBid = 0;
        delete auctionQueue;
        counter = 0;
        state = State.sessionEnded;
    }

    // This function will be called by the auctioneer if he feels that a seller is taking a lot of time to start his auction..
    function change_seller() public onlyAuctioneer inState(State.sessionStarted){
        counter++;
    }
}

/*
    Make sure to add that part which includes incrementing the counter by the auctioneer with the help of some code or something if particular seller taking time to start it's auction..
*/