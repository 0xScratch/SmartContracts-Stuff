// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding{

    /**
    @dev This is a struct which will usually store the newly created objects for Campaigns
     */
    struct Campaigns{
        State currentState;

        address campaign_owner;
        string name;
        uint target_amount;
        uint deadline;
        uint balance;
        uint leftAmount;
        bool success;
    }

    // States
    enum State{Campaign_Active, Campaign_Ended}

    // Events
    event Campaign_Launched(string name, uint target, uint deadline);
    event Campaign_Successful(string name, uint target);
    event Campaign_Failed(string name, uint target);

    // Modifiers & Errors

    ///The campaign has been ended due to the passed deadline
    error Deadline_hit();

    /**
    @dev This modifier checks whether the campaign in which the user is funding is still active or not
     */
    modifier is_valid(uint _id){
        require(Campaign_Records[_id].currentState == State.Campaign_Active, "Campaign has already ended");
        if (block.timestamp >= Campaign_Records[_id].deadline){
            Campaign_Records[_id].currentState = State.Campaign_Ended;
            revert Deadline_hit();
        }
        require(msg.value <= Campaign_Records[_id].leftAmount, "You are trying to transfer more ethers than required..");
        _;
    }

    /**
    @dev This modifier checks whether the function to be called in currentState is possible or not
     */
    modifier inState(State _state, uint _id){
        require(_state == Campaign_Records[_id].currentState, "You can't call this function in currentState");
        _;
    }

    modifier onlyOwner(uint _id){
        require(msg.sender == Campaign_Records[_id].campaign_owner, "You can't call this function in currentState");
        _;
    }

    uint public counter;
    mapping(uint => Campaigns) private Campaign_Records;
    mapping(uint => mapping(address => uint)) public fund_Records;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    /**
    @dev This function will help the user start a crowdfunding scenario..
    @notice Make sure to remember the ids while creating or funding in any campaign..
    @param _name -> This variable will let a name assigned to that contract
    @param _targetAmount -> This variable will let a target value assigned to that campaign
    @param _deadline -> This will let the campaign_owner set the required deadline
     */
    function create_Campaign(
        string memory _name,
        uint _targetAmount,
        uint _deadline
    ) external {
        require(_targetAmount > 0, "The target amount should be greater than zero");
        Campaigns memory campaign;
        campaign.name = _name;
        campaign.target_amount = _targetAmount;
        campaign.deadline = block.timestamp + _deadline;
        campaign.campaign_owner = payable(msg.sender);
        campaign.leftAmount = _targetAmount;
        campaign.currentState = State.Campaign_Active;
        Campaign_Records[counter] = campaign;
        counter++;
    }

    /**
    @notice This function will be called by the users who are willing to fund in a campaign
    @param id -> This will be needed to refer the particular type of campaign you wanna fund in..
     */
    function contribute(uint id) external inState(State.Campaign_Active, id)  is_valid(id) payable{
        Campaign_Records[id].balance += msg.value;
        fund_Records[id][msg.sender] = msg.value;
        if (Campaign_Records[id].balance >= Campaign_Records[id].target_amount){
            Campaign_Records[id].currentState = State.Campaign_Ended;
            Campaign_Records[id].success = true;
            Campaign_Records[id].leftAmount = 0;
        }else{
            Campaign_Records[id].leftAmount = Campaign_Records[id].target_amount - Campaign_Records[id].balance;
        }
    }

    /**
    @notice This function will let the owner of the campaign check status
     */
    function check_Status(uint id) external view onlyOwner(id) returns(string memory) {
        string memory status;
        if (block.timestamp > Campaign_Records[id].deadline || Campaign_Records[id].success == true){
            if (Campaign_Records[id].balance >= Campaign_Records[id].target_amount){
                status = "success";
            } else{
                status = "failed";
            }
        }else{
            status = "ongoing";
        }

        return status;
    }

    /**
    @notice This function will let the owner of the campaign hit the deadline if contribute function doesn't do so..
     */
    function hit_deadline(uint id) external onlyOwner(id){
        if (block.timestamp > Campaign_Records[id].deadline){
            Campaign_Records[id].currentState = State.Campaign_Ended;
        }
    }

    /**
    @notice This function will let the owner of the campaign withdraw all the contributed funds if the campaign hit a success..
     */
    function withdraw_Owner(uint id) external onlyOwner(id) inState(State.Campaign_Ended, id){
        require(Campaign_Records[id].success == true, "You can't withdraw the funds");
        uint funds = Campaign_Records[id].balance;
        Campaign_Records[id].balance = 0;
        payable(Campaign_Records[id].campaign_owner).transfer(funds);
    }

    /**
    @notice This function will let the contributors take their funds back if campaign didn't get successful
     */
    function withdraw_Contributor(uint id) external inState(State.Campaign_Ended, id){
        require(fund_Records[id][msg.sender] > 0, "You didn't contribute to this campaign");
        require(Campaign_Records[id].success == false, "You can't withdraw your contributed funds");
        uint funds = fund_Records[id][msg.sender];
        fund_Records[id][msg.sender] = 0;
        Campaign_Records[id].balance = 0;
        payable(msg.sender).transfer(funds);
    }
}