// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CourageCoin is ERC20, ERC20Burnable, Ownable {


    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxBuyAmount;
    mapping (address => bool) private _isExcludedFromMaxTxAmount;


    uint256 private _totalHolders;
    uint256 private _maxPurchase;
    uint256 private _maxTransaction;
    bool private _isFeeActive = false;
    uint256 private constant _sellFee = 3;
    uint256 private constant _buyFee = 0;

    //Note kindly replace the address(this) with an example of you test wallet

    address payable private _courageFoundation;

    event UpdatedTotalHolders(uint256 totalHolders);
    

    constructor(address couragefoundation) ERC20("Courage Coin", "COURAGE") {
        _courageFoundation = payable(couragefoundation);
        _totalHolders = 0;
        _maxPurchase = totalSupply() * 2 / 100;
        _maxTransaction = totalSupply() * 2 / 100;
         _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_courageFoundation] = true;
        _isExcludedFromMaxBuyAmount[owner()] = true;
        _isExcludedFromMaxTxAmount[owner()] = true;
        _isExcludedFromMaxBuyAmount[_courageFoundation] = true;
        _isExcludedFromMaxTxAmount[_courageFoundation] = true;
        _isExcludedFromMaxBuyAmount[address(this)] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;
    }

     function excludeFromFee(address[] memory accounts, bool isExcluded) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = isExcluded;
        }
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        _updateMaxPurchaseAndTransaction();
    }

    function transferWithEth(address recipient, uint256 amount) public payable returns (bool) {
        require(amount <= _maxTransaction, "CourageCoin: Transfer amount exceeds maximum transaction limit");
        _updateTotalHolders(_msgSender(), recipient);

        uint256 ethAmount = msg.value;
        uint256 ethFee = (ethAmount * _sellFee) / 100;
        uint256 ethToSend = ethAmount - ethFee;

        _courageFoundation.transfer(ethFee);
        payable(recipient).transfer(ethToSend);
        return super.transfer(recipient, amount);
    }

    

     function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_isExcludedFromFee[recipient] && _isExcludedFromMaxBuyAmount[recipient] && _isExcludedFromMaxTxAmount[recipient]){
            return super.transfer(recipient, amount);
        }
        require(amount <= _maxTransaction, "CourageCoin: Transfer amount exceeds maximum transaction limit");
        _updateTotalHolders(_msgSender(), recipient);

        uint256 fee = (amount * _sellFee) / 100;
        uint256 tokensToBuy = amount - fee;

        _transfer(_msgSender(), address(_courageFoundation), fee);
        return super.transfer(recipient, tokensToBuy);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= _maxTransaction, "CourageCoin: Transfer amount exceeds maximum transaction limit");
        _updateTotalHolders(sender, recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    function _updateTotalHolders(address sender, address recipient) private {
        bool isNewHolder = balanceOf(recipient) == 0 && sender != recipient;
        if (isNewHolder) {
            _totalHolders += 1;
            emit UpdatedTotalHolders(_totalHolders);

            if (_totalHolders == 1000) {
                uint256 burnAmount = totalSupply() * 10 / 100;
                _burn(address(0), burnAmount);
            }
        }
    }

    function _updateMaxPurchaseAndTransaction() private {
        _maxPurchase = totalSupply() * 2 / 100;
        _maxTransaction = totalSupply() * 2 / 100;
    }

    // This fallback function is necessary to receive ETH payments
    receive() external payable {}
    
}
