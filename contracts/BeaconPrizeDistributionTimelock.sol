// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IBeaconPrizeDistributionTimelock.sol";
import "./interfaces/IPrizeDistributionFactory.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 BeaconPrizeDistributionTimelock
  * @author PoolTogether Inc Team
  * @notice The BeaconPrizeDistributionTimelock smart contract is an upgrade of the L1TimelockTimelock smart contract.
            Reducing protocol risk by eliminating off-chain computation of PrizeDistribution parameters. The timelock will
            only pass the total supply of all tickets in a "PrizePool Network" to the prize distribution factory contract.
*/
contract BeaconPrizeDistributionTimelock is IBeaconPrizeDistributionTimelock, Manageable {
  
  /* ============ Global Variables ============ */

  /// @notice PrizeDistributionFactory reference.
  IPrizeDistributionFactory public immutable prizeDistributionFactory;

  /// @notice DrawCalculatorTimelock reference.
  IDrawCalculatorTimelock public immutable timelock;

  /* ============ Constructor ============ */

    /**
     * @notice Initialize BeaconPrizeDistributionTimelock smart contract.
     * @param _owner The smart contract owner
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    constructor(
      address _owner,
      IPrizeDistributionFactory _prizeDistributionFactory,
      IDrawCalculatorTimelock _timelock) Ownable(_owner) 
    {
      prizeDistributionFactory = _prizeDistributionFactory;
      timelock = _timelock;

      emit Deployed(_prizeDistributionFactory, _timelock);
    }

  /// @inheritdoc IBeaconPrizeDistributionTimelock
  function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply) external override onlyManagerOrOwner {
      timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
      prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
      emit DrawAndPrizeDistributionPushed(_draw.drawId, _draw, _totalNetworkTicketSupply);
  }
}