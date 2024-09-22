// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IExchange {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract SnipingBot {
    
    address public owner;
    IExchange public exchange;

    event SnipingOpportunity(address token, uint amountIn, uint amountOutMin);
    event Sniped(address token, uint amountReceived);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _exchange) {
        owner = msg.sender;
        exchange = IExchange(_exchange);
    }

    // Allow contract to receive ETH
    receive() external payable {}

    // Function to execute a snipe by calling the DEX swap function
    function snipeToken(address token, uint amountOutMin, address[] calldata path, uint deadline) external onlyOwner payable {
        require(msg.value > 0, "Must send ETH to swap");

        emit SnipingOpportunity(token, msg.value, amountOutMin);

        uint[] memory amounts = exchange.swapExactETHForTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
        
        emit Sniped(token, amounts[amounts.length - 1]);  // Emitting the amount of tokens received
    }

    // Withdraw any ERC20 tokens held by this contract
    function withdrawToken(address token) external onlyOwner {
        IToken erc20 = IToken(token);
        uint balance = erc20.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        erc20.transfer(owner, balance);
    }

    // Withdraw ETH from the contract
    function withdrawETH() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner).transfer(balance);
    }
}
