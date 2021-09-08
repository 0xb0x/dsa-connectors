pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { YieldFarmContinuous, IProvider, BarnBridgeMappingInterface, ISmartYield, RewardFactory } from "./interface.sol";


abstract contract Helpers is DSMath, Basic {

    // uint16 public BOND_LIFE_MAX = 90; // in days

    uint256 public constant EXP_SCALE = 1e18;

    /**
     * @dev BarnBridge Mapping
     */
    BarnBridgeMappingInterface internal constant bbMapping = BarnBridgeMappingInterface(address(0)); // mapping address from deploying barnbridge.sol
    RewardFactory internal constant rp_factory = RewardFactory(0x2e93403C675Ccb9C564edf2dC6001233d0650582);


    function getBalanceOfUnderlying(ISmartYield sy_pool, address addr) public view returns (uint256){
        address _provPool = sy_pool.pool() ;
        return TokenInterface(
            IProvider(_provPool).uToken()
            ).balanceOf(addr);
    }
    
    function rewardPoolExists(ISmartYield sy_pool) public view returns (bool){
        uint256 l1 = rp_factory.pools().length;
        YieldFarmContinuous[] memory yf_arr =  rp_factory.pools();
        for (uint i = 0; i < l1; i++){
            if (address(sy_pool) == address(yf_arr[i].poolToken())) return true;
        }
        return false;
    }

    function getRewardsPool(ISmartYield sy_pool) public view returns (YieldFarmContinuous) {
        uint256 l1 = rp_factory.pools().length;
        YieldFarmContinuous[] memory yf_arr =  rp_factory.pools();
        for (uint i = 0; i < l1; i++){
            if (address(sy_pool) == address(yf_arr[i].poolToken())) return yf_arr[i];
        }
    }
    // function bondLifeMax(ISmartYield sy_pool) public returns(uint16){
    //     return ;
    // }

}