// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/IDrawCalculator.sol";

interface IDrawCalculatorTimelock {

  struct Timelock {
    uint128 timestamp;
    uint32 drawId;
  }

  event Deployed(
    IDrawCalculator indexed drawCalculator,
    uint32 timelockDuration
  );

  event TimelockSet(Timelock timelock);
  event TimelockDurationSet(uint32 duration);

  function calculate(address user, uint32[] calldata drawIds, bytes calldata data) external view returns (uint256[] memory);
  function lock(uint32 drawId) external returns (bool);
  function getDrawCalculator() external view returns (IDrawCalculator);
  function getTimelock() external view returns (Timelock memory);
  function getTimelockDuration() external view returns (uint32);
  function setTimelock(Timelock memory _timelock) external;
  function setTimelockDuration(uint32 _timelockDuration) external;
  function hasElapsed() external view returns (bool);
}
