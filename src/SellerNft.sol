// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SellerNFT
 * @author Adam Crypt0Dev
 * @notice A simple NFT contract that allows users to mint tokens and approve them for auction
 * @dev Inherits from ERC721 for NFT functionality and Ownable for access control
 * @custom:security-contact adam@crypto.dev
 * @notice This contract is used in conjunction with the AuctionContract to enable NFT auctions
 * @dev Includes a token counter to track and assign unique IDs to minted NFTs
 */
contract SellerNFT is ERC721, Ownable {
    uint256 private tokenCounter;

    constructor() ERC721("SellerNFT", "SNFT") Ownable(msg.sender) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = tokenCounter;
        tokenCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function approveToAuction(address auctionContract, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "SellerNFT: not owner of token");
        approve(auctionContract, tokenId);
    }

    function getTokenCounter() public view returns (uint256) {
        return tokenCounter;
    }
}
