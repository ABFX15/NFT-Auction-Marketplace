// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SellerNFT} from "../src/SellerNft.sol";

contract DeploySellerNft is Script {
    SellerNFT private sellerNft;

    function run() public returns (SellerNFT) {
        vm.startBroadcast();
        sellerNft = new SellerNFT();
        vm.stopBroadcast();
        return sellerNft;
    }
}
