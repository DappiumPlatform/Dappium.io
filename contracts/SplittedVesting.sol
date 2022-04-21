// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity 0.8.4;

import "./PaymentSplitter.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SplittedVesting is PaymentSplitter, Ownable {
    VestingWallet public vestingWallet;
    address token;

    constructor(address tokenAddress, address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {
        token = tokenAddress;
    }

    function addMorePayees(address[] memory _payees, uint256[] memory _shares) public onlyOwner {
        require(_payees.length == _shares.length, "payees and shares must have the same length");
        require(block.timestamp < vestingWallet.start(), "vestingWallet has already started");

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    modifier withdrawVesting(address _token) {
        vestingWallet.release(_token);
        _;
    }

    function setVestingWallet(address _vestingWallet) public onlyOwner {
        vestingWallet = VestingWallet(payable(_vestingWallet));
    }

    function claim() public virtual withdrawVesting(token) {
        require(block.timestamp >= vestingWallet.start(), "Cliff period has not ended yet.");
        super.release(IERC20(token), msg.sender);
    }
}