// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DEX{
    // State
    enum State{noOrder, orderPlaced, orderExecuted}

    // stucts
    struct Order{
        uint order_id;
        uint Tokens_A;
        uint Tokens_B;
        State currentState;
        string token;
        uint amount_To_Pay;
        uint amount_To_Receive;
        address trader;
    }

    struct Traders{
        uint num_Tokens_A;
        uint num_Tokens_B;

    }

    // State Variables
    uint public counter;
    uint public quantity_A;
    uint public price_A;
    uint public quantity_B;
    uint public price_B;
    uint public k;
    address public owner;
    uint public balance = 0;
    mapping(uint => Order) public orderBook;
    mapping(address => Traders) public traderRecord;
    mapping(address => uint[]) public orderIds;

    // modifier
    modifier is_valid(uint _id){
        require(orderBook[_id].currentState == State.orderPlaced, "This order can't be executed");
        _;
    }

    modifier onlyUser(uint _id){
        require(orderBook[_id].trader == address(msg.sender), "You can't execute this order");
        _;
    }

    // Constructor
    constructor(uint _quantityA, uint _priceA, uint _quantityB, uint _priceB){
        owner = msg.sender;
        quantity_A = _quantityA;
        price_A = _priceA;
        quantity_B = _quantityB;
        price_B = _priceB;
        k = _quantityA * _quantityB;
    }

    // This function is used for checking the price of A
    function current_Price_A() external view returns(uint){
        return price_A;
    }

    // This function is used for checking the price of B
    function current_Price_B() external view returns(uint){
        return price_B;
    }

    // This function is used for placing a order of purchasing token A..
    function purchaseToken_A(uint _count) external {
        uint _amount = price_A * _count;
        require(address(msg.sender).balance >= _amount, "Insufficient Balance");
        Order memory order;
        order.order_id = counter;
        counter++;
        order.token = "A";
        order.Tokens_A = _count;
        order.currentState = State.orderPlaced;
        order.amount_To_Pay = _amount;
        order.trader = address(msg.sender);
        orderBook[order.order_id] = order;
        orderIds[msg.sender].push(order.order_id);
    }

    // This function is used for placing a order of purchasing token B..
    function purchaseToken_B(uint _count) external {
        uint _amount = price_B * _count;
        require(address(msg.sender).balance >= _amount, "Insufficient Balance");
        Order memory order;
        order.order_id = counter;
        counter++;
        order.token = "B";
        order.Tokens_B = _count;
        order.currentState = State.orderPlaced;
        order.amount_To_Pay = _amount;
        order.trader = address(msg.sender);
        orderBook[order.order_id] = order;
        orderIds[msg.sender].push(order.order_id);
    }

    // This function is used for placing a order of selling token A..
    function sellToken_A(uint _count) external {
        uint _amount = price_A * _count;
        require(traderRecord[msg.sender].num_Tokens_A >= _count, "Insufficient tokens to sell");
        Order memory order;
        order.order_id = counter;
        counter++;
        order.token = "A";
        order.Tokens_A = _count;
        order.currentState = State.orderPlaced;
        order.amount_To_Receive = _amount;
        order.trader = payable(msg.sender);
        orderBook[order.order_id] = order;
        orderIds[msg.sender].push(order.order_id);
    }

    // This function is used for placing a order of selling token B..
    function sellToken_B(uint _count) external {
        uint _amount = uint(price_B * _count);
        require(traderRecord[msg.sender].num_Tokens_B >= _count, "Insufficient tokens to sell");
        Order memory order;
        order.order_id = counter;
        counter++;
        order.token = "B";
        order.Tokens_B = _count;
        order.currentState = State.orderPlaced;
        order.amount_To_Receive = _amount;
        order.trader = payable(msg.sender);
        orderBook[order.order_id] = order;
        orderIds[msg.sender].push(order.order_id);
    }

    // This function is used for executing the order...
    function executeOrder(uint id) external is_valid(id) onlyUser(id) payable{
        if (orderBook[id].Tokens_A > 0){
            if (orderBook[id].amount_To_Pay > 0){
                require(msg.value >= orderBook[id].amount_To_Pay, "Insufficient Amount");
                balance += orderBook[id].amount_To_Pay;
                traderRecord[msg.sender].num_Tokens_A += orderBook[id].Tokens_A;
            }else{
                require(traderRecord[msg.sender].num_Tokens_A >= orderBook[id].Tokens_A, "Insufficient amount of tokens to sell");
                traderRecord[msg.sender].num_Tokens_A -= orderBook[id].Tokens_A;
                balance -= orderBook[id].amount_To_Receive;
                payable(msg.sender).transfer(orderBook[id].amount_To_Receive);
            }
        }else{
            if (orderBook[id].amount_To_Pay > 0){
                require(msg.value >= orderBook[id].amount_To_Pay, "Insufficient Amount");
                balance += orderBook[id].amount_To_Pay;
                traderRecord[msg.sender].num_Tokens_B += orderBook[id].Tokens_B;
            }else{
                require(traderRecord[msg.sender].num_Tokens_B >= orderBook[id].Tokens_B, "Insufficient amount of tokens to sell");
                traderRecord[msg.sender].num_Tokens_B -= orderBook[id].Tokens_B;
                balance -= orderBook[id].amount_To_Receive;
                payable(msg.sender).transfer(orderBook[id].amount_To_Receive);
            }
        }
        orderBook[id].currentState = State.orderExecuted;
    }

    // This function is used to cancel the order..
    function cancelOrder(uint id) external is_valid(id) onlyUser(id){
        orderBook[id].currentState = State.noOrder;
    }

    
    /** 
    @notice This function  is for trading tokens A to B..Trader will put amount of token A he wants to put into the liquidity pool and will get the token B..
    @param num_tokens -> Number of tokens user wants to trade for his A tokens..
    */
    function trade_A_to_B(uint num_tokens) external {
        require(traderRecord[msg.sender].num_Tokens_A >= num_tokens, "Insufficient tokens to trade");
        uint amount_A = quantity_A * price_A;
        uint amount_B = quantity_B * price_B;
        traderRecord[msg.sender].num_Tokens_A -= num_tokens;
        quantity_A += num_tokens;
        uint prev_B = quantity_B;
        quantity_B = k / quantity_A;
        price_A = amount_A / quantity_A;
        price_B = amount_B / quantity_B;
        traderRecord[msg.sender].num_Tokens_B += prev_B - quantity_B;
    }
    
    /** 
    @notice This function is for trading tokens B to A..Trader will put amount of token B he wants to put into the liquidity pool and will get the token A..
    @param num_tokens -> Number of tokens user wants to trade for his B tokens..
    */
    function trade_B_to_A(uint num_tokens) external {
        require(traderRecord[msg.sender].num_Tokens_B >= num_tokens, "Insufficient tokens to trade");
        uint amount_A = quantity_A * price_A;
        uint amount_B = quantity_B * price_B;
        traderRecord[msg.sender].num_Tokens_B -= num_tokens;
        quantity_B += num_tokens;
        uint prev_A = quantity_A;
        quantity_A = k / quantity_B;
        price_A = amount_A / quantity_A;
        price_B = amount_B / quantity_B;
        traderRecord[msg.sender].num_Tokens_A += prev_A - quantity_A;
    }
}