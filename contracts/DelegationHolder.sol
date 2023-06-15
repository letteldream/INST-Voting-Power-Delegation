// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IDelegationSplitter} from './interfaces/IDelegationSplitter.sol';

error NOT_DELEGATEE(address);

contract DelegationHolder {
    /* ============= STORAGE ============= */

    IDelegationSplitter public immutable splitter;

    address public immutable delegatee;

    /* ============= INITIALIZATION ============= */

    constructor(address _delegatee) {
        splitter = IDelegationSplitter(msg.sender);
        delegatee = _delegatee;

        IERC20(splitter.governanceToken()).approve(
            msg.sender,
            type(uint256).max
        );
    }

    /* ============= MODIFIER ============= */

    modifier onlyDelegatee() {
        if (msg.sender != delegatee) revert NOT_DELEGATEE(msg.sender);

        _;
    }

    /* ============= VIEW FUNCTIONS ============= */

    function governanceToken() external view returns (address) {
        return splitter.governanceToken();
    }

    function delegatedOf() external view returns (uint256) {
        return IERC20(splitter.governanceToken()).balanceOf(address(this));
    }

    /* ============= PUBLIC FUNCTIONS ============= */

    function vote(bytes32 _id, uint256 _value) external onlyDelegatee {}
}
