pragma solidity ^0.4.18;

import "./Bounty.sol";

contract BountyBoard {

    Bounty bountyContract;
 
    address[] bountyContractAddresses;
    mapping(address => Bounty) bountyContracts; 
 
    event LogAddress(address);


// =================
// GENERAL FUNCTIONS
// =================



    function getAllBountyAddresses() 
    public 
    view 
    returns(address[]) 
    {
        return bountyContractAddresses;
    }



// ==================
// CONTRACT INTERFACE
// ==================



    function createBountyContract(
        uint posterDeposit, 
        string description, 
        uint voterDeposit, 
        uint challengeDuration, 
        uint voteDuration
        ) 
    public 
    payable
    returns(address)
    {        
        address owner = msg.sender;

        bountyContract = (new Bounty).value(msg.value)(
        posterDeposit,
        owner, 
        description, 
        voterDeposit, 
        challengeDuration, 
        voteDuration
        );

        bountyContractAddresses.push(bountyContract);
       
        return address(bountyContract);
    }
}