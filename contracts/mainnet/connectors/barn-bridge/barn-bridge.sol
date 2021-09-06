pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
    function chief(address) external view returns (bool);
}

interface ISmartYield {
    function pool() external view returns (address);
}

interface Pool {
    function uToken() external view returns (address);
}

abstract contract Helpers {

    struct TokenMap {
        address smartYieldPool;
        address token;
    }

    event LogSmartYieldPoolAdded(string indexed name, address indexed token, address indexed ctoken);
    event LogSmartYieldPoolUpdated(string indexed name, address indexed token, address indexed ctoken);

    ConnectorsInterface public immutable connectors;

    // InstaIndex Address.
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    // address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping (string => TokenMap) public smartYieldPoolMapping;

    modifier isChief {
        require(msg.sender == instaIndex.master() || connectors.chief(msg.sender), "not-an-chief");
        _;
    }

    constructor(address _connectors) {
        connectors = ConnectorsInterface(_connectors);
    }

    function isSmartYieldPoolUnderlying(address smartYieldPool, address underlying) internal returns(bool){
        ISmartYield sy_pool = ISmartYield(smartYieldPool);
        return Pool(sy_pool).uToken() == underlying
    }

    function _addSmartYieldPoolMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _smartYieldPools
    ) internal {
        require(_names.length == _tokens.length, "addSmartYieldPoolMapping: not same length");
        require(_names.length == _smartYieldPools.length, "addSmartYieldPoolMapping: not same length");

        for (uint i = 0; i < _smartYieldPools.length; i++) {
            TokenMap memory _data = smartYieldPoolMapping[_names[i]];

            require(_data.smartYieldPool == address(0), "addSmartYieldPoolMapping: mapping added already");
            require(_data.token == address(0), "addSmartYieldPoolMapping: mapping added already");

            require(_tokens[i] != address(0), "addSmartYieldPoolMapping: _tokens address not vaild");
            require(_smartYieldPools[i] != address(0), "addSmartYieldPoolMapping: _smartYieldPools address not vaild");

            CTokenInterface _ctokenContract = CTokenInterface(_ctokens[i]);
            bool _val = isSmartYieldPoolUnderlying(_smartYieldPools[i], _tokens[i]);

            require(_val, "addSmartYieldPoolMapping: not a smartYieldPool or mapping mismatch");
    
            smartYieldPoolMapping[_names[i]] = TokenMap(
                _smartYieldPools[i],
                _tokens[i]
            );
            emit LogSmartYieldPoolAdded(_names[i], _tokens[i], _smartYieldPools[i]);
        }
    }

    function updateSmartYieldPoolMapping(
        string[] calldata _names,
        address[] memory _tokens,
        address[] calldata _smartYieldPools
    ) external {
        require(msg.sender == instaIndex.master(), "not-master");

        require(_names.length == _tokens.length, "updateSmartYieldPoolMapping: not same length");
        require(_names.length == _smartYieldPools.length, "updateSmartYieldPoolMapping: not same length");

        for (uint i = 0; i < _smartYieldPools.length; i++) {
            TokenMap memory _data = smartYieldPoolMapping[_names[i]];

            require(_data.smartYieldPool != address(0), "updateSmartYieldPoolMapping: mapping does not exist");
            require(_data.token != address(0), "updateSmartYieldPoolMapping: mapping does not exist");

            require(_tokens[i] != address(0), "updateSmartYieldPoolMapping: _tokens address not vaild");
            require(_smartYieldPools[i] != address(0), "updateSmartYieldPoolMapping: _smartYieldPools address not vaild");

        
            bool _val = isSmartYieldPoolUnderlying(_smartYieldPools[i], _tokens[i]);

            require(_val, "updateSmartYieldPoolMapping: not a smartYieldPool");
    
            smartYieldPoolMapping[_names[i]] = TokenMap(
                _smartYieldPools[i],
                _tokens[i]
            );
            emit LogSmartYieldPoolUpdated(_names[i], _tokens[i], _ctokens[i]);
        }
    }

    function addSmartYieldPoolMapping(
        string[] memory _names,
        address[] memory _tokens,
        address[] memory _smartYieldPools
    ) external isChief {
        _addSmartYieldPoolMapping(_names, _tokens, _ctokens);
    }

    function getMapping(string memory _tokenId) external view returns (address, address) {
        TokenMap memory _data = smartYieldPoolMapping[_tokenId];
        return (_data.token, _data.smartYieldPool);
    }

}

contract BarnBridgeCompoundMapping is Helpers {
    string constant public name = "Barnbridge-Mapping-v1.1";

    constructor(
        address _connectors,
        string[] memory _smartYieldPoolNames,
        address[] memory _tokens,
        address[] memory _smartYieldPools
    ) Helpers(_connectors) {
        _addSmartYieldPoolMapping(_smartYieldPoolNames, _tokens, _smartYieldPools);
    }
}