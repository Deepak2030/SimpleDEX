// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {

    address public immutable i_owner;
    IERC20 public immutable i_tokenA;
    IERC20 public immutable i_tokenB;
    uint256 public exchangeRate; 
    uint256 public s_reserveA;
    uint256 public s_reserveB;

    error SimpleDEX__NotOwner(address caller);
    error SimpleDEX__NotEnoughTokenA(address caller, uint256 amountA);
    error SimpleDEX__NotEnoughTokenB(address caller, uint256 amountB);
    error SimpleDEX__ProvideMoreLiquidityForTokenB(uint256 amountB);
    error SimpleDEX__ProvideMoreLiquidityForTokenA(uint256 amountA);

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

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert SimpleDEX__NotOwner(msg.sender);
        }
        _;
    }

    constructor(address _tokenA, address _tokenB, uint _exchangeRate) {
        i_owner = msg.sender;
        i_tokenA = IERC20(_tokenA);
        i_tokenB = IERC20(_tokenB);
        exchangeRate = _exchangeRate;
    }

    function setExchangeRate(uint _newRate) public onlyOwner {
        exchangeRate = _newRate;
        emit ExchangeRateUpdated(_newRate);
    }

    function exchangeTokenAForTokenB(uint amountA) public {
        uint amountB = amountA * exchangeRate;
        
        if (i_tokenA.balanceOf(msg.sender) < amountA) {
            revert SimpleDEX__NotEnoughTokenA(msg.sender, amountA);
        }

        if (i_tokenB.balanceOf(address(this)) < amountB) {
            revert SimpleDEX__ProvideMoreLiquidityForTokenB(amountB);
        }

        require(i_tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer of tokenA failed");
        require(i_tokenB.transfer(msg.sender, amountB), "Transfer of tokenB failed");

        s_reserveA += amountA;
        s_reserveB -= amountB;

        emit Swapped(address(i_tokenA), amountA, address(i_tokenB), amountB);
    }

    function exchangeTokenBForTokenA(uint amountB) public {
        uint amountA = amountB / exchangeRate;

        if (i_tokenB.balanceOf(msg.sender) < amountB) {
            revert SimpleDEX__NotEnoughTokenB(msg.sender, amountB);
        }

        if (i_tokenA.balanceOf(address(this)) < amountA) {
            revert SimpleDEX__ProvideMoreLiquidityForTokenA(amountA);
        }

        require(i_tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer of tokenB failed");
        require(i_tokenA.transfer(msg.sender, amountA), "Transfer of tokenA failed");

        s_reserveB += amountB;
        s_reserveA -= amountA;

        emit Swapped(address(i_tokenB), amountB, address(i_tokenA), amountA);
    }

    function provideLiquidity(uint256 _amountA, uint256 _amountB) external {
        IERC20 tokenA = i_tokenA;
        IERC20 tokenB = i_tokenB;

        require(tokenA.allowance(msg.sender, address(this)) >= _amountA, "Not enough allowance for tokenA");
        require(tokenB.allowance(msg.sender, address(this)) >= _amountB, "Not enough allowance for tokenB");

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        _updateLiquidity(s_reserveA + _amountA, s_reserveB + _amountB);

        emit AddedLiquidity(address(tokenA), _amountA, address(tokenB), _amountB);
    }

    function removeLiquidity(uint256 _amountA, uint256 _amountB) external onlyOwner {
        IERC20 tokenA = i_tokenA;
        IERC20 tokenB = i_tokenB;

        require(s_reserveA >= _amountA, "Not enough reserve for tokenA");
        require(s_reserveB >= _amountB, "Not enough reserve for tokenB");

        tokenA.transfer(msg.sender, _amountA);
        tokenB.transfer(msg.sender, _amountB);

        _updateLiquidity(s_reserveA - _amountA, s_reserveB - _amountB);

        emit RemovedLiquidity(address(tokenA), _amountA, address(tokenB), _amountB);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (s_reserveA, s_reserveB);
    }

    function getTokenAddress() public view returns (address, address) {
        return (address(i_tokenA), address(i_tokenB));
    }

    function _updateLiquidity(uint256 reserveA, uint256 reserveB) internal {
        s_reserveA = reserveA;
        s_reserveB = reserveB;
    }

    function showExchangeRate() public view returns(uint256) {
        return exchangeRate;
    }
}
