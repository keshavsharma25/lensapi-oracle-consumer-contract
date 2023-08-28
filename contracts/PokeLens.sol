// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PhatRollupAnchor.sol";
import "./NFTs/Pyroflame.sol";

contract PokeLens is PhatRollupAnchor, Ownable {
    struct Metrics {
        uint256 totalFollowers;
        uint256 totalPosts;
        uint256 totalComments;
        uint256 totalMirrors;
        uint256 totalCollects;
    }

    enum Class {
        FIRE,
        WATER,
        GRASS,
        ELECTRIC
    }

    struct Profile {
        Class category;
        string profileId;
    }

    Pyroflame nft;

    mapping(address => Profile) public class;
    mapping(Class => Pyroflame) public classContract;
    mapping(uint256 => address) internal _requesters;

    uint constant TYPE_RESPONSE = 0;
    uint constant TYPE_ERROR = 2;

    mapping(uint => string) requests;
    uint nextRequest = 1;

    event CategorySet(address indexed user, Class category, string profileId);
    event MintSuccessful(address indexed user, uint256 tokenId);
    event MintFailed(address indexed user, uint256 tokenId);
    event RequestSent(address indexed user, uint256 id, string profileId);
    event ResponseReceived(address indexed user, uint256 id, string profileId);
    event ErrorReceived(address indexed user, uint256 id, string profileId);

    constructor(address phatAttestor) Ownable() {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);

        classContract[Class.FIRE] = Pyroflame(
            address(0x76F249172183685a7E811Df1a44b7bbfF1dC5E65)
        );

        // classContract["water"] = PokeNFT(
        //     address(0x299914955E49298Eb1a8dc59a890E99127513172)
        // );
        // classContract["grass"] = PokeNFT(
        //     address(0x2162aa1C256e788eEf4705Ea39C42F28F07284Cb)
        // );
        // classContract["electric"] = PokeNFT(
        //     address(0x84f4690638200676d58e046D58424F4e63D52664)
        // );
    }

    function setAttestor(address phatAttestor) public {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);
    }

    function setClass(Class _category, string memory _profileId) internal {
        class[msg.sender] = Profile(_category, _profileId);

        emit CategorySet(msg.sender, _category, _profileId);
    }

    function getClass(address _user) public view returns (Profile memory) {
        return class[_user];
    }

    function request(string calldata profileId, Class category) public {
        // assemble the request
        uint id = nextRequest;
        _requesters[id] = msg.sender;
        requests[id] = profileId;
        _pushMessage(abi.encode(id, profileId));
        setClass(category, profileId);
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
            Class classId = class[_requesters[id]].category;

            nft = classContract[classId];

            nft.evolveOrClaim(_requesters[id], data);
            emit MintSuccessful(_requesters[id], data);
            delete requests[id];
            delete _requesters[id];
        } else if (resType == TYPE_ERROR) {
            emit ErrorReceived(_requesters[id], id, requests[id]);
            delete requests[id];
            delete _requesters[id];
        }
    }
}
