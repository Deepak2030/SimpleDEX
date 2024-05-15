// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleDEX - A simple decentralized exchange for swapping two ERC-20 tokens at a fixed rate.
contract SimpleDEX {

    // Immutable state variables
    address public immutable i_owner;  // The owner of the contract
    IERC20 public immutable i_tokenA;  // The first ERC-20 token
    IERC20 public immutable i_tokenB;  // The second ERC-20 token

    // Mutable state variables
    uint256 public exchangeRate;  // The exchange rate between tokenA and tokenB
    uint256 public s_reserveA;  // The reserve of tokenA in the contract
    uint256 public s_reserveB;  // The reserve of tokenB in the contract

    // Custom errors for more efficient error handling
    error SimpleDEX__NotOwner(address caller);  // Error for non-owner access
    error SimpleDEX__NotEnoughTokenA(address caller, uint256 amountA);  // Error for insufficient tokenA balance
    error SimpleDEX__NotEnoughTokenB(address caller, uint256 amountB);  // Error for insufficient tokenB balance
    error SimpleDEX__ProvideMoreLiquidityForTokenB(uint256 amountB);  // Error for insufficient tokenB liquidity
    error SimpleDEX__ProvideMoreLiquidityForTokenA(uint256 amountA);  // Error for insufficient tokenA liquidity

    // Events for tracking contract activity
    event AddedLiquidity(
        address tokenA,
        uint256 indexed amountA,
        address tokenB,
        uint256 indexed amountB
    );

    event ExchangeRateUpdated(
        uint256 newExchangeRate
    );

    event RemovedLiquidity(
        address tokenA,
        uint256 indexed amountA,
        address tokenB,
        uint256 indexed amountB 
    );

    event Swapped(
        address tokenIn,
        uint256 indexed amountIn,
        address tokenOut,
        uint256 indexed amountOut
    );

    // Modifier to restrict access to owner-only functions
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert SimpleDEX__NotOwner(msg.sender);
        }
        _;
    }

    /// @notice Constructor to initialize the contract with token addresses and exchange rate
    /// @param _tokenA Address of the first token
    /// @param _tokenB Address of the second token
    /// @param _exchangeRate Initial exchange rate between tokenA and tokenB
    constructor(address _tokenA, address _tokenB, uint _exchangeRate) {
        i_owner = msg.sender;
        i_tokenA = IERC20(_tokenA);
        i_tokenB = IERC20(_tokenB);
        exchangeRate = _exchangeRate;
    }

    /// @notice Allows the owner to set a new exchange rate
    /// @param _newRate The new exchange rate
    function setExchangeRate(uint _newRate) public onlyOwner {
        exchangeRate = _newRate;
        emit ExchangeRateUpdated(_newRate);
    }

    /// @notice Exchange a specified amount of tokenA for tokenB
    /// @param amountA The amount of tokenA to exchange
    function exchangeTokenAForTokenB(uint amountA) public {
        uint amountB = amountA * exchangeRate;
        
        if (i_tokenA.balanceOf(msg.sender) < amountA) {
            revert SimpleDEX__NotEnoughTokenA(msg.sender, amountA);
        }

        if (i_tokenB.balanceOf(address(this)) < amountB) {
            revert SimpleDEX__ProvideMoreLiquidityForTokenB(amountB);
        }

        // Transfer tokenA from sender to contract
        require(i_tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of tokenA failed");

        // Transfer tokenB from contract to sender
        require(i_tokenB.transfer(msg.sender, amountB), "Transfer of tokenB failed");

        s_reserveA += amountA;
        s_reserveB -= amountB;

        emit Swapped(address(i_tokenA), amountA, address(i_tokenB), amountB);
    }

    /// @notice Exchange a specified amount of tokenB for tokenA
    /// @param amountB The amount of tokenB to exchange
    function exchangeTokenBForTokenA(uint amountB) public {
        uint amountA = amountB / exchangeRate;

        if (i_tokenB.balanceOf(msg.sender) < amountB) {
            revert SimpleDEX__NotEnoughTokenB(msg.sender, amountB);
        }

        if (i_tokenA.balanceOf(address(this)) < amountA) {
            revert SimpleDEX__ProvideMoreLiquidityForTokenA(amountA);
        }

        // Transfer tokenB from sender to contract
        require(i_tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of tokenB failed");

        // Transfer tokenA from contract to sender
        require(i_tokenA.transfer(msg.sender, amountA), "Transfer of tokenA failed");

        s_reserveB += amountB;
        s_reserveA -= amountA;

        emit Swapped(address(i_tokenB), amountB, address(i_tokenA), amountA);
    }

    /// @notice Provide liquidity to the DEX
    /// @param _amountA Amount of tokenA to provide
    /// @param _amountB Amount of tokenB to provide
    function provideLiquidity(uint256 _amountA, uint256 _amountB) external {
        IERC20 tokenA = i_tokenA;
        IERC20 tokenB = i_tokenB;

        // Ensure sufficient allowance for tokens
        require(tokenA.allowance(msg.sender, address(this)) >= _amountA, "Not enough allowance for tokenA");
        require(tokenB.allowance(msg.sender, address(this)) >= _amountB, "Not enough allowance for tokenB");

        // Transfer tokens from sender to contract
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        _updateLiquidity(s_reserveA + _amountA, s_reserveB + _amountB);

        emit AddedLiquidity(address(tokenA), _amountA, address(tokenB), _amountB);
    }

    /// @notice Remove liquidity from the DEX (owner-only)
    /// @param _amountA Amount of tokenA to remove
    /// @param _amountB Amount of tokenB to remove
    function removeLiquidity(uint256 _amountA, uint256 _amountB) external onlyOwner {
        IERC20 tokenA = i_tokenA;
        IERC20 tokenB = i_tokenB;

        // Ensure sufficient reserves for removal
        require(s_reserveA >= _amountA, "Not enough reserve for tokenA");
        require(s_reserveB >= _amountB, "Not enough reserve for tokenB");

        // Transfer tokens from contract to owner
        tokenA.transfer(msg.sender, _amountA);
        tokenB.transfer(msg.sender, _amountB);

        _updateLiquidity(s_reserveA - _amountA, s_reserveB - _amountB);

        emit RemovedLiquidity(address(tokenA), _amountA, address(tokenB), _amountB);
    }

    /// @notice Get the current reserves of tokenA and tokenB
    /// @return The reserves of tokenA and tokenB
    function getReserves() public view returns (uint256, uint256) {
        return (s_reserveA, s_reserveB);
    }

    /// @notice Get the addresses of tokenA and tokenB
    /// @return The addresses of tokenA and tokenB
    function getTokenAddress() public view returns (address, address) {
        return (address(i_tokenA), address(i_tokenB));
    }

    /// @notice Internal function to update the liquidity reserves
    /// @param reserveA New reserve of tokenA
    /// @param reserveB New reserve of tokenB
    function _updateLiquidity(uint256 reserveA, uint256 reserveB) internal {
        s_reserveA = reserveA;
        s_reserveB = reserveB;
    }

    /// @notice Get the current exchange rate between tokenA and tokenB
    /// @return The current exchange rate
    function showExchangeRate() public view returns (uint256) {
        return exchangeRate;
    }
}
