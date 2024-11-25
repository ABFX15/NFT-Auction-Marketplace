# NFT Auction Smart Contract

A decentralized NFT auction platform built on Ethereum that allows users to create auctions for their NFTs and accept bids from other users.

## Features

- NFT owners can create auctions with custom reserve prices and durations
- Bidders can place bids on active auctions
- Automatic refund of outbid amounts
- Sellers can end auctions early if reserve price is met
- Built-in security with reentrancy protection
- Fully tested with Foundry

## Contract Details

The main contract `AuctionContract.sol` implements the following key functionality:

- `depositNft()`: Create a new auction by depositing an NFT
- `bid()`: Place a bid on an active auction
- `finishAuction()`: Complete an auction after time expires
- `sellerEndAuction()`: Allow seller to end auction early if reserve met
- `withdraw()`: Withdraw refunded bid amounts
- `getActiveAuctions()`: View all currently active auctions

## Technical Specifications

- Solidity version: 0.8.20
- Built with OpenZeppelin contracts
- Implements ERC721 receiver interface
- Uses ReentrancyGuard for security
- Comprehensive test suite in Foundry

## Security Features

- Reentrancy protection on critical functions
- Checks-Effects-Interactions pattern
- Access control via Ownable
- Minimum auction duration enforcement
- Safe transfer handling

## Testing

The contract includes extensive tests covering:

- NFT deposits
- Bidding functionality 
- Auction completion
- Withdrawal mechanics
- Edge cases and security scenarios

Run tests with:
`forge test`

