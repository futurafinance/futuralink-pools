// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./FuturaLinkPool.sol";

contract StakeFuturaPool is FuturaLinkPool {
    uint256 burnTokensThreshold;

    constructor(IFutura futura, IFuturaLinkFuel fuel, address _routerAddress, IBEP20 _outToken) FuturaLinkPool(futura, fuel, _routerAddress, futura, _outToken) {
        futuralinkPointsPerToken = 10;
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