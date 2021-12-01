// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";

/**
  * @title  PoolTogether V4 IPrizeDistributionTimelock 
  * @author PoolTogether Inc Team
  * @notice The IPrizeDistributionTimelock smart contract interface...
*/
interface IReceiverDrawAndPrizeDistributionTimelock  {
  function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}