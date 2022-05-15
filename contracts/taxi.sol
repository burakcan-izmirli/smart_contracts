// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract taxi_business {

    address manager;
    address payable carDealer;
    uint contractBalance;
    uint fixedExpenses;
    uint participationFee;
    uint ownedCar;
    uint lastExpensesSent;
    uint lastProfitCalculation;
    address[] participantAddresses;   


    mapping (address => participant) participants ;
    mapping (address => bool) driverVotes;
    mapping (address => bool) carVotes;
    mapping (address => bool) pepurchaseVotes;
    mapping (address => bool) firingVotes;

    
    struct participant{
        address payable participantAddress;
        uint balance;
    }

    struct driverProposal{
        address payable driverAddress;
        uint salary;
        uint balance;
        uint approvalState;
        uint lastPaycheck;
        bool exist;
    }

    struct carProposal{
        uint32 carId;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }


    carProposal proposedCar;
    carProposal repurchaseProposedCar;
    driverProposal proposedDriver;
    driverProposal taxiDriver;
    driverProposal fireProposedDriver; 

    constructor(){
        manager = msg.sender;
        fixedExpenses = 10 ether;
        participationFee = 100 ether;
    }



    function join() public payable {
        require(participants[msg.sender].participantAddress == address(0), "You are already a participant.");
        require(participantAddresses.length < 9 , "There is no place for new participants.");
        require(msg.value < participationFee, "You don't have enough ether to participate.");

        participants[msg.sender] = participant(payable(msg.sender),0 ether);
        participantAddresses.push(msg.sender);

        contractBalance += participationFee;

    }

    function assignCarDealer(address payable assignedCarDealer) public{
        require(msg.sender == manager, "Only manager can assign car dealer.");
        carDealer = assignedCarDealer;
    }

    function carProposeToBusiness(uint32 carId, uint price, uint offerValidTime) public {
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

    function purchaseCar() public{
        require(block.timestamp < proposedCar.offerValidTime, "Offer is not valid anymore.");
        require(proposedCar.approvalState > (participantAddresses.length/2), "Car is not approved by majority.");
        require(contractBalance >= proposedCar.price, "There is no enough ether to buy car.");

        contractBalance -= proposedCar.price ;
        carDealer.transfer(proposedCar.price);
        ownedCar = proposedCar.carId;

    }

    function repurchaseCarPropose(uint32 carId, uint price, uint offerValidTime) public{
        require(msg.sender == carDealer, "Only car dealer can call this function.");
        repurchaseProposedCar = carProposal(carId,price,offerValidTime,0);

        for(uint i=0; i < participantAddresses.length; i++){
                pepurchaseVotes[participantAddresses[i]] = false; 
            }
    }

    function approveSellProposal() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(!carVotes[msg.sender], "Each participant can vote only once.");
        repurchaseProposedCar.approvalState +=1;
        pepurchaseVotes[msg.sender] = true;
    }

    function repurchaseCar() payable public{
        require(block.timestamp < repurchaseProposedCar.offerValidTime, "Offer is not valid anymore.");
        require(repurchaseProposedCar.approvalState > (participantAddresses.length/2), "Car is not approved by majority.");
        require(msg.value >= repurchaseProposedCar.price, "There is no enough ether to repurchase car."); 

       contractBalance += repurchaseProposedCar.price;
       delete ownedCar;

    }

    function proposeDriver(address payable driverAddress, uint salary) public {
        require(!taxiDriver.exist, "We already have taxi driver.");
        proposedDriver = driverProposal(driverAddress,salary,0,0,0,false);

        for(uint i=0; i < participantAddresses.length; i++){
            driverVotes[participantAddresses[i]] = false; 
            }
    }

    function approveDriver() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(!carVotes[msg.sender], "Each participant can vote only once.");
        proposedDriver.approvalState +=1;
        driverVotes[msg.sender] = true;
    }

    function setDriver() public {
        require(proposedDriver.approvalState > (participantAddresses.length/2), "The driver is not approved by majority.");
        taxiDriver = proposedDriver;
        delete proposedDriver;
    }

    function proposeFireDriver() public {
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        fireProposedDriver = taxiDriver;
        fireProposedDriver.approvalState = 0;

        for(uint i=0; i < participantAddresses.length; i++){
            firingVotes[participantAddresses[i]] = false; 
            }
    }

    function approveFireDriver() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(!firingVotes[msg.sender], "Each participant can vote only once.");
        fireProposedDriver.approvalState +=1;
        firingVotes[msg.sender] = true;
    }

    function fireDriver() public {
        require(fireProposedDriver.approvalState > (participantAddresses.length/2) || msg.sender == taxiDriver.driverAddress, "Either the fire proposal is not approved or you are not the driver.");
        taxiDriver.driverAddress.transfer(taxiDriver.balance);
        delete taxiDriver;
    }

    function leaveJob() public{
       require(msg.sender == taxiDriver.driverAddress, "You are not the driver."); 
       fireDriver();
    }

    function getCharge() public payable {
        contractBalance += msg.value;
    }

    function getSalary() public{
        require(msg.sender == taxiDriver.driverAddress, "You are not the driver."); 
        require(block.timestamp - taxiDriver.lastPaycheck >= 2629743, "Next paycheck time has not come yet. (One month)"); 
        contractBalance -= taxiDriver.salary;
        taxiDriver.balance += taxiDriver.salary;
        taxiDriver.lastPaycheck = block.timestamp;

        if(taxiDriver.balance>0){
        taxiDriver.driverAddress.transfer(taxiDriver.salary);
        }
    }
    function carExpenses() public{        
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(block.timestamp - lastExpensesSent >= 15778463, "Next sending expenses time has not come yet. (Six months) ");
        require(contractBalance >= fixedExpenses, "There is no enough ether to pay fixed expenses.");
        contractBalance -= fixedExpenses;

        carDealer.transfer(fixedExpenses);
        lastExpensesSent = block.timestamp;
    }
    
    function payDividend() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");
        require(block.timestamp - lastProfitCalculation >= 15778463, "Next calculating profit time has not come yet. (Six months)");

        uint totalProfit = contractBalance;
        uint profitPerParticipant = contractBalance/participantAddresses.length;

        for (uint i=0; i<participantAddresses.length; i++){
                participants[participantAddresses[i]].balance +=profitPerParticipant;
            }
    }

    function getDividend() public{
        require(participants[msg.sender].participantAddress != address(0), "You are not a participant.");

        if(participants[msg.sender].balance >0){
            participants[msg.sender].participantAddress.transfer(participants[msg.sender].balance);
        }
        participants[msg.sender].balance = 0;

    }

    fallback() external{
        revert();
    }
}