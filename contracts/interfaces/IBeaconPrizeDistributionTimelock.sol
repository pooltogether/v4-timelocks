// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";

/**
  * @title  PoolTogether V4 IBeaconPrizeDistributionTimelock 
  * @author PoolTogether Inc Team
  * @notice The IBeaconPrizeDistributionTimelock smart contract interface...
*/
interface IBeaconPrizeDistributionTimelock  {
  function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}