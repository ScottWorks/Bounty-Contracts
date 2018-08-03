pragma solidity ^0.4.18;

contract Bounty {

    address owner;
    uint id;
    uint posterDeposit;
    uint status;
    uint creationTimestamp;
    string description;
    uint voterDeposit;
    uint challengerDeadline;
    uint voterDeadline;
    bool isInitialized = false;

    enum Status {
        Active,
        Inactive
    }

    struct Challenge {
        string[] ipfsHash;
        uint submissionTimestamp;
        uint upVotes;
    }

    mapping(address => Challenge) challenger;
    address[] public challengerAddresses;

    struct Vote {
        uint deposit;
        uint commitTimestamp;
        bytes32 hashedCommit; 
        uint upVotesAvailable;
    }

    mapping(address => Vote) voter;
    address[] public voterAddresses;

    constructor(
        uint _posterDeposit, 
        address _owner,
        uint _id, 
        string _description,
        uint _voterDeposit,
        uint _challengerDeadline,
        uint _voterDeadline
        ) 
    public 
    payable
    {
        require(msg.value >= _posterDeposit, "Insufficient funds, ETH sent must be equal to bounty deposit");

        require(!isInitialized, "Bounty is not modifiable");

        posterDeposit = _posterDeposit;
        owner = _owner;
        id = _id;
        status = uint(Status.Active);
        creationTimestamp = now;
        description = _description;
        voterDeposit = _voterDeposit;
        challengerDeadline = _challengerDeadline;
        voterDeadline = _voterDeadline;

        isInitialized = true;
    }


    // GENERAL FUNCTIONS \\

    function getBountyParameters()
    public
    view
    returns(
        address _owner,
        uint _posterDeposit, 
        uint _id, 
        string _description,
        uint _voterDeposit,
        uint _challengerDeadline,
        uint _voterDeadline
    )
    {
        return(
            owner,
            posterDeposit, 
            id, 
            description,
            voterDeposit,
            challengerDeadline,
            voterDeadline
        );
    }


    // CHALLENGER INTERFACE \\

    /** @dev Maps sender address to deposit, IPFS Hash, timestamp, upVotes, and an array of voter addresses. Stores ETH deposited and updates the challenger addresss array
    *   @param _ipfsHash - Hash of content submitted to IPFS
    */
    function submitChallenge(string _ipfsHash) 
    public
    {
        require(now < challengerDeadline, "Challenge deadline has expired");
        
        Challenge storage _challenger = challenger[msg.sender];

        _challenger.ipfsHash.push(_ipfsHash);
        _challenger.submissionTimestamp = now;

        challengerAddresses.push(msg.sender);
    }   


    /** @dev Returns array containing challenger addresses
    *   @return array of challenger addresses
    */
    function getAllChallengerAddresses() 
    public
    view 
    returns(address[])
    {
        return challengerAddresses;
    }


    // VOTER INTERFACE \\    

    function submitVoteDeposit()
    public
    payable
    {
        require(now < voterDeadline, "Commit deadline has expired");
        require(now > challengerDeadline, "Challenge period has not ended yet");
        require(msg.value >= voterDeposit, "Insufficient funds");

        Vote storage _voter = voter[msg.sender];

        _voter.deposit = msg.value;
        _voter.upVotesAvailable++;
        voterAddresses.push(msg.sender);
    }

    function submitCommit(bytes32 commit) public {
        require(now < voterDeadline, "Commit deadline has expired");
        require(now > challengerDeadline, "Challenge period has not ended yet");

        Vote storage _voter = voter[msg.sender];

        require(_voter.upVotesAvailable > 0, "Not enough votes available");
        require(_voter.deposit > voterDeposit * _voter.upVotesAvailable, "Insufficient funds");

        _voter.commitTimestamp = now;
        _voter.hashedCommit = commit;
        _voter.upVotesAvailable--;
    }

    function revealCommit(address challengerAddress, string secret) public {
        require(now < voterDeadline + 2 days, "Reveal deadline has expired");
        require(now > voterDeadline, "Commit period has not ended yet");

        Vote storage _voter = voter[msg.sender];

        bytes32 hashedVote = keccak256(abi.encodePacked(challengerAddress, secret));

        require(_voter.hashedCommit == hashedVote, "Previously submitted commit does not match reveal hash");

        Challenge storage _challenger = challenger[challengerAddress];

        _challenger.upVotes++; 
    }
}