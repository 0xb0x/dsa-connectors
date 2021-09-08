// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ISmartYield is IERC20{

    // a senior BOND (metadata for NFT)
    struct SeniorBond {
        // amount seniors put in
        uint256 principal;
        // amount yielded at the end. total = principal + gain
        uint256 gain;
        // bond was issued at timestamp
        uint256 issuedAt;
        // bond matures at timestamp
        uint256 maturesAt;
        // was it liquidated yet
        bool liquidated;
    }

    // a junior BOND (metadata for NFT)
    struct JuniorBond {
        // amount of tokens (jTokens) junior put in
        uint256 tokens;
        // bond matures at timestamp
        uint256 maturesAt;
    }

    // a checkpoint for all JuniorBonds with same maturity date JuniorBond.maturesAt
    struct JuniorBondsAt {
        // sum of JuniorBond.tokens for JuniorBonds with the same JuniorBond.maturesAt
        uint256 tokens;
        // price at which JuniorBonds will be paid. Initially 0 -> unliquidated (price is in the future or not yet liquidated)
        uint256 price;
    }

    function controller() external view returns (address);

    function buyBond(uint256 principalAmount_, uint256 minGain_, uint256 deadline_, uint16 forDays_) external returns (uint256);

    function redeemBond(uint256 bondId_) external;

    function buyTokens(uint256 underlyingAmount_, uint256 minTokens_, uint256 deadline_) external;

    /**
     * sell all tokens instantly
     */
    function sellTokens(uint256 tokens_, uint256 minUnderlying_, uint256 deadline_) external;

    function buyJuniorBond(uint256 tokenAmount_, uint256 maxMaturesAt_, uint256 deadline_) external;

    function redeemJuniorBond(uint256 jBondId_) external;

    function pool() external view returns(address);

    function juniorBondId() external view returns(uint256);

    function seniorBondId() external view returns(uint256);



}


interface BarnBridgeMappingInterface {
    function smartYieldPoolMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}

interface IProvider {
    function uToken() external view returns (address);

    function smartYield() external view returns (address);

    // current total underlying balance as measured by the provider pool, without fees
    function underlyingBalance() external returns (uint256);

}

interface YieldFarmContinuous{
    function poolToken() external view returns(IERC20);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawAndClaim(uint256 amount) external returns (uint256);

    function balances(address user) external returns (uint256);

    function claim() external returns (uint256);
}

interface RewardFactory{
    function pools() external view returns(YieldFarmContinuous[] memory); 
    function numberOfPools() external view returns(uint);
}