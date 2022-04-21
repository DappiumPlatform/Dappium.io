// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FTContract is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    using SafeERC20 for IERC20;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token Information
    address public _buyTokenAddress;
    bool public isCurrencyMain;
    mapping(uint256 => uint256) public itemPrices;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _uri,
        bool _isCurrencyMain
    ) ERC1155(_uri) {
        _name = name_;
        _symbol = symbol_;
        isCurrencyMain = _isCurrencyMain;
    }

    function updateAllowedBuyToken(address token_) public onlyOwner {
        _buyTokenAddress = token_;
    }

    function setItemPrices(uint256[] memory tokenIds, uint256[] memory prices) public onlyOwner {
        require(tokenIds.length == prices.length, "tokenIds and prices must be the same length");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            itemPrices[tokenIds[i]] = prices[i];
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function tokenBuy(uint256 _id, uint256 _amount) internal virtual {
        require(itemPrices[_id] > 0, "Item not on sale");
        require(IERC20(_buyTokenAddress).allowance(msg.sender, address(this)) >= (itemPrices[_id] * _amount), "Not enough allowance");

        IERC20(_buyTokenAddress).safeTransferFrom(msg.sender, owner(), (itemPrices[_id] * _amount));
        _mint(msg.sender, _id, _amount, "");
    }

    function mainBuy(uint256 _id, uint256 _amount) internal virtual {
        require(itemPrices[_id] > 0, "Item not on sale");
        require(msg.value >= (itemPrices[_id] * _amount), "Not enough value sent");

        payable(owner()).transfer(msg.value);
        _mint(msg.sender, _id, _amount, "");
    }

    function buy(uint256 _id, uint256 _amount) external virtual payable {
        if (isCurrencyMain) {
            mainBuy(_id, _amount);
        } else {
            tokenBuy(_id, _amount);
        }
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}