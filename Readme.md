# SimpleDEX

SimpleDEX is a decentralized exchange (DEX) smart contract that allows users to swap between two ERC-20 tokens, provide liquidity to the DEX, and remove liquidity. The contract owner can set the exchange rate between the two tokens.

## Overview

SimpleDEX allows users to:
- Swap Token A for Token B and vice versa.
- Provide liquidity to the DEX.
- Remove liquidity from the DEX.
- View the current reserves of Token A and Token B.
- View the current exchange rate between Token A and Token B.

## Functions

### Public Functions

- `setExchangeRate(uint _newRate)`: Updates the exchange rate between Token A and Token B. Only the owner can call this function.
- `exchangeTokenAForTokenB(uint amountA)`: Exchanges a specified amount of Token A for Token B.
- `exchangeTokenBForTokenA(uint amountB)`: Exchanges a specified amount of Token B for Token A.
- `provideLiquidity(uint256 _amountA, uint256 _amountB)`: Adds liquidity to the DEX.
- `removeLiquidity(uint256 _amountA, uint256 _amountB)`: Removes liquidity from the DEX. Only the owner can call this function.
- `getReserves()`: Returns the current reserves of Token A and Token B.
- `getTokenAddress()`: Returns the addresses of Token A and Token B.
- `showExchangeRate()`: Returns the current exchange rate between Token A and Token B.

## Errors

- `SimpleDEX__NotOwner(address caller)`: Thrown when a non-owner attempts to call a restricted function.
- `SimpleDEX__NotEnoughTokenA(address caller, uint256 amountA)`: Thrown when the caller does not have enough Token A for a swap.
- `SimpleDEX__NotEnoughTokenB(address caller, uint256 amountB)`: Thrown when the caller does not have enough Token B for a swap.
- `SimpleDEX__ProvideMoreLiquidityForTokenB(uint256 amountB)`: Thrown when there is insufficient liquidity of Token B for a swap.
- `SimpleDEX__ProvideMoreLiquidityForTokenA(uint256 amountA)`: Thrown when there is insufficient liquidity of Token A for a swap.

## Events

- `AddedLiquidity(address tokenA, uint256 indexed amountA, address tokenB, uint256 indexed amountB)`: Emitted when liquidity is added.
- `ExchangeRateUpdated(uint256 newExchangeRate)`: Emitted when the exchange rate is updated.
- `RemovedLiquidity(address tokenA, uint256 indexed amountA, address tokenB, uint256 indexed amountB)`: Emitted when liquidity is removed.
- `Swapped(address tokenIn, uint256 indexed amountIn, address tokenOut, uint256 indexed amountOut)`: Emitted when tokens are swapped.

Screenshot of implementation:
![image](https://github.com/Deepak2030/SimpleDEX/assets/83352186/fdd45980-9f0f-4734-9526-15a8d89995b6)
