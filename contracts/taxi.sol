// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract taxi_business {

    address manager;
    address carDealer;
    uint contractBalance;
    uint fixedExpenses;
    uint participationFee;
    uint ownedCar;
    address[] participantAddresses;    

    mapping (address => participant) participants ;
    mapping (address => bool) driverVotes;
    mapping (address => bool) carVotes;
    mapping (address => bool) pepurchaseVotes;

    
    struct participant{
        address participantAddress;
        uint balance;
    }

    struct taxiDriver{
        uint salary;
    }

    struct carProposal{
        uint carId;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }

    carProposal proposedCar;

    constructor(){
        manager = msg.sender;
        fixedExpenses = 10 ether;
        participationFee = 100 ether;
    }



    function join() public payable {
        require(participants[msg.sender].participantAddress == address(0), "You are already a participant.");
        require(participantAddresses.length < 9 , "There is no place for new participants.");
        require(msg.value < participationFee, "You don't have enough ether to participate.");

        participants[msg.sender] = participant(msg.sender,0 ether);
        participantAddresses.push(msg.sender);

        contractBalance += participationFee;

    }

    function assignCarDealer(address payable assignedCarDealer) public{
        require(msg.sender == manager, "Only manager can assign car dealer.");
        carDealer = assignedCarDealer;
    }

    function carProposeToBusiness(uint carId, uint price, uint offerValidTime) public {
        require(msg.sender == carDealer,"Only car dealer can propose a car.");
        proposedCar = carProposal(carId,price,offerValidTime,0);

        for(uint i=0; i < participantAddresses.length; i++){
            carVotes[participantAddresses[i]] = false; 
        }
    }

    function approvePurchaseCar() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(!carVotes[msg.sender], "Each participant can vote only once.");
        proposedCar.approvalState +=1;
        carVotes[msg.sender] = true;
    }


}