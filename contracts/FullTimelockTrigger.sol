pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "@pooltogether/v4-core/contracts/interfaces/ITsunamiDrawSettingsHistory.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawHistory.sol";

import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 DrawSettingsTimelockTrigger
  * @author PoolTogether Inc Team
  * @notice DrawSettingsTimelockTrigger(s) acts as an intermediary between multiple V4 smart contracts.
            The DrawSettingsTimelockTrigger is responsible for pushing Draws to a DrawHistory and routing
            claim requests from a ClaimableDraw to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract FullTimelockTrigger is Manageable {

  /* ============ Global Variables ============ */
  /// @notice 
  IDrawHistory public immutable drawHistory;

  /// @notice Internal TsunamiDrawSettingsHistory reference.
  ITsunamiDrawSettingsHistory public immutable tsunamiDrawSettingsHistory;

  /// @notice Internal Timelock struct reference.
  IDrawCalculatorTimelock public timelock;

  /* ============ Deploy ============ */

  /**
    * @notice Initialize DrawSettingsTimelockTrigger smart contract.
    * @param _tsunamiDrawSettingsHistory TsunamiDrawSettingsHistory address
    * @param _drawHistory                DrawHistory address
    * @param _timelock           Elapsed seconds before new Draw is available
  */
  constructor (
    address owner,
    IDrawHistory _drawHistory,
    ITsunamiDrawSettingsHistory _tsunamiDrawSettingsHistory,
    IDrawCalculatorTimelock _timelock
  ) Ownable(owner) {
    drawHistory = _drawHistory;
    tsunamiDrawSettingsHistory = _tsunamiDrawSettingsHistory;
    timelock = _timelock;
  }
  
  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Restricts new draws by forcing a push timelock.
    * @param _draw DrawLib.Draw
  */
  function push(DrawLib.Draw memory _draw, DrawLib.TsunamiDrawSettings memory _drawSetting) external onlyManagerOrOwner {
    timelock.lock(_draw.drawId);
    drawHistory.pushDraw(_draw);
    tsunamiDrawSettingsHistory.pushDrawSettings(_draw.drawId, _drawSetting);
  }
}
