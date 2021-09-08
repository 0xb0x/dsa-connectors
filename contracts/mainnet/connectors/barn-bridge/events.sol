pragma solidity ^0.7.0;

contract Events {
    event LogBuyTokens(
        address indexed sy_pool,
        uint256 amt, 
        uint256 minTokens,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    );

    event LogBuyBond(
        address indexed sy_pool,
        uint256 amt,  
        uint256 minGain, 
        uint16 forDays,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    );

    event LogRedeemBond(
        address indexed sy_pool,
        uint256 bondId_,
        uint256 getId,
        uint256 setId
    );

    event LogSellTokens(
        address indexed sy_pool,
        uint256 tokensAmount, 
        uint256 minUnderlying,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    );

    event LogBuyJuniorBond(
        address indexed sy_pool,
        uint256 tokenAmount,
        uint256 maxMaturesAt,
        uint256 deadline,
        uint256 getId,
        uint256 setId
    );

    event LogRedeemJuniorBond(
        address indexed sy_pool,
        uint256 bondId,
        uint256 getId,
        uint256 setId
    );
    
    event LogStake(
        address indexed sy_pool,
        uint256 amt,
        uint256 getId,
        uint256 setId
    );

    event LogUnStake(
        address indexed sy_pool,
        uint256 amt,
        uint256 getId,
        uint256 setId
    );
    event LogClaimRewards(
        address indexed sy_pool,
        uint256 amount_recieved
    );
}
