// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 OracleTimelock
  * @author PoolTogether Inc Team
  * @notice OracleTimelock(s) acts as an intermediary between multiple V4 smart contracts.
            The OracleTimelock is responsible for pushing Draws to a DrawHistory and routing
            claim requests from a ClaimableDraw to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract DrawCalculatorTimelock is IDrawCalculatorTimelock, Manageable {

  /* ============ Global Variables ============ */

  /// @notice Internal DrawCalculator reference.
  IDrawCalculator internal immutable calculator;

  /// @notice Seconds required to elapse before newest Draw is available
  uint32 internal timelockDuration;

  /// @notice Internal Timelock struct reference.
  Timelock internal timelock;

  /* ============ Deploy ============ */

  /**
    * @notice Initialize DrawCalculatorTimelockTrigger smart contract.
    * @param _owner                       Address of the DrawCalculator owner.
    * @param _calculator                 DrawCalculator address.
    * @param _timelockDuration           Elapsed seconds before new Draw is available.
  */
  constructor (
    address _owner,
    IDrawCalculator _calculator,
    uint32 _timelockDuration
  ) Ownable(_owner) {
    calculator = _calculator;
    timelockDuration = _timelockDuration;

    emit Deployed(_calculator, _timelockDuration);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IDrawCalculatorTimelock
  function calculate(address user, uint32[] calldata drawIds, bytes calldata data) external override view returns (uint256[] memory) {
    Timelock memory _timelock = timelock;

    for (uint256 i = 0; i < drawIds.length; i++) {
      // if draw id matches timelock and not expired, revert
      if (drawIds[i] == _timelock.drawId) {
        _requireTimelockElapsed(_timelock);
      }
    }

    return calculator.calculate(user, drawIds, data);
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function lock(uint32 _drawId) external override onlyManagerOrOwner returns (bool) {
    Timelock memory _timelock = timelock;
    require(_drawId == _timelock.drawId + 1, "OM/not-drawid-plus-one");
    _requireTimelockElapsed(_timelock);
    timelock = Timelock({
      drawId: _drawId,
      timestamp: uint128(block.timestamp)
    });
    return true;
  }

   /// @inheritdoc IDrawCalculatorTimelock
  function getDrawCalculator() external override view returns (IDrawCalculator) {
    return calculator;
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function getTimelock() external override view returns (Timelock memory) {
    return timelock;
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function getTimelockDuration() external override view returns (uint32) {
    return timelockDuration;
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function setTimelock(Timelock memory _timelock) external override onlyOwner {
    timelock = _timelock;

    emit TimelockSet(_timelock);
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function setTimelockDuration(uint32 _timelockDuration) external override onlyOwner {
    timelockDuration = _timelockDuration;

    emit TimelockDurationSet(_timelockDuration);
  }

  /// @inheritdoc IDrawCalculatorTimelock
  function hasElapsed() external override view returns (bool) {
    return _timelockHasElapsed(timelock);
  }


  /* ============ Internal Functions ============ */
  
  /**
    * @notice Read global DrawCalculator variable.
    * @return IDrawCalculator
  */
  function _timelockHasElapsed(Timelock memory _timelock) internal view returns (bool) {
    // If the timelock hasn't been initialized, then it's elapsed
    if (_timelock.timestamp == 0) { return true; }
    // otherwise if the timelock has expired, we're good.
    return (block.timestamp > _timelock.timestamp + timelockDuration);
  }

  /**
    * @notice Require the timelock "cooldown" period has elapsed
    * @param _timelock the Timelock to check
  */
  function _requireTimelockElapsed(Timelock memory _timelock) internal view {
    require(_timelockHasElapsed(_timelock), "OM/timelock-not-expired");
  }

}
