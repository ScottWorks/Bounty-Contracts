pragma solidity ^0.4.18;

import "./Bounty.sol";

contract BountyBoard {

    uint numBountyContracts = 0;
 
    address[] bountyContractAddresses;
    mapping(address => Bounty) bountyContracts; 
 
    event LogAddress(address);

    Bounty bountyContract;

    function getAllBountyAddresses() 
    public 
    view 
    returns(address[]) 
    {
        return bountyContractAddresses;
    }

    function createBountyContract(uint posterDeposit, string description, uint voterDeposit, uint challengerDeadline, uint voterDeadline) 
    public 
    payable
    returns(address)
    {        
        numBountyContracts++; 

        address owner = msg.sender;

        bountyContract = (new Bounty).value(msg.value)(
        posterDeposit,
        owner, 
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