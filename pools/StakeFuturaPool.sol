// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./FuturaLinkPool.sol";

contract StakeFuturaPool is FuturaLinkPool {
    uint256 burnTokensThreshold;

    constructor(IFutura futura, IFuturaLinkFuel fuel, IInvestor investor, address routerAddress, IBEP20 outToken) FuturaLinkPool(futura, fuel, investor, routerAddress, futura, outToken) {
        isStakingEnabled = true;
        burnTokensThreshold = 100000 * 10**futura.decimals();
    }

   function doProcessFunds(uint256 gas) override virtual internal {
        if (futura.isRewardReady(address(this))) {
            futura.claimReward(address(this));
        }

       super.doProcessFunds(gas);

        if (feeTokens >= burnTokensThreshold) {
            inToken.transfer(BURN_ADDRESS, feeTokens);
            emit Burned(feeTokens);

            delete feeTokens;
        }
   }

   function setBurnTokensThreshold(uint256 threshold) external onlyOwner {
       require(threshold > 0, "StakeFuturaPool: Invalid value");
       burnTokensThreshold = threshold;
   }
}