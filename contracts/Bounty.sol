pragma solidity ^0.4.18;

contract Bounty {



// =========
// VARIABLES
// =========



    address owner;
    uint id = 0;
    uint posterDeposit;
    uint status;
    uint creationTimestamp;
    string description;
    uint voterDeposit;
    uint challengeDuration;
    uint voteDuration;
    bool isInitialized = false;

    enum Status {
        Active,
        Inactive
    }

    struct Challenge {
        address challengerAddress;
        string[] ipfsHash;
        uint submissionTimestamp;
        uint upVotes;
    }

    mapping(uint => Challenge) challengerId;
    uint[] challengerIds;

    struct Vote {
        uint deposit;
        uint commitTimestamp;
        bytes32 commitHash; 
        uint upVotesAvailable;
    }

    mapping(address => Vote) voter;
    address[] voterAddresses;

    modifier isChallengePeriod(){
        require(now < creationTimestamp + challengeDuration, "Challenge period has ended.");
        _;
    }

    modifier isCommitPeriod(){
        require(now > creationTimestamp + challengeDuration, "Commit period has not started.");
        require(now < creationTimestamp + challengeDuration + voteDuration, "Commit period has ended.");
        _;
    }

    modifier isRevealPeriod(){
        require(now > creationTimestamp + challengeDuration + voteDuration, "Reveal period has not started.");
        require(now < creationTimestamp + challengeDuration + voteDuration + 2 days, "Reveal period has ended.");
        _;
    }
    
    modifier isPollingPeriod(){
        require(now > creationTimestamp + challengeDuration + voteDuration + 2 days, "Polling period has not started.");
        _;
    }

    event LogString(bytes stringgy);
    event LogHash(bytes20 _address, bytes32 _commitHash, bytes32 _revealHash);



// ===========
// CONSTRUCTOR
// ===========



    constructor(
        uint _posterDeposit, 
        address _owner,
        uint _id, 
        string _description,
        uint _voterDeposit,
        uint _challengerDeadline,
        uint _voteDuration
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
        challengeDuration = _challengerDeadline;
        voteDuration = _voteDuration;

        isInitialized = true;
    }



// =================
// GENERAL FUNCTIONS
// =================



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
        uint _voteDuration
    )
    {
        return(
            owner,
            posterDeposit, 
            id, 
            description,
            voterDeposit,
            challengeDuration,
            voteDuration
        );
    }



// ====================
// CHALLENGER INTERFACE
// ====================



    /** @dev Maps sender address to deposit, IPFS Hash, timestamp, upVotes, and an array of voter addresses. Stores ETH deposited and updates the challenger addresss array
    *   @param _ipfsHash - Hash of content submitted to IPFS
    */
    function submitChallenge(string _ipfsHash) 
    public
    isChallengePeriod
    {
        
        // require(now < challengeDuration, "Challenge deadline has expired");
        

        Challenge storage _challenger = challengerId[id];

        _challenger.ipfsHash.push(_ipfsHash);
        _challenger.challengerAddress = msg.sender;
        _challenger.submissionTimestamp = now;

        challengerIds.push(id);
        id++; 
    }   


    /** @dev Returns array containing challenger addresses
    *   @return array of challenger addresses
    */
    function getAllChallengerIds() 
    public
    view 
    returns(uint[])
    {
        return challengerIds;
    }



// ===============
// VOTER INTERFACE
// ===============



    function submitVoteDeposit()
    public
    payable
    // isCommitPeriod
    {
        // require(now < voteDuration, "Commit deadline has expired");
        // require(now > challengeDuration, "Challenge period has not ended yet");
        require(msg.value >= voterDeposit, "Insufficient funds");

        Vote storage _voter = voter[msg.sender];

        _voter.deposit = msg.value;
        _voter.upVotesAvailable++;
        voterAddresses.push(msg.sender);
    }

    // function submitCommit(bytes32 commitHash) public {
    function submitCommit(bytes20 challengerAddress, uint salt) 
    public 
    // isCommitPeriod
    {

        // require(now < voteDuration, "Commit deadline has expired");
        // require(now > challengeDuration, "Challenge period has not ended yet");

        Vote storage _voter = voter[msg.sender];

        require(_voter.upVotesAvailable > 0, "Not enough votes available");
        require(_voter.deposit >= voterDeposit * _voter.upVotesAvailable, "Insufficient funds");

        _voter.commitTimestamp = now;
        _voter.commitHash = keccak256(abi.encodePacked(challengerAddress, salt));
        _voter.upVotesAvailable--;
    }


    function revealCommit(bytes20 challengerAddress, uint salt) 
    public 
    // isRevealPeriod
    {
        // require(now < voteDuration + 2 days, "Reveal deadline has expired");
        // require(now > voteDuration, "Commit period has not ended yet");

        Vote storage _voter = voter[msg.sender];

        bytes32 revealHash = keccak256(abi.encodePacked(challengerAddress, salt));

        emit LogHash(challengerAddress, _voter.commitHash, revealHash);

        // require(_voter.commitHash == revealHash, "Previously submitted commit does not match reveal hash");

        // Challenge storage _challenger = challengerId[_challengerId];

        // _challenger.upVotes++; 
    }
}