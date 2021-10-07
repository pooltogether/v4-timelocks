// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 L2TimelockTrigger
  * @author PoolTogether Inc Team
  * @notice L2TimelockTrigger(s) acts as an intermediary between multiple V4 smart contracts.
            The L2TimelockTrigger is responsible for pushing Draws to a DrawBuffer and routing
            claim requests from a PrizeDistributor to a DrawCalculator. The primary objective is
            to  include a "cooldown" period for all new Draws. Allowing the correction of a
            malicously set Draw in the unfortunate event an Owner is compromised.
*/
contract L2TimelockTrigger is Manageable {
    
    /// @notice Emitted when the contract is deployed.
    event Deployed(
        IDrawBuffer indexed DrawBuffer,
        IPrizeDistributionBuffer indexed prizeDistributionBuffer,
        IDrawCalculatorTimelock indexed timelock
    );

    /**
     * @notice Emitted when target prize distribution is pushed.
     * @param drawId    Draw ID
     * @param prizeDistribution PrizeDistribution
     */
    event DrawAndPrizeDistributionPushed(uint32 indexed drawId, IDrawBeacon.Draw draw, IPrizeDistributionBuffer.PrizeDistribution prizeDistribution);

    /* ============ Global Variables ============ */
    /// @notice The DrawBuffer contract address.
    IDrawBuffer public immutable DrawBuffer;

    /// @notice Internal PrizeDistributionBuffer reference.
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice Timelock struct reference.
    IDrawCalculatorTimelock public timelock;

    /* ============ Deploy ============ */

    /**
     * @notice Initialize L2TimelockTrigger smart contract.
     * @param _owner                       Address of the L2TimelockTrigger owner.
     * @param _prizeDistributionBuffer PrizeDistributionBuffer address
     * @param _DrawBuffer                DrawBuffer address
     * @param _timelock           Elapsed seconds before new Draw is available
     */
    constructor(
        address _owner,
        IDrawBuffer _DrawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        DrawBuffer = _DrawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;
        timelock = _timelock;

        emit Deployed(_DrawBuffer, _prizeDistributionBuffer, _timelock);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _draw Draw
     * @param _prizeDistribution PrizeDistribution
     */
    function push(IDrawBeacon.Draw memory _draw, IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution)
        external
        onlyManagerOrOwner
    {
        timelock.lock(_draw.drawId);
        DrawBuffer.pushDraw(_draw);
        prizeDistributionBuffer.pushPrizeDistribution(_draw.drawId, _prizeDistribution);
        emit DrawAndPrizeDistributionPushed(_draw.drawId, _draw, _prizeDistribution);
    }
}
