pragma solidity ^0.7.0;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { IProvider, BarnBridgeMappingInterface } from "./interface.sol";


abstract contract Helpers is DSMath, Basic {

    // BB_AaveMarket
    // BB_CompMarket
    // BB_CreamMarket

     // max duration of a purchased sBond
    // uint16 public BOND_LIFE_MAX = 90; // in days

    uint256 public constant EXP_SCALE = 1e18;

    /**
     * @dev BarnBridge Mapping
     */
    BarnBridgeMappingInterface internal constant bbMapping = BarnBridgeMappingInterface(address(0));
    RewardPoolFactory internal constant rp_factory = RewardPoolFactory(address(0));


    function getBalanceOfUnderlying(ISmartYield sy_pool, address addr) public view returns (uint){
        address _provPool = sy_pool.pool ;
        return TokenInterface(
            IProvider(_provPool).uToken()
            ).balanceOf(addr);

    }

    function rewardPoolExists(ISmartYield sy_pool) public view returns (bool) {
        for (i=0; i < rp_factory.pools().length , i++){
            if IProvider(sy_pool.pool()) == rp_factory.pools[i].poolToken() return true;
        }
        return false
    }
    function getRewardsPool(ISmartYield sy_pool) public view returns (address) {
        for (i=0; i < rp_factory.pools().length , i++){
            if IProvider(sy_pool.pool()) == rp_factory.pools[i].poolToken()
                return rp_factory.pools[i];
        } 
    }

    function bondLifeMax(ISmartYield sy_pool){
        
    }
}