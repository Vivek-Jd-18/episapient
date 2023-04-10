// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EpisapientToken.sol";

contract Community is Ownable {
    EpisapientToken token; // declare a variable of type EpisapientToken to interact with the token contract
    uint256 public categoryIdCounter = 0; // declare a variable to keep track of the number of categories
    uint8 public addcommunityCounter = 0; // declare a variable to keep track of the number of communities
    uint256 public membershipCounter = 0; // declare a variable to keep track of the number of members

    // declare a struct to hold information about communities
    struct Communities {
        address ContractAddress;
        uint256 categoryId;
        uint256 id;
        address[] communityMembers;
        address[] wardenAddress;
    }

    // declare a struct to hold information about categories
    struct Category {
        string name;
        uint256 id;
    }

    // declare a struct to hold information about members
    struct Member {
        address communityAddress;
        address walletAddress;
        uint256 id;
    }

    // declare a mapping to store categories
    mapping(uint256 => Category) public category;
    // declare a mapping to store communities
    mapping(address => Communities) public AddCommunities;
    // declare a mapping to store members
    mapping(address => Member) public membership;

    // declare an array to keep track of all communities
    address[] public communityList;
    // declare an array to keep track of all categories
    uint256[] public categoryList;
    // declare an array to keep track of all members
    address[] public membersList;

    // constructor function to set the token address
    constructor(address tokenAddress) {
        token = EpisapientToken(tokenAddress);
    }

    // function to add a new community
    function addCommunity(address ContractAddress, uint256 categoryId) public {
        require(categoryId < categoryIdCounter, "Category not Exist");
        address[] memory arr;
        address[] memory arr1;
        Communities memory newCommunities = Communities(
            ContractAddress,
            categoryId,
            addcommunityCounter,
            arr,
            arr1
        );
        AddCommunities[ContractAddress] = newCommunities;
        communityList.push(ContractAddress);
        addcommunityCounter++;
    }

    // function to get all communities
    function getCommunities() public view returns (Communities[] memory) {
        Communities[] memory result = new Communities[](communityList.length);
        for (uint256 i = 0; i < communityList.length; i++) {
            result[i] = AddCommunities[communityList[i]];
        }
        return result;
    }

    // function to add a new category
    function addCategorie(string memory name) public onlyOwner {
        Category memory newCategory = Category(name, categoryIdCounter);
        category[categoryIdCounter] = newCategory;
        categoryList.push(categoryIdCounter);
        categoryIdCounter++;
    }

    // function to remove a category
    function removeCategory(uint256 categoryId) public onlyOwner {
        require(
            categoryId <= categoryList.length,
            "This Category does not Exist"
        );
        categoryList[categoryId] = categoryList[categoryList.length - 1];
        categoryList.pop();
    }

    // This function returns an array of all categories stored in the contract
    function getCategoryList() public view returns (Category[] memory) {
        Category[] memory result = new Category[](categoryList.length);
        for (uint256 i = 0; i < categoryList.length; i++) {
            // add the category with the corresponding ID to the result array
            result[i] = category[categoryList[i]];
        }
        return result;
    }

    // This function adds a new member to a community
    function addMember(
        address communityAddress,
        address walletAddress
    ) public payable {
        // get the community object from the mapping
        Communities storage community = AddCommunities[communityAddress];
        // check if the community exists
        require(community.ContractAddress != address(0), "Community not found");
        // check if the member does not already exist
        require(
            membership[walletAddress].communityAddress == address(0),
            "Member already exists"
        );

        // get the platform fee for the "Register" action
        uint256 platformFee = token.getPlatformFee("Register");
        // get the platform address
        address platformAddress = token.getPlatformAddress();
        // transfer the platform fee to the platform address
        if (platformFee > 0) {
            token.TokenTransfer(platformAddress, platformFee);
        }

        // add the member to the community
        community.communityMembers.push(walletAddress);
        // create a new member object
        Member memory newmember = Member(
            communityAddress,
            walletAddress,
            membershipCounter
        );
        // add the new member to the membership mapping
        membership[walletAddress] = newmember;
        // add the member to the members list
        membersList.push(walletAddress);
        // increase the membership counter
        membershipCounter++;
    }

    // This function returns an array of all members stored in the contract
    function communityMembersList(
        address _contractaddress
    ) public view returns (address[] memory) {
        return AddCommunities[_contractaddress].communityMembers;
    }

    function communityWardenList(
        address _contractaddress
    ) public view returns (address[] memory) {
        return AddCommunities[_contractaddress].wardenAddress;
    }

    function getMemberList() public view returns (Member[] memory) {
        Member[] memory result = new Member[](membersList.length);
        for (uint256 i = 0; i < membersList.length; i++) {
            // add the member with the corresponding wallet address to the result array
            result[i] = membership[membersList[i]];
        }
        return result;
    }

    // This function returns the platform fee and balance of an account
    function read(
        address acc
    )
        public
        view
        returns (
            uint256 _platformFee,
            address _PlatformFeeAddress,
            uint256 balance
        )
    {
        // get the platform fee for the "Register" action
        _platformFee = token.getPlatformFee("Register");
        // get the platform address
        _PlatformFeeAddress = token.getPlatformAddress();
        // get the balance of the account
        balance = token.balanceOf(acc);
    }

    // This function transfers tokens to a specified address
    function sendfees(address to, uint256 amount) public {
        // transfer the specified amount of tokens to the specified address
        token.TokenTransfer(to, amount);
    }

    // Remove the last element.
    function removeMember(
        address _contract,
        address item
    ) public returns (bool) {
        address[] storage arr = AddCommunities[_contract].communityMembers;
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

    // push the last element.
    function addWarden(address _contract, address _address) public {
        address[] storage arr = AddCommunities[_contract].wardenAddress;
        arr.push(_address);
    }

    // Remove the last element.
    function removeWarden(
        address _contract,
        address item
    ) public returns (bool) {
        address[] storage arr = AddCommunities[_contract].wardenAddress;
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
}
