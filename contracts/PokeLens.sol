// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./PhatRollupAnchor.sol";
import "./interfaces/IPokeNFT.sol";

contract PokeLens is PhatRollupAnchor, Ownable {
    struct Metrics {
        uint256 totalFollowers;
        uint256 totalPosts;
        uint256 totalComments;
        uint256 totalMirrors;
        uint256 totalCollects;
    }

    struct Profile {
        string category;
        string profileId;
    }

    mapping(address => Profile) public class;
    mapping(string => IPokeNFT) public classContract;
    mapping(uint256 => address) internal _requesters;

    uint constant TYPE_RESPONSE = 0;
    uint constant TYPE_ERROR = 2;

    mapping(uint => string) requests;
    uint nextRequest = 1;

    event CategorySet(address indexed user, string category, string profileId);
    event MintSuccessful(address indexed user, uint256 tokenId);
    event MintFailed(address indexed user, uint256 tokenId);
    event RequestSent(address indexed user, uint256 id, string profileId);
    event ResponseReceived(address indexed user, uint256 id, string profileId);
    event ErrorReceived(address indexed user, uint256 id, string profileId);

    constructor(address phatAttestor) Ownable() {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);

        classContract["fire"] = IPokeNFT(
            address(0x58B2CC9C68e9A4B73338E27d12663D73d641A723)
        );
        classContract["water"] = IPokeNFT(
            address(0x299914955E49298Eb1a8dc59a890E99127513172)
        );
        classContract["grass"] = IPokeNFT(
            address(0x2162aa1C256e788eEf4705Ea39C42F28F07284Cb)
        );
        classContract["electric"] = IPokeNFT(
            address(0x84f4690638200676d58e046D58424F4e63D52664)
        );
    }

    function setAttestor(address phatAttestor) public {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);
    }

    function setCategory(
        string memory _category,
        string memory _profileId
    ) internal {
        class[msg.sender] = Profile(_category, _profileId);

        emit CategorySet(msg.sender, _category, _profileId);
    }

    function getCategory(address _user) public view returns (string memory) {
        return category[_user];
    }

    function request(
        string calldata profileId,
        string calldata category
    ) public {
        // assemble the request
        uint id = nextRequest;
        _requesters[id] = msg.sender;
        requests[id] = profileId;
        _pushMessage(abi.encode(id, profileId));
        setCategory(category, profileId);
        nextRequest += 1;
        emit RequestSent(msg.sender, id, profileId);
    }

    function _onMessageReceived(bytes calldata action) internal override {
        require(action.length == 32 * 3, "cannot parse action");
        (uint256 resType, uint256 id, uint256 data) = abi.decode(
            action,
            (uint256, uint256, uint256)
        );
        emit ResponseReceived(_requesters[id], id, requests[id]);

        if (resType == TYPE_RESPONSE) {
            uint256[5] memory decoded = decode(data);
            string memory classId = class[_requesters[id]].category;
            IPokeNFT nft = IPokeNFT(classContract[classId]);

            IPokeNFT.Metrics memory resp = IPokeNFT.Metrics(
                decoded[0],
                decoded[1],
                decoded[2],
                decoded[3],
                decoded[4]
            );

            try nft.evolveOrClaim(msg.sender, resp) {
                emit MintSuccessful(msg.sender, data);
                delete requests[id];
                delete _requesters[id];
            } catch {
                emit MintFailed(msg.sender, data);
                delete requests[id];
                delete _requesters[id];
            }
        } else if (resType == TYPE_ERROR) {
            emit ErrorReceived(_requesters[id], id, requests[id]);
            delete requests[id];
            delete _requesters[id];
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

    function decode(uint256 _number) public pure returns (uint256[5] memory) {
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

        return decoded;
    }
}
