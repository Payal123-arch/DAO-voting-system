// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DAOVoting
 * @dev A decentralized autonomous organization voting system
 */
contract DAOVoting {
    struct Proposal {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    struct ProposalInfo {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
    }

    address public admin;
    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    uint256 public memberCount;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
        members[msg.sender] = true;
        memberCount = 1;
        emit MemberAdded(msg.sender);
    }

    /**
     * @dev Create a new proposal for the DAO to vote on
     * @param _description Description of the proposal
     * @return proposalId The ID of the newly created proposal
     */
    function createProposal(string memory _description) external onlyMembers returns (uint256) {
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = _description;
        proposal.deadline = block.timestamp + votingPeriod;
        proposal.executed = false;
        
        emit ProposalCreated(proposalId, _description, proposal.deadline);
        return proposalId;
    }

    /**
     * @dev Vote on an existing proposal
     * @param _proposalId The ID of the proposal to vote on
     * @param _support Whether the voter supports the proposal or not
     */
    function vote(uint256 _proposalId, bool _support) external onlyMembers {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.forVotes += 1;
        } else {
            proposal.againstVotes += 1;
        }
        
        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Execute a proposal after voting period ends
     * @param _proposalId The ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.deadline, "Voting period not yet ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        
        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId);
        
        // In a real implementation, you would execute the proposal's actions here
    }

    /**
     * @dev Add a new member to the DAO
     * @param _member Address of the new member
     */
    function addMember(address _member) external onlyAdmin {
        require(!members[_member], "Already a member");
        members[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    /**
     * @dev Remove a member from the DAO
     * @param _member Address of the member to remove
     */
    function removeMember(address _member) external onlyAdmin {
        require(members[_member], "Not a member");
        require(_member != admin, "Cannot remove admin");
        members[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Get proposal details
     * @param _proposalId The ID of the proposal
     * @return ProposalInfo structure with proposal details
     */
    function getProposal(uint256 _proposalId) external view returns (ProposalInfo memory) {
        Proposal storage proposal = proposals[_proposalId];
        return ProposalInfo({
            id: proposal.id,
            description: proposal.description,
            forVotes: proposal.forVotes,
            againstVotes: proposal.againstVotes,
            deadline: proposal.deadline,
            executed: proposal.executed
        });
    }
}
