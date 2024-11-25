// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SellerNFT} from "../src/SellerNft.sol";
import {AuctionContract} from "../src/AuctionContract.sol";

contract SellerNftTest is Test {
    SellerNFT private sellerNft;
    AuctionContract private auctionContract;

    address public USER = makeAddr("user");
    address public NOT_OWNER = makeAddr("not_owner");

    function setUp() external {
        sellerNft = new SellerNFT();
        auctionContract = new AuctionContract();
    }

    function testMint() public {
        uint256 tokenCounterId = sellerNft.getTokenCounter();
        vm.prank(USER);
        uint256 mintedNft = sellerNft.mint(USER);
        assertEq(mintedNft, tokenCounterId);
        assertEq(sellerNft.ownerOf(mintedNft), USER);
        assertEq(sellerNft.getTokenCounter(), tokenCounterId + 1);
        console.log("Minted token", mintedNft, "to", USER);
    }

    function testApproveToAuction() public {
        vm.prank(USER);
        uint256 mintNft = sellerNft.mint(USER);
        vm.prank(USER);
        sellerNft.approveToAuction(address(auctionContract), mintNft);
        assertEq(sellerNft.getApproved(mintNft), address(auctionContract));
    }

    function testCannotApproveIfNotOwner() public {
        vm.prank(USER);
        uint256 mintNft = sellerNft.mint(USER);
        vm.prank(NOT_OWNER);
        vm.expectRevert("SellerNFT: not owner of token");
        sellerNft.approveToAuction(address(auctionContract), mintNft);
    }
}
