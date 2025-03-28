// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "permit2NonceFinder/Permit2NonceFinder.sol";

contract NonceFinderScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // address pyth = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        // address mayan = 0xC38e4e6A15593f908255214653d3D947CA1c2338;

        Permit2NonceFinder permit2NonceFinder = new Permit2NonceFinder(permit2);

        console.log("Deployed MayanSwiftX at:", address(permit2NonceFinder));

        // https://basescan.org/address/0x09E158963a82834a6387bcedEbC0C9d245C4f74c

        // vm.startBroadcast(deployerPrivateKey);
    }
}
