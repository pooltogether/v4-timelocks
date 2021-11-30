// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

interface IPrizeDistributionFactory {
  function pushPrizeDistribution(uint32 _drawId, uint256 _totalNetworkTicketSupply) external;
}

/**
  * @title  PoolTogether V4 IPrizeDistributionTimelock 
  * @author PoolTogether Inc Team
  * @notice The IPrizeDistributionTimelock smart contract interface...
*/
interface IDrawAndPrizeDistributionTimelock  {
  function push(IDrawBeacon.Draw memory draw, uint256 totalNetworkTicketSupply) external;
}

/**
  * @title  PoolTogether V4 PrizeDistributionTimelock
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionTimelock smart contract...
*/
contract DrawAndPrizeDistributionTimelock is IDrawAndPrizeDistributionTimelock, Manageable {

  /* ============ Global Variables ============ */

    /// @notice The DrawBuffer contract address.
    IDrawBuffer public immutable drawBuffer;

    /// @notice Internal PrizeDistributionFactory reference.
    IPrizeDistributionFactory public immutable prizeDistributionFactory;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public timelock;

  /* ============ Constructor ============ */

    /**
     * @notice Initialize DrawAndPrizeDistributionTimelock smart contract.
     * @param _owner The smart contract owner
     */
    constructor(
      address _owner,
      IDrawBuffer _drawBuffer,
      IPrizeDistributionFactory _prizeDistributionFactory,
      IDrawCalculatorTimelock _timelock) Ownable(_owner) {
        drawBuffer = _drawBuffer;
        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;
      }

  function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply) external override onlyManagerOrOwner {
      timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
      drawBuffer.pushDraw(_draw);
      prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
  }
}