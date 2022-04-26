// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol"; 
contract SimpleElection is AccessControl {
    // Election details will be stored in these variables
    string public name;
    string public description;

    // The current state of the election can be tracked from these variables
    bool public isActive = false;
    bool public isEnded = false;

    // set view result status
    string private viewVote = "private";

    // stakeHolder structure
    struct stakeHolder {
        address stakeHolderAddress;
        string role;
    }

    // Create a new role identifier for the elcetion setup role
    bytes32 public constant SETUP_ROLE = keccak256("SETUP_ROLE");
 
    // Create a new role identifier for the chair person role
    bytes32 public constant CHAIR_PERSON_ROLE = keccak256("CHAIR_PERSON_ROLE");

    // Create a new role identifier for the voting role
    bytes32 public constant VOTING_ROLE = keccak256("VOTING_ROLE");

    // mapping of stake holders
    mapping (uint => stakeHolder) public stakeHolders;

    // Storing address of those voters who already voted
    mapping(address => bool) public voters;

    // Number of candidates in standing in the election
    uint256 public candidatesCount = 0;
    uint256 public adminCount = 0;
    uint256 public stakeHoldersCount = 0;

    // Structure of candidate standing in the election
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }


    // Storing candidates in a map
    mapping(uint256 => Candidate) public candidates;

    // Variables that store final election results
    uint256 public winnerVoteCount;

    ///@notice winnerId is an array to handle ties. In such cases, multiple Candidates would be "winners"
    uint256[] public winnerIds;

    // declaring chairperson
    
    /*
     *********************   PUBLIC FUNCTIONS   **************************
     */

    ///@param _nda : An array that contains the name and description of the election.
    constructor(string[] memory _nda) {
        name = _nda[0];
        description = _nda[1];
        setChairPersonRole(msg.sender);
        setupRole(msg.sender);
    }

     // functiom to add up stakeHolder
    function addStakeHolder (string memory _role) public {
        if(keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("teacher")) || keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("director"))) {
            setupRole(msg.sender);
            stakeHolders[stakeHoldersCount] = stakeHolder(msg.sender, _role);
            stakeHoldersCount ++;
        }
        _setupRole(VOTING_ROLE, msg.sender);
        stakeHolders[stakeHoldersCount] = stakeHolder(msg.sender, _role);
        stakeHoldersCount ++;
    }

    // Add a new admin to contract
    function addChairPerson(address _newAdmin) public onlyChairPerson(msg.sender) {
        grantRole(CHAIR_PERSON_ROLE, _newAdmin);
    }

    // Start the election and begin accepting votes
    function startElection() public onlyChairPerson(msg.sender) {
        isActive = true;
    }

    // Stop the election and stop receiving votes
    function endElection() public onlyChairPerson(msg.sender) {
        isEnded = true;
        _calcElectionWinner();
        emit ElectionEnded(winnerIds, winnerVoteCount);
    }

    // Cast vote for a candidate
    function vote(uint256 _candidateId)
        public
        electionIsStillOn
        electionIsActive
    {
        _vote(_candidateId, msg.sender);
    }

    function displayResult() public view canViewVote returns(uint256) {
        return winnerVoteCount;
    }

     // Retrieve all public votes
    function retrieveVotes () public view returns(Candidate[] memory) {
      Candidate[] memory _candidates = new Candidate[] (candidatesCount);
      for(uint i=0; i<candidatesCount; i++) {
        Candidate storage candidate = candidates[i];
            _candidates[i] = candidate;
      }
      return _candidates;
    }
 
    /*
     *********************   INTERNAL FUNCTIONS   **************************
     */

    function setupRole (address _stakeHolder) internal {
        // Grant the minter role to a specified account
        _setupRole(SETUP_ROLE, _stakeHolder);
        _setupRole(VOTING_ROLE, _stakeHolder);
    }

    function setChairPersonRole (address _chairperson) internal {
        _setupRole(CHAIR_PERSON_ROLE, _chairperson);
    }
 
    // Calculate election winner
    function _calcElectionWinner()
        internal
        returns (uint256, uint256[] memory)
    {
        for (uint256 i; i < candidatesCount; i++) {
            ///@notice If we have a larger value, update winnerVoteCount, and reset winnerId
            if (candidates[i].voteCount > winnerVoteCount) {
                winnerVoteCount = candidates[i].voteCount;
                delete winnerIds;
                winnerIds.push(candidates[i].id);
            }
            ///@notice If we encounter another candidate that has the maximum number of votes, we have a tie, and update winnerIds
            else if (candidates[i].voteCount == winnerVoteCount) {
                winnerIds.push(candidates[i].id);
            }
        }

        return (winnerVoteCount, winnerIds);
    }

    // Setting of variables and data, during the creation of election contract
    function _setUpElection(string[] memory _candidates) canSetup(msg.sender)
        public
    {
        require(
            _candidates.length > 0,
            "There should be at least 1 candidate."
        );
        for (uint256 i = 0; i < _candidates.length; i++) {
            _addCandidate(_candidates[i]);
        }
    }

    // Private function that effects voting on state variables
    function _vote(uint256 _candidateId, address _voter)
        internal
        onlyValidCandidate(_candidateId)
        canVote(_voter)
    {
        require(!voters[_voter], "Voter has already Voted!");
        voters[_voter] = true;
        candidates[_candidateId].voteCount++;

        emit VoteForCandidate(_candidateId, candidates[_candidateId].voteCount);
    }


    //Private function to add a candidate
    function _addCandidate(string memory _name) internal {
        candidates[candidatesCount] = Candidate({
            id: candidatesCount,
            name: _name,
            voteCount: 0
        });
        emit CandidateCreated(candidatesCount, _name);
        candidatesCount++;
    }

    // check is able to vote
    function isStakeHolder (address account) internal view returns ( bool ) {
        return hasRole(VOTING_ROLE, account);
    }

    // check if one can setup elction is teacher of chairperson
    function isAuthority (address account) internal view returns (bool) {
        return hasRole(SETUP_ROLE, account);
    }

    // check if msg.sender is chairPerson
    function isChairPerson (address account) internal view returns (bool) {
        return hasRole(CHAIR_PERSON_ROLE, account);
    }

    // change view vote 
    function changeViewStatus() public canSetup(msg.sender) {
        viewVote = "public";
        emit changedViewStatus("View status is now public");
    }


    /*
     *********************   MODIFIERS   **************************
     */
    modifier onlyChairPerson( address account) {
         require(isChairPerson(account), "Only chairperson can perform role");
         _;
    }

    modifier onlyValidCandidate(uint256 _candidateId) {
        require(
            _candidateId < candidatesCount && _candidateId >= 0,
            "Invalid candidate to Vote!"
        );
        _;
    }

    modifier electionIsStillOn() {
        require(!isEnded, "Election has ended!");
        _;
    }

    modifier electionIsActive() {
        require(isActive, "Election has not begun!");
        _;
    }

    modifier canVote (address account) {
        require(isStakeHolder(account), "Only stake holders can vote");
        _;
    }

    modifier canSetup (address account) {
        require(isAuthority(account), "Only chair person and teacher can setup election");
        _;
    }

    modifier canViewVote () {
        require(keccak256(abi.encodePacked(viewVote)) == keccak256(abi.encodePacked("public")), "only when votes are set to public can you view vote");
        _;
    }

    /*
     *********************   EVENTS & ERRORS  **************************
     */
    event ElectionEnded(uint256[] _winnerIds, uint256 _winnerVoteCount);
    event CandidateCreated(uint256 _candidateId, string _candidateName);
    event VoteForCandidate(uint256 _candidateId, uint256 _candidateVoteCount);
    event changedViewStatus(string _changed);
    error ElectionNotStarted();
    error ElectionHasEnded();
}