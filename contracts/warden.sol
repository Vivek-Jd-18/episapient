// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Community {
    uint256 public communityCount;

    struct CommunityStructure {
        string communityName;
        uint256 communityId;
        address[] communityMembers;
        address[] communityWardens;
        uint256 membersCount;
        uint256 wardensCount;
    }

    mapping(uint256 => CommunityStructure) public communityDetails;

    function createCommunity(uint256 cid, string memory name) public {
        communityDetails[cid].communityName = name;
        communityDetails[cid].communityId = cid;
        communityCount++;
    }

    function addMembers(uint256 cid, address _member) public {
        communityDetails[cid].communityMembers.push(_member);
        communityDetails[cid].membersCount++;
    }

    // Remove the last element.
    function _removeAddress(address[] storage arr, address item)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    function removeMembers(uint256 cid, address _member) public {
        _removeAddress(communityDetails[cid].communityMembers, _member);
        communityDetails[cid].membersCount--;
    }
}

contract Warden is Community {
    IERC20 public token;
    address payable owner;
    uint256 public wardenCount;
    uint256 public wardensPerCommunityRate;
    uint256 public rewardsPerBlock;
    uint256 public minimumStakeAmount;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not an owner");
        _;
    }

    function changeToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    struct WardenStructure {
        address wardenAddress;
        uint256[] activeInCategories;
        uint256 tokensStaked;
        uint256 stakingTime;
    }

    mapping(address => WardenStructure) public wardenDetails;

    mapping(uint256 => uint256) public currentWardenCount;

    //wardens per community memebers
    mapping(uint256 => uint256) public wardensPerCommunity;

    function stakeTokens(uint256 amount)
        internal
        returns (uint256 amountStaked)
    {
        require(amount >= minimumStakeAmount, "stake amount is not sufficient");
        require(
            amount <= token.allowance(msg.sender, address(this)),
            "Less Allowance"
        );
        token.transferFrom(msg.sender, address(this), amount);
        amountStaked = amount;
    }

    function unStakeTokens(address _address) internal {
        require(
            wardenDetails[_address].tokensStaked > 0,
            "You don't have any tokens staked yet"
        );
        token.transfer(msg.sender, wardenDetails[msg.sender].tokensStaked);
    }

    function ctrBal(address _address) public view returns (uint256 _balance) {
        _balance = token.balanceOf(_address);
    }

    // setWardensPerThousandMember(int) : this will define number of wardens a community can have per 1K members
    function changeWardensPerCommunityRate(uint256 _wardensPerCommunityRate)
        public
    {
        wardensPerCommunityRate = _wardensPerCommunityRate;
    }

    // MemberCapacity: total community members /  setWardensPerThousandMember
    function memberCapacity(uint256 communityId) internal {
        // currentWardenCount[communityId] =
        //     communityDetails[communityId].membersCount /
        //     wardensPerCommunityRate;
    }

    // becomeWarden(stackAmount, categoryId) - Check if user is whitelisted, Check if currentWardenCount < memberCapacity
    function becomeWarden(uint256 communityId, uint256 amount)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        uint256 totalMembers = communityDetails[communityId].membersCount;
        uint256 totalWardens = communityDetails[communityId].wardensCount;

        if (totalWardens > 0) {
            uint256 Res = totalMembers / wardensPerCommunityRate;
            require(Res > totalWardens, "Warden Limit Exceeded");
        }

        require(
            wardenDetails[msg.sender].tokensStaked <= 0,
            "You already are a warden!"
        );
        uint256 amountStaked = stakeTokens(amount);
        require(amountStaked > 0, "Stake Some Tokens to become a Warden");

        wardenDetails[msg.sender].wardenAddress = msg.sender;
        wardenDetails[msg.sender].activeInCategories.push(communityId);
        wardenDetails[msg.sender].tokensStaked = amountStaked;
        wardenDetails[msg.sender].stakingTime = block.timestamp;

        wardensPerCommunity[communityId]++;

        communityDetails[communityId].wardensCount++;
        communityDetails[communityId].communityWardens.push(msg.sender);

        wardenCount++;
        _wardenCount = wardenCount;
    }

    // Remove the last element.
    function removeItem(uint256[] storage arr, uint256 item)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    // Remove the last element.
    function removeAddress(address[] storage arr, address item)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                for (uint256 j = i; j < arr.length - 1; j++) {
                    arr[j] = arr[j + 1];
                }
                arr.pop();
                return true;
            }
        }
        return false;
    }

    // removeWarden(walletAddress, categoryId) - Remove warden of particular category - Only Owner / Contract Only
    function removeWarden(uint256 communityId, address wardenAddress)
        public
        returns (uint256 _wardenCount)
    {
        //updates warden
        // updateWardens(communityId);

        require(
            wardenDetails[wardenAddress].activeInCategories.length > 0,
            "It's Not a Warden"
        );

        unStakeTokens(wardenAddress);
        removeItem(
            wardenDetails[wardenAddress].activeInCategories,
            communityId
        );
        wardenDetails[wardenAddress].tokensStaked = 0;
        wardenDetails[wardenAddress].stakingTime = 0;

        communityDetails[communityId].wardensCount--;
        removeAddress(
            communityDetails[communityId].communityWardens,
            wardenAddress
        );

        wardensPerCommunity[communityId]--;
        wardenCount--;
        _wardenCount = wardenCount;
    }

    // resign(categoryId) : will unstake the tokens and user will be removed from warden position
    function resign(uint256 communityId) public returns (uint256 _wardenCount) {
        require(
            wardenDetails[msg.sender].activeInCategories.length > 0,
            "You're not an Warden"
        );

        //updates warden
        updateWardens(communityId);

        unStakeTokens(msg.sender);
        removeItem(wardenDetails[msg.sender].activeInCategories, communityId);
        wardenDetails[msg.sender].tokensStaked = 0;
        wardenDetails[msg.sender].stakingTime = 0;

        communityDetails[communityId].wardensCount--;
        removeAddress(
            communityDetails[communityId].communityWardens,
            msg.sender
        );

        wardensPerCommunity[communityId]--;
        wardenCount--;
        _wardenCount = wardenCount;
    }

    // isWarden(walletAddress) : will check if user is warden
    function isWarden(address _address) public view returns (bool _isIt) {
        if (wardenDetails[_address].activeInCategories.length > 0) {
            _isIt = true;
        } else {
            _isIt = false;
        }
    }

    // setRewardPerBlock : Only Owner
    function setRewardPerBlock(uint256 newRewardsPerBlock) public onlyOwner {
        rewardsPerBlock = newRewardsPerBlock;
    }

    // setMiniumStakeAmount - Only Owner
    function setMiniumStakeAmount(uint256 newMinimumStakeAmount)
        public
        onlyOwner
    {
        minimumStakeAmount = newMinimumStakeAmount;
    }

    // updateWardens :  for all categories check if currentWardenCount > memberCapacity, then remove the last warden
    function updateWardens(uint256 communityId) public returns (bool isValid) {
        
        uint256 totalMembers = (communityDetails[communityId].membersCount);
        uint256 wardenRate = (wardensPerCommunityRate); 
        uint256 totalWardens = communityDetails[communityId].wardensCount;
        
        if (totalWardens > 0) {
        uint256 Res = wardenRate*totalWardens;
            if (Res <= totalMembers) {
                uint256 noOfmembers = communityDetails[communityId]
                    .communityMembers
                    .length;
                address lastMember = communityDetails[communityId]
                    .communityMembers[noOfmembers - 1];
                removeWarden(communityId, lastMember);
                isValid = true;
            } else {
                isValid = false;
            }
        } else {
            isValid = false;
        }
        return isValid;
    }

    function displayAll(uint256 id)
        public
        view
        returns (address[] memory _data1, address[] memory _data2)
    {
        _data1 = communityDetails[id].communityWardens;
        _data2 = communityDetails[id].communityMembers;
    }
}
