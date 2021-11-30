// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

/**
  * @title  PoolTogether V4 IPrizeDistributionTimelock
  * @author PoolTogether Inc Team
  * @notice The IPrizeDistributionTimelock smart contract interface...
*/
interface IDrawAndPrizeDistributionTimelock  {
  
}

/**
  * @title  PoolTogether V4 PrizeDistributionTimelock
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionTimelock smart contract...
*/
contract DrawAndPrizeDistributionTimelock is IDrawAndPrizeDistributionTimelock, Manageable {

  /* ============ Deploy ============ */

    /**
     * @notice Initialize DrawAndPrizeDistributionTimelock smart contract.
     * @param _owner The smart contract owner
     */
    constructor(
        address _owner
    ) Ownable(_owner) {}

}