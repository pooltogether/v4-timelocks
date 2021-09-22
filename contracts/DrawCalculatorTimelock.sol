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
  IDrawCalculator internal immutable calculator; // 160, leaves 96

  /// @notice Seconds required to elapse before newest Draw is available
  uint32 internal timelockDuration; // take 32

  /// @notice Internal Timelock struct reference.
  Timelock internal timelock; // new word

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

  /**
    * @notice Routes claim/calculate requests between ClaimableDraw and DrawCalculator.
    * @dev    Will enforce a "cooldown" period between when a Draw is pushed and when users can start to claim prizes.
    * @param user    User address
    * @param drawIds Draw.drawId
    * @param data    Encoded pick indices
    * @return Prizes awardable array
  */
  function calculate(address user, uint32[] calldata drawIds, bytes calldata data) external override view returns (uint256[] memory) {
    Timelock memory timelock = timelock;

    for (uint256 i = 0; i < drawIds.length; i++) {
      // if draw id matches timelock and not expired, revert
      if (drawIds[i] == timelock.drawId) {
        requireTimelockElapsed(timelock);
      }
    }

    return calculator.calculate(user, drawIds, data);
  }

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Restricts new draws by forcing a push timelock.
    * @param _drawId Draw id
  */
  function lock(uint32 _drawId) external override onlyManagerOrOwner returns (bool) {
    Timelock memory _timelock = timelock;
    require(_drawId == _timelock.drawId + 1, "OM/not-drawid-plus-one");
    requireTimelockElapsed(_timelock);
    timelock = Timelock({
      drawId: _drawId,
      timestamp: uint128(block.timestamp)
    });
    return true;
  }

  /**
    * @notice Require the timelock "cooldown" period has elapsed
  */
  function requireTimelockElapsed(Timelock memory _timelock) internal view {
    require(_timelockHasElapsed(_timelock), "OM/timelock-not-expired");
  }

  /**
    * @notice Read internal DrawCalculator variable.
    * @return IDrawCalculator
  */
  function getDrawCalculator() external override view returns (IDrawCalculator) {
    return calculator;
  }

  /**
    * @notice Read internal Timelock struct.
    * @return Timelock
  */
  function getTimelock() external override view returns (Timelock memory) {
    return timelock;
  }

  /**
    * @notice Read internal timelockDuration variable.
    * @return Seconds to pass before Draw is valid.
  */
  function getTimelockDuration() external override view returns (uint32) {
    return timelockDuration;
  }

  /**
    * @notice Set new Timelock struct.
    * @dev    Set new Timelock struct and emit TimelockSet event.
  */
  function setTimelock(Timelock memory _timelock) external override onlyOwner {
    timelock = _timelock;

    emit TimelockSet(_timelock);
  }

  /**
    * @notice Set new timelockDuration.
    * @dev    Set new timelockDuration and emit TimelockDurationSet event.
  */
  function setTimelockDuration(uint32 _timelockDuration) external override onlyOwner {
    timelockDuration = _timelockDuration;

    emit TimelockDurationSet(_timelockDuration);
  }

  /**
    * @notice Returns bool for timelockDuration elapsing.
    * @return True if timelockDuration, since last timelock has elapsed, false otherwse.
  */
  function hasElapsed() external override view returns (bool) {
    return _timelockHasElapsed(timelock);
  }

  /**
    * @notice Read global DrawCalculator variable.
    * @return IDrawCalculator
  */
  function _timelockHasElapsed(Timelock memory timelock) internal view returns (bool) {
    // If the timelock hasn't been initialized, then it's elapsed
    if (timelock.timestamp == 0) { return true; }
    // otherwise if the timelock has expired, we're good.
    return (block.timestamp > timelock.timestamp + timelockDuration);
  }
}
