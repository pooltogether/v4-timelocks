import { BigNumber } from "@ethersproject/bignumber";
import { ethers } from 'hardhat';

type DrawCalculatorSettings = {
    matchCardinality: BigNumber;
    numberOfPicks: BigNumber;
    distributions: BigNumber[];
    bitRangeSize: BigNumber;
    prize: BigNumber;
    startOffsetTimestamp: BigNumber;
    endOffsetTimestamp: BigNumber;
    maxPicksPerUser: BigNumber;
};

const drawSettings: DrawCalculatorSettings = {
  matchCardinality: BigNumber.from(5),
  numberOfPicks: ethers.utils.parseEther('1'),
  distributions: [ethers.utils.parseUnits('0.5', 9)],
  bitRangeSize: BigNumber.from(3),
  prize: ethers.utils.parseEther('100'),
  startOffsetTimestamp: BigNumber.from(0),
  endOffsetTimestamp: BigNumber.from(3600),
  maxPicksPerUser: BigNumber.from(10)
}

export const newDrawSettings = (cardinality: number = 5): any => {
  return {
    ...drawSettings,
    matchCardinality: BigNumber.from(cardinality)
  }
}
