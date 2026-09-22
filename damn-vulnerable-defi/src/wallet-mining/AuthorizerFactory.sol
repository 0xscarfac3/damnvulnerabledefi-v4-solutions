// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {TransparentProxy} from "./TransparentProxy.sol";  // will visit sonn
import {AuthorizerUpgradeable} from "./AuthorizerUpgradeable.sol";  // will visit soon

contract AuthorizerFactory {
    function deployWithProxy(address[] memory wards, address[] memory aims, address upgrader)
        external
        returns (address authorizer)
    {
        authorizer = address(
            new TransparentProxy( // proxy
                address(new AuthorizerUpgradeable()), // implementation
                abi.encodeCall(AuthorizerUpgradeable.init, (wards, aims)) // init data
            )
        );
        // answer : checks nounce;
        assert(AuthorizerUpgradeable(authorizer).needsInit() == 0); // invariant
        TransparentProxy(payable(authorizer)).setUpgrader(upgrader);
    }
}
