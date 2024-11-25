// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SellerNFT} from "./SellerNft.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


/**
 * @title AuctionContract
 * @author Adam Crypt0Dev
 * @notice This contract implements an NFT auction system where users can deposit NFTs and others can bid on them
 * @dev Inherits from Ownable for access control, ReentrancyGuard for security, and IERC721Receiver for NFT handling
 * @custom:security-contact adam@crypto.dev
 */
contract AuctionContract is Ownable, ReentrancyGuard, IERC721Receiver {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error NFTAuction__ReservePriceNotMet();
    error NFTAuction__AuctionDurationTooShort();
    error NFTAuction__NotEnoughFundsToWithdraw();
    error NFTAuction__TransferFailed();
    error NFTAuction__BidTooLow();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    // Event for when an NFT is deposited to the contract 
    event NFTDeposited(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 reservePrice
    );
    // Event for a new bid placed
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidPrice
    );
    // Event for when an auction ends
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 bidPrice
    );
    // Event for when a bid is refunded
    event bidRefunded(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidPrice
    );

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Seller can choose the duration of the auction
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    uint256 public constant MAX_AUCTION_DURATION = 30 days;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // Struct of NFT auction
    struct NFTAuction {
        uint256 tokenId;
        uint256 reservePrice;
        uint256 bidPrice;
        uint256 startTime;
        uint256 endTime;
        address seller;
        address highestBidder;
        address nftContract;
        bool ended;
    }

    // Array of the NFT auctions
    NFTAuction[] public nftAuctions;

    // mapping of bidder to NFT tokenId
    mapping(address => uint256) public balances;

    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    // Modifier to check if the auction is active
    modifier auctionActive(uint256 auctionId) {
        NFTAuction storage auction = nftAuctions[auctionId];
        require(block.timestamp <= auction.endTime, "Auction ended");
        require(msg.sender != auction.seller, "Seller cannot bid");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice A seller can deposit an NFT to the contract to start an auction
     * @param nftContract The address of the NFT contract
     * @param tokenId The ID of the NFT
     * @param _reservePrice The reserve price of the NFT set by the seller
     * @param _auctionDuration The duration of the auction
     * @notice The contract uses the IERC721 interface to interact with the NFT contract
     * @notice The contract uses the IERC721Receiver interface to receive the NFT
     * @return The auction ID of the NFT
     */
    function depositNft(
        address nftContract,
        uint256 tokenId,
        uint256 _reservePrice,
        uint256 _auctionDuration
    ) external returns (uint256) {
        if (_auctionDuration < MIN_AUCTION_DURATION) {
            revert NFTAuction__AuctionDurationTooShort();
        }
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(
            nft.getApproved(tokenId) == address(this),
            "Auction not approved"
        );
        nft.transferFrom(msg.sender, address(this), tokenId);

        uint256 auctionId = nftAuctions.length;
        nftAuctions.push(
            NFTAuction({
                tokenId: tokenId,
                seller: msg.sender,
                reservePrice: _reservePrice,
                highestBidder: address(0),
                bidPrice: 0,
                startTime: block.timestamp,
                endTime: block.timestamp + 1 days,
                ended: false,
                nftContract: nftContract
            })
        );

        emit NFTDeposited(nftAuctions.length - 1, msg.sender, _reservePrice);
        return auctionId;
    }

    /**
     * @notice A bidder can place a bid on an NFT auction
     * @param auctionId The ID of the auction
     * @notice The contract uses the nonReentrant modifier to prevent reentrancy attacks
     * @notice The contract uses the auctionActive modifier to check if the auction is active
     */
    function bid(
        uint256 auctionId
    )
        external
        payable
        nonReentrant
        auctionActive(auctionId)
    {
        NFTAuction storage auction = nftAuctions[auctionId];

        if (auction.highestBidder != address(0) && msg.value <= auction.bidPrice) {
        revert NFTAuction__BidTooLow();
        }

        // Then check reserve price
        if (msg.value < auction.reservePrice) {
            revert NFTAuction__ReservePriceNotMet();
        }  

        if (auction.highestBidder != address(0)) {
            balances[auction.highestBidder] += auction.bidPrice;
            emit bidRefunded(auctionId, auction.highestBidder, auction.bidPrice);

            emit bidRefunded(
                auctionId,
                auction.highestBidder,
                auction.bidPrice
            );
        }

        auction.highestBidder = msg.sender;
        auction.bidPrice = msg.value;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /**
     * @notice A seller can end an auction and transfer the NFT to the highest bidder
     * @param auctionId The ID of the auction
     * @notice The contract uses the nonReentrant modifier to prevent reentrancy attacks
     * @notice The contract uses the auctionActive modifier to check if the auction is active
     */
    function sellerEndAuction(uint256 auctionId) 
        external 
        nonReentrant 
        auctionActive(auctionId) 
    {
        NFTAuction storage auction = nftAuctions[auctionId];
        if (auction.bidPrice < auction.reservePrice) {
            revert NFTAuction__ReservePriceNotMet();
        }
        auction.ended = true;

        uint256 sellerEth = auction.bidPrice;
        payable(auction.seller).transfer(sellerEth);

        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId
        );

        emit AuctionEnded(auctionId, auction.highestBidder, auction.bidPrice);
    }

    /**
     * @notice returns the active auctions
     * @return activeAuctions
     */
    function getActiveAuctions() 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory activeAuctions = new uint256[](nftAuctions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < nftAuctions.length; i++) {
            if (!nftAuctions[i].ended) {
                activeAuctions[count] = i;
                count++;
            }
        }
        return activeAuctions;
    }

    /**
     * @notice a withdraw function in case of any remaining balance inside the contract
     */
    function withdraw() public payable {
        uint256 amount = balances[msg.sender];
        if (amount == 0) {
            revert NFTAuction__NotEnoughFundsToWithdraw();
        }
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert NFTAuction__TransferFailed();
        }
    }

    fallback() external payable {}
    receive() external payable {}

    /**
     * @notice ERC721 onReceived function
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    /**
     * @notice returns the NFT auction
     */
    function getNftAuction() public view returns (NFTAuction[] memory) {
        return nftAuctions;
    }
}
