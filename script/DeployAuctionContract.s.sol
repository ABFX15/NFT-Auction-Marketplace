// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AuctionContract} from "../src/AuctionContract.sol";

contract DeployAuctionContract is Script {
    AuctionContract private auctionContract;

    function run() public returns (AuctionContract) {
        vm.startBroadcast();
        auctionContract = new AuctionContract();
        vm.stopBroadcast();
        return auctionContract;
    }
}
