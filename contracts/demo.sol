// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Vote {
    uint256 public wardenCount;
    struct Categories {
        uint256 cId;
        uint256 memberCount;
        uint256 wardenCount;
        address[] communityMembers;
        address[] communityWardens;
    }

    struct Members {
        uint256[] cId;
        address memberAddress;
    }

    struct Wardens {
        uint256[] cId;
        address wardenAddress;
    }

    uint256 public wardenRate;
    mapping(address => Members) public memberDetails;
    mapping(uint256 => Categories) public categoryDetails;
    mapping(address => Wardens) public wardenDetails;

    function changeRate(uint256 _wardenRate) public {
        wardenRate = _wardenRate;
    }

    function addMembers(address _add, uint256 cid) public {
        memberDetails[_add].memberAddress = msg.sender;
        memberDetails[_add].cId.push(cid);
        categoryDetails[cid].communityMembers.push(_add);
        categoryDetails[cid].memberCount++;
    }

    function removeMembers(uint256 cid, address _member) public {
        removeAddress(
            categoryDetails[cid].communityWardens,
            msg.sender
        );
        removeAddress(categoryDetails[cid].communityMembers, _member);
        categoryDetails[cid].memberCount--;

    }

    function addWarden(address _add, uint256 cid) public {
        uint256 totalMembers = categoryDetails[cid].memberCount;
        uint256 totalWardens = categoryDetails[cid].wardenCount;

        if (totalWardens > 0) {
            uint256 Res = totalMembers / wardenRate;
            require(Res > totalWardens, "Warden Limit Exceeded");
        }

        wardenDetails[_add].wardenAddress = msg.sender;
        wardenDetails[_add].cId.push(cid);
        categoryDetails[cid].wardenCount++;
    }

    function categoryReader(uint256 cat)
        public
        view
        returns (Categories memory __)
    {
        __ = categoryDetails[cat];
    }

    function memberReader(address _add)
        public
        view
        returns (Members memory __)
    {
        __ = memberDetails[_add];
    }

    function wardenReader(address _add)
        public
        view
        returns (Wardens memory __)
    {
        __ = wardenDetails[_add];
    }

    // updateWardens :  for all categories check if currentWardenCount > memberCapacity, then remove the last warden
    function updateWardens(uint256 communityId) public returns (bool isValid) {
        uint256 totalMembers = (categoryDetails[communityId].memberCount);
        uint256 totalWardens = categoryDetails[communityId].wardenCount;

        if (totalWardens > 0) {
            uint256 Res = wardenRate * totalWardens;
            if (Res <= totalMembers) {
                uint256 noOfmembers = categoryDetails[communityId]
                    .communityMembers
                    .length;
                address lastMember = categoryDetails[communityId]
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

    // removeWarden(walletAddress, categoryId) - Remove warden of particular category - Only Owner / Contract Only
    function removeWarden(uint256 communityId, address wardenAddress) public {
        //updates warden
        // updateWardens(communityId);

        require(
            wardenDetails[wardenAddress].cId.length > 0,
            "It's Not a Warden"
        );

        removeItem(wardenDetails[wardenAddress].cId, communityId);

        removeAddress(
            categoryDetails[communityId].communityWardens,
            wardenAddress
        );
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

    // becomeWarden(stackAmount, categoryId) - Check if user is whitelisted, Check if currentWardenCount < memberCapacity
    function becomeWarden(uint256 communityId) public {
        //updates warden
        // updateWardens(communityId);

        uint256 totalMembers = categoryDetails[communityId].memberCount;
        uint256 totalWardens = categoryDetails[communityId].wardenCount;
        if (totalWardens > 0) {
            uint256 Res = totalMembers / wardenRate;
            require(Res > totalWardens, "Warden Limit Exceeded");
        }
        categoryDetails[communityId].communityMembers.push(msg.sender);

        wardenDetails[msg.sender].wardenAddress = msg.sender;
        wardenDetails[msg.sender].cId.push(communityId);

        categoryDetails[communityId].wardenCount++;
        categoryDetails[communityId].communityWardens.push(msg.sender);
        wardenCount++;
    }
}
