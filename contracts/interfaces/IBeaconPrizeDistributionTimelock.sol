// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "./IPrizeDistributionFactory.sol";
import "./IDrawCalculatorTimelock.sol";
/**
  * @title  PoolTogether V4 IBeaconPrizeDistributionTimelock 
  * @author PoolTogether Inc Team
  * @notice The IBeaconPrizeDistributionTimelock smart contract interface...
*/
interface IBeaconPrizeDistributionTimelock  {

  /// @notice Emitted when the contract is deployed.
  event Deployed(
    IPrizeDistributionFactory indexed prizeDistributionFactory,
    IDrawCalculatorTimelock indexed timelock
  );

  /**
    * @notice Emitted when Draw and PrizeDistribution are pushed to external contracts.
    * @param drawId Draw ID
    * @param draw Draw
    * @param totalNetworkTicketSupply totalNetworkTicketSupply
    */
  event DrawAndPrizeDistributionPushed(
    uint32 indexed drawId, 
    IDrawBeacon.Draw draw, 
    uint256 totalNetworkTicketSupply
  );

  /**
    * @notice Locks next Draw and pushes totalNetworkTicketSupply to PrizeDistributionFactory
    * @dev    Restricts new draws for N seconds by forcing timelock on the next target draw id.
    * @param draw Draw
    * @param totalNetworkTicketSupply totalNetworkTicketSupply
    */
  function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}