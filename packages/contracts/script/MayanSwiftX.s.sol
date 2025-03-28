// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MayanSwiftX} from "../src/MayanSwiftX.sol";

contract MayanSwiftScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address pyth = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        address mayan = 0xC38e4e6A15593f908255214653d3D947CA1c2338;
        address mayanForwader = 0x337685fdaB40D39bd02028545a4FfA7D287cC3E2;

        MayanSwiftX mayanSwiftX = new MayanSwiftX(permit2, mayan, mayanForwader, pyth, msg.sender);

        console.log("Deployed MayanSwiftX at:", address(mayanSwiftX));

        // https://basescan.org/address/0x5D9C504b3F02611912Af20ED39E60C539621E678

        // vm.startBroadcast(deployerPrivateKey);
    }
}
