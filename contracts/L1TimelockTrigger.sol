// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionHistory.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawHistory.sol";

import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 L1TimelockTrigger
  * @author PoolTogether Inc Team
  * @notice L1TimelockTrigger(s) acts as an intermediary between multiple V4 smart contracts.
            The L1TimelockTrigger is responsible for pushing Draws to a DrawHistory and routing
            claim requests from a ClaimableDraw to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract L1TimelockTrigger is Manageable {

  /// @notice Emitted when the contract is deployed.
  event Deployed(
    IDrawHistory indexed drawHistory,
    ITsunamiDrawSettingsHistory indexed tsunamiDrawSettingsHistory,
    IDrawCalculatorTimelock indexed timelock
  );

  /* ============ Global Variables ============ */
  /// @notice
  IDrawHistory public immutable drawHistory;

  /// @notice Internal PrizeDistributionHistory reference.
  IPrizeDistributionHistory public immutable prizeDistributionHistory;

  /// @notice Timelock struct reference.
  IDrawCalculatorTimelock public timelock;

  /* ============ Deploy ============ */

  /**
    * @notice Initialize L1TimelockTrigger smart contract.
    * @param _owner                       Address of the L1TimelockTrigger owner.
    * @param _prizeDistributionHistory PrizeDistributionHistory address
    * @param _drawHistory                DrawHistory address
    * @param _timelock           Elapsed seconds before new Draw is available
  */
  constructor (
    address _owner,
    IDrawHistory _drawHistory,
    IPrizeDistributionHistory _prizeDistributionHistory,
    IDrawCalculatorTimelock _timelock
  ) Ownable(_owner) {
    drawHistory = _drawHistory;
    prizeDistributionHistory = _prizeDistributionHistory;
    timelock = _timelock;

    emit Deployed(_drawHistory, _tsunamiDrawSettingsHistory, _timelock);
  }

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Restricts new draws by forcing a push timelock.
    * @param _draw DrawLib.Draw
    * @param _drawSetting DrawLib.PrizeDistribution
  */
  function push(DrawLib.Draw memory _draw, DrawLib.PrizeDistribution memory _drawSetting) external onlyManagerOrOwner {
    timelock.lock(_draw.drawId);
    drawHistory.pushDraw(_draw);
    prizeDistributionHistory.pushDrawSettings(_draw.drawId, _drawSetting);
  }
}
