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
    event VotingPeriodChanged(uint256 newPeriod);

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

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp >= proposal.deadline, "Voting period not yet ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");

        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    function addMember(address _member) external onlyAdmin {
        require(!members[_member], "Already a member");
        members[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyAdmin {
        require(members[_member], "Not a member");
        require(_member != admin, "Cannot remove admin");
        members[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

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

    // ✅ New Functions Below

    function changeVotingPeriod(uint256 _newPeriod) external onlyAdmin {
        require(_newPeriod > 0, "Voting period must be positive");
        votingPeriod = _newPeriod;
        emit VotingPeriodChanged(_newPeriod);
    }

    function hasUserVoted(uint256 _proposalId, address _user) external view returns (bool) {
        return proposals[_proposalId].hasVoted[_user];
    }

    function getActiveProposals() external view returns (ProposalInfo[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.timestamp < proposals[i].deadline && !proposals[i].executed) {
                activeCount++;
            }
        }

        ProposalInfo[] memory activeProposals = new ProposalInfo[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (block.timestamp < proposals[i].deadline && !proposals[i].executed) {
                Proposal storage p = proposals[i];
                activeProposals[index] = ProposalInfo({
                    id: p.id,
                    description: p.description,
                    forVotes: p.forVotes,
                    againstVotes: p.againstVotes,
                    deadline: p.deadline,
                    executed: p.executed
                });
                index++;
            }
        }
        return activeProposals;
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    function resetProposal(uint256 _proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Cannot reset executed proposal");

        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.deadline = block.timestamp + votingPeriod;

        // Reset all votes (insecure in production, just for example/testing)
        for (uint256 i = 0; i < memberCount; i++) {
            proposal.hasVoted[address(uint160(i))] = false;
        }
    }
}
