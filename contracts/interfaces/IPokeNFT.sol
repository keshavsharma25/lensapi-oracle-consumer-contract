// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

interface IPokeNFT is IERC1155, IERC1155Receiver {
    struct Metrics {
        uint256 totalFollowers;
        uint256 totalPosts;
        uint256 totalComments;
        uint256 totalMirrors;
        uint256 totalCollects;
    }

    function evolveOrClaim(address _claimer, Metrics memory user) external;
}
