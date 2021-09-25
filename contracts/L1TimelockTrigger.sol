pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "@pooltogether/v4-core/contracts/interfaces/ITsunamiDrawSettingsHistory.sol";
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

  /* ============ Global Variables ============ */

  /// @notice Internal TsunamiDrawSettingsHistory reference.
  ITsunamiDrawSettingsHistory internal immutable tsunamiDrawSettingsHistory;

  /// @notice Internal Timelock struct reference.
  IDrawCalculatorTimelock internal timelock;

  /* ============ Deploy ============ */

  /**
    * @notice Initialize L1TimelockTrigger smart contract.
    * @param _tsunamiDrawSettingsHistory TsunamiDrawSettingsHistory address
    * @param _timelock           Elapsed seconds before new Draw is available
  */
  constructor (
    address owner,
    ITsunamiDrawSettingsHistory _tsunamiDrawSettingsHistory,
    IDrawCalculatorTimelock _timelock
  ) Ownable(owner) {
    tsunamiDrawSettingsHistory = _tsunamiDrawSettingsHistory;
    timelock = _timelock;
  }

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Restricts new draws by forcing a push timelock.
    * @param _drawId draw id
    * @param _drawSetting Draw settings
  */
  function pushDrawSettings(uint32 _drawId, DrawLib.TsunamiDrawSettings memory _drawSetting) external onlyManagerOrOwner {
    timelock.lock(_drawId);
    tsunamiDrawSettingsHistory.pushDrawSettings(_drawId, _drawSetting);
  }

}