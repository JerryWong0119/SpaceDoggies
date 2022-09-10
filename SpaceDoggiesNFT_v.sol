// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpaceDoggiesNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("SpaceDoggiesNFT", "SDT") {
        _tokenIdCounter.increment();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /****************For Space Doggies****************/
    struct SpaceDoggie {
        uint256 tokenId;                
        address payable mintedBy;       
        address payable currentOwner;   
        address payable previousOwner;  
        uint256 price;                  
        uint256 numberOfTransfers;      
        bool forGame;
    }

    mapping(uint256 => SpaceDoggie) public allSpaceDoggies;
    mapping(string => uint256) public orderId2TokenId;
    mapping(uint256 => address) private whiteList;

    event MintSpaceDoggie(address indexed from, address indexed owner, uint256 indexed tokenId, string orderId);
    event Token2Game(uint256 indexed tokenId, string orderId);
    event Game2Token(uint256 indexed tokenId, string orderId);
    event ExchangeToken(address indexed from, address indexed to, uint256 indexed tokenId, string orderId);

    modifier isWhiteList(uint256 _id) {
        _checkWhiteList(_id);
        _;
    }

    function _checkWhiteList(uint256 _id) internal view virtual {
        require( _msgSender() == whiteList[_id], "SpaceDoggiesNFT: caller is not the whitelist");
    }

    function setWhiteList(uint256 _id, address _minter) external onlyOwner returns (bool) {
        require(_id > 0, "SpaceDoggiesNFT: id must > 0");
        require(_minter != address(0), "SpaceDoggiesNFT: minter address is zero");
        whiteList[_id] = _minter;
        return true;
    }

    function mintSpaceDoggie(
        address _owner,
        string memory _orderId,
        uint256 _id
    ) external isWhiteList(_id) {
        require(msg.sender != address(0), "SpaceDoggiesNFT: caller of the function is the zeor address");
        require(!_exists(orderId2TokenId[_orderId]), "SpaceDoggiesNFT: Order id is already exists");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment(); // +1
        _safeMint(_owner, tokenId);
        // _setTokenURI(tokenId, "http://122.248.215.114:8989/tokenid?id=");
        SpaceDoggie memory newSpaceDoggie = SpaceDoggie(
            tokenId,
            payable(msg.sender),
            payable(_owner),
            payable(address(0)),
            0,
            0,
            false
        );
        allSpaceDoggies[tokenId] = newSpaceDoggie;
        orderId2TokenId[_orderId] = tokenId;
        emit MintSpaceDoggie(address(0), _owner, tokenId, _orderId);
        
    }

    //
    function game2Token(uint _tokenId, string memory _orderId) public {
        require(msg.sender != address(0), "SpaceDoggiesNFT: caller of the function is the zeor address");
        require(_exists(_tokenId), "SpaceDoggiesNFT: require that token should exist");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "SpaceDoggiesNFT: owner should be equal to the caller");
        SpaceDoggie memory spacedoggie = allSpaceDoggies[_tokenId];
        require(spacedoggie.forGame, "SpaceDoggiesNFT: Token must in game");
        spacedoggie.forGame = false;
        spacedoggie.price = 0;
        allSpaceDoggies[_tokenId] = spacedoggie;
        emit Game2Token(_tokenId, _orderId);
    }

    //
    function token2Game(uint256 _tokenId, string memory _orderId) public {
        require(msg.sender != address(0), "SpaceDoggiesNFT: caller of the function is the zeor address");
        require(_exists(_tokenId), "SpaceDoggiesNFT: require that token should exist");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "SpaceDoggiesNFT: owner should be equal to the caller");
        SpaceDoggie memory spacedoggie = allSpaceDoggies[_tokenId];
        require(!spacedoggie.forGame, "SpaceDoggiesNFT: Token already in game");
        // price=0; forGame=true
        spacedoggie.price = 0;
        spacedoggie.forGame = true; // 
        allSpaceDoggies[_tokenId] = spacedoggie;
        emit Token2Game(_tokenId, _orderId);
    }

    //
    function exchangeToken(address _from, address _to, uint256 _tokenId, string memory _orderId, uint256 _id) external isWhiteList(_id) {
        require(msg.sender != address(0), "SpaceDoggiesNFT: caller of the function is the zeor address");
        require(_exists(_tokenId), "SpaceDoggiesNFT: require that token should exist");
        SpaceDoggie memory spacedoggie = allSpaceDoggies[_tokenId];
        spacedoggie.previousOwner =  spacedoggie.currentOwner;
        spacedoggie.currentOwner = payable(_to);
        spacedoggie.price = 0;
        spacedoggie.forGame = false;
        allSpaceDoggies[_tokenId] = spacedoggie;
        _transfer(_from, _to, _tokenId);
        emit ExchangeToken(_from, _to, _tokenId, _orderId);
    }

    function getTokenIdByOrderId(string memory _orderId) public view returns (uint256) {
        require(_exists(orderId2TokenId[_orderId]));
        return orderId2TokenId[_orderId];
    }
}
