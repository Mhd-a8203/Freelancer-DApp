// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract project {
    enum Status {COMPLETED, PENDING, CANCELED}

    address payable public freelancer;
    address payable public employer;
    uint public deadline;
    uint public price;
    uint public remainingPayment;
    uint public createdAt;
    Status public status;

    bool locked = false;

    struct Request {
        string description;
        uint amount;
        bool locked;
        bool paid;
    }

    Request[] public requests;

    constructor(address payable _freelancer, uint _deadline) payable {
        employer = payable(msg.sender);
        freelancer = _freelancer;
        createdAt = block.timestamp;
        deadline = block.timestamp + _deadline;
        price = msg.value;
        remainingPayment = msg.value;
        status = Status.PENDING;
    }

    modifier onlyFreelancer() {
        require(msg.sender == freelancer, "only Freelancer!");
        _;
    }

    modifier onlyPendingProject() {
        require(status == Status.PENDING, "only Pending!");
        _;
    }

    modifier onlyEmployer() {
        require(msg.sender == employer, "only Employer!");
        _;
    } 
    
    event RequestCreated(string _description, uint amount, bool locked, bool paid);
    event RequestUnlocked(bool locked);
    event RequestPaid(address receiver, uint amount);
    event ProjectCompleted(address employer, address freelancer, uint amount, Status status);
    event ProjectCanceled(uint remainingPayment, Status status);

    function creatRequest(string memory _description, uint _amount) public onlyFreelancer onlyPendingProject {
        require(_amount <= remainingPayment, "high request price!");
        Request memory request = Request({
            description: _description,
            amount: _amount,
            locked: true,
            paid: false
        });
         
        requests.push(request);
        emit RequestCreated(request.description, request.amount, request.locked, request.paid);
    }

    function unlockRequest(uint _index) public onlyEmployer onlyPendingProject {
        Request storage request = requests[_index];
        require(request.locked, "Already unlocked!");
        request.locked = false;

        emit RequestUnlocked(request.locked);
    }

    function payRequest(uint _index) public onlyFreelancer {
        require(!locked, "Reentrant detected!");
        Request storage request = requests[_index];
        require(!request.locked, "request is locked!");
        require(!request.paid, "already paid!");
        locked = true;
        (bool success, bytes memory transaction) = freelancer.call{value: request.amount}("");
        require(success, "transaction failed!");
        request.paid = true;
        locked = false;

        emit RequestPaid(msg.sender, request.amount);
    } 

    function complieteProject() public onlyEmployer onlyPendingProject{
        require(!locked, "Reentrant detected!");
        locked = true; 
        (bool success, bytes memory transaction) = freelancer.call{value: remainingPayment}("");
        require(success, "transaction failed!");
        status = Status.COMPLETED;
        locked = false;

        emit ProjectCompleted(employer, freelancer, remainingPayment, status);
    }

    function cancelProject() public onlyEmployer onlyPendingProject{
        require(!locked, "Reentrant detected!");
        locked = true; 
        (bool success, bytes memory transaction) = employer.call{value: remainingPayment}("");
        require(success, "transaction failed!");
        status = Status.CANCELED;
        locked = false;

        emit ProjectCanceled(remainingPayment, status);
    } 

    function increaseDeadline(uint _deadline) public onlyEmployer onlyPendingProject{
        deadline += _deadline;
    }
}
