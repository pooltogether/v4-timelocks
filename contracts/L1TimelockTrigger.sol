// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";

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
    /* ============ Events ============ */

    /// @notice Emitted when the contract is deployed.
    /// @param prizeDistributionHistory The address of the prize distribution history contract.
    /// @param timelock The address of the DrawCalculatorTimelock
    event Deployed(
        IPrizeDistributionBuffer indexed prizeDistributionHistory,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when target prize distribution is pushed.
     * @param drawId    Draw ID
     * @param prizeDistribution PrizeDistribution
     */
    event PrizeDistributionPushed(uint32 indexed drawId, DrawLib.PrizeDistribution prizeDistribution);


    /* ============ Global Variables ============ */

    /// @notice Internal PrizeDistributionBuffer reference.
    IPrizeDistributionBuffer public immutable prizeDistributionHistory;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public timelock;

    /* ============ Deploy ============ */

    /**
     * @notice Initialize L1TimelockTrigger smart contract.
     * @param _owner                    Address of the L1TimelockTrigger owner.
     * @param _prizeDistributionHistory PrizeDistributionBuffer address
     * @param _timelock                 Elapsed seconds before new Draw is available
     */
    constructor(
        address _owner,
        IPrizeDistributionBuffer _prizeDistributionHistory,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        prizeDistributionHistory = _prizeDistributionHistory;
        timelock = _timelock;

        emit Deployed(_prizeDistributionHistory, _timelock);
    }

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _drawId draw id
     * @param _prizeDistribution PrizeDistribution parameters
     */
    function push(uint32 _drawId, DrawLib.PrizeDistribution memory _prizeDistribution)
        external
        onlyManagerOrOwner
    {
        timelock.lock(_drawId);
        prizeDistributionHistory.pushPrizeDistribution(_drawId, _prizeDistribution);
        emit PrizeDistributionPushed(_drawId, _prizeDistribution);
    }
}
