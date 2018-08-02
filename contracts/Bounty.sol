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

    event logString(string);


    constructor(uint _posterDeposit) 
    public 
    payable
    {
        posterDeposit = _posterDeposit;
    }

    /** @dev Initialized Bounty contract with variables passed in from BountyBoard contract
    *   @param _owner - address of Bounty Poster
    *   @param _id - id of Bounty contract
    *   @param _description - description of bounty
    *   @param _voterDeposit - amount deposited by voter
    *   @param _challengerDeadline - deadline for submitting challenges
    *   @param _voterDeadline - deadline for submitting vote commits
    */
    function initializeBounty(
        address _owner,
        uint _id,
        string _description, 
        uint _voterDeposit, 
        uint _challengerDeadline, 
        uint _voterDeadline
    )
    private
    {
        owner = _owner;
        id = _id;
        status = uint(Status.Active);
        creationTimestamp = now;
        description = _description;
        voterDeposit = _voterDeposit;
        challengerDeadline = _challengerDeadline;
        voterDeadline = _voterDeadline;
    }


    // GENERAL FUNCTIONS \\

    /** @dev Returns the total amount held in the bounty
    Note: This is not particularly useful, the vote and challenger bounties need to be differentiated. 
    *   @return balance of contract
    */
    function getBountyTotal() 
    public
    view
    returns(uint balance)
    {
        return address(this).balance;
    }


    // CHALLENGER INTERFACE \\

    // function submitChallengeDeposit() 
    // public
    // payable
    // {         
    //     require(now < challengerDeadline, "Challenge deadline has expired");
    //     require(msg.value >= challengerDeposit, "Insufficient funds");
        
    //     Challenge storage _challenger = challenger[msg.sender];

    //     _challenger.deposit = msg.value;
    //     _challenger.submissionsAvailable++;
    //     challengerAddresses.push(msg.sender);
    // }

    /** @dev Maps sender address to deposit, IPFS Hash, timestamp, upVotes, and an array of voter addresses. Stores ETH deposited and updates the challenger addresss array
    *   @param _ipfsHash - Hash of content submitted to IPFS
    */
    function submitChallenge(string _ipfsHash) 
    public
    {
        require(now < challengerDeadline, "Challenge deadline has expired");
        
        Challenge storage _challenger = challenger[msg.sender];

        // require(_challenger.submissionsAvailable > 0, "Not enough submissions available");
        // require(_challenger.deposit > challengerDeposit * _challenger.submissionsAvailable, "Insufficient funds");

        _challenger.ipfsHash.push(_ipfsHash);
        _challenger.submissionTimestamp = now;
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