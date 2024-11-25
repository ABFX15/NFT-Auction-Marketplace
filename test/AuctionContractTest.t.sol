// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AuctionContract} from "../src/AuctionContract.sol";
import {SellerNFT} from "../src/SellerNft.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RaffleTest is Test {
   error NFTAuction__BidTooLow();
   error NFTAuction__ReservePriceNotMet();

   AuctionContract private auctionContract;
   SellerNFT private sellerNft;

   uint256 tokenId = 0;
   uint256 public constant AUCTION_ID = 0;
   uint256 public constant NFT_PRICE = 0.1 ether;
   uint256 public constant RESERVE_PRICE = 1 ether;
   uint256 public constant AUCTION_DURATION = 1 days;
   uint256 public constant BID_PRICE = 2 ether;
   uint256 public constant STARTING_BALANCE = 10 ether;
   uint256 public constant MIN_BID_VALUE = 0.01 ether;
   uint256 public constant BALANCE = 5 ether;

   address public user = makeAddr("user");
   address public notUser = makeAddr("not_user");
   address public bidder = makeAddr("bidder");

   function setUp() external {
      auctionContract = new AuctionContract();
      sellerNft = new SellerNFT();
      vm.prank(user);
      sellerNft.mint(user);

      vm.deal(bidder, STARTING_BALANCE);
   }

   modifier mintNft {
      vm.startPrank(user);
      sellerNft.approve(address(auctionContract), tokenId);
      auctionContract.depositNft(address(sellerNft), tokenId, RESERVE_PRICE, AUCTION_DURATION);
      vm.stopPrank();
      _;
   }

   function testDepostingAnNft() public {
      vm.startPrank(user);
      sellerNft.approve(address(auctionContract), tokenId);
      auctionContract.depositNft(address(sellerNft), tokenId, RESERVE_PRICE, AUCTION_DURATION);
      vm.stopPrank();
      assertEq(sellerNft.ownerOf(tokenId), address(auctionContract));
      console.log("NFT deposited by: ", sellerNft.ownerOf(tokenId));
   }

   function testRevertsIfNotTheOwner() public {
      vm.startPrank(notUser);
      vm.expectRevert("You don't own this NFT");
      auctionContract.depositNft(address(sellerNft), tokenId, RESERVE_PRICE, AUCTION_DURATION);
      vm.stopPrank();
   }

   function testYouCanMakeABid() public {
      vm.startPrank(user);
      sellerNft.approve(address(auctionContract), tokenId);
      auctionContract.depositNft(address(sellerNft), tokenId, RESERVE_PRICE, AUCTION_DURATION);
      vm.stopPrank();
      
      console.log("Reserve Price:", RESERVE_PRICE);
      console.log("Bid Amount:", BID_PRICE);
      
      vm.startPrank(bidder);
      auctionContract.bid{value: BID_PRICE}(AUCTION_ID);
      vm.stopPrank();
      console.log("Bid placed by: ", bidder);
   }

   function testHighestBidderAddressNotZero() public mintNft {
      vm.startPrank(bidder);
      auctionContract.bid{value: BID_PRICE}(AUCTION_ID);
      vm.stopPrank();
      
      assertNotEq(auctionContract.getNftAuction()[AUCTION_ID].highestBidder, address(0));
      console.log("Highest Bidder: ", auctionContract.getNftAuction()[AUCTION_ID].highestBidder);
   }

   function testRevertsIfBidIsLowerThanCurrentBidPrice() public mintNft {
      vm.prank(bidder);
      auctionContract.bid{value: BID_PRICE}(AUCTION_ID);

      vm.startPrank(notUser);
      vm.deal(notUser, STARTING_BALANCE);
      vm.expectRevert(NFTAuction__BidTooLow.selector);
      auctionContract.bid{value: MIN_BID_VALUE}(AUCTION_ID);
      vm.stopPrank();
   }

   function testWithdraw() public mintNft {
      vm.startPrank(bidder);
      auctionContract.bid{value: BID_PRICE}(AUCTION_ID);
      vm.stopPrank();

      vm.warp(block.timestamp + AUCTION_DURATION + 1);

      uint256 initialContractBalance = address(auctionContract).balance;

      vm.startPrank(user);
      uint256 initialUserBalance = address(user).balance;
      auctionContract.sellerEndAuction(AUCTION_ID);
      vm.stopPrank();

      uint256 finalUserBalance = address(user).balance;
      uint256 finalContractBalance = address(auctionContract).balance;

      assertEq(initialContractBalance, BID_PRICE);
      assertEq(finalUserBalance, initialUserBalance + BID_PRICE);
      assertEq(finalContractBalance, 0);
   }
}
