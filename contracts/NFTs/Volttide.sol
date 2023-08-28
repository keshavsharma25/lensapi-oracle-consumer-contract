// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Volttide is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155URIStorage,
    ReentrancyGuard
{
    struct Metrics {
        uint256 totalFollowers;
        uint256 totalPosts;
        uint256 totalComments;
        uint256 totalMirrors;
        uint256 totalCollects;
    }

    constructor() ERC1155("") {
        _setURI(
            0,
            "https://ipfs.io/ipfs/bafybeidnhlx5xlgwinajcsfxcsytjvcxdkq6ynnjcvzu6mnreyouqd2zla/pichu.png"
        );
        _setURI(
            1,
            "https://ipfs.io/ipfs/bafybeibmfvleovtoccdzijwfvowpel6sgskvxxpseljawmdfticrisoes4/pikachu.png"
        );
        _setURI(
            2,
            "https://ipfs.io/ipfs/bafybeiees5ghqidviq5mx3co347ryuciugj4nasog36zaosxcbzf3mjrva/raichu.png"
        );
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) public payable nonReentrant {
        // verifyClaim(msg.sender, _tokenId, _quantity); // Add your claim verification logic by overriding this function.

        mint(_receiver, _tokenId, _quantity); // Mints tokens. Apply any state updates by overriding this function.
        // emit TokensClaimed(msg.sender, _receiver, _tokenId, _quantity);
    }

    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view {
        require(_quantity == 1, "Only one token can be claimed at a time");
        require(
            balanceOf(_claimer, _tokenId) < 1,
            "Only one token can be claimed"
        );
        require(_tokenId == 0, "Only token id:0 can be claimed");
        require(_claimer == msg.sender, "Only the sender can claim");
    }

    function evolveOrClaim(address _claimer, uint256 data) internal {
        Metrics memory user = decode(data);

        uint256 levelId = whichLevel(user);
        require(
            isEvovledAndClaimed(_claimer, user) == false,
            "Already Evolved and Claimed"
        );

        if (levelId == 2) {
            if (balanceOf(_claimer, 1) == 1) {
                _burn(_claimer, 1, 1);
            }
            _mint(_claimer, 2, 1, "");
        } else if (levelId == 1) {
            if (balanceOf(_claimer, 0) == 1) {
                _burn(_claimer, 0, 1);
            }
            _mint(_claimer, 1, 1, "");
        } else if (levelId == 0) {
            claim(_claimer, 0, 1);
        }
    }

    function isEvovledAndClaimed(
        address userAddress,
        Metrics memory user
    ) public view returns (bool) {
        uint256 levelId = whichLevel(user);

        if (levelId == 2 && balanceOf(userAddress, 2) == 1) {
            return true;
        }

        return false;
    }

    function levels(
        uint256 level
    ) public pure returns (Metrics memory requirements) {
        require(level < 3, "level out of range: Valid range is 0-2");

        if (level == 0) {
            requirements = Metrics(
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            );
        } else if (level == 1) {
            requirements = Metrics(
                uint256(10),
                uint256(50),
                uint256(50),
                uint256(10),
                uint256(10)
            );
        } else {
            requirements = Metrics(
                uint256(50),
                uint256(100),
                uint256(100),
                uint256(20),
                uint256(20)
            );
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

    function digitArray(int256 _number) public pure returns (int256[] memory) {
        int256 num = _number;

        int256 no_digits = 0;

        while (num > 0) {
            num /= 10;
            no_digits++;
        }

        num = _number;
        int256[] memory numberArray = new int256[](uint256(no_digits));

        for (int256 i = no_digits - 1; i >= 0; i--) {
            int256 digit = num % 10;
            numberArray[uint256(i)] = digit;
            num /= 10;
        }

        return numberArray;
    }

    function decode(uint256 _number) public pure returns (Metrics memory user) {
        int256 num = int256(_number);

        int256[] memory numberArray = digitArray(num);
        uint256[5] memory decoded;

        int256 offset = 0;

        for (int256 i = 0; i < 5; i++) {
            int256 numLength = numberArray[uint256(offset)];
            offset += 1;

            int256 extractedValue = 0;

            for (int256 j = offset; j < offset + numLength; j++) {
                extractedValue = extractedValue * 10 + numberArray[uint256(j)];
            }

            decoded[uint256(i)] = uint256(extractedValue);
            offset += numLength;
        }

        user = Metrics(
            decoded[0],
            decoded[1],
            decoded[2],
            decoded[3],
            decoded[4]
        );
    }
}
