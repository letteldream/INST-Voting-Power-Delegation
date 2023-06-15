// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

interface IDelegationSplitter {
    function governanceToken() external view returns (address);
}
