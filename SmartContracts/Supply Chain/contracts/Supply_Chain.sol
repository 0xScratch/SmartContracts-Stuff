/*
    Problem 4: Supply Chain Management

    You need to create a smart contract for a supply chain management system. The supply chain management system should track the journey of goods from the supplier to the end customer.
    The smart contract should have the following functionalities:
    1. Add a new product to the supply chain system along with the product details and the supplier's details.
    2. Assign a unique tracking ID to each product.
    3. Update the product status at various stages of the journey, such as when the product is picked up by the carrier, when it reaches the warehouse, when it is dispatched from the warehouse, and when it is delivered to the end customer.
    4. Allow the supplier, carrier, warehouse manager, and end customer to view the current status of the product using the unique tracking ID.
    5. Allow the supplier, carrier, warehouse manager, and end customer to update the product status at their respective stages of the journey using the unique tracking ID.

    You can assume that each product can have only one supplier, one carrier, and one warehouse manager.
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Supply_Chain{
    // Declaring the States
    enum State{productOnSale, carrierAssigned, deliveredToWarehouse, inStock, delivered, itemRequested, itemApproved, itemReady}

    // Struct for the products
    struct Products{
        State currentState;

        uint trackingID;
        address seller;
        address buyer;
        string name;
        string description;
        uint quantity;
        uint priceEach;
        uint carrier_fee;
        uint totalAmount;
        address carrier;
    }

    uint counter = 0;
    uint counter_ = 0;
    address public owner;
    uint balance = 0;
    mapping(uint => Products) public records;
    mapping(string => Products) public wareHouse;
    mapping(uint => Products) public items_Requested;

    // Events
    event productPurchased(uint Track, string Name);
    event inWareHouse(uint Track, string Name, uint Quantity);

    // Modifiers
    modifier inState_1(State _state, uint id){
        require(records[id].currentState == _state, "function can't be called on current state");
        _;
    }

    modifier inState_2(State _state, uint id){
        require(items_Requested[id].currentState == _state, "function can't be called on current state");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBuyer(uint id){
        require(items_Requested[id].buyer == msg.sender, "You are not the buyer of this item");
        _;
    }

    modifier onlyCarrier(State _state, uint id){
        require(records[id].currentState == _state, "function can't be called on current state");
        require(records[id].carrier == msg.sender, "You are not the carrier of this product");
        _;
    }

    modifier InStock(string memory _name, uint _quantity){
        require(wareHouse[_name].quantity > 0, "This Item is not in stock");
        require(wareHouse[_name].quantity >= _quantity, "You are trying to buy more items than in stock");
        _;
    }

    constructor(){
        owner = payable(msg.sender);
    }

    /**
    * It will let the seller register its products in the supply chain
    * Each stock gonna have its own tracking id..
    * Seller need to give details of the product
    * He will also assign a carrier fee such that the carrier would decide whether this deal in his profit or not..
     */
    function register_product(
        string memory _name,
        string memory _description,
        uint _quantity,
        uint _priceEach
        ) external payable{
            Products memory product;
            product.currentState = State.productOnSale;
            product.trackingID = counter;
            product.seller = payable(msg.sender);
            product.name = _name;
            product.description = _description;
            product.quantity = _quantity;
            product.priceEach = _priceEach;
            balance += msg.value;
            product.carrier_fee = msg.value;
            records[counter] = product;
            counter++;
    }

    /**
    * This function will let the carriers assign themselves to a particular product on first come first serve basis
    * It will keep track of the carrier who assigned itself to the product and make its address payable
    * Also updates the state to 'carrierAssigned'
     */
    function assign_CarrierToWareHouse(uint id) external inState_1(State.productOnSale, id){
        records[id].carrier = payable(msg.sender);
        records[id].currentState = State.carrierAssigned;
    }

    /**
    * This function can be used by anyone to check the state of the product by giving its tracking id
     */
    function check_State(uint id) external view returns(State){
        return records[id].currentState;
    }

    /**
    * This function will only be used by the particular carrier assigned to the product
    * This will update the state to 'deliveredtoWareHouse' which will tell that the carrier has delivered the item to the warehouse.
     */
    function delivered_by_carrier(uint id) external onlyCarrier(State.carrierAssigned, id){
        records[id].currentState = State.deliveredToWarehouse;
    }

    /**
    * This function can only be used in the state when the product will be delivered to warehouse
    * It will stock the product in the wareHouse mapping and also give the fee to the carreir for its work
     */
    function stock_in_warehouse(uint id) external inState_1(State.deliveredToWarehouse, id) onlyOwner{
        records[id].currentState = State.inStock;
        wareHouse[records[id].name] = records[id];
        balance -= records[id].carrier_fee;
        payable(records[id].carrier).transfer(records[id].carrier_fee);
        emit inWareHouse(id, records[id].name, records[id].quantity);
    }

    /**
    * This function will be called by the buyer to check whether the item requested by the buyer is in stock or not
    * It also pushes the request in separate mapping which gonna track all the items bought by the buyers
    * changes state to itemRequested
     */
    function check_availability(string memory _name, uint _quantity, string memory _otherDetails) external InStock(_name, _quantity){
        Products memory product;
        product.currentState = State.itemRequested;
        product.trackingID = counter_;
        product.seller = wareHouse[_name].seller;
        product.buyer = msg.sender;
        product.name = _name;
        product.description = _otherDetails;
        product.quantity = _quantity;
        product.priceEach = wareHouse[_name].priceEach;
        items_Requested[counter_] = product;
        counter_++;
    } 

    /**
    * This function will only be called by the owner that is warehouse manager for permissing that the item is available to buy
    * It will also assign the carrier fee for the buyer;
     */
    function approve_availability(uint id, uint _carrierFee) external onlyOwner inState_2(State.itemRequested, id){
        items_Requested[id].carrier_fee = _carrierFee;
        items_Requested[id].currentState = State.itemApproved;
    }

    /**
    * This function will let the buyer buy that particular item after approval
    * It also makes sure that the buyer pays amount atleast the sum of original total amount plus the carrier fees
     */
    function buy_item(uint id) external inState_2(State.itemApproved, id) onlyBuyer(id) payable{
        require(msg.value >= (items_Requested[id].priceEach * items_Requested[id].quantity) + items_Requested[id].carrier_fee, "You haven't payed enough amount for buying this item up");
        balance += msg.value;
        items_Requested[id].totalAmount = items_Requested[id].priceEach * items_Requested[id].quantity;
        items_Requested[id].currentState = State.itemReady;
    }

    /**
    * This function gonna be called by any carrier company or service to deliver the item to the buyer
    * also changes the state
     */
    function assign_Carrier(uint id) external inState_2(State.itemReady, id) {
        items_Requested[id].carrier = payable(msg.sender);
        items_Requested[id].currentState = State.carrierAssigned;
    } 

    /**
    * This function will be called by the carrier of that particular item delivery when the item is delivered
    * Also changes the state
     */
    function item_delivered(uint id) external inState_2(State.carrierAssigned, id){
        require(items_Requested[id].carrier == msg.sender, "You aren't the carrier for this item");
        items_Requested[id].currentState = State.delivered;
    }

    /**
    * This function will be called by the buyer to tell that particular item is received
    * It will also do the necessary transactions
     */
    function item_received(uint id) external onlyBuyer(id) inState_2(State.delivered, id){
        balance -= items_Requested[id].totalAmount;
        balance -= items_Requested[id].carrier_fee;
        payable(items_Requested[id].seller).transfer(items_Requested[id].totalAmount);
        payable(items_Requested[id].carrier).transfer(items_Requested[id].carrier_fee);
    }

    /**
    * This function will give the balance of the contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}