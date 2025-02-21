// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TitanSentara {
    address public admin;
    bool public votingActive;

    constructor() {
        admin = msg.sender;
        admins[msg.sender] = true;
        adminCount = 1;
    }

    function claimAdmin() external {
        require(admin == address(0), "Admin already set");
        admin = msg.sender;
    }

    function startVoting() external onlyAdmin {
        votingActive = true;
    }

    function endVoting() external onlyAdmin {
        votingActive = false;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can perform this action");
        _;
    }

    modifier onlyDuringVoting() {
        require(
            block.timestamp >= voteStartTime && block.timestamp <= voteEndTime,
            "Voting is not active"
        );
        _;
    }

    struct Position {
        uint256 id;
        string name;
        bool exists;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 positionId;
        uint256 voteCount;
        bool exists;
    }

    uint256 private _positionCounter;
    uint256 private _candidateCounter;
    mapping(uint256 => Position) public positions;
    mapping(uint256 => Candidate) public candidates;
    mapping(uint256 => uint256[]) public positionCandidates;

    uint256 public voteCost;
    uint256 public voteStartTime;
    uint256 public voteEndTime;

    mapping(address => bool) public admins;
    uint256 public adminCount;

    event PositionAdded(uint256 indexed positionId, string name);
    event CandidateAdded(uint256 indexed candidateId, string name, uint256 positionId);
    event VotesCast(address indexed voter, uint256 positionId, uint256 candidateId, uint256 quantity);
    event VotingParametersSet(uint256 voteCost, uint256 startTime, uint256 endTime);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    function setVotingParameters(
        uint256 _voteCost,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyAdmin {
        require(_endTime > _startTime, "Invalid voting time range");
        voteCost = _voteCost;
        voteStartTime = _startTime;
        voteEndTime = _endTime;
        emit VotingParametersSet(_voteCost, _startTime, _endTime);
    }

    function addPosition(string memory name) external onlyAdmin {
        require(bytes(name).length > 0, "Invalid name");
        require(!_positionExists(name), "Position exists");

        _positionCounter++;
        positions[_positionCounter] = Position({
            id: _positionCounter,
            name: name,
            exists: true
        });
        emit PositionAdded(_positionCounter, name);
    }

    function addCandidate(
        string memory name,
        uint256 positionId
    ) external onlyAdmin {
        require(positions[positionId].exists, "Invalid position");
        require(bytes(name).length >= 2, "Name too short");
        require(!_candidateExistsInPosition(name, positionId), "Candidate exists");

        _candidateCounter++;
        candidates[_candidateCounter] = Candidate({
            id: _candidateCounter,
            name: name,
            positionId: positionId,
            voteCount: 0,
            exists: true
        });
        positionCandidates[positionId].push(_candidateCounter);
        emit CandidateAdded(_candidateCounter, name, positionId);
    }

    function castVotes(
        uint256 positionId,
        uint256 candidateId,
        uint256 quantity
    ) external payable onlyDuringVoting {
        require(positions[positionId].exists, "Invalid position");
        require(candidates[candidateId].exists, "Invalid candidate");
        require(candidates[candidateId].positionId == positionId, "Candidate mismatch");
        require(quantity > 0, "Minimum 1 vote");
        require(msg.value >= voteCost * quantity, "Insufficient funds");

        candidates[candidateId].voteCount += quantity;
        emit VotesCast(msg.sender, positionId, candidateId, quantity);
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        require(!admins[newAdmin], "Already admin");

        admins[newAdmin] = true;
        adminCount++;
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address adminToRemove) external onlyAdmin {
        require(adminToRemove != address(0), "Invalid address");
        require(admins[adminToRemove], "Not an admin");
        require(adminCount > 1, "Cannot remove last admin");

        admins[adminToRemove] = false;
        adminCount--;
        emit AdminRemoved(adminToRemove);
    }

    function getCandidatesByPosition(uint256 positionId) external view returns (Candidate[] memory) {
        require(positions[positionId].exists, "Invalid position");
        uint256[] storage candidateIds = positionCandidates[positionId];
        Candidate[] memory result = new Candidate[](candidateIds.length);
        for (uint256 i = 0; i < candidateIds.length; i++) {
            result[i] = candidates[candidateIds[i]];
        }
        return result;
    }

    function _positionExists(string memory name) private view returns (bool) {
        for (uint256 i = 1; i <= _positionCounter; i++) {
            if (keccak256(bytes(positions[i].name)) == keccak256(bytes(name))) {
                return true;
            }
        }
        return false;
    }

    function _candidateExistsInPosition(string memory name, uint256 positionId) private view returns (bool) {
        uint256[] storage candidateIds = positionCandidates[positionId];
        for (uint256 i = 0; i < candidateIds.length; i++) {
            if (keccak256(bytes(candidates[candidateIds[i]].name)) == keccak256(bytes(name))) {
                return true;
            }
        }
        return false;
    }
}