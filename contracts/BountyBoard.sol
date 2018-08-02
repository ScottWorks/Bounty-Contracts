pragma solidity ^0.4.18;

import "./Bounty.sol";

contract BountyBoard {

    uint numBountyContracts = 0;
    address[] bountyContractAddresses;
    mapping(address => Bounty) bountyContracts; 
 
    Bounty bountyContract;

    function getAllBountyAddresses() 
    public 
    view 
    returns(address[]) 
    {
        return bountyContractAddresses;
    }

    function createBountyContract(
        string description,
        uint posterDeposit, 
        uint voterDeposit, 
        uint challengerDeadline, 
        uint voterDeadline
        ) 
    public 
    payable
    returns(address)
    {
        numBountyContracts++; 

        bountyContract = (new Bounty).value(msg.value)(posterDeposit);

        bountyContract.initializeBounty(
            msg.sender,
            numBountyContracts,
            description,
            voterDeposit, 
            challengerDeadline, 
            voterDeadline
        );

        bountyContractAddresses.push(bountyContract);
       
        return address(bountyContract);
    }
}