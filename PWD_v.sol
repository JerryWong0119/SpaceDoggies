// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWDToken is ERC20, Ownable {
    constructor() ERC20("PWDToken", "PWD") {
        _mint(msg.sender, 300000000 * 10 ** decimals());
    }

    /****************For Space Doggies****************/
    // address private _pwdTreasuryAddress;    
    event Withdraw(address indexed from, address indexed to, uint256 value, string data);
    event Deposit(address indexed from, address indexed to, uint256 value, string data);
    mapping(uint256 => address) private whiteList; 

    modifier isWhiteList(uint256 _id) {
        _checkWhiteList(_id);
        _;
    }

    function _checkWhiteList(uint256 _id) internal view virtual {
        require( _msgSender() == whiteList[_id], "SpaceDoggiesNFT: caller is not the whitelist");
    }

    function setWhiteList(uint256 _id, address _treasury) external onlyOwner returns (bool) {
        require(_id > 0, "SpaceDoggiesNFT: id must > 0");
        require(_treasury != address(0), "SpaceDoggiesNFT: minter address is zero");
        whiteList[_id] = _treasury;
        return true;
    }

    /**
     */
    function withdraw(address _to, uint256 _amount, string memory _data, uint256 _id) external isWhiteList(_id)  {
        require(msg.sender != address(0), "PWDToken: caller of the function is the zeor address");
        require(_to != address(0), "PWDToken: the withdraw account is the zero address");
        require(balanceOf(msg.sender) >= _amount, "PWDToken: the Treasury Wallet have not enough balance");
        transfer(_to, _amount);
        emit Withdraw(msg.sender, _to, _amount, _data);
    }

    /**
     */
    function deposit(address _account, address _to, uint256 _amount, string memory _data, uint256 _id) external {
        require(msg.sender != address(0), "PWDToken: caller of the function is the zeor address");
        require(_account != address(0), "PWDToken: the deposit account is the zero address");
        require(_to != address(0), "PWDToken: the receiving account is the zeor address");
        require(_to == whiteList[_id], "PWDToken: the receiving account must be Treasury Wallet");
        require(balanceOf(msg.sender) >= _amount, "PWDToken: PWD Token Insufficient Balance");
        _transfer(_account, _to, _amount);
        emit Deposit(_account, _to, _amount, _data);
    }
}

