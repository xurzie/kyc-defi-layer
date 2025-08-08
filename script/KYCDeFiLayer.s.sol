// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/KYCDeFiLayer.sol";

contract DeployKYCDeFiLayer is Script {
    function run() external {
        // 📌 Параметры — замени на свои
        address stableToken = 0x546187512140956d94E61f15Fc3e3248F5430c85; 
        address verifier = 0xfcc86A79fCb057A8e55C6B853dff9479C3cf607c; // UniversalVerifier Amoy
        uint64 basicKycRequestId = 1755142413;
        uint64 advancedKycRequestId = 1755198332;

        vm.startBroadcast();
        KYCDeFiLayer layer = new KYCDeFiLayer(
            stableToken,
            verifier,
            basicKycRequestId,
            advancedKycRequestId
        );
        vm.stopBroadcast();

        console.log("KYCDeFiLayer deployed at:", address(layer));
    }
}