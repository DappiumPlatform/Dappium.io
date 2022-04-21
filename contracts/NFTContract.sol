// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTContract is
ERC721,
Ownable,
AccessControlEnumerable,
ERC721Enumerable,
ERC721Burnable,
ERC721Pausable
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIdCounter;
    string private baseTokenURI;
    uint256 private MAX_SUPPLY;

    // Token Information
    address public _buyTokenAddress;
    bool public isCurrencyMain;
    uint256 public itemPrice;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _maxSupply,
        uint256 _itemPrice,
        bool _isCurrencyMain
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        MAX_SUPPLY = _maxSupply;
        itemPrice = _itemPrice;
        isCurrencyMain = _isCurrencyMain;
    }

    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function currentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function updateAllowedBuyToken(address token_) public onlyOwner {
        _buyTokenAddress = token_;
    }

    function setItemPrice(uint256 price_) public onlyOwner {
        itemPrice = price_;
    }

    function tokenBuy() internal virtual {
        require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");
        require(IERC20(_buyTokenAddress).allowance(msg.sender, address(this)) >= itemPrice, "Not enough allowance");

        IERC20(_buyTokenAddress).safeTransferFrom(msg.sender, owner(), itemPrice);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function mainBuy() internal virtual {
        require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= itemPrice, "Not enough value sent");

        payable(owner()).transfer(msg.value);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function buy() external virtual payable {
        if (isCurrencyMain) {
            mainBuy();
        } else {
            tokenBuy();
        }
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}