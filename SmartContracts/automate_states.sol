/*
    Sure, here's an example of how you can automate the creation of instances of a 'Patient' contract:
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Patient {
    enum State { Admitted, InProgress, Discharged }
    
    struct PatientRecord {
        State currentState;
        uint256 admissionDate;
        uint256 dischargeDate;
    }
    
    mapping(address => PatientRecord) public patients;
    address[] public patientAddresses;
    
    function registerPatient() public {
        PatientRecord memory newPatient;
        newPatient.currentState = State.Admitted;
        newPatient.admissionDate = block.timestamp;
        patients[msg.sender] = newPatient;
        patientAddresses.push(msg.sender);
    }
    
    function getCurrentState() public view returns (State) {
        return patients[msg.sender].currentState;
    }
    
    function updateState(State newState) public {
        require(newState != patients[msg.sender].currentState, "State is already updated.");
        patients[msg.sender].currentState = newState;
        if (newState == State.Discharged) {
            patients[msg.sender].dischargeDate = block.timestamp;
        }
    }
}
