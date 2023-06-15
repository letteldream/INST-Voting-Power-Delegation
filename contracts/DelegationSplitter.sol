/*
 * DelegationSplitter: A contract designed to split and manage voting power delegations by creating DelegationHolder contracts and delegate governance tokens.
 */

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {DelegationHolder} from './DelegationHolder.sol';

import {IDelegationSplitter} from './interfaces/IDelegationSplitter.sol';

error INVALID_ADDRESS();
error INVALID_AMOUNT();
error NOT_DELEGATION_HOLDER(address);

contract DelegationSplitter is Ownable, IDelegationSplitter {
    using SafeERC20 for IERC20;

    /* ============= STORAGE ============= */

    IERC20 public immutable token;

    uint256 private holderIndexer;

    mapping(address => bool) public isHolder;

    /* ============= EVENT ============= */

    event DelegationHolderCreated(address indexed holder);
    event Transferred(
        address indexed fromHolder,
        address indexed toHolder,
        uint256 amount
    );
    event Withdrawn(
        address indexed fromHolder,
        address indexed to,
        uint256 amount
    );
    event Delegated(
        address indexed from,
        address indexed toHolder,
        uint256 amount
    );

    /* ============= INITIALIZATION ============= */

    constructor(IERC20 _token) Ownable() {
        token = _token;
    }

    /* ============= VIEW FUNCTIONS ============= */

    function governanceToken() external view override returns (address) {
        return address(token);
    }

    function delegatedOf(address _holder) external view returns (uint256) {
        return token.balanceOf(_holder);
    }

    /* ============= PUBLIC FUNCTIONS ============= */

    function createDelegationHolder(address _delegatee) external onlyOwner {
        if (_delegatee == address(0)) revert INVALID_ADDRESS();

        bytes memory bytecode = abi.encodePacked(
            type(DelegationHolder).creationCode,
            abi.encode(_delegatee)
        );
        uint256 salt = holderIndexer++;
        address addr;

        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        isHolder[addr] = true;

        emit DelegationHolderCreated(addr);
    }

    function transferToken(
        address _fromHolder,
        address _toHolder,
        uint256 _amount
    ) external onlyOwner {
        if (!isHolder[_fromHolder]) revert NOT_DELEGATION_HOLDER(_fromHolder);
        if (!isHolder[_toHolder]) revert NOT_DELEGATION_HOLDER(_toHolder);
        if (_amount == 0) revert INVALID_AMOUNT();

        token.safeTransferFrom(_fromHolder, _toHolder, _amount);

        emit Transferred(_fromHolder, _toHolder, _amount);
    }

    function withdrawToken(
        address _fromHolder,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (!isHolder[_fromHolder]) revert NOT_DELEGATION_HOLDER(_fromHolder);
        if (_to == address(0)) revert INVALID_ADDRESS();
        if (_amount == 0) revert INVALID_AMOUNT();

        token.safeTransferFrom(_fromHolder, _to, _amount);

        emit Withdrawn(_fromHolder, _to, _amount);
    }

    function delegateToken(
        address _from,
        address _toHolder,
        uint256 _amount
    ) external onlyOwner {
        if (_from == address(0)) revert INVALID_ADDRESS();
        if (!isHolder[_toHolder]) revert NOT_DELEGATION_HOLDER(_toHolder);
        if (_amount == 0) revert INVALID_AMOUNT();

        token.safeTransferFrom(_from, _toHolder, _amount);

        emit Delegated(_from, _toHolder, _amount);
    }
}
