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
import { ISmartYield, YieldFarmContinuous, IProvider } from "./interface.sol";

abstract contract BarnBridgeResolver is Events, Helpers {

    /**
     * @notice User enters the senior tranche, an NFT representing the senior bond is minted
     * @param sy_pool Smart Yield Pool to interact with
     * @param amt amount to purchase senior bond with
     * @param minGain minimum gain
     * @param forDays bonds lifespan
     * @param deadline deadline(timestamp) for tx to occur
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */
     
    function buySeniorBondRaw(
        ISmartYield sy_pool,
        uint256 amt,  
        uint256 minGain, 
        uint16 forDays,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
    
        uint _amt = getUint(getId, amt);

        require(// forDays <= bondLifeMax(sy_pool) && forDays > 0
                address(sy_pool) != address(0)
                && deadline > block.timestamp,
                "Invalid Arg(s)"
            );
   
        _amt = _amt == uint(-1) ? getBalanceOfUnderlying(sy_pool, address(this)) : _amt;

        address token = IProvider(sy_pool.pool()).uToken();
        approve(TokenInterface(token), sy_pool.pool(), _amt);

        sy_pool.buyBond(
            _amt,
            minGain,
            deadline,
            forDays
        );

        uint nft_id = sy_pool.seniorBondId();
        setUint(setId, nft_id);

        _eventName = "LogBuyBond(address,uint256,uint256,uint16,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(sy_pool), _amt, minGain, forDays, deadline ,getId, setId);

    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */
    function buySeniorBond(
        string calldata tokenId,
        uint256 amt,
        uint16 forDays,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = buySeniorBondRaw(ISmartYield(_pool), amt, 0, forDays, block.timestamp + 1, getId, setId);
    }

    /**
     * @notice User buys jTokens (junior tokens), an ERC-20 token that represents 
     *          ownership in the tranche, are minted at an 1:1 ratio to the underlying asset
     * @param sy_pool Smart Yield Pool to interact with
     * @param amt amount of jTokens to purchase
     * @param minTokens minimum amount of jTokens to purchase
     * @param deadline deadline(timestamp) for tx to occur
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */

    function buyTokensRaw(
        ISmartYield sy_pool  /** address smartYieldPool*/,
        uint256 amt /**amount in underlying */, 
        uint256 minTokens /** minGain in underlying */, 
        uint256 deadline,
        uint256 getId,
        uint256 setId
        
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        require(address(sy_pool) != address(0)
                && deadline > block.timestamp,
                "invalid arg(s)"
            );
        uint256 initialBalOfUnderlying = getBalanceOfUnderlying(sy_pool, address(this));
        
        _amt = _amt == uint(-1) ? initialBalOfUnderlying : _amt;

        address token = IProvider(sy_pool.pool()).uToken();
        approve(TokenInterface(token), sy_pool.pool(), _amt);

        sy_pool.buyTokens(
            _amt,
            minTokens,
            deadline
        );
        uint256 finalBal = getBalanceOfUnderlying(sy_pool, address(this));

        _amt = sub(initialBalOfUnderlying, finalBal);

        setUint(setId, _amt);

        _eventName = "LogBuyTokens(address,uint256, uint256, uint256 ,uint256 ,uint256 )";
        _eventParam = abi.encode(address(sy_pool), amt, minTokens, deadline, getId, setId);

    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function buyTokens(
        string calldata tokenId,
        uint amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = buyTokensRaw(ISmartYield(_pool), amt, 0, block.timestamp + 1, getId, setId);
    }


    /**
     * @notice A junior holder has the option to sell his tokens before maturity, 
     *         but he will have to forfeit his potential future gain in order to protect 
     *         the senior bond holders’ guaranteed gains
     * @param sy_pool Smart Yield Pool to interact with
     * @param tokensAmount amount of jTokens to sell
     * @param minUnderlying minimum mount to sell tokens for
     * @param deadline deadline(timestamp) for tx to occur
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */

    function sellTokensRaw(
        ISmartYield sy_pool,
        uint256 tokensAmount, 
        uint256 minUnderlying,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, tokensAmount);
        
        require (
            address(sy_pool) != address(0)
            && _amt > 0
            && deadline > block.timestamp,
            "Invalid Arg(s)"
        );
            
        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        uint256 initialBal = sy_pool.balanceOf(address(this));
        sy_pool.sellTokens(
            _amt, 
            minUnderlying, 
            deadline
        );
        uint256 finalBal = sy_pool.balanceOf(address(this));
        _amt = sub(finalBal, initialBal);

        setUint(setId, _amt);

        _eventName = "LogSellTokens(address,uint256, uint256, int256 ,uint256 ,uint256 )";
        _eventParam = abi.encode(address(sy_pool), _amt , minUnderlying, deadline, getId, setId);
    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */
    function sellTokens(
        string calldata tokenId,
        uint amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = sellTokensRaw(ISmartYield(_pool), amt, 0, block.timestamp + 1, getId, setId);
    }


    /**
     * @notice Allows senior bond holder to redeem his bond, If the bond has reached maturity. 
     *         Anyone can redeem but owner gets principal + gain
     * @param sy_pool Smart Yield Pool to interact with
     * @param bondId_ id of senior bond to redeem
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */

    function redeemSeniorBondRaw(
        ISmartYield sy_pool,
        uint256 bondId_,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
        uint id = getUint(getId, bondId_);
        require(address(sy_pool) != address(0));
        sy_pool.redeemBond(id);

        setUint(setId, id);

        _eventName = "LogRedeemBond(address, uint256, uint256, uint256 )";
        _eventParam = abi.encode(address(sy_pool), id, getId, setId);
    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function redeemSeniorBond(
        string calldata tokenId,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = redeemSeniorBondRaw(ISmartYield(_pool), bondId, getId, setId);
    }

    /**
     * @notice In order to not forfeit his gain, a junior token holder can mint a 
     *         junior bond using his jTokens, which he can only redeem at maturity
     * @param sy_pool Smart Yield Pool to interact with
     * @param tokenAmount amount of jTokens
     * @param maxMaturesAt time of bond maturity
     * @param deadline deadline(timestamp) for tx to occur
     * @param getId ID to retrieve amt.
     * @param setId ID stores the junior bond id.
     */

    function buyJuniorBondRaw(
        ISmartYield sy_pool,
        uint256 tokenAmount,
        uint256 maxMaturesAt,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, tokenAmount);

        require(address(sy_pool) != address(0));

        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        sy_pool.buyJuniorBond(
            _amt, 
            maxMaturesAt, 
            deadline
        );

        setUint(setId, sy_pool.juniorBondId());

        _eventName = "LogBuyJuniorBond(address, uint256,uint256,uint256, uint256, uint256)";
        _eventParam = abi.encode(address(sy_pool), _amt, maxMaturesAt, deadline, getId, setId);
    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function buyJuniorBond(
        string calldata tokenId,
        uint256 tokenAmount,
        uint256 maxMaturesAt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = buyJuniorBondRaw(ISmartYield(_pool), tokenAmount, maxMaturesAt, block.timestamp + 1, getId, setId);
    }

    /**
     * @notice Allows senior bond holder to redeem his bond, If the bond has reached maturity.
     * @param sy_pool Smart Yield Pool to interact with
     * @param bondId Junior bond id to redeem
     * @param getId ID to retrieve amt.
     * @param setId ID stores the junior bond id.
     */

    function redeemJuniorBondRaw(
        ISmartYield sy_pool,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) public payable returns (string memory _eventName, bytes memory _eventParam){
        uint id = getUint(getId, bondId);
        require(address(sy_pool) != address(0));

        sy_pool.redeemJuniorBond(id);

        setUint(setId, id);

        _eventName = "LogRedeemJuniorBond(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(sy_pool), id, getId, setId);
    }


    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function redeemJuniorBond(
        string calldata tokenId,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = redeemJuniorBondRaw(ISmartYield(_pool), bondId, getId, setId);
    }

    /**
     * @notice Allows junior token holders to stake their jTokens in the reward pool. 
     * @param sy_pool Smart Yield Pool to interact with
     * @param amt amount of junior tokens to stake
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */

    function stakeRaw(
        ISmartYield sy_pool,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public returns (string memory _eventName, bytes memory _eventParam){
        uint _amt = getUint(getId, amt);

        _amt = _amt == uint(-1) ? sy_pool.balanceOf(address(this)) : _amt;

        require(rewardPoolExists(sy_pool), "Reward pool doesn't exist");

        approve(TokenInterface(address(sy_pool)), address(getRewardsPool(sy_pool)), _amt);

        uint initialBal = sy_pool.balanceOf((address(this)));

        getRewardsPool(sy_pool).deposit(_amt);

        uint finalBal = sy_pool.balanceOf((address(this)));

        _amt = sub(initialBal, finalBal);

        setUint(setId, _amt);

        _eventName = "LogStake(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(sy_pool), _amt, getId, setId);
    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function stake(
        string calldata tokenId,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = stakeRaw(ISmartYield(_pool), amt, getId, setId);
    }


    /**
     * @notice Allows depositors to unstake their jTokens from the reward pool and claims reward
     * @param sy_pool Smart Yield Pool to interact with
     * @param amt amount of jTokens to unstake
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of jTokens unstaked.
     */

    function unStakeRaw(
        ISmartYield sy_pool,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) public returns (string memory _eventName, bytes memory _eventParam){
        uint256 _amt = getUint(getId, amt);

        require(rewardPoolExists(sy_pool), "Reward pool doesn't exist");
        YieldFarmContinuous rew_pool = getRewardsPool(sy_pool);

        _amt = _amt == uint(-1) ? rew_pool.balances(address(this)) : _amt;

        _amt = rew_pool.withdrawAndClaim(_amt);

        setUint(setId, _amt);

        _eventName = "LogStake(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(address(sy_pool), _amt, getId, setId);

    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */

    function unStake(
         string calldata tokenId,
         uint256 amt,
         uint256 getId,
         uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = unStakeRaw(ISmartYield(_pool), amt, getId, setId);
    }

    /**
     * @notice Allows depositors to claim rewards from the reward pool without unstaking their jTokens
     * @param sy_pool Smart Yield Pool to interact with
     * @param setId ID stores the amount of token rewards recieved.
     */
    function claimRewardRaw(
        ISmartYield sy_pool,
        uint256 setId
    )public returns (string memory _eventName, bytes memory _eventParam){
        require(rewardPoolExists(sy_pool), "Reward pool doesn't exist");
        YieldFarmContinuous rew_pool = getRewardsPool(sy_pool);

        uint256 amtRecieved = rew_pool.claim();
        setUint(setId, amtRecieved);

        _eventName = "LogClaimRewards(address,uint256)";
        _eventParam = abi.encode(address(sy_pool), setId);
    }

    /**
     * @param tokenId The id of the Smart Yield Pool to interact with.
     */
    function claimReward(
        string calldata tokenId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam){
        (, address _pool) = bbMapping.getMapping(tokenId);
        (_eventName, _eventParam) = claimRewardRaw(ISmartYield(_pool), setId);
    }

}
contract ConnectV2BarnBridge is BarnBridgeResolver {
    string public name = "BarnBridge-v1.1";
}
