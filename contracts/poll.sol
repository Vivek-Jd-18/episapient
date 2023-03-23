// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Details for Poll
// 1. Create Vote Poll (Wallet Addresses, Poll Id, PollType, Time limit, Creator, Result, metadata)
// 2. Vote on a Poll (Poll Id)
// 3. Add Voters (Poll Id, WalletAddress)
// 4. End Poll (Poll Id)
// 5. Get Voting Results (Poll Id)
// 6. Get Poll Details (Poll Id) → Number of Yes, Number of No, Result, Poll Type

contract Vote{

    uint8 public pollCount;

    modifier onlyPollCreator(uint8 pollId) {
        if (pollDetails[pollId].pollCreator != msg.sender) {
            revert("you are not a poll creator");
        } else {
            _;
        }
    }

    modifier eligibleToVote(uint8 pollId) {
        if (voterDetails[msg.sender][pollId].pollId != pollId) {
            revert("you are not eligible to vote in this Poll");
        } else {
            _;
        }
    }

    struct PollInfo{
        uint256 pollId;
        string pollName;
        address pollCreator;
        bool pollStatus;
        uint256 pollMemberCount;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesMade;
        uint256 voteOptions;
        PollVoteOptions pollVoteOptions; 
    }

    struct PollVoteOptions{
        uint256 pollId;
        uint256[] optionsWithVoteCount;
    }

    struct VoterInfo{
        uint256 pollId;
        bool voted;
        uint256 vote;
    }

    struct WardenInfo{
        uint256[] pollId;
        uint256 currentPoll;
        bool haveActivePoll;
    }

    mapping(uint256=>PollInfo) public pollDetails;
    mapping(address=>mapping(uint256=>VoterInfo)) public voterDetails;
    mapping(address=>WardenInfo) wardenDetails;

    function createPoll(address[] memory members,uint256 timeLimit, uint256 voteOptions,string memory _pollName)public returns(uint[] memory _defaultVotes){

        require(wardenDetails[msg.sender].haveActivePoll==false,"You only can create a single Poll at a time");
        uint256 newPollId = pollCount+1;
        uint[] memory defaultVotes = new uint[](voteOptions);
        
        pollDetails[newPollId] = PollInfo(newPollId,_pollName,msg.sender,true,members.length,block.timestamp,timeLimit,0,voteOptions,PollVoteOptions(newPollId,defaultVotes));
        voterDetails[msg.sender][newPollId] = VoterInfo(newPollId,false,0);
        for(uint256 i;i<members.length;i++){
            voterDetails[members[i]][newPollId] = VoterInfo(newPollId,false,0);
        }
        pollCount+=1;
        wardenDetails[msg.sender].pollId.push(newPollId);
        wardenDetails[msg.sender].currentPoll=newPollId;
        wardenDetails[msg.sender].haveActivePoll=true;

        _defaultVotes=defaultVotes;
    }   

    function getPollDetails(uint8 pollId)public view returns(PollInfo memory pollInfo){
        PollInfo storage _pollInfo = pollDetails[pollId];
        pollInfo = _pollInfo;
    }

    function makeVote(uint8 pollId, uint256 _vote)public eligibleToVote(pollId){
        VoterInfo storage voter = voterDetails[msg.sender][pollId];
        PollInfo storage poll = pollDetails[pollId];

        require(poll.pollStatus,"Poll is closed for now");
        require(poll.endTime>block.timestamp,"poll has expired");
        require(poll.totalVotesMade<=poll.pollMemberCount,"Maximum Votes are made");
        require(voterDetails[msg.sender][pollId].voted==false,"Already voted");
        require(pollDetails[pollId].voteOptions>=_vote,"Invalid voting options");

        pollDetails[pollId].pollVoteOptions.optionsWithVoteCount[_vote]+=1;
        poll.totalVotesMade+=1;

        if(poll.totalVotesMade==poll.pollMemberCount){
            poll.pollStatus=false;
        }

        voter.voted=true;
        voter.vote=_vote;
    }

    function addVoters(uint8 pollId,address[] memory members) public onlyPollCreator(pollId) returns(uint256 _memberCount){
        pollDetails[pollId].pollMemberCount += members.length;
        for(uint256 i=0;i<members.length;i++){
            voterDetails[members[i]][pollId] = VoterInfo(pollId,false,0);
        }
        _memberCount = pollDetails[pollId].pollMemberCount;
    }

    function endPoll(uint8 pollId)public onlyPollCreator(pollId){
        PollInfo memory poll = pollDetails[pollId];
        poll.pollStatus=false;
        wardenDetails[msg.sender].haveActivePoll=false;
    }
    
    function poleResult(uint8 pollId)public view returns(PollVoteOptions memory result,string memory _pollName){
        require(pollDetails[pollId].endTime<block.timestamp,"Can't show result now, let Poll end first");
        result = pollDetails[pollId].pollVoteOptions;
        _pollName = pollDetails[pollId].pollName;
    }
}