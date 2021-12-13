// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./AutoCompoundPool.sol";

contract FuturaCompoundPool is AutoCompoundPool {
    uint256 public processingFeesThreshold = 500000000000000000 wei;
    address public processingFeesDestination;

    constructor(IFutura futura, IFuturaLinkFuel fuel, address processingFeeDestination, address routerAddress, IBEP20 _outToken) AutoCompoundPool(futura, fuel, routerAddress, _outToken) { 
        setProcessingFeesDestination(processingFeeDestination);
    }

    function doProcessFunds(uint256 gas) internal override {
        super.doProcessFunds(gas);

        if (processingFees >= processingFeesThreshold) {
            swapBNBForTokens(swapTokensForBNB(processingFees, outToken, address(this)), futura, processingFeesDestination);
            delete processingFees;
        }
    }

    function swapBNBForTokens(uint256 bnbAmount, IBEP20 token, address to) internal returns(uint256) { 
        // Generate pair for WBNB -> Token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(token);

        // Swap and send the tokens to the 'to' address
        uint256 previousBalance = token.balanceOf(to);
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(0, path, to, block.timestamp + 360);
        return token.balanceOf(to) - previousBalance;
    }

    function swapTokensForBNB(uint256 tokenAmount, IBEP20 token, address to) internal returns(uint256) {
        uint256 initialBalance = to.balance;
        
        // Generate pair for Token -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = _pancakeswapV2Router.WETH();

        // Swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp + 360);
        
        // Return the amount received
        return to.balance - initialBalance;
    }
    
    function setProcessingFeesThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "FuturaEthPool: Invalid value");
        processingFeesThreshold = threshold;
    }

    function setProcessingFeesDestination(address destination) public onlyOwner {
        require(destination != address(0), "FuturaEthPool: Invalid address");
        processingFeesDestination = destination;
    }

    function approvePancake() external onlyOwner {
        outToken.approve(address(_pancakeswapV2Router), ~uint256(0));
    }
}