pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Barn-Bridge.
 * @dev Risk Tranching.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { ISmartYield} from "./interface.sol";

abstract contract BarnBridgeResolver is Events, Helpers {

    function buyBondRaw(
        ISmartYield sy_pool,
        uint256 amt,  
        uint256 minGain, 
        uint16 forDays,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
    
        uint _amt = getUint(getId, amt);

        require(forDays =< bondLifeMax(sy_pool) && forDays > 0
                && address(sy_pool) !=0
                && deadline > block.timestamp,
                "Invalid Arg(s)"
            );

        
        _amt = _amt == uint(-1) ? getBalanceOfUnderlying(pool, address(this)) : _amt;

        sy_pool.buyBond(
            _amt,
            minGain,
            deadline,
            forDays
        );

        uint nft_id = sy_pool.SeniorBondId;
        setUint(setId, nft_id);

    }
    function buyBond(
        string calldata tokenId,
        uint256 amt,
        uint16 forDays,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        buyBondRaw(ISmartYield(_pool), amt, 0, forDays, block.timestamp + 1, getId, setId);

    }


// ********************************************************************************
// ********************************************************************************

    function buyTokensRaw(
        ISmartYield sy_pool,    /** address smartYieldPool*/,
        uint256 amt /**amount in underlying */, 
        uint256 minTokens /** minGain in underlying */, 
        uint256 deadline,
        uint256 getId,
        uint256 setId
        
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(sy_pool != 0
                && deadline > block.timestamp,
                "invalid arg(s)"
            );

        _amt = _amt == uint(-1) ? getBalanceOfUnderlying(sy_pool, address(this)) : _amt;

        sy_pool.buyTokens(
            _amt,
            minTokens,
            deadline,
        );

        // uint jTokens = price(sy_pool);
        setUint(setId, _amt);

    }

    function buyTokens(
        string calldata tokenId,
        uint amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        buyTokensRaw(_pool, amt, 0, block.timestamp + 1, getId, setId);
    }

// ************************************************************************
    function sellTokensRaw(
        ISmartYield sy_pool,
        uint256 tokensAmount, 
        uint256 minUnderlying,
        int256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, tokensAmount);
        
        require (
            address(sy_pool) != 0
            && amt > 0
            && deadline > block.timestamp,
            "Invalid Arg(s)"
        );
            
        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        pool.sellTokens(
            _amt, 
            minUnderlying_, 
            deadline
        );

        setUint(setId, _amt);
    }

    function sellTokens(
        string calldata tokenId,
        uint amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        sellTokensRaw(ISmartYield(_pool), amt, 0, block.timestamp + 1, getId, setId);
    }
// ********************************************************************************


    function redeemBondRaw(
        ISmartYield sy_pool,
        uint256 bondId_,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
        uint id = getUint(getId, bondId_);
        require(address(sy_pool) != 0);
        sy_pool.redeemBond(id);

        setUint(setId, id);
    }

    function redeemBond(
        string calldata tokenId,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        sellTokensRaw(_pool, bondId, getId, setId);
    }


// *************************************************************************************
    function buyJuniorBondRaw(
        ISmartYield sy_pool,
        uint256 tokenAmount,
        uint256 maxMaturesAt,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, tokenAmount);

        require(address(sy_pool) != 0);

        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        sy_pool.buyJuniorBond(
            _amt, 
            maxMaturesAt, 
            deadline
        );

        setUint(setId, sy_pool.JuniorBondId);
    }

    function buyJuniorBond(
        uint256 tokenAmount,
        uint256 maxMaturesAt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        redeemBondRaw(ISmartYield(_pool), tokenAmount, maxMaturesAt, getId, setId);
    }
// ****************************************************************************************
    function redeemJuniorBondRaw(
        ISmartYield sy_pool,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
        uint id = getUint(getId, bondId);
        require(address(sy_pool) != 0);
        sy_pool.redeemJuniorBond(id);
        setUint(setId, id);
    }

    function redeemJuniorBond(
        string calldata tokenId,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        redeemBondRaw(ISmartYield(_pool), bondId, getId, setId);
    }

    function stakeRaw(
        ISmartYield sy_pool
        uint256 amt,
        uint256 getId
    ) public {
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        require(rewardPoolExists(sy_pool), "Reward pool doesn't exist");

        address rew_pool = getRewardsPool(sy_pool);
        IYieldFarm(rew_pool).deposit(_amt);
    }

    function stake(
        string calldata tokenId,
        uint256 amt,
        uint256 getId
    ) external {
        (, address _pool) = bbMapping.getMapping(tokenId);
        stakeRaw(ISmartYield(_pool), amt, getId);
    }

    function unStakeRaw(
        ISmartYield sy_pool,
        uint256 amt,
        uint256 getId
    ) public {
        uint _amt = getUint(getId, amt);

        require(rewardPoolExists(sy_pool), "Reward pool doesn't exist");
        address rew_pool = getRewardsPool(sy_pool);

        _amt = _amt == uint(-1) ? IYieldFarm(rew_pool).balances(address(this)) : _amt;

        IYieldFarm(rew_pool).withdrawAndClaim(_amt);

    }

    function unStake(
         string calldata tokenId,
         uint256 amt,
         uint256 getId
    ){
        (, address _pool) = bbMapping.getMapping(tokenId);
        unStakeRaw(ISmartYield(_pool), amt, getId);
    }





}