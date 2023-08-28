// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155LazyMint.sol";

contract PokeNFT is ERC1155LazyMint {
    struct Metrics {
        uint256 totalFollowers;
        uint256 totalPosts;
        uint256 totalComments;
        uint256 totalMirrors;
        uint256 totalCollects;
    }

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155LazyMint(_defaultAdmin, _name, _symbol, msg.sender, 0) {}

    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view override {
        require(_quantity == 1, "Only one token can be claimed at a time");
        require(
            balanceOf[_claimer][_tokenId] < 1,
            "Only one token can be claimed"
        );
        require(_tokenId == 0, "Only token id:0 can be claimed");
        require(_claimer == msg.sender, "Only the sender can claim");
    }

    function evolveOrClaim(address _claimer, Metrics memory user) public {
        uint256 levelId = whichLevel(user);
        require(
            isEvovledAndClaimed(_claimer, user),
            "Already Evolved and Claimed"
        );

        if (levelId > 0) {
            _burn(_claimer, levelId - 1, 1);
            _mint(_claimer, levelId, 1, "");
        } else {
            claim(_claimer, levelId, 1);
        }
    }

    function isEvovledAndClaimed(
        address userAddress,
        Metrics memory user
    ) public view returns (bool) {
        uint256 levelId = whichLevel(user);

        if (levelId == 2 && balanceOf[userAddress][2] == 1) {
            return true;
        }

        return false;
    }

    function levels(uint256 level) public pure returns (Metrics memory) {
        require(level < 3, "level out of range: Valid range is 0-2");
        Metrics memory requirements;

        if (level == 0) {
            requirements = Metrics(
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            );

            return requirements;
        } else if (level == 1) {
            requirements = Metrics(
                uint256(100),
                uint256(500),
                uint256(500),
                uint256(50),
                uint256(10)
            );

            return requirements;
        } else {
            requirements = Metrics(
                uint256(1000),
                uint256(5000),
                uint256(5000),
                uint256(500),
                uint256(50)
            );

            return requirements;
        }
    }

    function compareMetrics(
        uint256 lvlNo,
        Metrics memory user
    ) public pure returns (bool) {
        Metrics memory lvl = levels(lvlNo);

        if (lvl.totalFollowers > user.totalFollowers) {
            return false;
        }

        if (lvl.totalPosts > user.totalPosts) {
            return false;
        }

        if (lvl.totalComments > user.totalComments) {
            return false;
        }

        if (lvl.totalMirrors > user.totalMirrors) {
            return false;
        }

        if (lvl.totalCollects > user.totalCollects) {
            return false;
        }

        return true;
    }

    function whichLevel(Metrics memory user) public pure returns (uint256) {
        if (compareMetrics(2, user)) {
            return 2;
        } else if (compareMetrics(1, user)) {
            return 1;
        } else {
            return 0;
        }
    }
}
